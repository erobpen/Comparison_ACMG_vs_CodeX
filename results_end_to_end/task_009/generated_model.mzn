int: num_tasks = 4;
array[1..num_tasks] of int: durations = [3, 2, 4, 1];
array[1..num_tasks] of int: resources = [1, 1, 2, 1];
int: max_workers = 2;
int: deadline = 10;

array[1..num_tasks] of var 0..deadline: start_times;
array[1..num_tasks] of var 0..deadline: end_times;

constraint forall(i in 1..num_tasks) (
    end_times[i] = start_times[i] + durations[i]
);

constraint start_times[2] >= end_times[1];
constraint start_times[3] >= end_times[1];
constraint start_times[4] >= end_times[2];
constraint start_times[4] >= end_times[3];

constraint forall(t in 0..deadline) (
    sum(i in 1..num_tasks where start_times[i] <= t /
        end_times[i] > t) (resources[i]) <= max_workers
);

constraint max(end_times) <= deadline;

solve minimize max(end_times);