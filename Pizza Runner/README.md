
### Pizza Runner Case study & Problem statement
Did you know that over 115 million kilograms of pizza is consumed daily worldwide??? (Well according to Wikipedia anyway…)
Danny was scrolling through his Instagram feed when something really caught his eye - “80s Retro Styling and Pizza Is The Future!”

Danny was sold on the idea, but he knew that pizza alone was not going to help him get seed funding to expand his new Pizza Empire - so he had one more genius idea to combine with it - he was going to Uberize it - and so Pizza Runner was launched!

Danny started by recruiting “runners” to deliver fresh pizza from Pizza Runner Headquarters (otherwise known as Danny’s house) and also maxed out his credit card to pay freelance developers to build a mobile app to accept orders from customers.

Danny has prepared for us an entity relationship diagram of his database design but requires further assistance to clean his data and apply some basic calculations so he can better direct his runners and optimise Pizza Runner’s operations.

We have the following datasets - 
runner_orders, customer_orders, pizza_names, runners, pizza_recipes, pizza_toppings



### Project Overview

1. This project is based on the Pizza Runner SQL Case Study by Danny Ma (8 Week SQL Challenge). 
2. View full case study problem at - https://8weeksqlchallenge.com/case-study-2/
3. The goal was to clean and analyze a raw pizza delivery dataset to answer key business questions around customer orders, delivery performance, and runner efficiency.

### Business Objectives

The fictional company Pizza Runner wants to analyze:
1. Customer ordering trends
2. Runner delivery performance
3. Ingredients usage
4. Revenue and order completion rates

### The database contains multiple tables such as:
1. customer_orders
2. runner_orders
3. runners
4. pizza_names
5. pizza_recipes
6. pizza_toppings

### Data Exploration
1. The customer_orders table had NULL, 'null' word in string type, blank space and NaN values in the **extras and exclusion** columns.
2. The runner_orders table also has null and blank values in the **pickup_time, distance, duration & cancellation** columns. 
3. No blank or null values are present in the **runners, pizza_names, pizza_recipes, pizza_toppings**.

### Data Cleaning - Performed data cleaning using SQL
1. Checked the count of nulls and blanks in all the columns for each table.
2. Based on the previous points output, I focused on the tables having null values in them. So I checked the count of types of null values like for example:- 'null' in string format, NULL or Blank space so that I can replace the null values accordingly.
3. Used **Alter and Update statements** in SQL to change & replace the nulls with proper values.

See the file here - Data/Cleaned Data/customer_orders.xlsx

*See the file* → [scripts/data_cleaning.sql](scripts/data_cleaning.sql)



















