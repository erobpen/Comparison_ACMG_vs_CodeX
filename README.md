# Comparison_ACMG_vs_CodeX

Reproducibility package for an exploratory academic comparison between a modular LLM-driven constraint-model-generation framework (ACMG) and an autonomous agentic workflow for MiniZinc model generation.

## Contents

- `tasks_10.xlsx`: benchmark workbook supplied for the experiment.
- `scripts/run_experiment.py`: deterministic experiment runner.
- `results/environment_setup.md`: MiniZinc, solver, Python, API, and workbook setup log.
- `results/final_results.csv`: per-task final outcomes.
- `results/summary_statistics.csv`: aggregated metrics by model.
- `results/graph_data.csv`: compact metrics for later graph generation.
- `results/experiment_report.md`: generated experiment report.
- `results/gpt35/`: GPT-3.5 task artifacts and logs.
- `results/gpt4omini/`: GPT-4o-mini task artifacts and logs.
- `CHAT_TRANSCRIPT.md`: conversation transcript for experiment provenance.

## Reproduction

Prerequisites:

- Python 3.11+
- MiniZinc with Gecode available on `PATH`
- Python packages: `openpyxl`, `openai`
- `OPENAI_API_KEY` set in the environment

Run:

```powershell
python scripts\run_experiment.py
```

The runner reads a snapshot workbook from `results/_input_snapshot/tasks_10.xlsx`, uses column B for generation, and reads columns G/H only after successful generated-model execution for evaluation.

## Notes

- The original `tasks_10.xlsx` was not modified during the experiment.
- GPT-3.5 was executed as `gpt-3.5-turbo`.
- GPT-4o-mini was executed as `gpt-4o-mini`.
- Each task allowed up to five repair attempts.
