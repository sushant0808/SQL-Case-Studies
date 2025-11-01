SET search_path = pizza_runner;

-- Base query
select * from customer_orders;
select * from pizza_names;
select * from pizza_recipes;
select * from pizza_toppings;
select * from runner_orders;
select * from runners;


********** Checking for null or uncleaned data for each table **********

-- Here I am checking null or blank values for each column in the customer_orders table
select count(*) from customer_orders where (exclusions is null) or (exclusions in ('null','')); 
-- Above query gives 9 null/empty values in the column named as exclusions.

select count(*) from customer_orders where (extras is null) or (extras in ('null',''));
-- Above query gives 10 null/empty values in the column named as extras

select count(*) from customer_orders where (order_time is null);
select count(*) from customer_orders where (order_id is null);
select count(*) from customer_orders where (customer_id is null);
select count(*) from customer_orders where (pizza_id is null);
-- Columns order_time, order_id, customer_id, pizza_id in the Above 4 queries don't have anu null values


-- As we see from the above query result only the exclusions and extras column have null or blank values. So we will classify data 
-- based on null, empty values and also check the count.

-- Below query checks for the count of null or blank values for the 'exclusions' column
SELECT 
    CASE 
        WHEN exclusions IS NULL THEN 'NULL'
        WHEN exclusions = '' THEN 'Empty'
		WHEN exclusions = 'null' THEN 'NULL'
        ELSE 'Valid'
    END AS exclusions_value,
    COUNT(*) AS count
FROM customer_orders
GROUP BY exclusions_value;


-- Below query checks for the count of null or blank values for the 'extras' column
SELECT 
    CASE 
        WHEN extras IS NULL THEN 'NULL'
        WHEN extras = '' THEN 'Empty'
		WHEN extras = 'null' THEN 'NULL'
        ELSE 'Valid'
    END AS extras_value,
    COUNT(*) AS count
FROM customer_orders
GROUP BY extras_value;


-- Cleaning the data
UPDATE customer_orders
SET extras = '0'
WHERE (extras IS NULL) OR (extras IN ('null', ''));

UPDATE customer_orders
SET exclusions = '0'
WHERE (extras IS NULL) OR (extras IN ('null', ''));


-- Runner Orders --
-- Columns "order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation", "distance_numeric"
select count(*) from runner_orders where (order_id is null); -- order_id - No null/empty values
select count(*) from runner_orders where (runner_id is null); -- runner_id - No null/empty values
select count(*) from runner_orders where (pickup_time is null) or (pickup_time in ('null','')); -- pickup_time - No null/empty values
select count(*) from runner_orders where (distance is null) or (distance in ('null','')); -- distance - 2 null/empty
select count(*) from runner_orders where (duration is null) or (duration in ('null','')); -- duration - 2 null/empty values
select count(*) from runner_orders where (cancellation is null) or (cancellation in ('null','')); -- cancellation - No null/empty values

-- Cleaning the data
ALTER TABLE runner_orders ADD COLUMN distance_numeric FLOAT;

-- Below I am adding the distance data to the new column by cleaning it like removing the 'km' string etc
UPDATE runner_orders
SET distance_numeric = 
    CASE 
        WHEN distance IS NULL THEN NULL
        WHEN TRIM(distance) in ('null','') THEN NULL
        ELSE CAST(REGEXP_REPLACE(distance, '[^0-9.]', '', 'g') AS FLOAT)
    END;


-- replacing the null values with 0 by using the update command
UPDATE runner_orders
SET distance_numeric = '0'
WHERE (distance_numeric IS NULL);

-- removing the old distance column
ALTER TABLE runner_orders DROP COLUMN distance;


-- adding new duration column
ALTER TABLE runner_orders ADD COLUMN duration_numeric FLOAT;

UPDATE runner_orders
SET duration_numeric = 
    CASE 
        WHEN duration IS NULL THEN NULL
        WHEN TRIM(duration) in ('null','') THEN NULL
        ELSE CAST(REGEXP_REPLACE(duration, '[^0-9.]', '', 'g') AS FLOAT)
    END;

UPDATE runner_orders
SET duration_numeric = '0'
WHERE (duration_numeric IS NULL);


ALTER TABLE runner_orders DROP COLUMN duration;

UPDATE runner_orders
SET cancellation = 'Not Applicable'
WHERE (cancellation IS NULL) OR (cancellation IN ('null', ''));


UPDATE runner_orders
SET pickup_time = '0'
WHERE (pickup_time IS NULL) OR (pickup_time IN ('null', ''));





