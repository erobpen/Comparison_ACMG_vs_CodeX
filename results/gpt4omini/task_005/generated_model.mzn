int: WIDTH = 10;
int: HEIGHT = 10;
int: DEPTH = 10;

int: NUM_ITEMS = 5;
array[1..NUM_ITEMS] of int: item_width = [2, 3, 4, 1, 2];
array[1..NUM_ITEMS] of int: item_height = [2, 3, 2, 1, 3];
array[1..NUM_ITEMS] of int: item_depth = [2, 2, 3, 1, 2];

array[1..NUM_ITEMS] of var 0..WIDTH - 1: x;
array[1..NUM_ITEMS] of var 0..HEIGHT - 1: y;
array[1..NUM_ITEMS] of var 0..DEPTH - 1: z;

% Ensure items do not intersect
constraint forall(i, j in 1..NUM_ITEMS where i < j) (
    (x[i] + item_width[i] <= x[j]  
     || x[j] + item_width[j] <= x[i]  
     || y[i] + item_height[i] <= y[j]  
     || y[j] + item_height[j] <= y[i]  
     || z[i] + item_depth[i] <= z[j]  
     || z[j] + item_depth[j] <= z[i])
);

solve satisfy;

output [
    "Item positions:\n",
    "Item 1: (" ++ show(x[1]) ++ ", " ++ show(y[1]) ++ ", " ++ show(z[1]) ++ ")\n",
    "Item 2: (" ++ show(x[2]) ++ ", " ++ show(y[2]) ++ ", " ++ show(z[2]) ++ ")\n",
    "Item 3: (" ++ show(x[3]) ++ ", " ++ show(y[3]) ++ ", " ++ show(z[3]) ++ ")\n",
    "Item 4: (" ++ show(x[4]) ++ ", " ++ show(y[4]) ++ ", " ++ show(z[4]) ++ ")\n",
    "Item 5: (" ++ show(x[5]) ++ ", " ++ show(y[5]) ++ ", " ++ show(z[5]) ++ ")\n"
];
