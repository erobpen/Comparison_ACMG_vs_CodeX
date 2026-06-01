int: W = 10;
int: H = 10;
int: D = 10;

int: n_items = 5;
array[1..n_items, 1..3] of int: item_dimensions = array2d(1..n_items, 1..3, [
    2, 2, 2,
    3, 3, 2,
    4, 2, 3,
    1, 1, 1,
    2, 3, 2
]);

array[1..n_items, 1..3] of var 0..10: positions;

constraint
  forall(i in 1..n_items) (
    positions[i, 1] + item_dimensions[i, 1] <= W /\
    positions[i, 2] + item_dimensions[i, 2] <= H /\
    positions[i, 3] + item_dimensions[i, 3] <= D
  ) /\
  forall(i, j in 1..n_items where i < j) (
    positions[i, 1] + item_dimensions[i, 1] <= positions[j, 1] \/
    positions[j, 1] + item_dimensions[j, 1] <= positions[i, 1] \/
    positions[i, 2] + item_dimensions[i, 2] <= positions[j, 2] \/
    positions[j, 2] + item_dimensions[j, 2] <= positions[i, 2] \/
    positions[i, 3] + item_dimensions[i, 3] <= positions[j, 3] \/
    positions[j, 3] + item_dimensions[j, 3] <= positions[i, 3]
  );

solve satisfy;