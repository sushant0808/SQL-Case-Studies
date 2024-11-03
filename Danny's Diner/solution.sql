
CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;


CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');


CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');


CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);


INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

  
  
-- Start

select * from sales;
select * from members;
select * from menu;

-- Questions solution
-- 1. What is the total amount each customer spent at the restaurant?

select 
s.customer_id, sum(m.price) as total_amount
from
sales as s left join menu as m
on s.product_id = m.product_id
group by s.customer_id;

-- 2. How many days has each customer visited the restaurant?

select
customer_id,
count(distinct(order_date)) as total_visiting_days
from sales
group by customer_id


-- 3. What was the first item from the menu purchased by each customer?

select customer_id, product_name, purchase_rank from (
	select s.customer_id, m.product_name, m.price,
	row_number() OVER (
		PARTITION BY customer_id
		ORDER BY order_date
	) as purchase_rank
	from sales as s left join
	menu as m on s.product_id = m.product_id
) where purchase_rank = 1


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select 
m.product_name,
count(s.product_id) as total_count
from sales as s
left join menu as m
on s.product_id = m.product_id
group by m.product_name order by total_count desc limit 1;


-- 5. Which item was the most popular for each customer?

select 
customer_id, product_name, total_count
from (
	select 
	s.customer_id,
	s.product_id,
	m.product_name,
	count(s.product_id) as total_count,
	rank() OVER (
		PARTITION BY customer_id
		ORDER BY count(s.product_id) desc
	) as most_popular_products_rank
	from sales as s
	left join menu as m
	on s.product_id = m.product_id
	group by s.customer_id, s.product_id,m.product_name
	order by s.customer_id
) where most_popular_products_rank = 1


-- 6. Which item was purchased first by the customer after they became a member?

select customer_id, product_name 
from (
	select s.customer_id, me.product_name,
	rank() OVER (
		PARTITION BY s.customer_id
		ORDER BY s.order_date
	) as first_purchase_rank
	from sales as s
	left join members as m
	on s.customer_id = m.customer_id
	left join menu as me
	on s.product_id = me.product_id
	where s.order_date > m.join_date
	order by s.customer_id
) where first_purchase_rank = 1


-- 7. Which item was purchased just before the customer became a member?
select customer_id, product_name 
from (
	select s.customer_id, me.product_name,
	rank() OVER (
		PARTITION BY s.customer_id
		ORDER BY s.order_date desc
	) as first_purchase_rank
	from sales as s
	left join members as m
	on s.customer_id = m.customer_id
	left join menu as me
	on s.product_id = me.product_id
	where s.order_date < m.join_date
	order by s.customer_id
) where first_purchase_rank = 1


-- 8. What is the total items and amount spent for each member before they became a member?

select 
s.customer_id, count(s.product_id) as total_items, sum(me.price) as total_amount_spent
from sales as s
inner join
members as m
on s.customer_id = m.customer_id
inner join menu as me
on s.product_id = me.product_id
where s.order_date < m.join_date
group by s.customer_id
order by s.customer_id


-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?


select  
customer_id, sum(points) as total_points
from (
	select 
	s.customer_id, m.product_name,
	case 
		when m.product_name = lower('sushi') then (m.price * (10 * 2))
		else (m.price * 10)
	end as points
	from sales as s
	left join
	menu as m
	on s.product_id = m.product_id order by s.customer_id
) group by customer_id


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- not just sushi - how many points do customer A and B have at the end of January?

select  
customer_id, sum(points) as total_points
from (
	select 
	s.customer_id, m.product_name,
	case 
		when mem.join_date between '2021-01-01' and '2021-01-07' then (m.price * (10 * 2))
		else (m.price * 10)
	end as points
	from sales as s
	inner join
	menu as m
	on s.product_id = m.product_id
	inner join 
	members as mem
	on s.customer_id = mem.customer_id
) group by customer_id


-- Join All The Things

select 
s.customer_id, s.order_date, m.product_name, m.price,
case 
	when s.order_date >= mem.join_date then 'Y'
	else 'N'
end as member
from 
sales as s
left join
menu as m
on s.product_id = m.product_id
left join
members as mem
on s.customer_id = mem.customer_id
order by s.customer_id, s.order_date


-- Rank All The Things
WITH cte_bonus AS(
 SELECT s.customer_id, s.order_date, m.product_name, m.price, 
  CASE WHEN s.order_date >= mem.join_date THEN 'Y'
       WHEN s.order_date < mem.join_date THEN 'N'  
       ELSE 'N' 
       END AS member 
FROM sales s 
LEFT JOIN menu m ON s.product_id = m.product_id 
LEFT JOIN members mem 
ON s.customer_id = mem.customer_id) 

select *, 
CASE WHEN member = 'Y' THEN DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date)
ELSE NULL
END AS ranking 
from cte_bonus 


	






























