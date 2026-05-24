int: num_tasks = 4;
array[1..num_tasks] of int: task_durations = [3, 2, 4, 1];
array[1..num_tasks] of int: resource_requirements = [1, 1, 2, 1];
int: max_workers = 2;
int: project_deadline = 10;
array[1..num_tasks] of var 0..project_deadline: start_times;
array[1..num_tasks] of var 0..project_deadline: end_times;
array[1..num_tasks] of var 0..max_workers: num_workers_needed;

constraint forall(t in 1..num_tasks)(end_times[t] == start_times[t] + task_durations[t]);

constraint start_times[2] >= end_times[1];
constraint start_times[3] >= end_times[1];
constraint start_times[4] >= end_times[2] /\ start_times[4] >= end_times[3];

constraint forall(t in 1..project_deadline)(
    sum(t in 1..num_tasks)(num_workers_needed[t]) <= max_workers
);

constraint end_times[4] <= project_deadline;

var int: max_end_time = max(t in 1..num_tasks)(end_times[t]);

solve minimize max_end_time;

output [
    "Start Times: \(start_times)",
    "End Times: \(end_times)",
    "Max End Time: \(max_end_time)"
];
