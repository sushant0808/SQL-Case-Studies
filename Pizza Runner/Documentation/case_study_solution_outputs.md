### NOTE - 
### For this case study, I have included all the sql queries and their output in this file. Some outputs are in image format and some in a table format. For table format outputs, you will see double quotes i.e " " around the columns and values in the table. 

### This is because I am taking the output of the sql queries from Postgresql and pasting it in an online table formatter to format the output in well structured table format.
<br><br>

### -------------------------------------------------- A. Pizza Metrics --------------------------------------------------
<br>

## Q1. How many pizzas were ordered?

```sql
select count(order_id) as total_pizzas_ordered from customer_orders;
```

Description - Each record in the customer_orders table is a pizza order. So if a customer orders 3 pizza's then the table will have 3 records with the relevant pizza_id in the table for that customer. So to get the total pizzas ordered we are just counting the number of orders.
<br><br>

<img width="236" height="78" alt="image" src="https://github.com/user-attachments/assets/27b998ac-a330-4a11-9827-a18664bf2727" />
<br><br>

## Q2. How many unique customer orders were made?

```sql
select count(distinct order_id) as unqiue_customer_orders from customer_orders;
```
Description - We are using the distinct keyword to get the unique customer orders.
<br><br>

<img width="236" height="78" alt="image" src="https://github.com/user-attachments/assets/27b998ac-a330-4a11-9827-a18664bf2727" />
<br><br>

## 3. How many successful orders were delivered by each runner?
```sql
select runner_id, count(order_id) as successful_orders from runner_orders where cancellation = 'Not Applicable'
group by runner_id order by successful_orders desc;
```

Description - We are using the runner_orders table for the above question. We are grouping by runner_id column to ge the total successful orders for each runner. We are using the 'Not Applicable' status to get successful orders mentioned in the question.
<br><br>

<img width="332" height="156" alt="image" src="https://github.com/user-attachments/assets/4088e2ef-330b-45a1-9e15-0712d1208acd" />
<br><br>

## 4. How many of each type of pizza was delivered?
```sql
SELECT 
    c.pizza_id, p.pizza_name, COUNT(c.pizza_id) AS delivered_pizzas
FROM customer_orders AS c
JOIN runner_orders AS r ON c.order_id = r.order_id
JOIN pizza_names AS p ON c.pizza_id = p.pizza_id
WHERE r.cancellation = 'Not Applicable'
GROUP BY c.pizza_id, p.pizza_name
ORDER BY p.pizza_name;
```

<img width="440" height="117" alt="image" src="https://github.com/user-attachments/assets/682cf6fe-f54c-4685-a474-c1ceae397389" />
<br><br>

## 5. How many Vegetarian and Meatlovers were ordered by each customer?
```sql
select 
c.customer_id, p.pizza_name, count(c.pizza_id) as total_pizza
from customer_orders as c 
inner join pizza_names as p
on c.pizza_id = p.pizza_id
group by c.customer_id, p.pizza_name order by c.customer_id;
```

<img width="423" height="307" alt="image" src="https://github.com/user-attachments/assets/363c8ff2-2016-4a48-a736-036696987dd0" />
<br><br>

## 6. What was the maximum number of pizzas delivered in a single order?
```sql
SELECT 
c.order_id,
count(c.order_id) as total_pizzas
FROM customer_orders AS c
JOIN runner_orders AS r ON c.order_id = r.order_id
WHERE r.cancellation = 'Not Applicable'
group by c.order_id order by total_pizzas desc limit 1;
```

<img width="285" height="91" alt="image" src="https://github.com/user-attachments/assets/9d0c716f-fe06-43af-97c0-35199d563e00" />
<br><br>


## 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
```sql
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
```

<img width="453" height="246" alt="image" src="https://github.com/user-attachments/assets/911d978c-7f61-4b32-9233-0096104b1e59" />
<br><br>


## 8. How many pizzas were delivered that had both exclusions and extras?
```sql
SELECT COUNT(c.pizza_id) AS total_pizzas
FROM customer_orders AS c
JOIN runner_orders AS r ON c.order_id = r.order_id
WHERE r.cancellation = 'Not Applicable'
  AND c.exclusions <> '0' 
  AND c.extras <> '0';
```

<img width="182" height="85" alt="image" src="https://github.com/user-attachments/assets/443e2ccb-578b-453b-9629-fd4a33cbee78" />
<br><br>

## 9. What was the total volume of pizzas ordered for each hour of the day?
```sql
with t1 as (
	select *, extract(hour from order_time) as hours_from_timestamp from customer_orders
)
select hours_from_timestamp as hours, count(pizza_id) as total_pizzas 
from t1 group by hours_from_timestamp order by hours_from_timestamp;
```

Description - The EXTRACT() function in PostgreSQL is used to retrieve specific components (like year, month, day, etc.) from a date or time value.

<img width="287" height="246" alt="image" src="https://github.com/user-attachments/assets/806d0b35-8152-44e2-8142-33f72525fdb1" />
<br><br>


## 10. What was the volume of orders for each day of the week?
```sql
WITH t1 AS (
	SELECT *, TO_CHAR(order_time, 'Day') AS day_of_week
	FROM customer_orders
)
SELECT TRIM(day_of_week) AS day, COUNT(pizza_id) AS total_pizzas
FROM t1
GROUP BY day_of_week
ORDER BY MIN(order_time);
```

<img width="295" height="182" alt="image" src="https://github.com/user-attachments/assets/45997347-6b0b-4907-b954-65d9e4313b43" />
<br><br>

### ------------------------------------------ B. Runner and Customer Experience ------------------------------------------
<br><br>
## 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

```sql
with t1 as (
	SELECT 
	    *,
	    DATE_TRUNC('week', registration_date::date - INTERVAL '4 days') + INTERVAL '4 days' AS calendar_week
	FROM 
	    runners	
)
select calendar_week, count(runner_id) as total_runners from t1 group by calendar_week order by calendar_week;
```

Description - I have not used the EXTRACT(WEEK FROM date) in the sql query as it is giving me the ISO week. So for date 01-01-2021 the extract function is giving me 53rd week as the ISO week starts on Monday. Below is the output for the reference.

<img width="428" height="187" alt="image" src="https://github.com/user-attachments/assets/fe515cc4-864a-497f-803f-75a72911fa33" />


Understanding ISO Week Logic & Custom Week Calculation. By default, PostgreSQL’s EXTRACT(WEEK FROM date) function follows the ISO week numbering system, which has specific international rules:
1. The week starts on Monday.
2. Week 1 of any year is the week that contains the first Thursday of that year.
3. As a result, the first few days of January sometimes belong to the last week (Week 52 or 53) of the previous year.

To fix the ISO issue and consider 01-01-2021 as the start of the week, we are using below code line in ou sql query.
DATE_TRUNC('week', registration_date::date - INTERVAL '4 days') + INTERVAL '4 days' AS week_start

How it works:
1. registration_date::date - INTERVAL '4 days' - shifts the date 4 days backward, so Friday becomes the new “Monday.”
2. DATE_TRUNC('week', …) - rounds that adjusted date down to the start of its ISO week.
3. INTERVAL '4 days' - moves forward again by 4 days so the week starts on Friday instead of Monday.

<br>
Output - 
<br><br>

<img width="427" height="148" alt="image" src="https://github.com/user-attachments/assets/75405a03-c9f4-4ce1-87cf-da78dfb8d1f3" />
<br><br>

## 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
```sql
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
```

Description -
1. The order_prep_times CTE groups each runner by their orders. We do this because each runner has delivered multiple orders, and some of these orders may include multiple pizzas.

2. For example, if a customer orders 3 pizzas in a single order, there will be 3 rows for that order in the customer_orders table. Each of those rows will have the same order_time value, since they all belong to one order.
If we don’t account for this, our calculations will count that order_time multiple times and give an incorrect average.

3. To avoid this, we group by both order_id and runner_id, ensuring that each runner-order pair is counted only once.

4. Within the query, we calculate the prep_time_mins by subtracting the order_time from the pickup_time. This gives an interval data type (e.g., 00:10:14). Since we cannot directly calculate averages on interval data, we use the EXTRACT(EPOCH FROM ...) function to convert the interval into seconds, and then divide it by 60 to convert it into minutes.

5. Finally, in the main query, we calculate the average preparation time per runner, giving us the average number of minutes each runner takes to pick up an order from the restaurant.


<img width="362" height="155" alt="image" src="https://github.com/user-attachments/assets/2a28dcbd-2349-4406-b4d3-5dc3e6ec76fe" />
<br><br>

## 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
```sql
select 
c.order_id, c.pizza_id, c.order_time,
r.runner_id, r.pickup_time
from customer_orders as c
inner join runner_orders as r
on c.order_id = r.order_id order by c.order_id;
```

Output - 
| "order_id" 	| "pizza_id" 	| "order_time"          	| "runner_id" 	| "pickup_time"         	|
|------------	|------------	|-----------------------	|-------------	|-----------------------	|
| 1          	| 1          	| "2020-01-01 18:05:02" 	| 1           	| "2020-01-01 18:15:34" 	|
| 2          	| 1          	| "2020-01-01 19:00:52" 	| 1           	| "2020-01-01 19:10:54" 	|
| 3          	| 2          	| "2020-01-02 23:51:23" 	| 1           	| "2020-01-03 00:12:37" 	|
| 3          	| 1          	| "2020-01-02 23:51:23" 	| 1           	| "2020-01-03 00:12:37" 	|
| 4          	| 1          	| "2020-01-04 13:23:46" 	| 2           	| "2020-01-04 13:53:03" 	|
| 4          	| 1          	| "2020-01-04 13:23:46" 	| 2           	| "2020-01-04 13:53:03" 	|
| 4          	| 2          	| "2020-01-04 13:23:46" 	| 2           	| "2020-01-04 13:53:03" 	|
| 5          	| 1          	| "2020-01-08 21:00:29" 	| 3           	| "2020-01-08 21:10:57" 	|
| 6          	| 2          	| "2020-01-08 21:03:13" 	| 3           	| "00:00:00"            	|
| 7          	| 2          	| "2020-01-08 21:20:29" 	| 2           	| "2020-01-08 21:30:45" 	|
| 8          	| 1          	| "2020-01-09 23:54:33" 	| 2           	| "2020-01-10 00:15:02" 	|
| 9          	| 1          	| "2020-01-10 11:22:59" 	| 2           	| "00:00:00"            	|
| 10         	| 1          	| "2020-01-11 18:34:49" 	| 1           	| "2020-01-11 18:50:20" 	|
| 10         	| 1          	| "2020-01-11 18:34:49" 	| 1           	| "2020-01-11 18:50:20" 	|
| 10         	| 1          	| "2020-01-11 18:34:49" 	| 1           	| "2020-01-11 18:50:20" 	|
<br><br>

## 4. What was the average distance travelled for each customer?
```sql
select 
c.customer_id, round(avg(r.distance_numeric))::TEXT || ' km' as avg_distance
from customer_orders as c
inner join runner_orders as r
on c.order_id = r.order_id
group by c.customer_id order by c.customer_id
```

<img width="316" height="216" alt="image" src="https://github.com/user-attachments/assets/f1e1f2f1-91c0-43a9-96e6-369ddd547e82" />
<br><br>

## 5. What was the difference between the longest and shortest delivery times for all orders?
```sql
with tab1 as(
	SELECT 
	    MAX(pickup_time::time + (duration_numeric || ' minutes')::INTERVAL) AS latest_delivery_time,
	    MIN(pickup_time::time + (duration_numeric || ' minutes')::INTERVAL) AS earliest_delivery_time
	FROM runner_orders where pickup_time <> '00:00:00'
)
select *, latest_delivery_time - earliest_delivery_time as difference_time from tab1;
```

<img width="601" height="92" alt="image" src="https://github.com/user-attachments/assets/68c0fadb-5e50-429c-8a56-04b37a3a67ac" />
<br><br>

## 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
```sql
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
```

<img width="790" height="151" alt="image" src="https://github.com/user-attachments/assets/f280f321-07d9-4f47-88c7-c131a91bb27c" />
<br><br>

## 7. What is the successful delivery percentage for each runner?
```sql
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
```

<img width="760" height="156" alt="image" src="https://github.com/user-attachments/assets/87551307-0efc-486d-96c4-6728c101b584" />
<br><br>
























