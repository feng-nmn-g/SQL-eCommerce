-- select schemas for this project
ALTER USER postgres SET search_path TO "e-commerce";

-- Query 1: From the customer dataset table, find out the how many customers in each city and state, order by customer number in descending order 
select
    customer_city,
    customer_state,
    count(*) as customer_number
from customers_dataset
group by customer_city, customer_state
order by customer_number DESC


-- Query 2 (a): Sort daily order number (convert timestamp to date) using "orders_dataset" table. Find the dates with the most orders purchased. (It's a black friday week)
select
    cast(order_purchase_timestamp as date) as purchase_date,
    count(*) as order_number
from orders_dataset
group by purchase_date
order by order_number desc

-- Query 2 (b): Sort order number for each day of the week. (While Monday has the most order number. Weekend has the least. The orders are roughly evenly distributed over the weekdays.)
select
    TO_CHAR(order_purchase_timestamp, 'Day') as day_of_the_week,
    count(*) as order_number
from orders_dataset
group by day_of_the_week
order by order_number desc


-- Query 3: Find the category has the most item ordered. Add english translation using the translation table.
select
    prod.product_category_name as category_portuguese,
    trans.product_category_name_english as category_english,
    count(*) as order_number
from products_dataset prod
inner join order_items_dataset ord on prod.product_id = ord.product_id
inner join product_category_name_translation trans on prod.product_category_name = trans.product_category_name
group by prod.product_category_name, trans.product_category_name_english
order by order_number desc


-- Query 4: For all delivered orders, calculate the difference between estimated delivery & actual delivery in days.
-- (a) List all the orders above that are more than 3 months late (180 days)
select
    order_id,
    order_status,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    order_estimated_delivery_date::date - order_delivered_customer_date::date as day_diff
from orders_dataset
where order_status = 'delivered' and 
    (order_delivered_customer_date is not null or order_estimated_delivery_date is not null) and
    (order_estimated_delivery_date::date - order_delivered_customer_date::date) <= -180
order by day_diff asc

-- (b) Get the average day difference (estimated delivery date - actual delivery date) by purchase month and year
select
    purchase_year,
    purchase_month,
    avg(day_diff) as avg_day_diff
from(
    select
        order_id,
        order_status,
        order_purchase_timestamp,
        date_part('year', order_purchase_timestamp) as purchase_year,
        date_part('month', order_purchase_timestamp) as purchase_month,
        order_delivered_customer_date,
        order_estimated_delivery_date,
        order_estimated_delivery_date::date - order_delivered_customer_date::date as day_diff
    from orders_dataset
    where order_status = 'delivered' and 
        (order_delivered_customer_date is not null or order_estimated_delivery_date is not null)
) 
group by purchase_year, purchase_month
order by purchase_year, purchase_month