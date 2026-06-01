int: num_states = 50;
set of int: States = 1..num_states;
set of int: SwingStates = {1, 2, 3, 4, 6};
set of int: NonSwingStates = States diff SwingStates;

array[States] of int: electoral_votes;
array[States] of float: electoral_coefficients;

var float: winning_probability;

constraint
  let {
    var int: non_swing_votes = sum(s in NonSwingStates where electoral_coefficients[s] > 0.5) (electoral_votes[s]),
    var float: swing_probability = sum(outcome in 0..(2^card(SwingStates)-1)) (
      let {
        array[SwingStates] of bool: outcome_vector = [bool2int((outcome div (2^(i-1))) mod 2 == 1) | i in SwingStates],
        var int: swing_votes = sum(i in SwingStates) (outcome_vector[i] * electoral_votes[i]),
        var float: outcome_probability = product(i in SwingStates) (
          if outcome_vector[i] then electoral_coefficients[i] else 1.0 - electoral_coefficients[i] endif
        )
      } in
        if non_swing_votes + swing_votes > 270 then outcome_probability else 0.0 endif
    )
  } in
    winning_probability = swing_probability;

solve satisfy;

output ["Winning Probability: ", show(winning_probability)];