% Number of tasks
int: num_tasks;

% Duration of each task
array[1..num_tasks] of int: duration;

% Resource requirements for each task
array[1..num_tasks] of int: resource_requirements;

% Maximum number of workers available
int: num_workers;

% Project deadline
int: project_deadline;

% Decision variables: start and end times for each task
array[1..num_tasks] of var 0..project_deadline: start;
array[1..num_tasks] of var 0..project_deadline: end;

% Ensure end times are correctly calculated
constraint forall(i in 1..num_tasks) (
    end[i] == start[i] + duration[i]
);

% Dependencies: an array of pairs (A, B) meaning task B depends on task A
int: num_dependencies;
array[1..num_dependencies] of int: task_A;
array[1..num_dependencies] of int: task_B;

% Apply dependencies
constraint forall(dep in 1..num_dependencies) (
    start[task_B[dep]] >= end[task_A[dep]]
);

% Resource availability constraint
constraint forall(t in 0..project_deadline) (
    sum(i in 1..num_tasks where start[i] <= t /\ end[i] > t) (
        resource_requirements[i]
    ) <= num_workers
);

% Project deadline constraint
constraint max(end) <= project_deadline;

% Objective: Minimize the maximum end time of all tasks
solve minimize max(end);

% Output the start and end times for each task
output ["start: " ++ show(start) ++ "\nend: " ++ show(end)];