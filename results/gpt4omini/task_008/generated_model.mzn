int: num_months = 12;

int: budget = 89990;

array[1..num_months] of int: required_energy = [500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600];
array[1..num_months] of int: renewable_energy = [300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400];

int: storage_capacity = 500;

int: num_sources = 2;
array[1..num_sources] of int: ramp_rates = [10, 15];
array[1..num_sources] of int: max_capacities = [100, 200];
array[1..num_sources] of int: costs_per_mw = [50, 60];

array[1..num_months, 1..num_sources] of var 0..max_capacities: non_renewable_output;
array[1..num_months] of var 0..storage_capacity: stored_energy;

% Constraints
constraint sum([non_renewable_output[m, s] * costs_per_mw[s] | s in 1..num_sources]) <= budget;

constraint forall(m in 2..num_months)(
    forall(s in 1..num_sources)(
        abs(non_renewable_output[m, s] - non_renewable_output[m-1, s]) <= ramp_rates[s]
    )
);

constraint forall(m in 1..num_months)(
    renewable_energy[m] + sum([non_renewable_output[m, s] | s in 1..num_sources]) + (if m == 1 then storage_capacity else stored_energy[m-1]) >= required_energy[m]
);

constraint forall(m in 1..num_months)(
    stored_energy[m] = (if m == 1 then storage_capacity else stored_energy[m-1]) - (required_energy[m] - renewable_energy[m] - sum([non_renewable_output[m, s] | s in 1..num_sources]))
);

% Ensure storage does not exceed capacity
constraint forall(m in 1..num_months)(stored_energy[m] >= 0);

% Solve
solve satisfy;

% Output
output [
    "Non-renewable outputs: ", show(non_renewable_output), "\n",
    "Stored energy: ", show(stored_energy), "\n"
];
