int: n = 4;
int: rows = 3;
int: cols = 3;
array[1..n] of int: furniture = [1, 2, 3, 4];
array[1..n, 1..n] of int: compatibility = [
  [0, 1, 0, 1],
  [1, 0, 1, 0],
  [0, 1, 0, 1],
  [1, 0, 1, 0]
];
array[1..rows, 1..cols] of var 1..n: placement;

% Ensure unique positions for each furniture piece
constraint forall(i, j in 1..n where i < j) (
  placement[i] != placement[j]
);

% Ensure incompatible pieces are not adjacent
constraint forall(i in 1..rows, j in 1..cols) (
  let {
    var int: current = placement[i, j];
  } in
  (i < rows ->
    let {
      var int: below = placement[i + 1, j];
    } in
    compatibility[current][below] == 0
  ) /
  (j < cols ->
    let {
      var int: right = placement[i, j + 1];
    } in
    compatibility[current][right] == 0
  ) /
  (i > 1 ->
    let {
      var int: above = placement[i - 1, j];
    } in
    compatibility[current][above] == 0
  ) /
  (j > 1 ->
    let {
      var int: left = placement[i, j - 1];
    } in
    compatibility[current][left] == 0
  )
);

solve satisfy;

output [
  show(placement)
];
