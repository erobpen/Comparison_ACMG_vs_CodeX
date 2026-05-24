int: num_tasks = 4;
int: max_workers = 2;
int: deadline = 10;
array[1..num_tasks] of int: durations = [3, 2, 4, 1];
array[1..num_tasks] of int: resources = [1, 1, 2, 1];
array[1..num_tasks] of var 0..deadline: start_times;
array[1..num_tasks] of var 0..deadline: end_times;

% Define end times based on start times and durations
constraint forall(i in 1..num_tasks)(
    end_times[i] = start_times[i] + durations[i]
);

% Task dependencies
constraint start_times[2] >= end_times[1];
constraint start_times[3] >= end_times[1];
constraint start_times[4] >= end_times[2];
constraint start_times[4] >= end_times[3];

% Resource constraints
constraint forall(t in 0..deadline)(
    sum(i in 1..num_tasks where start_times[i] <= t /
    end_times[i] > t)(resources[i]) <= max_workers
);

% Project deadline constraint
constraint end_times[4] <= deadline;

% Objective: Minimize the maximum end time
var int: max_end_time = max(end_times);
solve minimize max_end_time;

% Output
output ["Start times: " ++ show(start_times) ++ "\n", "End times: " ++ show(end_times) ++ "\n", "Maximum end time: " ++ show(max_end_time) ++ "\n"];
