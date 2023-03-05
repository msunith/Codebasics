use gdb023

1. Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.

select distinct market from dim_customer where customer = "Atliq Exclusive" and region = "APAC" order by market;

2. What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg

with 
cte0 as (select count(distinct product_code) as unique_products_2020 from fact_sales_monthly where fiscal_year = 2020 ),
cte1 as (select count(distinct product_code) as unique_products_2021 from fact_sales_monthly where fiscal_year = 2021 )
select unique_products_2020, unique_products_2021 , round((unique_products_2021 - unique_products_2020)/unique_products_2020*100,2) as percentage_chg from cte0 cross join cte1

3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count



select distinct segment,count(product_code) as product_count from dim_product group by segment order by product_count desc;

select segment,count(distinct product) as product_count from dim_product group by segment order by product_count desc;

4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference

with cte as 
	(select p.segment,count(distinct p.product_code) as product_count,s.fiscal_year from dim_product p
	join fact_sales_monthly s where p.product_code=s.product_code group by segment,fiscal_year),
	cte2020 as 
	(select cte.segment,cte.product_count from cte  where cte.fiscal_year = 2020),
	cte2021 as
	(select cte.segment,cte.product_count from cte where cte.fiscal_year = 2021)
select cte2020.segment,cte2020.product_count as product_count_2020,
cte2021.product_count as product_count_2021, (cte2021.product_count-cte2020.product_count) as difference
from cte2020 join cte2021 on cte2020.segment = cte2021.segment order by difference desc;


5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost

with cte as (select product_code,manufacturing_cost from fact_manufacturing_cost where manufacturing_cost in (
	(select max(manufacturing_cost) from fact_manufacturing_cost),
	(select min(manufacturing_cost) from fact_manufacturing_cost)))
select cte.product_code,p.product,cte.manufacturing_cost from cte join dim_product as p using (product_code);

6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage

with 
	cte1 as (select avg(pre_invoice_discount_pct) as average_percentage from fact_pre_invoice_deductions group by fiscal_year having fiscal_year = 2021),
	cte2 as (select customer_code,pre_invoice_discount_pct as average_discount_percentage from fact_pre_invoice_deductions where customer_code in
	(select customer_code from dim_customer where market = "India") and fiscal_year = 2021)
select cus.customer_code,cus.customer, cte2.average_discount_percentage from dim_customer as cus
join cte2 on cte2.customer_code = cus.customer_code 
cross join cte1 where cte2.average_discount_percentage > cte1.average_percentage order by cte2.average_discount_percentage desc limit 5 ;


7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount

with 
cte as
	(select s.date,s.product_code,s.customer_code,s.fiscal_year, (g.gross_price*s.sold_quantity) as Gross_sales_amount from fact_sales_monthly s 
	join fact_gross_price g on s.product_code = g.product_code and s.fiscal_year=g.fiscal_year
    having s.customer_code in (select customer_code from dim_customer where customer = "Atliq Exclusive"))
select month(cte.date) as Month, cte.fiscal_year as Year, round(sum(cte.Gross_sales_amount)/1000000.0,2) as gross_sales_amount_million from cte group by Month,Year order by year,gross_sales_amount_million desc

8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity

with cte as
(select month(date) as month_col,sold_quantity,fiscal_year,
case 
	when month(date) in (9,10,11) then  1
	when month(date) in (12,1,2) then 2
	when month(date) in (3,4,5) then 3
	when month(date) in (6,7,8) then 4    
End as Quarter
 from fact_sales_monthly where fiscal_year = 2020)
 select Quarter, sum(sold_quantity) as Total_sold_quantity from cte group by Quarter order by Total_sold_quantity desc;

9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage

with 
	cte as
	(select sm.product_code,sm.customer_code,sm.sold_quantity,sm.fiscal_year, (gp.gross_price * sm.sold_quantity) as gross_sales 
	from fact_sales_monthly sm join
	fact_gross_price gp on sm.product_code = gp.product_code where (sm.fiscal_year = 2021 and gp.fiscal_year=2021)),
cte1 as (select channel,sum(gross_sales) as gross_sales_channel,(select sum(gross_sales)from cte)  as total_gross_sale from dim_customer dc
	join cte on dc.customer_code = cte.customer_code group by channel )
select channel, round(gross_sales_channel/1000000,2) as gross_sales_mln,round((gross_sales_channel/total_gross_sale*100),2) as percentage from cte1 order by gross_sales_mln desc;

10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these fields,
division
product_code
product
total_sold_quantity
rank_order

with cte as 
	(select product_code, sum(sold_quantity) as sold_quantity,fiscal_year from fact_sales_monthly group by product_code having fiscal_year = 2021),
    cte1 as
	(select p.division,p.product_code, concat(p.product," ",p.variant) as product ,c.sold_quantity as total_sold_quantity,
	rank() over (partition by division  order by c.sold_quantity desc) rank_order from dim_product p
	join cte c on p.product_code = c.product_code) 
select * from cte1 where cte1.rank_order <=3;