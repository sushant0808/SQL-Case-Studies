

```sql
select count(*) from customer_orders where (exclusions is null) or (exclusions in ('null',''));
```

Output -

<img width="160" height="82" alt="image" src="https://github.com/user-attachments/assets/c57399d7-6efb-4d1a-9890-675bc7b6f3d4" />
<br><br>

```sql
select count(*) from customer_orders where (extras is null) or (extras in ('null',''));
```

Output - 

<img width="157" height="86" alt="image" src="https://github.com/user-attachments/assets/ebf64135-e44e-41d1-899a-1de489c5da73" />
<br><br>

```sql
select count(*) from customer_orders where (order_time is null);
```

Output - 

<img width="165" height="97" alt="image" src="https://github.com/user-attachments/assets/0355a5b7-7c07-4f88-8c92-b79b52cbbd5a" />
<br><br>

```sql
select count(*) from customer_orders where (order_id is null);
```

Output - 

<img width="162" height="90" alt="image" src="https://github.com/user-attachments/assets/64b032ad-5612-4b26-b765-36663ea5257c" />
<br><br>

```sql
select count(*) from customer_orders where (customer_id is null);
```

Output - 

<img width="158" height="82" alt="image" src="https://github.com/user-attachments/assets/2b14261c-8266-4fba-bd3e-b9608b6b4270" />
<br><br>

```sql
select count(*) from customer_orders where (pizza_id is null);
```

Output -

<img width="155" height="87" alt="image" src="https://github.com/user-attachments/assets/a74fb713-af51-4320-afe0-d3d3d868d918" />
<br><br>

```sql
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
```

Output -

<img width="322" height="152" alt="image" src="https://github.com/user-attachments/assets/1f7ec9ee-fcd9-469b-9b69-9d3f83f1fd89" />
<br><br>


```sql
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
```

Output -

<img width="287" height="150" alt="image" src="https://github.com/user-attachments/assets/c69e1b23-69b2-4aff-812b-5d37de91316d" />
<br><br>

```sql
select count(*) from runner_orders where (order_id is null);
```

Output - 

<img width="165" height="87" alt="image" src="https://github.com/user-attachments/assets/ea9e155e-eca9-4bc5-bda7-9601bbd00136" />
<br><br>

```sql
select count(*) from runner_orders where (runner_id is null);
```

Output - 

<img width="163" height="90" alt="image" src="https://github.com/user-attachments/assets/9015df2c-f97d-4c5e-bb8c-863d0415062a" />
<br><br>

```sql
select count(*) from runner_orders where (pickup_time is null) or (pickup_time in ('null',''));
```

Output - 

<img width="161" height="90" alt="image" src="https://github.com/user-attachments/assets/b48cebbc-885f-4dfb-80a7-a4a31a1d8f9a" />
<br><br>

```sql
select count(*) from runner_orders where (distance is null) or (distance in ('null',''));
```

Output - 

<img width="167" height="92" alt="image" src="https://github.com/user-attachments/assets/11b8b722-6359-4030-804e-7db0a1af6a32" />
<br><br>

```sql
select count(*) from runner_orders where (duration is null) or (duration in ('null',''));
```

Output - 

<img width="158" height="91" alt="image" src="https://github.com/user-attachments/assets/f440dec4-2600-4bfb-9297-693afce0248f" />
<br><br>

```sql
select count(*) from runner_orders where (cancellation is null) or (cancellation in ('null',''));
```

Output - 

<img width="171" height="91" alt="image" src="https://github.com/user-attachments/assets/0604ed60-c46f-44df-94e7-7b73876de0b4" />
<br><br>





















