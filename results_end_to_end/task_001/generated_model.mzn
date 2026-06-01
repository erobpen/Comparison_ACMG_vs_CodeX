int: n = 8;
array[1..n] of var 1..n: q;

constraint
  forall(i, j in 1..n where i < j) (
    q[i] != q[j] /\
    abs(q[i] - q[j]) != j - i
  );

solve satisfy;