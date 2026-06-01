int: n = 5; % Number of board types
int: m = 36; % Number of available slots

set of int: BOARD_TYPES = 1..3;
set of int: LBOARD_TYPES = 4..5;

array[BOARD_TYPES] of int: board_quantity = [5, 5, 5];
array[LBOARD_TYPES] of int: lboard_quantity = [4, 4];

array[1..m] of var 0..1: slots;

constraint
  forall(i in BOARD_TYPES) (
    let {
      set of int: valid_slots =
        if i == 1 then {j | j in 1..m where j mod 2 = 1}
        else if i == 2 then {1, 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31}
        else {j | j in 1..m where j mod 2 = 0}
    } in
    sum(j in valid_slots) (slots[j]) = board_quantity[i]
  )
  /\
  forall(i in LBOARD_TYPES) (
    let {
      set of int: valid_slots =
        if i == 4 then {j | j in 1..m where j mod 2 = 1}
        else {1, 2, 4, 8, 16}
    } in
    sum(j in valid_slots) (slots[j]) = lboard_quantity[i]
  );

solve satisfy;