-- find highest renvenue generating products --
select product_id, SUM(sale_price)as sales
from df_orders
group by product_id 
order by sales desc

--find selling highest region --
with cte as (	
select region, product_id  , SUM(sale_price) as sales
from df_orders
group by region, product_id)
select * from(
select * 
, row_number() over (partition by region order by sales desc) as rn 
from cte) A
where rn < = 5

--find monoth over month growth comparsion--
with  cte  as(
select year(order_date) as order_year , month( order_date) as order_month, 
sum(sale_price)as sales
from df_orders
group by year (order_date) , month(order_date)
--order by year (order_date) , month(order_date)
	)
select order_month
,  sum(case when order_year = 2022 then sales else 0 end )sales_2022
,  sum(case when order_year = 2023 then sales else 0 end) sales_2023
from cte
group by order_month
order by order_month


--highest sales for each category--
with cte as (
select category, format (order_date, 'yyyyMM') as order_year_month
, sum (sale_price) as sales
from df_orders
group by category ,format(order_date , 'yyyyMM')
--group by category ,format(order_date , 'yyyyMM')
)
select  *  from (
select  * ,
row_number() over( partition by category order by sales desc) as rn
from cte
) a
where rn = 1

--which sub_category having a highest growth rate in 2023 to 2022--
with  cte  as(
select sub_category , year(order_date) as order_year,
sum(sale_price)as sales
from df_orders
group by sub_category,year (order_date)
--order by year (order_date) , month(order_date)
	)
, cte2 as (
select sub_category
,  sum(case when order_year = 2022 then sales else 0 end )sales_2022
,  sum(case when order_year = 2023 then sales else 0 end) sales_2023
from cte
group by sub_category
)
select  top 1*
, (sales_2023-sales_2022)*100/ sales_2022
from cte2
order by (sales_2023-sales_2022)*100/ sales_2022 desc