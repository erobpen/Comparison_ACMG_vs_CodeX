int: n = 4; % number of classes
int: m = 3; % maximum hours per classroom per day
int: z = 5; % maximum subjects per class per week
int: days = 5; % number of days in a week
int: subjects = 4; % number of subjects
array[1..n, 1..subjects] of int: sessions = [| 2, 2, 1, 3 |
                                                  | 1, 2, 3, 3 |
                                                  | 1, 2, 3, 3 |
                                                  | 4, 2, 1, 3 |];

array[1..days, 1..subjects] of var 0..m: schedule; % schedule for each subject per day

% Constraints to ensure that the total sessions for each subject are met
constraint forall(i in 1..n) (
    forall(j in 1..subjects) (
        sum(d in 1..days)(schedule[d, j]) >= sessions[i, j]
    )
);

% Ensure that the total hours per day do not exceed the maximum classroom hours
constraint forall(d in 1..days) (
    sum(j in 1..subjects)(schedule[d, j]) <= m
);

% Output the schedule
output ["Schedule:\n" ++ show(schedule)]
