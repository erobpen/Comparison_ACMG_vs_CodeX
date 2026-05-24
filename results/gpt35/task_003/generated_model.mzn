int: n = 30;
int: m = 40;
set of int: TILE_TYPES = 1..5; % 1: CO, 2: MO, 3: FO, 4: HI, 5: GR
set of int: LAND_TYPES = 1..4; % 1: CO, 2: MO, 3: FO, 4: HI
set of int: BORDER_TYPES = {1, 2}; % 1: CO, 2: MO
set of int: RIVER_PATH_TYPES = 6..7; % 6: R, 7: P
set of int: SPECIAL_TYPES = 8..9; % 8: B, 9: PR
array[TILE_TYPES] of int: num_variations = [3, 3, 3, 3, 3];
array[TILE_TYPES] of int: num_rotations = [6, 6, 6, 6, 6];
array[1..n, 1..m] of var TILE_TYPES: map;
array[1..n, 1..m] of var LAND_TYPES: land_map;
array[1..n, 1..m] of var BORDER_TYPES: border_map;
array[1..n, 1..m] of var RIVER_PATH_TYPES: river_path_map;
array[1..n, 1..m] of var SPECIAL_TYPES: special_map;
constraint forall(i in 1..n, j in 1..m) (
    map[i, j] >= 1 /\ map[i, j] <= 5 /\ land_map[i, j] >= 1 /\ land_map[i, j] <= 4 /\ border_map[i, j] >= 1 /\ border_map[i, j] <= 2 /\ river_path_map[i, j] >= 6 /\ river_path_map[i, j] <= 7 /\ special_map[i, j] >= 8 /\ special_map[i, j] <= 9
);
% Constraints for accurate transitions and connections
% Constraints for river and path placement
solve satisfy;
output [
    "Map: \n",
    show(map),
    "\nLand Map: \n",
    show(land_map),
    "\nBorder Map: \n",
    show(border_map),
    "\nRiver/Path Map: \n",
    show(river_path_map),
    "\nSpecial Map: \n",
    show(special_map)
];
