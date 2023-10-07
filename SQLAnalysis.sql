use Brazilian_Ecommerce
--Customer count per Zipcode
select count(distinct customer_id) as no_customers_per_zipcode,customer_zip_code_prefix
from olist_customers_dataset
group by customer_zip_code_prefix
order by count(distinct customer_id) desc


--1. Total Revenue by Product Category:
--Calculate the total revenue for each product category.

select pd.product_category_name,product_category_name_english,sum(price*order_item_id) as total_revenue from
olist_products_dataset pd
join olist_order_items_dataset oi
on oi.product_id=pd.product_id
join product_category_name_translation pt
on pt.Product_category_name=pd.product_category_name
group by pd.product_category_name,product_category_name_english
order by sum(price) desc

--2. Average Review Score by Seller State:
--Calculate the average review score for sellers in each state.
select os.seller_id,avg(review_score) as avg_review_score,seller_state
from olist_order_reviews_dataset ord
left join olist_order_items_dataset oi
on ord.order_id=oi.order_id
left join olist_sellers_dataset os
on os.seller_id=oi.seller_id
group by seller_state,os.seller_id
order by avg(review_score) desc

--3.Identify High-Value Customers:
select oc.customer_id,sum(price*order_item_id) as high_revenue
from olist_customers_dataset oc
left join olist_orders_dataset oo
on oc.customer_id=oo.customer_id
left join olist_order_items_dataset oi
on oi.order_id=oo.order_id
group by oc.customer_id
order by sum(price*order_item_id) 

--4.Count of Null revenue customers
with customer_revenue as
(
select oc.customer_id,sum(price*order_item_id) as high_revenue
from olist_customers_dataset oc
left join olist_orders_dataset oo
on oc.customer_id=oo.customer_id
left join olist_order_items_dataset oi
on oi.order_id=oo.order_id
group by oc.customer_id
) 
select count(customer_id) as null_revenue_customers
from customer_revenue
where high_revenue is NULL

--5.Calculate Monthly Orders Count:

select month(order_purchase_timestamp) as order_month,count(order_id) as order_count 
from olist_orders_dataset
group by month(order_purchase_timestamp)
order by count(order_id) desc

--6.Calculate monthly sale trends
create view monthly_sales as
select month(order_purchase_timestamp) as month,sum(price*order_item_id) as sales
from olist_order_items_dataset oi
join olist_orders_dataset od
on oi.order_id=od.order_id
group by month(order_purchase_timestamp)

alter view monthly_sales as
select month(order_purchase_timestamp) as month,round(sum(price*order_item_id),2) as sales
from olist_order_items_dataset oi
join olist_orders_dataset od
on oi.order_id=od.order_id
group by month(order_purchase_timestamp)

select * from monthly_sales
order by sales desc

--7.Find the Most Reviewed Products:

select pd.product_id,pt.Product_category_name_english,count(review_id) as review_count
from olist_order_reviews_dataset ord
join olist_order_items_dataset oi
on oi.order_id=ord.order_id
join olist_products_dataset pd
on pd.product_id=oi.product_id
join product_category_name_translation pt
on pt.Product_category_name=pd.product_category_name
group by pd.product_id,pt.Product_category_name_english
order by count(review_id) desc

--8.Identify Late Deliveries:
select order_id,order_status,order_delivered_customer_date
from olist_orders_dataset
where order_delivered_customer_date > order_estimated_delivery_date

--No.of.days difference between delivery and estimated delivery date

with delivery_details as(
select order_id,day(order_delivered_customer_date) as delivery_date,day(order_estimated_delivery_date) as estimated_date
from olist_orders_dataset
)
select order_id, (delivery_date-estimated_date) as days_difference
from delivery_details
order by (delivery_date-estimated_date) desc

--9.Cummulative revenue over time
with monthly_sales as
(
select month(order_purchase_timestamp) as month,round(sum(price*order_item_id),2) as sales
from olist_order_items_dataset oi
join olist_orders_dataset od
on oi.order_id=od.order_id
group by month(order_purchase_timestamp)
)
select month,sales,sum(sales) over(order by month)as cummulative_sales from monthly_sales

--10 Identify Top Sellers by Revenue

with seller_revenue as
(
select sd.seller_id,sum(price*order_item_id) as revenue 
from olist_sellers_dataset sd
join olist_order_items_dataset oi
on oi.seller_id = sd.seller_id
group by sd.seller_id
)
select sr.seller_id,seller_city,revenue,
rank() over(order by revenue desc) as seller_rank
from seller_revenue sr
join olist_sellers_dataset sd
on sd.seller_id = sr.seller_id

--Calculate Average Delivery Time by Seller (Using Window Function):
/*with delivery_time as
(
select sd.seller_id,avg(cast(datediff(hour,COALESCE(order_purchase_timestamp,order_estimated_delivery_date) ,COALESCE(order_delivered_customer_date,getdate())) as bigint)) as avg_delivery_time_hours
from olist_orders_dataset od
join olist_order_items_dataset oi
on od.order_id = oi.order_id
join olist_sellers_dataset sd
on sd.seller_id = oi.seller_id
-- where order_status = 'delivered' and order_delivered_customer_date <> null and order_purchase_timestamp <> null
group by sd.seller_id
)
select seller_id,rank() over(order by avg_delivery_time)
from delivery_time */

--11.Calculate Average Delivery Time by Seller (Using Window Function):
with delivery_time_hours as
(
select sd.seller_id,avg(datediff(hour,order_purchase_timestamp,order_delivered_customer_date)) as avg_delivery_time_hours
from olist_orders_dataset od
join olist_order_items_dataset oi
on od.order_id = oi.order_id
join olist_sellers_dataset sd
on sd.seller_id = oi.seller_id
where order_status = 'delivered' and order_delivered_customer_date is not null
group by sd.seller_id
)
select seller_id,avg_delivery_time_hours,rank() over(order by avg_delivery_time_hours) as delivery_rank
from delivery_time_hours



