include "globals.mzn";

int: n = 30;  % Rows
int: m = 40;  % Columns
int: total_tiles = n * m;  % Total tiles

% Tile types
set of int: TileTypes = 1..8;
int: SEA = 1;
int: CO = 2;
int: MO = 3;
int: FO = 4;
int: HI = 5;
int: GR = 6;
int: RIVER = 7;   % NEW: River overlay indicator
int: PATH = 8;    % NEW: Path overlay indicator

array[1..5] of int: per;

% Adjusted tile counts based on new percentages
int: sea_tiles = total_tiles * 15 div 100;  % 15% SEA (adjusted as per new problem)
int: land_tiles = total_tiles - sea_tiles;  % 85% LAND
int: co_tiles = (land_tiles * per[1]) div 100;  % 20% of LAND is CO
int: mo_tiles = (land_tiles * per[2]) div 100;  % 10% of LAND is MO
int: fo_tiles = (land_tiles * per[3]) div 100;  % 30% of LAND is FO
int: hi_tiles = (land_tiles * per[4]) div 100;  % 20% of LAND is HI
int: gr_tiles = (land_tiles * per[5]) div 100;  % 20% of LAND is GR

array[1..n, 1..m] of var TileTypes: board;

% Constraints for tile counts
constraint count(board, SEA) == sea_tiles;
constraint count(board, CO) == co_tiles;
constraint count(board, MO) == mo_tiles;
constraint count(board, FO) == fo_tiles;
constraint count(board, HI) == hi_tiles;
constraint count(board, GR) == gr_tiles;

% Border rules
constraint forall(i in 1..n, j in {1, m}) (board[i,j] == CO \/ board[i,j] == MO);
constraint forall(i in {1, n}, j in 1..m) (board[i,j] == CO \/ board[i,j] == MO);


% SEA surrounded by CO
constraint forall(i in 1..n, j in 1..m where board[i,j] == SEA) (
   
    i = 1 /\ j = 1 -> (
      (board[2,1] = SEA \/ board[2,1] = CO) /\
      (board[2,2] = SEA \/ board[2,2] = CO) /\
      (board[1,2] = SEA \/ board[1,2] = CO)
    ) /\  i = 1 /\ j = m -> (
      (board[1,m-1] = SEA \/ board[1,m-1] = CO) /\
      (board[2,m] = SEA \/ board[2,m] = CO) /\
      (board[2,m-1] = SEA \/ board[2,m-1] = CO)
    ) /\  i = n /\ j = 1 -> (
      (board[n-1,1] = SEA \/ board[n-1,1] = CO) /\
      (board[n,2] = SEA \/ board[n,2] = CO) /\
      (board[n-1,2] = SEA \/ board[n-1,2] = CO)
    ) /\  i = n /\ j = m -> (
      (board[n,m-1] = SEA \/ board[n,m-1] = CO) /\
      (board[n-1,m] = SEA \/ board[n-1,m] = CO) /\
      (board[n-1,m-1] = SEA \/ board[n-1,m-1] = CO)
    ) /\  i = 1 -> ( % upper border
        (board[2, j] = CO \/ board[2, j] = SEA) /\
        (board[2, j + 1] = CO \/ board[2, j + 1] = SEA)
    ) /\  j = 1 -> ( % left border
        (board[i-1, 1] = SEA \/ board[i-1, 1] = CO) /\
        (board[i, 2] = SEA \/ board[i, 2] = CO) /\
        (board[i+1, 1] = SEA \/ board[i+1, 1] = CO)
    ) /\  i = n -> ( % right border
        (board[n-1, j] = SEA \/ board[n-1, j] = CO) /\
        (board[n, j-1] = SEA \/ board[n, j-1] = CO) /\
        (board[n+1, j] = SEA \/ board[n+1, j] = CO)
    ) /\  j = m -> ( % bottom border
        (board[i-1, m-1] = SEA \/ board[i-1, m-1] = CO) /\
        (board[i-1, m] = SEA \/ board[i-1, m] = CO)
    )
);

constraint forall(i in 2..n-1, j in 2..m-1 where board[i,j] == SEA)(
        (board[i-1, j] = SEA \/ board[i-1, j] = CO) /\
        (board[i-1, j+1] = SEA \/ board[i-1, j+1] = CO) /\
        (board[i, j-1] = SEA \/ board[i, j-1] = CO) /\
        (board[i, j+1] = SEA \/ board[i, j+1] = CO) /\
        (board[i+1, j] = SEA \/ board[i+1, j] = CO) /\
        (board[i+1, j+1] = SEA \/ board[i+1, j+1] = CO)
);
 
% Define neighbors based on hexagonal adjacency
constraint forall(i, j in 1..n, k in 1..m) (
    (j mod 2 == 0 /\ i > 1 /\ k > 1 /\ i < n /\ k < m ->
        board[i,j] = board[i-1,k] \/board[i,j] = board[i+1,k] \/ board[i,j] = board[i,k-1] \/ board[i,j] = board[i,k+1] \/ board[i,j] = board[i+1,k-1] \/ board[i,j] = board[i+1,k+1]) \/
    (j mod 2 == 1 /\ i > 1 /\ k > 1 /\ i < n /\ k < m ->
        board[i,j] = board[i-1,k] \/ board[i,j] = board[i+1,k] \/ board[i,j] = board[i,k-1] \/ board[i,j] = board[i,k+1] \/ board[i,j] = board[i-1,k-1] \/ board[i,j] = board[i-1,k+1])
);


% Optional: Transition rules (simplified)
constraint forall(i in 2..n-1, j in 2..m-1) (
    if board[i,j] == HI then
        (board[i-1,j] in TileTypes \/ board[i+1,j] in TileTypes \/ board[i,j-1] in TileTypes \/ board[i,j+1] in TileTypes)
    else
        true
    endif
);
% NEW: River must start from an MO tile and end on a CO tile
var int: river_start_row;
var int: river_start_col;
var int: river_end_row;
var int: river_end_col;

constraint board[river_start_row, river_start_col] == MO; % NEW
constraint board[river_end_row, river_end_col] == CO;     % NEW

% NEW: Define river path that overlays FO, HI, and GR tiles only
array[1..n, 1..m] of var bool: is_river; % NEW
constraint forall(i in 1..n, j in 1..m) (
    is_river[i,j] -> board[i,j] in {FO, HI, GR, MO, CO}
);

% NEW: Define path constraints (overlays FO, HI, and GR only)
array[1..n, 1..m] of var bool: is_path; % NEW
constraint forall(i in 1..n, j in 1..m) (
    is_path[i,j] -> board[i,j] in {FO, HI, GR}
);

% NEW: Bridge condition (river and path intersect on the same tile)
array[1..n, 1..m] of var bool: is_bridge; % NEW
constraint forall(i in 1..n, j in 1..m) (
    is_bridge[i,j] <-> (is_river[i,j] /\ is_path[i,j])
);

% NEW: Parallel condition (river and path both present but not intersecting as bridge)
array[1..n, 1..m] of var bool: is_parallel; % NEW
constraint forall(i in 1..n, j in 1..m) (
    is_parallel[i,j] <-> (is_river[i,j] /\ is_path[i,j] /\ not is_bridge[i,j])
);

solve satisfy;

output ["\(board) \n River:\(is_river)\n Path\(is_path) \n Bridge\(is_bridge) Parallel\n\(is_parallel)"];