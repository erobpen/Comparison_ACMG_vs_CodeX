# ACMG vs autonomous agentic workflow benchmark experiment

## Experiment description

This run evaluates an autonomous LLM-driven MiniZinc model generation workflow on the 10 benchmark tasks in `tasks_10.xlsx`. Two independent model conditions were executed: GPT-3.5 and GPT-4o-mini.

## Methodology

- For each task, only column B was supplied to the LLM during generation and repair.
- Columns G and H were read only after a generated model compiled and executed successfully.
- Each task was run with `minizinc --solver gecode generated_model.mzn generated_data.dzn`.
- Failed MiniZinc compilation or execution triggered up to five LLM repair attempts.
- Semantic comparison used solver completion status, satisfiability status, recognizable objective values, and common variable assignments where available.

## Assumptions

- GPT-3.5 was executed as API model `gpt-3.5-turbo`.
- GPT-4o-mini was executed as API model `gpt-4o-mini`.
- If generated/reference outputs did not expose comparable objective values or common assignments, the result was marked `NOT_COMPARABLE`.
- The source workbook was not modified; a snapshot copy was used for repeatable reads.

## Environment setup

See `results/environment_setup.md` for command outputs and setup actions.

## Execution details

Detailed per-task artifacts and logs are stored under `results/gpt35/` and `results/gpt4omini/`. The complete result table is `final_results.csv`.

## Aggregated statistics

| llm_model | total_tasks | valid_models | valid_percentage | same_results | same_results_percentage | average_repair_attempts | average_execution_time_seconds |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| GPT-3.5 | 10 | 2 | 20.00 | 0 | 0.00 | 4.00 | 1.257 |
| GPT-4o-mini | 10 | 0 | 0.00 | 0 | 0.00 | 4.50 | 0.064 |

## Notable failure cases

- GPT-3.5 task_001: valid=FALSE, comparison=NOT_COMPARABLE, generated=ERROR, reference=NOT_RUN, notes=Generated model was invalid.
- GPT-3.5 task_002: valid=FALSE, comparison=NOT_COMPARABLE, generated=ERROR, reference=NOT_RUN, notes=Generated model was invalid.
- GPT-3.5 task_003: valid=TRUE, comparison=NOT_COMPARABLE, generated=SAT, reference=SAT, notes=Both executions succeeded, but outputs had no common semantic assignments/objective.
- GPT-3.5 task_004: valid=FALSE, comparison=NOT_COMPARABLE, generated=ERROR, reference=NOT_RUN, notes=Generated model was invalid.
- GPT-3.5 task_005: valid=FALSE, comparison=NOT_COMPARABLE, generated=ERROR, reference=NOT_RUN, notes=Generated model was invalid.
- GPT-3.5 task_006: valid=FALSE, comparison=NOT_COMPARABLE, generated=ERROR, reference=NOT_RUN, notes=Generated model was invalid.
- GPT-3.5 task_007: valid=FALSE, comparison=NOT_COMPARABLE, generated=ERROR, reference=NOT_RUN, notes=Generated model was invalid.
- GPT-3.5 task_008: valid=FALSE, comparison=NOT_COMPARABLE, generated=ERROR, reference=NOT_RUN, notes=Generated model was invalid.
- GPT-3.5 task_009: valid=TRUE, comparison=NOT_COMPARABLE, generated=OPTIMAL_OR_COMPLETE, reference=OPTIMAL_OR_COMPLETE, notes=Both executions succeeded, but outputs had no common semantic assignments/objective.
- GPT-3.5 task_010: valid=FALSE, comparison=NOT_COMPARABLE, generated=ERROR, reference=NOT_RUN, notes=Generated model was invalid.
- GPT-4o-mini task_001: valid=FALSE, comparison=NOT_COMPARABLE, generated=ERROR, reference=NOT_RUN, notes=Generated model was invalid.
- GPT-4o-mini task_002: valid=FALSE, comparison=NOT_COMPARABLE, generated=ERROR, reference=NOT_RUN, notes=Generated model was invalid.
- GPT-4o-mini task_003: valid=FALSE, comparison=NOT_COMPARABLE, generated=ERROR, reference=NOT_RUN, notes=Generated model was invalid.
- GPT-4o-mini task_004: valid=FALSE, comparison=NOT_COMPARABLE, generated=ERROR, reference=NOT_RUN, notes=Generated model was invalid.
- GPT-4o-mini task_005: valid=FALSE, comparison=NOT_COMPARABLE, generated=ERROR, reference=NOT_RUN, notes=Generated model was invalid.
- GPT-4o-mini task_006: valid=FALSE, comparison=NOT_COMPARABLE, generated=ERROR, reference=NOT_RUN, notes=Generated model was invalid.
- GPT-4o-mini task_007: valid=FALSE, comparison=NOT_COMPARABLE, generated=ERROR, reference=NOT_RUN, notes=Generated model was invalid.
- GPT-4o-mini task_008: valid=FALSE, comparison=NOT_COMPARABLE, generated=ERROR, reference=NOT_RUN, notes=Generated model was invalid.
- GPT-4o-mini task_009: valid=FALSE, comparison=NOT_COMPARABLE, generated=ERROR, reference=NOT_RUN, notes=Generated model was invalid.
- GPT-4o-mini task_010: valid=FALSE, comparison=NOT_COMPARABLE, generated=ERROR, reference=NOT_RUN, notes=Generated model was invalid.

## Observations

- Validity captures MiniZinc compilation and solver execution, not necessarily semantic fidelity.
- `NOT_COMPARABLE` cases indicate insufficient shared observable semantics in the raw MiniZinc outputs, or failed reference/generated execution.
- Repair counts measure post-generation MiniZinc-driven iterations only.
