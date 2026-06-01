int: n; % number of classrooms
int: m; % maximum hours per classroom per day
int: k; % number of classes
int: z; % maximum subjects per class per week
array[1..k, 1..4] of int: Qty; % quantity of sessions per class per subject

set of int: Days = 1..5;
set of int: Hours = 1..3;
set of int: Subjects = 1..4;

array[1..n, Days, Hours] of var 0..1: Schedule; % Schedule for each classroom

constraint
  forall(d in Days, h in Hours, c in 1..n) (
    sum(s in Subjects) (Schedule[c, d, h] = s) <= 1
  ) /
  forall(c in 1..k, s in Subjects) (
    sum(d in Days, h in Hours, r in 1..n) (Schedule[r, d, h] = s) = Qty[c, s]
  ) /
  forall(d in Days, r in 1..n) (
    sum(h in Hours) (exists(s in Subjects) (Schedule[r, d, h] = s)) <= m
  );

solve satisfy;