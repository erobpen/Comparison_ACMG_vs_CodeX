int: num_sources = 2;
array[1..num_sources] of int: ramp_rates = [10, 15];
array[1..num_sources] of int: max_capacities = [100, 200];
array[1..num_sources] of int: costs_per_mw = [50, 60];
array[1..12] of int: renewable_availability = [300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400];
array[1..12] of int: required_energy = [500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600];
int: storage_capacity = 500;
int: budget = 89990;
int: common_upper_limit = 300;

array[1..12, 1..num_sources] of var 0..common_upper_limit: non_renewable_output;
array[1..12] of var 0..storage_capacity: storage_balance;

constraint
  storage_balance[1] = storage_capacity;

constraint
  forall(m in 1..12) (
    let {
      var int: total_non_renewable = sum(s in 1..num_sources) (non_renewable_output[m, s]),
      var int: total_energy = renewable_availability[m] + total_non_renewable + storage_balance[m]
    } in
    total_energy >= required_energy[m]
  );

constraint
  sum(m in 1..12, s in 1..num_sources) (non_renewable_output[m, s] * costs_per_mw[s]) <= budget;

constraint
  forall(m in 2..12, s in 1..num_sources) (
    abs(non_renewable_output[m, s] - non_renewable_output[m-1, s]) <= ramp_rates[s]
  );

constraint
  forall(m in 1..11) (
    storage_balance[m+1] = storage_balance[m] + renewable_availability[m] + sum(s in 1..num_sources) (non_renewable_output[m, s]) - required_energy[m]
  );

solve satisfy;
