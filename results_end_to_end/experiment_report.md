# End-to-End Zero-Shot MiniZinc Generation Baseline

## Methodology

For each task, only column B from `tasks_10.xlsx` was provided to GPT-4o. The model was asked once to directly generate `model.mzn` and `data.dzn` as JSON fields. No intermediate representations, semantic extraction, decomposition, repair loop, recognizer, parser, or iterative workflow was used. Columns G and H were used only after generation for reference evaluation.

Generated models were executed with `minizinc --solver gecode --statistics --time-limit 10000 generated_model.mzn generated_data.dzn`. Reference models were executed with the same solver, statistics flag, and time limit.

## Assumptions

- A generated model is counted as valid when MiniZinc compiles and executes without timeout, unknown status, or error.
- SAT/UNSAT status is compared first. When both runs are satisfiable and MiniZinc reports objective values, objectives are compared. If objectives are absent and solution text is not directly comparable, the result is marked `NOT_COMPARABLE`.
- MiniZinc solver time limit per run: 10 seconds.
- Outer process timeout per run: 30 seconds.

## Configuration

- LLM: `gpt-4o`
- Temperature: `0`
- Interaction pattern: one API call per task
- Solver: `gecode`
- MiniZinc version: `MiniZinc to FlatZinc converter, version 2.8.5, build 1315240962`

## Per-Task Outcomes

| task_id | valid_model | generated_status | reference_status | comparison | time_s | notes |
|---|---:|---|---|---|---:|---|
| task_001 | TRUE | SATISFIABLE | SATISFIABLE | NOT_COMPARABLE | 0.148 | SAT/UNSAT matched or was unavailable, but objective/solution comparison was not meaningful. |
| task_002 | FALSE | ERROR | SATISFIABLE | NOT_COMPARABLE | 0.086 | Generated model did not compile/execute successfully. |
| task_003 | FALSE | ERROR | UNKNOWN | NOT_COMPARABLE | 0.075 | Generated model did not compile/execute successfully. Reference run did not produce a comparable result. |
| task_004 | FALSE | ERROR | SATISFIABLE | NOT_COMPARABLE | 0.084 | Generated model did not compile/execute successfully. |
| task_005 | TRUE | SATISFIABLE | OPTIMAL | NOT_COMPARABLE | 0.141 | SAT/UNSAT matched or was unavailable, but objective/solution comparison was not meaningful. |
| task_006 | FALSE | ERROR | SATISFIABLE | NOT_COMPARABLE | 0.084 | Generated model did not compile/execute successfully. |
| task_007 | TRUE | OPTIMAL | SATISFIABLE | NOT_COMPARABLE | 0.152 | SAT/UNSAT matched or was unavailable, but objective/solution comparison was not meaningful. |
| task_008 | FALSE | UNKNOWN | UNKNOWN | NOT_COMPARABLE | 10.068 | Generated model did not compile/execute successfully. Reference run did not produce a comparable result. |
| task_009 | FALSE | ERROR | OPTIMAL | NOT_COMPARABLE | 0.097 | Generated model did not compile/execute successfully. |
| task_010 | TRUE | SATISFIABLE | SATISFIABLE | NOT_COMPARABLE | 0.157 | SAT/UNSAT matched or was unavailable, but objective/solution comparison was not meaningful. |

## Aggregate Statistics

- Total tasks: 10
- Valid models: 4 (40.00%)
- Same results: 0 (0.00%)
- Average generated-model execution time: 1.109 seconds

## Failure Analysis

- Invalid generated models: 6
- Different results: 0
- Not comparable: 10
- task_001: valid=TRUE, generated=SATISFIABLE, reference=SATISFIABLE, comparison=NOT_COMPARABLE. SAT/UNSAT matched or was unavailable, but objective/solution comparison was not meaningful.
- task_002: valid=FALSE, generated=ERROR, reference=SATISFIABLE, comparison=NOT_COMPARABLE. Generated model did not compile/execute successfully.
- task_003: valid=FALSE, generated=ERROR, reference=UNKNOWN, comparison=NOT_COMPARABLE. Generated model did not compile/execute successfully. Reference run did not produce a comparable result.
- task_004: valid=FALSE, generated=ERROR, reference=SATISFIABLE, comparison=NOT_COMPARABLE. Generated model did not compile/execute successfully.
- task_005: valid=TRUE, generated=SATISFIABLE, reference=OPTIMAL, comparison=NOT_COMPARABLE. SAT/UNSAT matched or was unavailable, but objective/solution comparison was not meaningful.
- task_006: valid=FALSE, generated=ERROR, reference=SATISFIABLE, comparison=NOT_COMPARABLE. Generated model did not compile/execute successfully.
- task_007: valid=TRUE, generated=OPTIMAL, reference=SATISFIABLE, comparison=NOT_COMPARABLE. SAT/UNSAT matched or was unavailable, but objective/solution comparison was not meaningful.
- task_008: valid=FALSE, generated=UNKNOWN, reference=UNKNOWN, comparison=NOT_COMPARABLE. Generated model did not compile/execute successfully. Reference run did not produce a comparable result.
- task_009: valid=FALSE, generated=ERROR, reference=OPTIMAL, comparison=NOT_COMPARABLE. Generated model did not compile/execute successfully.
- task_010: valid=TRUE, generated=SATISFIABLE, reference=SATISFIABLE, comparison=NOT_COMPARABLE. SAT/UNSAT matched or was unavailable, but objective/solution comparison was not meaningful.
