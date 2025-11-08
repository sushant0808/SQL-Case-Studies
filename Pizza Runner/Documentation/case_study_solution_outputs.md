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


### ------------------------------------------ C.  Ingredient Optimisation ------------------------------------------
<br><br>

## 1. What are the standard ingredients for each pizza?
```sql
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
```

Description - 
1. This query focuses on listing the standard ingredients for each pizza type as defined in the pizza_recipes table.
2. It does not involve the customer_orders table, since that table reflects what customers actually ordered (which may include exclusions or extras).
3. The goal here is to understand the default pizza compositions on the menu, not customer-specific modifications.
4. STRING_TO_ARRAY() converts a comma-separated text value like '1,2,3,4,5' into an array like {1,2,3,4,5}
5. UNNEST() expands that array like {1,2,3,4,5} into multiple rows. So for this array {1,2,3,4,5} UNNEST() will create 5 records as we have 5 elements within array {1,2,3,4,5}.
6. Together, they allow us to normalize denormalized data — breaking a single text field with multiple values into separate rows for easy joining and analysis.

<img width="808" height="122" alt="image" src="https://github.com/user-attachments/assets/7623434e-f099-4112-9b14-93b6be180316" />
<br><br>


## 2. What was the most commonly added extra?
```sql
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
```

Description - 
1. This query identifies the most commonly added extra topping across all customer orders.
2. The extras column contains topping IDs stored as comma-separated strings, which are first split into individual rows using STRING_TO_ARRAY() and UNNEST().
3. After converting them to integers, the query joins with the pizza_toppings table to retrieve topping names.
4. Finally, it counts how many times each topping was added and returns the one with the highest count.

Result - The most commonly added extra topping is Bacon, which was added 5 times.

<img width="381" height="90" alt="image" src="https://github.com/user-attachments/assets/728ecafb-6a3f-473d-9cc9-86794204eac7" />

<br><br>

## 3. What was the most common exclusion?
```sql
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
```

Description - 
1. This query identifies the most commonly excluded topping across all customer orders.
2. The exclusion column contains topping IDs stored as comma-separated strings, which are first split into individual rows using STRING_TO_ARRAY() and UNNEST().
3. After converting them to integers, the query joins with the pizza_toppings table to retrieve topping names.
4. Finally, it counts how many times each topping was excluded and returns the one with the highest count.

Result - The most commonly excluded topping is Cheeze, which was added 4 times.

<img width="380" height="87" alt="image" src="https://github.com/user-attachments/assets/4d4abca3-b363-4509-bb61-d672f2b5b3eb" />
<br><br>

## 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
o Meat Lovers
<br>
o Meat Lovers - Exclude Beef
<br>
o Meat Lovers - Extra Bacon
<br>
o Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
<br>

```sql
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
```

Description - This query generates a readable “order item” for each pizza ordered by customers, including any toppings that were excluded or added as extras.

The process involves:
1. Expanding the comma-separated exclusions and extras topping IDs into multiple rows using STRING_TO_ARRAY() and UNNEST().
2. Mapping those topping IDs to human-readable topping names via joins with the pizza_toppings and pizza_names tables.
3. Recombining them into comma-separated lists using STRING_AGG().
4. Merging exclusions and extras for each pizza using a conditional CASE statement to produce outputs like:
   a. Meatlovers - Exclude Cheese
   b. Meatlovers - Extra Bacon
   c. Meatlovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
5. This allows a direct, readable summary of every customized pizza ordered by customers.


Output - 
<img width="1137" height="562" alt="image" src="https://github.com/user-attachments/assets/2c5b85c4-721f-455e-b28e-83830eafad83" />
<br><br>


## 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients. For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"


```sql
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
```

Description - 
Logic:
1. Each pizza’s extras are extracted and joined with the pizza’s default recipe to check for overlap.
2. If a topping exists both in the base recipe and extras, it’s labeled as 2x<topping>.
3. If a topping only exists in extras (new addition), it’s listed as <topping>.
4. Only customized extras are displayed (not base toppings).
5. Final toppings are alphabetically ordered and formatted per pizza.

Example Output:
1. Meatlovers: 2xBacon
2. Vegetarian: Bacon
3. Meatlovers: 2xBacon, 2xCheese


NOTE - The null values in the below image output are because there were no extras for those particular orders.
<img width="410" height="527" alt="image" src="https://github.com/user-attachments/assets/e732b115-50f3-4b23-9131-a2cea8180467" />
<br><br>










