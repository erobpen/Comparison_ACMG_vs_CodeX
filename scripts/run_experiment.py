import csv
import json
import os
import re
import subprocess
import time
from datetime import datetime
from pathlib import Path

import openpyxl
from openai import OpenAI


ROOT = Path(__file__).resolve().parents[1]
RESULTS = ROOT / "results"
WORKBOOK = RESULTS / "_input_snapshot" / "tasks_10.xlsx"
MAX_REPAIRS = 5
TIMEOUT_SECONDS = 60

RUNS = [
    ("gpt35", "GPT-3.5", "gpt-3.5-turbo"),
    ("gpt4omini", "GPT-4o-mini", "gpt-4o-mini"),
]


SYSTEM_PROMPT = """You generate MiniZinc constraint programming artifacts from natural language only.
Return strict JSON with exactly these string fields:
- model: complete MiniZinc model for generated_model.mzn
- data: complete MiniZinc data for generated_data.dzn

Requirements:
- Use only the problem description supplied by the user.
- Do not mention reference models or hidden benchmark data.
- The model and data together must compile and run with: minizinc --solver gecode generated_model.mzn generated_data.dzn
- Prefer clear finite domains and explicit constants.
- If the problem is optimization, include an objective.
- If the problem is satisfaction, use solve satisfy.
- Include an output block that prints the key decision variables and, if optimized, the objective.
- Return JSON only; do not wrap in markdown.
"""


REPAIR_SYSTEM_PROMPT = """You repair MiniZinc artifacts.
Return strict JSON with exactly these string fields:
- model: repaired complete MiniZinc model
- data: repaired complete MiniZinc data

Requirements:
- Use only the original natural language problem description and the MiniZinc error/output supplied by the user.
- Do not use any reference model or reference output.
- Preserve the intended problem semantics as much as possible.
- Return JSON only; do not wrap in markdown.
"""


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text or "", encoding="utf-8", newline="\n")


def strip_code_fence(text: str) -> str:
    text = text.strip()
    if text.startswith("```"):
        text = re.sub(r"^```(?:json)?\s*", "", text)
        text = re.sub(r"\s*```$", "", text)
    return text.strip()


def parse_json_artifacts(text: str) -> tuple[str, str]:
    cleaned = strip_code_fence(text)
    try:
        payload = json.loads(cleaned)
    except json.JSONDecodeError:
        match = re.search(r"\{.*\}", cleaned, flags=re.S)
        if not match:
            raise
        payload = json.loads(match.group(0))
    return str(payload.get("model", "")).strip() + "\n", str(payload.get("data", "")).strip() + "\n"


def call_model(client: OpenAI, model_name: str, messages: list[dict]) -> str:
    response = client.chat.completions.create(
        model=model_name,
        messages=messages,
        temperature=0,
        response_format={"type": "json_object"},
    )
    return response.choices[0].message.content or ""


def run_minizinc(model_path: Path, data_path: Path) -> dict:
    cmd = [
        "minizinc",
        "--solver",
        "gecode",
        "--time-limit",
        str(TIMEOUT_SECONDS * 1000),
        str(model_path),
        str(data_path),
    ]
    started = time.perf_counter()
    try:
        proc = subprocess.run(
            cmd,
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=TIMEOUT_SECONDS + 10,
        )
        timed_out = False
    except subprocess.TimeoutExpired as exc:
        elapsed = time.perf_counter() - started
        return {
            "cmd": " ".join(cmd),
            "returncode": None,
            "stdout": exc.stdout or "",
            "stderr": exc.stderr or "Python subprocess timeout expired.",
            "elapsed": elapsed,
            "timed_out": True,
        }
    elapsed = time.perf_counter() - started
    return {
        "cmd": " ".join(cmd),
        "returncode": proc.returncode,
        "stdout": proc.stdout,
        "stderr": proc.stderr,
        "elapsed": elapsed,
        "timed_out": timed_out,
    }


def solver_status(result: dict) -> str:
    out = ((result.get("stdout") or "") + "\n" + (result.get("stderr") or "")).upper()
    if result.get("timed_out"):
        return "TIMEOUT"
    if result.get("returncode") is None and "REFERENCE NOT EXECUTED" in out:
        return "NOT_RUN"
    if result.get("returncode") is None and ("RATELIMITERROR" in out or "INSUFFICIENT_QUOTA" in out):
        return "API_ERROR"
    if result.get("returncode") is None and "GENERATION DID NOT RUN" in out:
        return "NOT_RUN"
    if result.get("returncode") not in (0,):
        return "ERROR"
    if "UNSATISFIABLE" in out:
        return "UNSAT"
    if "UNKNOWN" in out:
        return "UNKNOWN"
    if "==========" in out:
        return "OPTIMAL_OR_COMPLETE"
    if "----------" in out or (result.get("stdout") or "").strip():
        return "SAT"
    return "SUCCESS_NO_OUTPUT"


def extract_objective(stdout: str) -> str | None:
    patterns = [
        r"objective\s*=\s*(-?\d+(?:\.\d+)?)",
        r"obj\s*=\s*(-?\d+(?:\.\d+)?)",
        r"total[_ ]?(?:cost|profit|value|price|energy)?\s*=\s*(-?\d+(?:\.\d+)?)",
    ]
    for pattern in patterns:
        match = re.search(pattern, stdout, flags=re.I)
        if match:
            return match.group(1)
    return None


def normalized_assignments(stdout: str) -> dict[str, str]:
    assignments = {}
    for line in stdout.splitlines():
        if "=" not in line or line.strip().startswith("%"):
            continue
        if line.strip() in {"----------", "=========="}:
            continue
        name, value = line.split("=", 1)
        name = name.strip()
        value = value.strip().rstrip(";")
        if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name):
            assignments[name] = re.sub(r"\s+", "", value)
    return assignments


def compare_results(generated: dict, reference: dict) -> tuple[str, str]:
    gen_status = solver_status(generated)
    ref_status = solver_status(reference)
    if gen_status in {"ERROR", "TIMEOUT"} or ref_status in {"ERROR", "TIMEOUT"}:
        return "NOT_COMPARABLE", "At least one execution did not complete successfully."
    if gen_status in {"UNSAT", "UNKNOWN"} or ref_status in {"UNSAT", "UNKNOWN"}:
        return ("SAME_RESULT" if gen_status == ref_status else "DIFFERENT_RESULT"), "Compared solver satisfiability status."

    gen_obj = extract_objective(generated.get("stdout") or "")
    ref_obj = extract_objective(reference.get("stdout") or "")
    if gen_obj is not None or ref_obj is not None:
        if gen_obj is not None and ref_obj is not None:
            return ("SAME_RESULT" if gen_obj == ref_obj else "DIFFERENT_RESULT"), f"Compared objective values generated={gen_obj}, reference={ref_obj}."
        return "NOT_COMPARABLE", "Only one output exposed a recognizable objective value."

    gen_assign = normalized_assignments(generated.get("stdout") or "")
    ref_assign = normalized_assignments(reference.get("stdout") or "")
    common = sorted(set(gen_assign) & set(ref_assign))
    if common:
        equal = all(gen_assign[name] == ref_assign[name] for name in common)
        return ("SAME_RESULT" if equal else "DIFFERENT_RESULT"), f"Compared common assignments: {', '.join(common)}."
    if gen_status == ref_status:
        return "NOT_COMPARABLE", "Both executions succeeded, but outputs had no common semantic assignments/objective."
    return "DIFFERENT_RESULT", "Solver completion statuses differ."


def load_tasks() -> list[dict]:
    wb = openpyxl.load_workbook(WORKBOOK, data_only=False, read_only=True)
    ws = wb.active
    tasks = []
    for row in range(2, ws.max_row + 1):
        problem = ws.cell(row=row, column=2).value
        ref_model = ws.cell(row=row, column=7).value
        ref_data = ws.cell(row=row, column=8).value
        if not problem:
            continue
        tasks.append(
            {
                "task_id": f"task_{len(tasks) + 1:03d}",
                "row": row,
                "problem": str(problem),
                "reference_model": str(ref_model or ""),
                "reference_data": str(ref_data or ""),
            }
        )
    return tasks


def write_run_log(path: Path, entries: list[str]) -> None:
    write_text(path, "\n\n".join(entries) + "\n")


def main() -> None:
    RESULTS.mkdir(exist_ok=True)
    client = OpenAI()
    rows = []
    tasks = load_tasks()

    for run_dir_name, model_label, api_model in RUNS:
        run_dir = RESULTS / run_dir_name
        run_dir.mkdir(parents=True, exist_ok=True)
        for task in tasks:
            task_dir = run_dir / task["task_id"]
            task_dir.mkdir(parents=True, exist_ok=True)
            write_text(task_dir / "problem.txt", task["problem"])
            log = [
                f"# Execution log: {task['task_id']} / {model_label}",
                f"- Started: {datetime.now().isoformat(timespec='seconds')}",
                f"- Workbook row: {task['row']}",
                f"- API model: {api_model}",
                "- Generation input: column B natural language problem only.",
            ]

            model_text = ""
            data_text = ""
            valid = False
            repair_attempts = 0
            generated_result = {
                "returncode": None,
                "stdout": "",
                "stderr": "Generation did not run.",
                "elapsed": 0.0,
                "timed_out": False,
            }

            try:
                raw = call_model(
                    client,
                    api_model,
                    [
                        {"role": "system", "content": SYSTEM_PROMPT},
                        {"role": "user", "content": task["problem"]},
                    ],
                )
                write_text(task_dir / "llm_initial_response.json", raw)
                model_text, data_text = parse_json_artifacts(raw)
                write_text(task_dir / "generated_model.mzn", model_text)
                write_text(task_dir / "generated_data.dzn", data_text)
            except Exception as exc:
                generated_result["stderr"] = f"{type(exc).__name__}: {exc}"
                write_text(task_dir / "generated_model.mzn", "% LLM generation failed before a MiniZinc model was produced.\n")
                write_text(task_dir / "generated_data.dzn", "% LLM generation failed before a MiniZinc data file was produced.\n")
                write_text(task_dir / "generated_output.txt", generated_result["stderr"] + "\n")
                log.append(f"## Initial generation failed\n\n```text\n{generated_result['stderr']}\n```")

            for attempt in range(0, MAX_REPAIRS + 1):
                if not model_text:
                    break
                generated_result = run_minizinc(task_dir / "generated_model.mzn", task_dir / "generated_data.dzn")
                write_text(
                    task_dir / "generated_output.txt",
                    (generated_result.get("stdout") or "")
                    + ("\n[stderr]\n" + (generated_result.get("stderr") or "") if generated_result.get("stderr") else ""),
                )
                status = solver_status(generated_result)
                log.append(
                    f"## Generation attempt {attempt}\n\n"
                    f"- Command: `{generated_result['cmd']}`\n"
                    f"- Return code: {generated_result['returncode']}\n"
                    f"- Status: {status}\n"
                    f"- Elapsed seconds: {generated_result['elapsed']:.3f}\n"
                    f"- Timed out: {generated_result['timed_out']}"
                )
                if generated_result.get("returncode") == 0 and not generated_result.get("timed_out"):
                    valid = True
                    repair_attempts = attempt
                    break
                if attempt == MAX_REPAIRS:
                    repair_attempts = MAX_REPAIRS
                    break

                repair_attempts = attempt + 1
                repair_prompt = (
                    f"Original problem description:\n{task['problem']}\n\n"
                    f"Current generated_model.mzn:\n```minizinc\n{model_text}\n```\n\n"
                    f"Current generated_data.dzn:\n```minizinc\n{data_text}\n```\n\n"
                    f"MiniZinc command:\n{generated_result['cmd']}\n\n"
                    f"MiniZinc stdout:\n{generated_result.get('stdout') or ''}\n\n"
                    f"MiniZinc stderr:\n{generated_result.get('stderr') or ''}\n"
                )
                try:
                    raw = call_model(
                        client,
                        api_model,
                        [
                            {"role": "system", "content": REPAIR_SYSTEM_PROMPT},
                            {"role": "user", "content": repair_prompt},
                        ],
                    )
                    write_text(task_dir / f"llm_repair_{attempt + 1}.json", raw)
                    model_text, data_text = parse_json_artifacts(raw)
                    write_text(task_dir / "generated_model.mzn", model_text)
                    write_text(task_dir / "generated_data.dzn", data_text)
                except Exception as exc:
                    generated_result["stderr"] = f"{type(exc).__name__}: {exc}"
                    log.append(f"## Repair {attempt + 1} failed\n\n```text\n{generated_result['stderr']}\n```")
                    break

            reference_result = {
                "returncode": None,
                "stdout": "",
                "stderr": "Reference not executed because generated model was invalid.",
                "elapsed": 0.0,
                "timed_out": False,
            }
            comparison = "NOT_COMPARABLE"
            comparison_note = "Generated model was invalid."
            if solver_status(generated_result) == "API_ERROR":
                comparison_note = "OpenAI API generation failed before MiniZinc execution."

            if valid:
                write_text(task_dir / "reference_model.mzn", task["reference_model"])
                write_text(task_dir / "reference_data.dzn", task["reference_data"])
                reference_result = run_minizinc(task_dir / "reference_model.mzn", task_dir / "reference_data.dzn")
                write_text(
                    task_dir / "reference_output.txt",
                    (reference_result.get("stdout") or "")
                    + ("\n[stderr]\n" + (reference_result.get("stderr") or "") if reference_result.get("stderr") else ""),
                )
                comparison, comparison_note = compare_results(generated_result, reference_result)
                log.append(
                    f"## Reference execution\n\n"
                    f"- Command: `{reference_result['cmd']}`\n"
                    f"- Return code: {reference_result['returncode']}\n"
                    f"- Status: {solver_status(reference_result)}\n"
                    f"- Elapsed seconds: {reference_result['elapsed']:.3f}"
                )
            else:
                write_text(task_dir / "reference_output.txt", reference_result["stderr"])

            gen_status = solver_status(generated_result)
            ref_status = solver_status(reference_result)
            log.append(
                "## Comparison\n\n"
                f"- Result: {comparison}\n"
                f"- Generated status: {gen_status}\n"
                f"- Reference status: {ref_status}\n"
                f"- Notes: {comparison_note}"
            )
            log.append(f"- Finished: {datetime.now().isoformat(timespec='seconds')}")
            write_run_log(task_dir / "execution_log.md", log)

            rows.append(
                {
                    "task_id": task["task_id"],
                    "llm_model": model_label,
                    "valid_model": "TRUE" if valid else "FALSE",
                    "repair_attempts": repair_attempts,
                    "generated_solver_status": gen_status,
                    "reference_solver_status": ref_status,
                    "comparison_result": comparison,
                    "execution_time_seconds": f"{generated_result.get('elapsed', 0.0) + reference_result.get('elapsed', 0.0):.3f}",
                    "notes": comparison_note,
                }
            )

    write_csv(RESULTS / "final_results.csv", rows)
    write_summary(rows)
    write_report(rows)


def write_csv(path: Path, rows: list[dict]) -> None:
    if not rows:
        return
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def write_summary(rows: list[dict]) -> None:
    summary = []
    graph = []
    for _, model_label, _ in RUNS:
        model_rows = [row for row in rows if row["llm_model"] == model_label]
        total = len(model_rows)
        valid = sum(row["valid_model"] == "TRUE" for row in model_rows)
        same = sum(row["comparison_result"] == "SAME_RESULT" for row in model_rows)
        avg_repairs = sum(int(row["repair_attempts"]) for row in model_rows) / total if total else 0
        avg_time = sum(float(row["execution_time_seconds"]) for row in model_rows) / total if total else 0
        valid_pct = 100 * valid / total if total else 0
        same_pct = 100 * same / total if total else 0
        summary.append(
            {
                "llm_model": model_label,
                "total_tasks": total,
                "valid_models": valid,
                "valid_percentage": f"{valid_pct:.2f}",
                "same_results": same,
                "same_results_percentage": f"{same_pct:.2f}",
                "average_repair_attempts": f"{avg_repairs:.2f}",
                "average_execution_time_seconds": f"{avg_time:.3f}",
            }
        )
        graph.append(
            {
                "llm_model": model_label,
                "valid_percentage": f"{valid_pct:.2f}",
                "same_results_percentage": f"{same_pct:.2f}",
                "average_repair_attempts": f"{avg_repairs:.2f}",
            }
        )
    write_csv(RESULTS / "summary_statistics.csv", summary)
    write_csv(RESULTS / "graph_data.csv", graph)


def write_report(rows: list[dict]) -> None:
    summary_path = RESULTS / "summary_statistics.csv"
    final_path = RESULTS / "final_results.csv"
    summary_rows = list(csv.DictReader(summary_path.open(encoding="utf-8"))) if summary_path.exists() else []
    failures = [
        row
        for row in rows
        if row["valid_model"] != "TRUE" or row["comparison_result"] != "SAME_RESULT"
    ]
    lines = [
        "# ACMG vs autonomous agentic workflow benchmark experiment",
        "",
        "## Experiment description",
        "",
        "This run evaluates an autonomous LLM-driven MiniZinc model generation workflow on the 10 benchmark tasks in `tasks_10.xlsx`. Two independent model conditions were executed: GPT-3.5 and GPT-4o-mini.",
        "",
        "## Methodology",
        "",
        "- For each task, only column B was supplied to the LLM during generation and repair.",
        "- Columns G and H were read only after a generated model compiled and executed successfully.",
        "- Each task was run with `minizinc --solver gecode generated_model.mzn generated_data.dzn`.",
        "- Failed MiniZinc compilation or execution triggered up to five LLM repair attempts.",
        "- Semantic comparison used solver completion status, satisfiability status, recognizable objective values, and common variable assignments where available.",
        "",
        "## Assumptions",
        "",
        "- GPT-3.5 was executed as API model `gpt-3.5-turbo`.",
        "- GPT-4o-mini was executed as API model `gpt-4o-mini`.",
        "- If generated/reference outputs did not expose comparable objective values or common assignments, the result was marked `NOT_COMPARABLE`.",
        "- The source workbook was not modified; a snapshot copy was used for repeatable reads.",
        "",
        "## Environment setup",
        "",
        "See `results/environment_setup.md` for command outputs and setup actions.",
        "",
        "## Execution details",
        "",
        f"Detailed per-task artifacts and logs are stored under `results/gpt35/` and `results/gpt4omini/`. The complete result table is `{final_path.name}`.",
        "",
        "## Aggregated statistics",
        "",
        "| llm_model | total_tasks | valid_models | valid_percentage | same_results | same_results_percentage | average_repair_attempts | average_execution_time_seconds |",
        "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]
    for row in summary_rows:
        lines.append(
            f"| {row['llm_model']} | {row['total_tasks']} | {row['valid_models']} | {row['valid_percentage']} | {row['same_results']} | {row['same_results_percentage']} | {row['average_repair_attempts']} | {row['average_execution_time_seconds']} |"
        )
    lines.extend(["", "## Notable failure cases", ""])
    if failures:
        for row in failures:
            lines.append(
                f"- {row['llm_model']} {row['task_id']}: valid={row['valid_model']}, comparison={row['comparison_result']}, generated={row['generated_solver_status']}, reference={row['reference_solver_status']}, notes={row['notes']}"
            )
    else:
        lines.append("- No invalid or non-matching cases were recorded.")
    lines.extend(
        [
            "",
            "## Observations",
            "",
            "- Validity captures MiniZinc compilation and solver execution, not necessarily semantic fidelity.",
            "- `NOT_COMPARABLE` cases indicate insufficient shared observable semantics in the raw MiniZinc outputs, or failed reference/generated execution.",
            "- Repair counts measure post-generation MiniZinc-driven iterations only.",
        ]
    )
    write_text(RESULTS / "experiment_report.md", "\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
