SET search_path = pizza_runner;

-- delete from runner_orders where order_id = 11;

select * from customer_orders order by order_id;
select * from runner_orders order by order_id;
select * from pizza_names;
select * from pizza_recipes;
select * from pizza_toppings;
select * from runners;

 ----------- A. Pizza Metrics -----------
 
-- 1. How many pizzas were ordered?
select count(order_id) as total_pizzas_ordered from customer_orders;

-- 2. How many unique customer orders were made?
select count(distinct order_id) as unqiue_customer_orders from customer_orders;

--  3. How many successful orders were delivered by each runner?
select runner_id, count(order_id) as successful_orders from runner_orders where cancellation = 'Not Applicable'
group by runner_id order by successful_orders desc;


-- 4. How many of each type of pizza was delivered? actual result should be 10 and 2
SELECT 
    c.pizza_id, p.pizza_name, COUNT(c.pizza_id) AS delivered_pizzas
FROM customer_orders AS c
JOIN runner_orders AS r ON c.order_id = r.order_id
JOIN pizza_names AS p ON c.pizza_id = p.pizza_id
WHERE r.cancellation = 'Not Applicable'
GROUP BY c.pizza_id, p.pizza_name
ORDER BY p.pizza_name;


-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
select 
c.customer_id, p.pizza_name, count(c.pizza_id) as total_pizza
from customer_orders as c 
inner join pizza_names as p
on c.pizza_id = p.pizza_id
group by c.customer_id, p.pizza_name order by c.customer_id;


-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT 
c.order_id,
count(c.order_id) as total_pizzas
FROM customer_orders AS c
JOIN runner_orders AS r ON c.order_id = r.order_id
WHERE r.cancellation = 'Not Applicable'
group by c.order_id order by total_pizzas desc limit 1;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
-- Check this solution thoroughly
WITH changes_flag AS (
    SELECT
        c.customer_id,
        c.pizza_id,
        CASE 
            WHEN (c.exclusions <> '0' OR c.extras <> '0') THEN 'At least 1 Change'
            WHEN (c.exclusions = '0' AND c.extras = '0') THEN 'No Change'
            ELSE 'Unknown'
        END AS change_flag
    FROM customer_orders AS c
    JOIN runner_orders AS r
        ON c.order_id = r.order_id
    WHERE r.cancellation = 'Not Applicable'  -- only delivered pizzas
)
SELECT
    customer_id,
    change_flag,
    COUNT(pizza_id) AS total_pizzas
FROM changes_flag
GROUP BY customer_id, change_flag
ORDER BY customer_id, change_flag;


-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(c.pizza_id) AS total_pizzas
FROM customer_orders AS c
JOIN runner_orders AS r ON c.order_id = r.order_id
WHERE r.cancellation = 'Not Applicable'
  AND c.exclusions <> '0' 
  AND c.extras <> '0';


-- 9. What was the total volume of pizzas ordered for each hour of the day?
with t1 as (
	select *, extract(hour from order_time) as hours_from_timestamp from customer_orders
)
select hours_from_timestamp as hours, count(pizza_id) as total_pizzas 
from t1 group by hours_from_timestamp order by hours_from_timestamp;

select * from customer_orders 

-- 10. What was the volume of orders for each day of the week?
WITH t1 AS (
	SELECT *, TO_CHAR(order_time, 'Day') AS day_of_week
	FROM customer_orders
)
SELECT TRIM(day_of_week) AS day, COUNT(pizza_id) AS total_pizzas
FROM t1
GROUP BY day_of_week
ORDER BY MIN(order_time);



----------- B. Runner and Customer Experience -----------

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

with t1 as (
	SELECT 
	    *,
	    DATE_TRUNC('week', registration_date::date - INTERVAL '4 days') + INTERVAL '4 days' AS calendar_week
	FROM 
	    runners	
)
select calendar_week, count(runner_id) as total_runners from t1 group by calendar_week order by calendar_week;


-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
WITH order_prep_times AS (
    SELECT 
        r.runner_id,
        c.order_id,
        MIN(c.order_time) AS order_time,      
        MIN(r.pickup_time) AS pickup_time,    
        ROUND(
            EXTRACT(EPOCH FROM (MIN(r.pickup_time)::timestamp - MIN(c.order_time)::timestamp)) / 60,
            2
        ) AS prep_time_mins                   
    FROM customer_orders AS c
    JOIN runner_orders AS r
        ON c.order_id = r.order_id
    WHERE r.pickup_time <> '00:00:00'         
    GROUP BY r.runner_id, c.order_id 
)
SELECT
    runner_id,
    ROUND(AVG(prep_time_mins), 2) AS avg_pickup_time_mins
FROM order_prep_times
GROUP BY runner_id
ORDER BY runner_id;



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
c.customer_id, round(avg(r.distance_numeric))::TEXT || ' km' as avg_distance
from customer_orders as c
inner join runner_orders as r
on c.order_id = r.order_id
group by c.customer_id order by c.customer_id;


-- 5. What was the difference between the longest and shortest delivery times for all orders?

with tab1 as(
	SELECT 
	    MAX(pickup_time::time + (duration_numeric || ' minutes')::INTERVAL) AS latest_delivery_time,
	    MIN(pickup_time::time + (duration_numeric || ' minutes')::INTERVAL) AS earliest_delivery_time
	FROM runner_orders where pickup_time <> '00:00:00'
)
select *, latest_delivery_time - earliest_delivery_time as difference_time from tab1;


-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
with tab1 as (
	SELECT 
	    runner_id,
	    order_id,
	    distance_numeric AS distance_km,
		duration_numeric as duration_in_minutes,
	    (duration_numeric::numeric / 60.0) AS time_hours,
	    distance_numeric / (duration_numeric / 60.0) AS speed_in_kmph
	FROM runner_orders
	WHERE cancellation = 'Not Applicable' order by runner_id
)
SELECT 
runner_id,
round(avg(distance_km))::text || ' km' as distance_km,
round(avg(duration_in_minutes))::text || ' minutes' as duration_in_minutes,
round(avg(time_hours), 2)::text || ' hours' as duration_in_hours,
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
select * from customer_orders order by order_id;
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

select * from customer_orders order by order_id;

-- 2. What was the most commonly added extra?
with orders as (
	select *, UNNEST(STRING_TO_ARRAY(extras, ','))::INTEGER AS topping_id
	from customer_orders order by order_id
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

-- Main Logic
with adding_unique_identifier_to_customers_table as (
	select *, row_number() over(order by order_time) as unique_row_id from customer_orders
), unnest_exclusions as (
	select *, unnest(STRING_TO_ARRAY(exclusions,','))::INTEGER as unnested_exclusion_id
	from adding_unique_identifier_to_customers_table
), join_topping_names_with_unnested_exclusions as (
	select ue.*, pn.pizza_name, pt.topping_name from unnest_exclusions as ue
	left join pizza_toppings as pt
	on ue.unnested_exclusion_id = pt.topping_id
	left join pizza_names as pn
	on ue.pizza_id = pn.pizza_id
), nest_back_exclusions as (
	select
	unique_row_id,
	order_id,
	pizza_name,
	STRING_AGG(topping_name,', ') as exclusions_list 
	from join_topping_names_with_unnested_exclusions
	group by unique_row_id, order_id, pizza_name
), unnest_extras as (
	select *, unnest(STRING_TO_ARRAY(extras,','))::INTEGER as unnested_extras_id
	from adding_unique_identifier_to_customers_table
), join_topping_names_with_unnested_extras as (
	select ue.*, pn.pizza_name, pt.topping_name from unnest_extras as ue
	left join pizza_toppings as pt
	on ue.unnested_extras_id = pt.topping_id
	left join pizza_names as pn
	on ue.pizza_id = pn.pizza_id
), nest_back_extras as (
	select
	unique_row_id,
	order_id,
	pizza_name,
	STRING_AGG(topping_name,', ') as extras_list 
	from join_topping_names_with_unnested_extras
	group by unique_row_id, order_id, pizza_name
)
select 
n1.*, n2.extras_list,
case 
	when exclusions_list is null and extras_list is null then null
	when exclusions_list is null and extras_list is not null then concat('Extra ',extras_list)
	when extras_list is null and exclusions_list is not null then concat('Exclude ', exclusions_list)
	else concat('Exclude ', exclusions_list,' - Extra ',extras_list)
end as order_item_information
from nest_back_exclusions as n1
left join nest_back_extras as n2 
on n1.unique_row_id = n2.unique_row_id
order by order_id;


-- Alternative solution by chtagpt
-- SELECT 
--     co.order_id,
--     pn.pizza_name || 
--     COALESCE(' - Exclude ' || exclusions_list, '') || 
--     COALESCE(' - Extra ' || extras_list, '') AS order_item
-- FROM customer_orders co
-- INNER JOIN pizza_names pn
--     ON co.pizza_id = pn.pizza_id
-- LEFT JOIN LATERAL (
--     SELECT 
--         STRING_AGG(pt_ex.topping_name, ', ') AS exclusions_list
--     FROM UNNEST(STRING_TO_ARRAY(co.exclusions, ',')) AS excl_id
--     LEFT JOIN pizza_toppings pt_ex
--         ON excl_id::INTEGER = pt_ex.topping_id
-- ) ex ON TRUE
-- LEFT JOIN LATERAL (
--     SELECT 
--         STRING_AGG(pt_extr.topping_name, ', ') AS extras_list
--     FROM UNNEST(STRING_TO_ARRAY(co.extras, ',')) AS extr_id
--     LEFT JOIN pizza_toppings pt_extr
--         ON extr_id::INTEGER = pt_extr.topping_id
-- ) ex2 ON TRUE
-- ORDER BY co.order_id;


-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table 
-- and add a 2x in front of any relevant ingredients For example: "Meat Lovers: 2xBacon, Beef, ... , Salami".

select * from customer_orders order by order_id;
select * from pizza_names;
select * from pizza_recipes;
select * from pizza_toppings;


-- New Logic
with adding_unique_identifier_to_customers_table as (
	select *, row_number() over(order by order_time) as unique_row_id from customer_orders
), unnest_extras as (
	select *, unnest(string_to_array(extras, ','))::Integer as unnested_extras_id
	from adding_unique_identifier_to_customers_table
), join_with_pizza_recipes as (
	select ue.*, temp_tbl.unnested_toppings_id
	from unnest_extras as ue
	left join (
		select *, unnest(string_to_array(toppings, ','))::Integer as unnested_toppings_id from pizza_recipes
	) as temp_tbl
	on ue.pizza_id = temp_tbl.pizza_id and
	ue.unnested_extras_id = temp_tbl.unnested_toppings_id  
),join_topping_names as (
	select jp.*, 
	case
		when jp.unnested_extras_id is not null and jp.unnested_toppings_id is not null then concat('2x',pt.topping_name)
		when jp.unnested_extras_id is not null and jp.unnested_toppings_id is null then pt.topping_name
		else null
	end as concatenated_ingredients_list
	from join_with_pizza_recipes as jp
	left join pizza_toppings as pt
	on jp.unnested_extras_id = pt.topping_id
), nest_back_unnested_extras as (
	select unique_row_id,
	order_id,
	pn.pizza_name,
	STRING_AGG(concatenated_ingredients_list,', ' ORDER BY concatenated_ingredients_list) as extras_list
	from join_topping_names as jtn
	left join pizza_names as pn
	on jtn.pizza_id = pn.pizza_id
	group by unique_row_id, order_id, pn.pizza_name
	order by order_id, pn.pizza_name, extras_list
)
select 
order_id,
case
	when extras_list is null then null
	else concat(pizza_name, ': ', extras_list,', ')
end as final_order_ingredients
from nest_back_unnested_extras;


-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
select * from customer_orders order by order_id;
select * from runner_orders;
select * from pizza_recipes;


-- New Logic
WITH delivered_orders AS (
    SELECT c.order_id, c.pizza_id, c.exclusions, c.extras
    FROM customer_orders c
    JOIN runner_orders r 
        ON c.order_id = r.order_id
    WHERE r.cancellation = 'Not Applicable'
), base_toppings AS (
    SELECT 
        d.order_id,
        d.pizza_id,
        UNNEST(STRING_TO_ARRAY(pr.toppings, ','))::Integer AS topping_id
    FROM delivered_orders d
    JOIN pizza_recipes pr
        ON d.pizza_id = pr.pizza_id
), exclude_toppings AS (
    SELECT 
        d.order_id,
        UNNEST(STRING_TO_ARRAY(d.exclusions, ','))::Integer AS topping_id
    FROM delivered_orders d
    WHERE d.exclusions IS NOT NULL AND d.exclusions <> '0'
), extra_toppings AS (
    SELECT 
        d.order_id,
        UNNEST(STRING_TO_ARRAY(d.extras, ','))::Integer AS topping_id
    FROM delivered_orders d
    WHERE d.extras IS NOT NULL AND d.extras <> '0'
), final_ingredients AS (
    SELECT bt.order_id, bt.topping_id
    FROM base_toppings bt
    LEFT JOIN exclude_toppings et
        ON bt.order_id = et.order_id AND bt.topping_id = et.topping_id
    WHERE et.topping_id IS NULL  

    UNION ALL

    SELECT order_id, topping_id FROM extra_toppings
)
SELECT  pt.topping_name, COUNT(*) AS total_times_used FROM final_ingredients fi
INNER JOIN pizza_toppings pt
ON fi.topping_id = pt.topping_id
GROUP BY pt.topping_name
ORDER BY total_times_used DESC;

 ----------- D. Pricing and Ratings -----------
 
-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money 
-- has Pizza Runner made so far if there are no delivery fees?

WITH pizza_cost AS (
    SELECT 
        co.order_id,
        pn.pizza_name,
        CASE 
            WHEN pn.pizza_name = 'Meatlovers' THEN 12
            WHEN pn.pizza_name = 'Vegetarian' THEN 10
            ELSE 0
        END AS pizza_price
    FROM customer_orders co
    JOIN runner_orders r
        ON co.order_id = r.order_id
    JOIN pizza_names pn
        ON co.pizza_id = pn.pizza_id
    WHERE r.cancellation = 'Not Applicable'  -- only delivered orders
)
SELECT 
    '$' || SUM(pizza_price) AS total_revenue
FROM pizza_cost;


-- 2. What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra

-- Inserting some new records just to check if it works for all scenarios
INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time") values
('11', '101', '1', '3, 7', '6, 4', '2020-01-12 19:34:49'),
('11', '101', '2', '2, 6', '4, 5', '2020-01-12 19:40:49'),
('11', '101', '2', '3, 5', '1, 4', '2020-01-12 19:50:49');

-- Below is the main query
WITH cheese_id AS (
    SELECT topping_id 
    FROM pizza_toppings 
    WHERE topping_name = 'Cheese'
),
pizza_base AS (
    SELECT 
        co.order_id,
        co.pizza_id,
        pn.pizza_name,
        REGEXP_REPLACE(co.extras, '\s+', '', 'g') AS extras_clean,
        CASE
            WHEN pn.pizza_name = 'Meatlovers' THEN 12
            WHEN pn.pizza_name = 'Vegetarian' THEN 10
            ELSE 0
        END AS base_price
    FROM customer_orders co
    JOIN pizza_names pn
        ON co.pizza_id = pn.pizza_id
),
add_cheese_flag AS (
    SELECT 
        p.*,
        CASE 
            WHEN (ARRAY(SELECT topping_id FROM cheese_id)) && 
                 (STRING_TO_ARRAY(p.extras_clean, ',')::INT[])
            THEN 1 ELSE 0
        END AS has_cheese
    FROM pizza_base p
)
SELECT 
    order_id,
    pizza_name,
    base_price,
    has_cheese,
    base_price + has_cheese AS total_price
FROM add_cheese_flag
ORDER BY order_id;



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

SELECT 
    co.customer_id,
    co.order_id,
    ro.runner_id,
    rr.rating,
    co.order_time,
    ro.pickup_time,
    ro.duration_numeric AS duration_mins,
    ro.distance_numeric AS distance_km,
    ROUND(EXTRACT(EPOCH FROM (ro.pickup_time::timestamp - co.order_time)) / 60)::INT AS time_to_pickup_mins,
    ROUND(ro.distance_numeric / (ro.duration_numeric / 60.0))::INT AS avg_speed_kmph,
    COUNT(DISTINCT co.pizza_id) AS total_pizzas
FROM customer_orders co
JOIN runner_orders ro
    ON co.order_id = ro.order_id
LEFT JOIN runner_ratings rr
    ON co.order_id = rr.order_id
WHERE ro.cancellation = 'Not Applicable'
GROUP BY 
    co.customer_id, co.order_id, ro.runner_id, rr.rating,
    co.order_time, ro.pickup_time, ro.duration_numeric, ro.distance_numeric
ORDER BY co.customer_id;

-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per
-- kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

WITH pizza_cost AS (
    SELECT 
        co.order_id,
        CASE
            WHEN pn.pizza_name = 'Meatlovers' THEN 12
            WHEN pn.pizza_name = 'Vegetarian' THEN 10
            ELSE 0
        END AS pizza_price
    FROM customer_orders co
    JOIN runner_orders r ON co.order_id = r.order_id
    JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
    WHERE r.cancellation = 'Not Applicable'
),
runner_payment AS (
    SELECT 
        order_id, 
        ROUND(distance_numeric::numeric * 0.30::numeric, 2) AS runner_pay
    FROM runner_orders
    WHERE cancellation = 'Not Applicable'
),
profit_calc AS (
    SELECT 
        pc.order_id,
        SUM(pc.pizza_price) AS total_pizza_sales,
        rp.runner_pay
    FROM pizza_cost pc
    JOIN runner_payment rp ON pc.order_id = rp.order_id
    GROUP BY pc.order_id, rp.runner_pay
)
SELECT 
    ROUND(SUM(total_pizza_sales - runner_pay), 2) AS total_profit
FROM profit_calc;


