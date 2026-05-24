int: total_seats = 1000;
int: vip_seats = 200;
int: free_seats = 400;
int: ticket_price_vip = 150;
int: ticket_price_regular = 50;
int: total_price_goal = 50000;
int: total_expenses = 35000;
int: goal_profit = total_price_goal - total_expenses;

int: num_vip_sold;
int: num_regular_sold;

% Constraints
constraint num_vip_sold <= vip_seats;
constraint num_regular_sold + num_vip_sold <= total_seats;
constraint num_regular_sold >= 0;
constraint num_vip_sold >= 0;
constraint num_regular_sold >= free_seats;

% Total revenue calculation
int: total_revenue = num_vip_sold * ticket_price_vip + num_regular_sold * ticket_price_regular;

% Ensure total price goal is met
constraint total_revenue = total_price_goal;

% Objective: Maximize profit
solve satisfy;

% Output
output ["VIP tickets sold: " ++ show(num_vip_sold) ++ "\n", "Regular tickets sold: " ++ show(num_regular_sold) ++ "\n", "Total Revenue: " ++ show(total_revenue) ++ "\n", "Profit: " ++ show(total_revenue - total_expenses) ++ "\n"];
