int: N = 4;
int: rows = 3;
int: cols = 3;
array[1..N] of 1..rows*cols: position;
array[1..N, 1..N] of int: compatibility = 
    [| 0, 1, 0, 1 |
     | 1, 0, 1, 0 |
     | 0, 1, 0, 1 |
     | 1, 0, 1, 0 |];

constraint all_different(position);

constraint forall(i in 1..N, j in 1..N where compatibility[i,j]=1) (
    abs(position[i] div cols - position[j] div cols) > 1 \/
    abs(position[i] mod cols - position[j] mod cols) > 1
);

solve satisfy;

output [
    "Furniture Positions: \n",
    show(position),
    "\n"
];
