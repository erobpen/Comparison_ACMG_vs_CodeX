%% 8 Queens Problem

int: n = 8;

array[1..n] of var 1..n: queens;

constraint all_different([queens[i] + i | i in 1..n]) /\ all_different([queens[i] - i | i in 1..n]) /\ all_different(queens);

solve satisfy;

output [
  "Queens positions: \(queens)"
];
