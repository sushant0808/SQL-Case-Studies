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

## 3. How many successful orders were delivered by each runner?
```sql
select runner_id, count(order_id) as successful_orders from runner_orders where cancellation = 'Not Applicable'
group by runner_id order by successful_orders desc;
```

Description - We are using the runner_orders table for the above question. We are grouping by runner_id column to ge the total successful orders for each runner. We are using the 'Not Applicable' status to get successful orders mentioned in the question.
<br><br>

<img width="332" height="156" alt="image" src="https://github.com/user-attachments/assets/4088e2ef-330b-45a1-9e15-0712d1208acd" />


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
<br>































