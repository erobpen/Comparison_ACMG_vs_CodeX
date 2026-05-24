int: n = 5;
int: m = 36;

% Board types
int: BOARD1 = 1;
int: BOARD2 = 2;
int: BOARD3 = 3;
int: LBOARD1 = 4;
int: LBOARD2 = 5;

% Slot restrictions
set of int: ODD_SLOTS = {1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31, 33, 35};
set of int: EVEN_SLOTS = {2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36};
set of int: BOARD2_SLOTS = {1, 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31};
set of int: LBOARD2_SLOTS = {1, 2, 4, 8, 16};

% Quantity of each board type
int: qty_BOARD1 = 5;
int: qty_BOARD2 = 5;
int: qty_BOARD3 = 5;
int: qty_LBOARD1 = 4;
int: qty_LBOARD2 = 4;

% Decision variables
array[1..n] of var 0..qty_BOARD1: board_count;
array[1..2] of var 0..qty_LBOARD1: lboard_count;

% Constraints
constraint board_count[BOARD1] + board_count[BOARD2] + board_count[BOARD3] <= qty_BOARD1;
constraint lboard_count[LBOARD1] + lboard_count[LBOARD2] <= qty_LBOARD1;

% Slot allocation
array[1..m] of var 0..n: slots;

% Board placement constraints
constraint forall(i in 1..m)(
    (slots[i] == BOARD1) -> (i in ODD_SLOTS) /
    (slots[i] == BOARD2) -> (i in BOARD2_SLOTS) /
    (slots[i] == BOARD3) -> (i in EVEN_SLOTS) /
    (slots[i] == LBOARD1) -> (i in ODD_SLOTS) /
    (slots[i] == LBOARD2) -> (i in LBOARD2_SLOTS)
);

% LBOARD minimum quantity constraint
constraint lboard_count[LBOARD1] >= 2 -> lboard_count[LBOARD1] > 0;
constraint lboard_count[LBOARD2] >= 2 -> lboard_count[LBOARD2] > 0;

% Total slots used constraint
constraint sum(i in 1..m)(if slots[i] == LBOARD1 then 2 else 1 endif) <= m;

solve satisfy;

output ["Board1: " ++ show(board_count[BOARD1]) ++ "\n" ++
        "Board2: " ++ show(board_count[BOARD2]) ++ "\n" ++
        "Board3: " ++ show(board_count[BOARD3]) ++ "\n" ++
        "LBoard1: " ++ show(lboard_count[LBOARD1]) ++ "\n" ++
        "LBoard2: " ++ show(lboard_count[LBOARD2]) ++ "\n"];
