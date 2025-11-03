
## Q1. How many pizzas were ordered?

```sql
select count(order_id) as total_pizzas_ordered from customer_orders;
```
Description - Each record in the customer_orders table is a pizza order. So if a customer orders 3 pizza's then the table will have 3 records with the relevant pizza_id in the table. So to get the total pizzas ordered we are just counting the number of orders.
<br><br>

<img width="236" height="78" alt="image" src="https://github.com/user-attachments/assets/27b998ac-a330-4a11-9827-a18664bf2727" />



<br><br>

## Q2. How many unique customer orders were made?

```sql
select count(distinct order_id) as unqiue_customer_orders from customer_orders;
```

<img width="236" height="78" alt="image" src="https://github.com/user-attachments/assets/27b998ac-a330-4a11-9827-a18664bf2727" />


