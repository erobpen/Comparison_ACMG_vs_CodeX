int: n = 4; % Number of furniture pieces
int: grid_size = 3; % Room dimensions
array[1..n, 1..n] of int: compatibility =
  [| 0, 1, 0, 1
   | 1, 0, 1, 0
   | 0, 1, 0, 1
   | 1, 0, 1, 0 |];

array[1..n] of var 1..grid_size: row;
array[1..n] of var 1..grid_size: col;

constraint
  forall(i, j in 1..n where i < j) (
    (row[i] != row[j] \/ col[i] != col[j]) /\
    (compatibility[i, j] = 0 \/
     (abs(row[i] - row[j]) + abs(col[i] - col[j]) > 1))
  );

solve satisfy;