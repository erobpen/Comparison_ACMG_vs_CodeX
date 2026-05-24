var int: VIP_price = 150;
var int: regular_price = 50;
var int: total_seats = 1000;
var int: VIP_seats = 200;
var int: free_seats = 400;
var int: total_price_goal = 50000;
var int: total_expenses = 35000;

var 0..VIP_seats: VIP_tickets_sold;
var 0..free_seats: free_tickets_sold;

constraint VIP_tickets_sold * VIP_price + free_tickets_sold * regular_price >= total_price_goal;
constraint VIP_tickets_sold + free_tickets_sold <= total_seats;
constraint VIP_tickets_sold <= VIP_seats;
constraint free_tickets_sold <= free_seats;

var int: total_revenue = VIP_tickets_sold * VIP_price + free_tickets_sold * regular_price;
var int: goal_profit = total_price_goal - total_expenses;

solve satisfy;

output [
  "VIP Tickets Sold: \(VIP_tickets_sold)",
  "Free Tickets Sold: \(free_tickets_sold)",
  "Total Revenue: \(total_revenue)",
  "Goal Profit: \(goal_profit)"
];
