int: num_states = 50;
array[1..num_states] of int: electoral_votes = [3, 3, 5, 6, 8, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55];
array[1..num_states] of float: electoral_coefficients = [0.4, 0.6, 0.55, 0.45, 0.7, 0.3, 0.6, 0.5, 0.4, 0.6, 0.55, 0.45, 0.7, 0.3, 0.6, 0.5, 0.4, 0.6, 0.55, 0.45, 0.7, 0.3, 0.6, 0.5, 0.4, 0.6, 0.55, 0.45, 0.7, 0.3, 0.6, 0.5, 0.4, 0.6, 0.55, 0.45, 0.7, 0.3, 0.6, 0.5, 0.4, 0.6, 0.55, 0.45, 0.7, 0.3, 0.6, 0.5];
array[1..5] of int: swing_states = [1, 2, 3, 4, 6];

int: required_votes = 270;

% Calculate the total votes from non-swing states
int: non_swing_votes = sum(i in 1..num_states where !(i in swing_states) \ (if electoral_coefficients[i] > 0.5 then electoral_votes[i] else 0 endif));

% Calculate the total votes from swing states
array[1..5] of var 0..1: swing_outcomes;

% Calculate the total votes from swing states based on outcomes
int: swing_votes = sum(i in 1..5) (swing_outcomes[i] * electoral_votes[swing_states[i]]);

% Total votes for Democrats
int: total_votes = non_swing_votes + swing_votes;

% Probability of winning
float: winning_probability = (if total_votes > required_votes then 1.0 else 0.0 endif);

% Objective: maximize the probability of winning
solve maximize winning_probability;

output ["Winning Probability: " ++ show(winning_probability), "Total Votes: " ++ show(total_votes)]
