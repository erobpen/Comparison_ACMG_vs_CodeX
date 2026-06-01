int: n = 30;
int: m = 40;

set of int: Rows = 1..n;
set of int: Cols = 1..m;

enum TileType = {SEA, CO, MO, FO, HI, GR, R, P, B, PR};

array[Rows, Cols] of var TileType: map;

constraint
  let {
    int: total_tiles = n * m,
    int: sea_tiles = total_tiles * 15 div 100,
    int: land_tiles = total_tiles - sea_tiles,
    int: mo_tiles = land_tiles * 10 div 100
  } in
    sum(r in Rows, c in Cols)(map[r, c] == SEA) == sea_tiles /\
    sum(r in Rows, c in Cols)(map[r, c] == MO) == mo_tiles /\
    forall(r in Rows, c in Cols) (
      if map[r, c] == SEA then
        (c == 1 \/ c == m \/ r == 1 \/ r == n \/ map[r, c-1] == CO \/ map[r, c+1] == CO \/ map[r-1, c] == CO \/ map[r+1, c] == CO)
      else if map[r, c] == MO then
        (c == 1 \/ c == m \/ r == 1 \/ r == n \/ map[r, c-1] == HI \/ map[r, c+1] == HI \/ map[r-1, c] == HI \/ map[r+1, c] == HI)
      else if map[r, c] == HI then
        (map[r, c-1] in {CO, MO, FO, GR} \/ map[r, c+1] in {CO, MO, FO, GR} \/ map[r-1, c] in {CO, MO, FO, GR} \/ map[r+1, c] in {CO, MO, FO, GR})
      else if map[r, c] == R then
        (map[r, c-1] in {MO, CO} \/ map[r, c+1] in {MO, CO} \/ map[r-1, c] in {MO, CO} \/ map[r+1, c] in {MO, CO})
      else if map[r, c] == P then
        (map[r, c-1] in {FO, HI, GR} \/ map[r, c+1] in {FO, HI, GR} \/ map[r-1, c] in {FO, HI, GR} \/ map[r+1, c] in {FO, HI, GR})
      else if map[r, c] == B then
        (map[r, c-1] == R /\ map[r, c+1] == P \/ map[r, c-1] == P /\ map[r, c+1] == R)
      else if map[r, c] == PR then
        (map[r, c-1] == R /\ map[r, c+1] == P \/ map[r, c-1] == P /\ map[r, c+1] == R)
      else true
    );

solve satisfy;