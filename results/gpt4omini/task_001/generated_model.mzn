int: n = 8;

array[1..n] of var 1..n: queens;

% Constraints to ensure no two queens threaten each other
constraint all_different(queens);
constraint all_different([queens[i] + i | i in 1..n]);
constraint all_different([queens[i] - i | i in 1..n]);

solve satisfy;

output ["Queen at row " ++ show(i) ++ " is in column " ++ show(queens[i]) ++ "\n" | i in 1..n];
