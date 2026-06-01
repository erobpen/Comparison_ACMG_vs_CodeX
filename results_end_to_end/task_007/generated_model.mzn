int: total_seats = 1000;
int: vip_seats = 200;
int: free_seats = 400;
int: vip_price = 150;
int: regular_price = 50;
int: total_price_goal = 50000;
int: expenses = 35000;

var 0..vip_seats: vip_sold;
var 0..(total_seats - free_seats): regular_sold;

constraint vip_sold + regular_sold + free_seats <= total_seats;
constraint vip_sold <= vip_seats;
constraint free_seats == 400;
constraint vip_sold * vip_price + regular_sold * regular_price >= total_price_goal;

var int: profit = (vip_sold * vip_price + regular_sold * regular_price) - expenses;

solve maximize profit;

output ["VIP tickets sold: ", show(vip_sold), "\n",
        "Regular tickets sold: ", show(regular_sold), "\n",
        "Profit: ", show(profit), "\n"];
