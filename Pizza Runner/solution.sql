SET search_path = pizza_runner;

select * from customer_orders;
select * from pizza_names;
select * from pizza_recipes;
select * from pizza_toppings;
select * from runner_orders;
select * from runners;

 ----------- A. Pizza Metrics -----------
 
-- 1. How many pizzas were ordered?
select count(order_id) as total_pizzas_ordered from customer_orders;

-- 2. How many unique customer orders were made?
select count(distinct order_id) as unqiue_customer_orders from customer_orders;

--  3. How many successful orders were delivered by each runner?
select runner_id, count(order_id) as successful_orders from runner_orders where cancellation = 'Not Applicable'
group by runner_id order by successful_orders desc;

-- 4. How many of each type of pizza was delivered?
select 
c.pizza_id, p.pizza_name, count(c.pizza_id) as total_pizzas
from customer_orders as c 
inner join pizza_names as p
on c.pizza_id = p.pizza_id
group by c.pizza_id, p.pizza_name order by p.pizza_name;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
select 
c.customer_id, p.pizza_name, count(c.pizza_id) as total_pizza
from customer_orders as c 
inner join pizza_names as p
on c.pizza_id = p.pizza_id
group by c.customer_id, p.pizza_name order by c.customer_id;


-- 6. What was the maximum number of pizzas delivered in a single order?

-- 1st approach
select 
order_id,
count(order_id) as total_pizzas
from
customer_orders group by order_id order by total_pizzas desc limit 1;

-- 2nd approach
WITH PizzaCounts AS (
    SELECT 
        order_id,
        COUNT(order_id) AS total_pizzas
    FROM 
        customer_orders
    GROUP BY 
        order_id
),
MaxPizza AS (
    SELECT 
        MAX(total_pizzas) AS max_pizzas
    FROM 
        PizzaCounts
)
SELECT 
    order_id,
    total_pizzas
FROM 
    PizzaCounts
WHERE 
    total_pizzas = (SELECT max_pizzas FROM MaxPizza);

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
-- Check this solution thoroughly
with tbl1 as(
	select *,
	case 
		when exclusions != '0' or extras != '0' then 'Atleast 1 change'
		when exclusions = '0' and extras = '0' then 'No change'
		else 'null'
	end as change_flag
	from customer_orders
)
select customer_id, change_flag, count(pizza_id) from tbl1
group by customer_id, change_flag order by customer_id;

-- 8. How many pizzas were delivered that had both exclusions and extras?
select 
count(pizza_id) as total_pizzas
from customer_orders where exclusions <> '0' and extras <> '0';

-- 9. What was the total volume of pizzas ordered for each hour of the day?
with t1 as (
	select *, extract(hour from order_time) as hours_from_timestamp from customer_orders
)
select hours_from_timestamp as hours, count(pizza_id) as total_pizzas 
from t1 group by hours_from_timestamp order by hours_from_timestamp;

-- 10. What was the volume of orders for each day of the week?
with t1 as (
	select *, date_part('week',order_time) as week_number from customer_orders
)
select week_number as week, count(pizza_id) as total_pizzas 
from t1 group by week order by week;


----------- B. Runner and Customer Experience -----------

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

with t1 as (
	SELECT 
	    *,
	    FLOOR((EXTRACT(DOY FROM registration_date) - 1) / 7) + 1 AS calendar_week
	FROM 
	    runners	
)
select calendar_week, count(runner_id) as total_runners from t1 group by calendar_week order by calendar_week;


-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
with t1 as (
	select *, date_part('minutes', pickup_time::time) AS minute_part from runner_orders
)
select runner_id, sum(minute_part) / count(runner_id) as avg_time_taken from t1 group by runner_id;


-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
select 
c.order_id, c.pizza_id, c.order_time,
r.runner_id, r.pickup_time
from customer_orders as c
inner join runner_orders as r
on c.order_id = r.order_id order by c.order_id;

-- According to the above query's data, I can see that orders having multiple pizzas ordered have taken more time to prepare. 
-- So if a order has 2 or 3 or even more pizzas ordered then the time taken to prepare is relatively high.


-- 4. What was the average distance travelled for each customer?
select 
c.customer_id, round(avg(r.distance_numeric))::TEXT || ' km'
from customer_orders as c
inner join runner_orders as r
on c.order_id = r.order_id
group by c.customer_id order by c.customer_id;


-- 5. What was the difference between the longest and shortest delivery times for all orders?
select *, pickup_time::time + (duration_numeric || ' minutes')::INTERVAL from runner_orders;

with tab1 as(
	SELECT 
	    MAX(pickup_time::time + (duration_numeric || ' minutes')::INTERVAL) AS latest_delivery_time,
	    MIN(pickup_time::time + (duration_numeric || ' minutes')::INTERVAL) AS earliest_delivery_time
	FROM runner_orders where pickup_time <> '00:00:00'
)
select *, latest_delivery_time - earliest_delivery_time from tab1;


-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
with tab1 as (
	SELECT 
	    runner_id,
	    order_id,
	    distance_numeric AS distance_km,
		duration_numeric as duration_in_minutes,
	    duration_numeric / 60.0 AS time_hours,
	    distance_numeric / (duration_numeric / 60.0) AS speed_in_kmph
	FROM runner_orders
	WHERE cancellation = 'Not Applicable' order by runner_id
)
SELECT 
runner_id,
round(avg(distance_km))::text || ' km' as distance_km,
round(avg(duration_in_minutes))::text || ' minutes' as duration_in_minutes,
avg(time_hours)::text || ' hours' as duration_in_hours,
round(AVG(speed_in_kmph))::text || ' km' AS avg_speed_kmph
from tab1 group by runner_id;

-- 7. What is the successful delivery percentage for each runner?

SELECT 
    runner_id,
    COUNT(CASE WHEN cancellation = 'Not Applicable' THEN 1 END) AS successful_delivery_count,
	COUNT(*) as total_count,
	(
		COUNT(CASE WHEN cancellation = 'Not Applicable' THEN 1 END)::float 
		/ 
		COUNT(*)::float
	) * 100
	AS successful_delivery_percentage
FROM runner_orders
GROUP BY runner_id
ORDER BY runner_id;


----------- C.  Ingredient Optimisation -----------

-- 1. What are the standard ingredients for each pizza?
select * from customer_orders;

select * from pizza_names;
select * from pizza_recipes;
select * from pizza_toppings;

WITH expanded_toppings AS (
    SELECT 
        pr.pizza_id, 
        UNNEST(STRING_TO_ARRAY(pr.toppings, ','))::INTEGER AS topping_id
    FROM pizza_recipes pr
)
select 
et.pizza_id as pizza_id,
pn.pizza_name as pizza_name,
STRING_AGG(pt.topping_name, ', ') AS standard_toppings
from expanded_toppings as et
inner join pizza_toppings as pt on et.topping_id = pt.topping_id
inner join pizza_names as pn on et.pizza_id = pn.pizza_id 
group by et.pizza_id, pn.pizza_name
order by et.pizza_id;

-- 2. What was the most commonly added extra?
with orders as (
	select *, UNNEST(STRING_TO_ARRAY(extras, ','))::INTEGER AS topping_id
	from customer_orders
)
select 
pt.topping_name, count(pt.topping_id) as total_toppings_used
from orders as o 
inner join pizza_toppings as pt
on o.topping_id = pt.topping_id
where extras <> '0'
group by pt.topping_name order by total_toppings_used desc limit 1;

-- 3. What was the most common exclusion?
with orders as (
	select *, UNNEST(STRING_TO_ARRAY(exclusions, ','))::INTEGER AS topping_id
	from customer_orders
)
select 
pt.topping_name, count(pt.topping_id) as total_toppings_used
from orders as o 
inner join pizza_toppings as pt
on o.topping_id = pt.topping_id
where exclusions <> '0'
group by pt.topping_name order by total_toppings_used desc limit 1;



-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
	-- Meat Lovers
	-- Meat Lovers - Exclude Beef
	-- Meat Lovers - Extra Bacon
	-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
SELECT 
    co.order_id,
    pn.pizza_name || 
    COALESCE(' - Exclude ' || exclusions_list, '') || 
    COALESCE(' - Extra ' || extras_list, '') AS order_item
FROM customer_orders co
INNER JOIN pizza_names pn
    ON co.pizza_id = pn.pizza_id
LEFT JOIN LATERAL (
    SELECT 
        STRING_AGG(pt_ex.topping_name, ', ') AS exclusions_list
    FROM UNNEST(STRING_TO_ARRAY(co.exclusions, ',')) AS excl_id
    LEFT JOIN pizza_toppings pt_ex
        ON excl_id::INTEGER = pt_ex.topping_id
) ex ON TRUE
LEFT JOIN LATERAL (
    SELECT 
        STRING_AGG(pt_extr.topping_name, ', ') AS extras_list
    FROM UNNEST(STRING_TO_ARRAY(co.extras, ',')) AS extr_id
    LEFT JOIN pizza_toppings pt_extr
        ON extr_id::INTEGER = pt_extr.topping_id
) ex2 ON TRUE
ORDER BY co.order_id;

-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table 
-- and add a 2x in front of any relevant ingredients For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

with expanded_extras as (
	select 
	co.order_id,
	pn.pizza_name,
	UNNEST(string_to_array(co.extras,','))::INTEGER AS topping_id
	from
	customer_orders as co
	inner join pizza_names as pn
	on co.pizza_id = pn.pizza_id
	where co.extras <> '0'
),
grouped_extras as (
	select 
	order_id, 
	pizza_name,
	topping_id,
	count(topping_id) total_toppings
	from
	expanded_extras
	group by order_id, pizza_name, topping_id
),
formatted_extras as (
	select *
	from grouped_extras as gx
	inner join pizza_toppings as pt
	on gx.topping_id = pt.topping_id
),create_final_topping_name as (
	select *,
	case
		when total_toppings > 1 then '2x'||topping_name
	else topping_name
	end as final_topping_name
	from formatted_extras
), final_output as (
	select
	order_id,
	pizza_name,
	pizza_name||': '||STRING_AGG(final_topping_name, ', ') AS combined_toppings
	from create_final_topping_name
	group by order_id, pizza_name
)
select * from final_output order by order_id;

-- NOTE
-- Adding an element to check how the code works for orders having multiple same extras. For example if an order has 2 pizzas
-- and each of these 2 orders have a topping. So it should show 2X for that topping.

INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
	('10', '104', '1', '3, 6', '1, 4', '2020-01-11 18:34:49');



-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
select * from customer_orders;


with expanded_extras as (
	select 
	co.order_id,
	pn.pizza_name,
	order_time,
	UNNEST(string_to_array(co.extras,','))::INTEGER AS topping_id
	from
	customer_orders as co
	inner join pizza_names as pn
	on co.pizza_id = pn.pizza_id
	where co.extras <> '0'
),
grouped_extras as (
	select 
	order_id, 
	order_time,
	pizza_name,
	topping_id,
	count(topping_id) total_toppings
	from
	expanded_extras
	group by order_id,order_time, pizza_name, topping_id
)
select * from grouped_extras order by order_time desc;

 ----------- D. Pricing and Ratings -----------
 
-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money 
-- has Pizza Runner made so far if there are no delivery fees?

with populating_pizza_cost as (
	select *,
	case	
		when pm.pizza_name = 'Meatlovers' then 12
		when pm.pizza_name = 'Vegetarian' then 10
		else 0
		end as pizza_cost
	from customer_orders as co
	inner join pizza_names as pm
	on co.pizza_id = pm.pizza_id
),
final_output as (
	select sum(pizza_cost) as total_sales
	from populating_pizza_cost
)
select '$'||total_sales from final_output;

-- 2. What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra

-- Inserting some new records just to check if it works for all scenarios
INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time") values
('11', '101', '1', '3, 7', '6, 4', '2020-01-12 19:34:49'),
('11', '101', '2', '2, 6', '4, 5', '2020-01-12 19:40:49'),
('11', '101', '2', '3, 5', '1, 4', '2020-01-12 19:50:49');

-- Below is the main query
WITH get_cheese_id AS (
    SELECT topping_id 
    FROM pizza_toppings 
    WHERE topping_name = 'Cheese'
), identifying_cheese_extra as (
	SELECT 
	    co.order_id,
	    co.customer_id,
	    co.pizza_id,
	    co.extras,
	    pn.pizza_name,
	    STRING_TO_ARRAY(co.extras, ',') AS extras_array,
	    CASE
	        WHEN 
	            ARRAY[(SELECT topping_id FROM get_cheese_id)] <@ (STRING_TO_ARRAY(co.extras, ',')::INTEGER[])
	        THEN 'Cheese'
	        ELSE 'No cheese'
	    END AS is_cheese,
	    CASE    
	        WHEN pn.pizza_name = 'Meatlovers' THEN 12
	        WHEN pn.pizza_name = 'Vegetarian' THEN 10
	        ELSE 0
	    END AS pizza_cost
	FROM customer_orders AS co 
	LEFT JOIN pizza_names AS pn
	    ON co.pizza_id = pn.pizza_id
	ORDER BY co.order_id, co.pizza_id
), final_table as (
	select *,
	case
		when is_cheese = 'Cheese' then pizza_cost + 1
		else pizza_cost
	end as total_pizza_cost
	from identifying_cheese_extra
)
select * from final_table;


-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would 
-- you design an additional table for this new dataset - generate a schema for this new table and insert your own 
-- data for ratings for each successful customer order between 1 to 5.

-- Inserting a runner for order id 11, because in previous questions I added an order of order id 11 for just checking purposes,
-- but I didn't add the runner for it because it wasn't necessary at that time. But now I need to add it for this question & it'answer
-- to make sense
INSERT INTO runner_orders
  ("order_id", "runner_id", "pickup_time", "distance_numeric", "duration_numeric", "cancellation")
VALUES
  ('11', '3', '2020-01-02 19:55:00', 22, 40, 'Not Applicable');


-- Creating runner_rating table
DROP TABLE IF EXISTS runner_ratings;
CREATE TABLE runner_ratings (
    rating_id SERIAL PRIMARY KEY,  -- Auto-incremented unique ID for each rating
    order_id INTEGER NOT NULL,    -- Links to customer_orders table
    runner_id INTEGER NOT NULL,   -- Links to the runner responsible for delivery
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),  -- Customer's rating (1 to 5)
    rating_date DATE  -- Date when the rating was given
)

-- Inserting data into the runner_rating table
INSERT INTO runner_ratings
  ("rating_id", "order_id", "runner_id", "rating", "rating_date")
VALUES
	('1001','1','1','4','01-01-2020'),
	('1002','2','1','2','01-01-2020'),
	('1003','3','1','3','03-01-2020'),
	('1004','4','2','4','04-01-2020'),
	('1005','5','3','5','08-01-2020'),
	('1006','8','2','3','10-01-2020'),
	('1007','10','1','5','11-01-2020')

-- 4. Using your newly generated table - can you join all of the information together to form a table which has the following 
-- information for successful deliveries?
-- customer_id
-- order_id
-- runner_id
-- rating
-- order_time
-- pickup_time
-- Time between order and pickup
-- Delivery duration
-- Average speed
-- Total number of pizzas

select 
co.customer_id, co.order_id, ro.runner_id, rr.rating,
co.order_time, ro.pickup_time, ro.duration_numeric as duration, ro.distance_numeric as distance,
(round(EXTRACT(EPOCH FROM ((ro.pickup_time::timestamp) - co.order_time)) / 60,0))::text || ' mins' AS time_difference,
(round((ro.distance_numeric / (ro.duration_numeric / 60.0))))::text || ' kmph' AS avg_speed, 
count(co.order_id) as total_pizzas
from customer_orders as co
left join runner_orders as ro
on co.order_id = ro.order_id
left join runner_ratings as rr
on co.order_id = rr.order_id
where ro.cancellation = 'Not Applicable'
group by co.customer_id, co.order_id, ro.runner_id, rr.rating,
co.order_time, ro.pickup_time, ro.duration_numeric, ro.distance_numeric
order by co.customer_id;

select * from runner_orders;
select * from customer_orders;

update runner_orders set pickup_time = '2020-01-12 19:55:00' where order_id = '11';

update customer_orders set order_time = '2020-01-12 19:50:00' where order_id = '11';

-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per
-- kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

with pizza_cost as (
	select 
	co.order_id, co.pizza_id, pn.pizza_name,
	case
		when pn.pizza_name = 'Meatlovers' then 12
		when pn.pizza_name = 'Vegetarian' then 10
		else 0
	end as pizza_cost
	from
	customer_orders as co
	left join pizza_names as pn
	on co.pizza_id = pn.pizza_id
), runner_table as (
	select order_id, distance_numeric * 0.30 as company_delivery_spends
	from runner_orders 
), transformed_table as(
	select *,
	round(pizza_cost::integer * company_delivery_spends::integer,0) as total_amount,
	round(pizza_cost::integer - company_delivery_spends::integer,0) as profit_amount
	from pizza_cost as pc
	left join runner_table as rt
	on pc.order_id = rt.order_id
	order by pc.order_id
)
select sum(profit_amount) from transformed_table;


