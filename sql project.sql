use gdb0041;
#exploring tables

select * from dim_customer; 
select distinct market from dim_customer; # returned 27
select distinct channel from dim_customer; # returned 3

select * from dim_market;
select distinct market from dim_market; # returned 27
select distinct region from dim_market; # returned 4

select * from dim_product;

select * from fact_sales_monthly;
select * from fact_forecast_monthly;
select * from fact_gross_price;
select * from fact_pre_invoice_deductions;
select * from fact_post_invoice_deductions;
select * from fact_manufacturing_cost;
select * from fact_freight_cost;


#task1 Gross sales report
#Croma India product wise sales report for fiscal year 2021;
#generate report of individual product sales (aggregated on monthly basis at product code level for croma india customer for FY=2021
#to track individual product sales and run further analysis in excel
#The report should have following fields
-- month 
-- product name
-- variant
-- sold quantity
-- gross price per item
-- gross price total

select * from dim_customer where customer like '%Croma%' and market ="India"; -- customer code 90002002
select * from fact_sales_monthly where customer_code = 90002002 and year(DATE_ADD(date, INTERVAL 4 MONTH)) = 2021; # data is already monthwise aggregated 
 
# created a function to get fiscal year
select * from fact_sales_monthly where customer_code = 90002002 and get_fiscal_year(date) = 2021; # data is already monthwise aggregated 

select date, product, variant, sold_quantity, gross_price from fact_sales_monthly join dim_product using(product_code) join fact_gross_price using(product_code) where customer_code = 90002002 and get_fiscal_year(date) = 2021; 
#created function get_fiscal_quarter()
select date, product, variant, sold_quantity, gross_price from fact_sales_monthly join dim_product using(product_code) join fact_gross_price using(product_code) where customer_code = 90002002 and get_fiscal_year(date) = 2021 and get_fiscal_quarter(date)='Q1'; 

#final report
select date, product, variant, sold_quantity, gross_price, round((gross_price*sold_quantity),2) as gross_price_total from fact_sales_monthly s join dim_product p using(product_code) join fact_gross_price f on  s.product_code = f.product_code and f.fiscal_year = get_fiscal_year(date) where customer_code = 90002002 and get_fiscal_year(date) = 2021 order by date asc limit 100000; 

#Exercise: yearly sales report
#Generate a yearly report for croma india where there are two columns 
-- Fiscal year 
-- total gross sales amount in that year from croma

Select get_fiscal_year(date) as year, sum(gross_price*sold_quantity) as total_gross_price  from fact_sales_monthly join fact_gross_price using(product_code)  where customer_code = 90002002 group by  year;
Call gdb0041.gross_sales_monthly_for_customer(90002002);

# if one customer has two customer codes
#in_customer_code TEXT
#where find_in_set(s.cutomer_code,  in_customer_code) >0 

#Stored procedure for market  badge
-- Create a stored procedure that can determine the market badge based on the following logic 
-- If total sales quantity > 5 million that market is considered as gold else it is silver
-- Input market and fiscal year
-- Output badge
-- to know where your prominent sales are happening 

Call gdb0041.get_market_badge('india', 2021, @out_badge);
select @out_badge;

Call gdb0041.get_market_badge('USA', 2020, @out_badge);
select @out_badge;

Call gdb0041.get_market_badge('indonesia', 2020, @out_badge);
select @out_badge;

#generate report for top market, top customers, top products based on net sales 
#gross sales – preinvoice decduction (net preinvoice sales)
-- postinvoice deduction (net sales)
-- cogs (= manufacturing cost+ freight cost + other cost    gross margin)
-- marketing cost (advertisement  net margin) 
#get preinvoice deduction 

Select 
date, 
s.product_code, 
product, 
variant, 
sold_quantity, 
gross_price, 
gross_price*sold_quantity as total_gross_price, 
pre_invoice_discount_pct 
from fact_sales_monthly s join  dim_product p on s.product_code = p.product_code join fact_gross_price g  on s.product_code = g.product_code and get_fiscal_year(date) = g.fiscal_year join fact_pre_invoice_deductions pre on pre.customer_code = s.customer_code
where s.customer_code = 90002002 and get_fiscal_year(date) = 2021
limit 100000;

# took 6 seconds to show results so optimize this query
explain analyze 
Select 
date, 
s.product_code, 
product, 
variant, 
sold_quantity, 
gross_price, 
gross_price*sold_quantity as total_gross_price, 
pre_invoice_discount_pct 
from fact_sales_monthly s join  dim_product p on s.product_code = p.product_code join fact_gross_price g  on s.product_code = g.product_code and get_fiscal_year(date) = g.fiscal_year join fact_pre_invoice_deductions pre on pre.customer_code = s.customer_code
where s.customer_code = 90002002 and get_fiscal_year(date) = 2021
limit 100000;

#filter operation is taking more time it involves taking date adding 4 months to get fiscal_year then take out the year for 1.4 million records
# and date is repetative so we are calling function unnessesarily for repeated dates

#what if we created a date table and perform join then their will not be any repetion of date and not applying get_fiscal_year for every records
#created dim_tabel 
select min(date), max(date) from fact_sales_monthly; # min 2017-09-01 max 2021-12-01
select * from dim_date;

#Explain analyze #0.078
Select 
s.date, 
s.product_code, 
product, 
variant, 
sold_quantity, 
gross_price, 
gross_price*sold_quantity as total_gross_price, 
pre_invoice_discount_pct 
from fact_sales_monthly s join  dim_product p on s.product_code = p.product_code join dim_date d on s.date = d.date join fact_gross_price g  on s.product_code = g.product_code and d.fiscal_year = g.fiscal_year join fact_pre_invoice_deductions pre on pre.customer_code = s.customer_code
where s.customer_code = 90002002 and d.fiscal_year = 2021
limit 100000; #this took only 0.078 sec 

#add fiscal year column in fact sales monthly table 
select * from fact_sales_monthly; #1.484 sec
Select 
s.date, 
s.product_code, 
product, 
variant, 
sold_quantity, 
gross_price, 
gross_price*sold_quantity as total_gross_price, 
pre_invoice_discount_pct 
from fact_sales_monthly s join  dim_product p on s.product_code = p.product_code join fact_gross_price g  on s.product_code = g.product_code and s.fiscal_year = g.fiscal_year join fact_pre_invoice_deductions pre on pre.customer_code = s.customer_code
where s.customer_code = 90002002 and s.fiscal_year = 2021
limit 100000;

Explain analyze #1.624 sec
Select 
s.date, 
s.product_code, 
product, 
variant, 
sold_quantity, 
gross_price, 
gross_price*sold_quantity as total_gross_price, 
pre_invoice_discount_pct 
from fact_sales_monthly s join  dim_product p on s.product_code = p.product_code join fact_gross_price g  on s.product_code = g.product_code and s.fiscal_year = g.fiscal_year join fact_pre_invoice_deductions pre on pre.customer_code = s.customer_code
where s.customer_code = 90002002 and s.fiscal_year = 2021
limit 100000;

#calculate net invoice sales
#created a view for above select statement "sales_preinv_discount"
select *, round((1-pre_invoice_discount_pct)* total_gross_price,2) as net_invoice_sales  from sales_preinv_discount;
#create view for post_invoice_discount 
select * from sales_preinv_discount;
select * from post_ipost_invoice_discountnvoice_discount;

#create a view for net sales
select *, (1-post_invoice_dicount_pct)*net_invoice_sales as net_sales from post_invoice_discount;
#create view 
select * from net_sales;

# excercise create a view for gross sales 
#it should have following coloumns 
-- date, 
-- fiscal_year, 
-- customer_code, 
-- customer, 
-- market, 
-- product_code, 
-- product, 
-- variant, 
-- sold_quantity, 
-- gross_price_per_item, 
-- gross_price_total

#top markets by net sales
select * from net_sales;
select market, 
round(sum(net_sales)/1000000,2) as net_sales_mln 
from net_sales 
where fiscal_year = 2021 
group by market 
order by net_sales_mln 
desc limit 5; # took 96 sec

call gdb0041.Top_n_markets_by_net_sales(5, 2021);
call gdb0041.Top_n_customers_by_net_sales(5, 2021, 'india');#3 sec

#excercise write a stored procedure to get the top n products by net sales for given year. use product name with out varient 


select * from fact_manufacturing_cost;
select * from fact_freight_cost;

select *, manufacturing_cost * sold_quantity as total_manufacturing_cost  from post_invoice_discount; 

#create bar chart to show percentage contribution on global net sales by given customer

with cte as (
select customer, 
round(sum(net_sales)/1000000,2) as net_sales_mln 
from net_sales n
join dim_customer c using (customer_code) 
where fiscal_year = 2021 
group by customer 
)
select *, net_sales_mln*100/sum(net_sales_mln) over() as pct  from cte order by net_sales_mln desc;
#exported to csv and created bar chart in excel

#excercise net sales percentage by region 
#want region wise percentage net sales breakdown by customers in respective region 
#to perform regional analysis on financial performance of the company
#end result bar chart for 2021

select * from net_sales;
with cte as (
select region, 
customer,
round(sum(net_sales)/1000000,2) as net_sales_mln 
from net_sales n
join dim_customer c using (customer_code) 
where fiscal_year = 2021 
group by customer, region 
)
select *, net_sales_mln*100/sum(net_sales_mln) over(partition by region) as pct_contribution  from cte order by region, net_sales_mln desc  ;
# returns % contribution of each customer in a given region

# get top n products in each division by their quantity sold
#Description Write a Stored procedure for getting top n product in each division by their quantity sold in a given financial year

select * from net_sales;
with cte as (
select division, p.product , sum(sold_quantity) as total_sold_quantity  
from fact_sales_monthly s 
join dim_product p 
using(product_code) 
where fiscal_year = 2021
group by p.product, p.division ),
cte2 as (select *, dense_rank() over(partition by division order by total_sold_quantity desc ) as dnrk from cte)
select * from cte2 where dnrk<6; 
#create store procedure 

#top 2 markets in every region by their gross sales in fiscal year 2021
select * from net_sales;
with cte1 as (
select 
region, 
c.market, 
sum(total_gross_price) as total_gross_sales
from net_sales n 
join dim_customer c 
using(customer_code) 
where fiscal_year = 2021 
group by  region, c.market),
cte2 as (select 
*, 
dense_rank() 
over(partition by region order by total_gross_sales desc) as dsrk 
from cte1) 
select * from cte2 where dsrk <=2;


#Forecast accuracy for all customers for a given fiscal year
#aggregate forecast accuracy report for all the customers for a given fiscal year to track accuracy of forecast
-- customer code, name, market
-- total sold quantity
-- total forecast quantity 
-- net error
-- absolute error
-- forecast accuracy 
-- for 2021 
-- create store procedure

# creating single table which includes sales and forecast quantity to make query simple
create table fact_act_est (
select 
s.date as date,
s.fiscal_year as fiscal_year,
s.product_code as product_code,
s.customer_code as customer_code,
s.sold_quantity as sold_quantity,
f.forecast_quantity as forecast_quantity
from fact_sales_monthly s 
left join fact_forecast_monthly f 
using(customer_code, product_code, date) 
union 
select 
f.date as date,
f.fiscal_year as fiscal_year,
f.product_code as product_code,
f.customer_code as customer_code,
s.sold_quantity as sold_quantity,
f.forecast_quantity as forecast_quantity
from fact_sales_monthly s 
right join fact_forecast_monthly f 
using(customer_code, product_code, date));  

select count(*) from fact_act_est;
set SQL_SAFE_UPDATES = 1;
update fact_act_est set sold_quantity = 0 where sold_quantity is null;
update fact_act_est set forecast_quantity = 0 where forecast_quantity is null;

#created triggers to automatically update new records fro fact_sales_monthly and fact_forecat_monthly to fact_act_est
show triggers;
insert into fact_sales_monthly (date, product_code, customer_code, sold_quantity)
values("2030-09-01", "haha", 99, 89);
select * from fact_sales_monthly where customer_code= 99;
insert into fact_forecast_monthly (date, product_code, customer_code, forecast_quantity)
values("2030-09-01", "haha", 99, 104);

select * from fact_sales_monthly where customer_code= 99;
select * from fact_forecast_monthly where customer_code= 99;
select * from fact_act_est where customer_code= 99;

delete from fact_sales_monthly where customer_code= 99 and product_code = "haha" and date = "2030-09-01";
delete from fact_forecast_monthly where customer_code= 99 and product_code = "haha" and date = "2030-09-01";
delete from fact_act_est where customer_code= 99 and product_code = "haha" and date = "2030-09-01";

use gdb0041;

select * from fact_act_est;
select customer_code, sum(forecast_quantity-sold_quantity) as net_error from fact_act_est where fiscal_year = 2021 group by customer_code;
select 
customer_code, 
sum(forecast_quantity-sold_quantity) as net_error, 
abs(sum(forecast_quantity-sold_quantity)) as abs_net_error,
sum(forecast_quantity-sold_quantity)/sum(forecast_quantity)*100 as net_error_pct, 
abs(sum(forecast_quantity-sold_quantity))/ sum(forecast_quantity)*100 as abs_net_error_pct, 
100 - (sum(forecast_quantity-sold_quantity)/sum(forecast_quantity)*100) as forecast_accuraccy_net_error, 
100- (abs(sum(forecast_quantity-sold_quantity))/ sum(forecast_quantity)*100) as forecast_accuraccy_abs_error
from fact_act_est 
where fiscal_year = 2021 
group by customer_code;

with abs_error_table  as (select 
customer_code, 
sum(sold_quantity) as sold_quantity,
sum(forecast_quantity) as forecast_quantity,
sum(forecast_quantity-sold_quantity) as net_error, 
sum(forecast_quantity-sold_quantity)/sum(forecast_quantity)*100 as net_error_pct, 
sum(abs(forecast_quantity-sold_quantity)) as abs_error,
sum(abs(forecast_quantity-sold_quantity))/ sum(forecast_quantity)*100 as abs_error_pct
from fact_act_est 
where fiscal_year = 2021 
group by customer_code)
select a.*,
c.customer,
c.market, 
if(net_error_pct > 100,  0, 100-abs_error_pct) as forecast_accuracy_pct
from abs_error_table a
join 
dim_customer c using(customer_code)
order by forecast_accuracy_pct desc; 

#create temporary table 
create temporary table forcast_accuracy_table 
with abs_error_table  as (select 
customer_code, 
sum(sold_quantity) as sold_quantity,
sum(forecast_quantity) as forecast_quantity,
sum(forecast_quantity-sold_quantity) as net_error, 
sum(forecast_quantity-sold_quantity)/sum(forecast_quantity)*100 as net_error_pct, 
sum(abs(forecast_quantity-sold_quantity)) as abs_error,
sum(abs(forecast_quantity-sold_quantity))/ sum(forecast_quantity)*100 as abs_error_pct
from fact_act_est 
where fiscal_year = 2021 
group by customer_code)
select a.*,
c.customer,
c.market, 
if(abs_error_pct > 100,  0, 100-abs_error_pct) as forecast_accuracy_pct
from abs_error_table a
join 
dim_customer c using(customer_code)
order by forecast_accuracy_pct desc; 

select * from forcast_accuracy_table1 where forecast_accuracy_pct <0; 
#which customers forecast_accuracy has dropped from 2020 to 2021
#complete report with these columns
-- customer code,
-- customer name
-- market
-- forecast_accuracy 2020
--  forecast_accuracy 2021 
with abs_error_table_2020  as (select 
customer_code, 
sum(sold_quantity) as sold_quantity,
sum(forecast_quantity) as forecast_quantity,
sum(forecast_quantity-sold_quantity) as net_error, 
sum(forecast_quantity-sold_quantity)/sum(forecast_quantity)*100 as net_error_pct_2020, 
sum(abs(forecast_quantity-sold_quantity)) as abs_error,
sum(abs(forecast_quantity-sold_quantity))/ sum(forecast_quantity)*100 as abs_error_pct_2020
from fact_act_est 
where fiscal_year = 2020 
group by customer_code),
abs_error_table_2021  as (select 
customer_code, 
sum(sold_quantity) as sold_quantity,
sum(forecast_quantity) as forecast_quantity,
sum(forecast_quantity-sold_quantity) as net_error, 
sum(forecast_quantity-sold_quantity)/sum(forecast_quantity)*100 as net_error_pct_2021, 
sum(abs(forecast_quantity-sold_quantity)) as abs_error,
sum(abs(forecast_quantity-sold_quantity))/ sum(forecast_quantity)*100 as abs_error_pct_2021
from fact_act_est 
where fiscal_year = 2021 
group by customer_code),
forecast_accuracy_table as (select 
c.customer_code,
c.customer,
c.market, 
if(a20.abs_error_pct_2020 > 100,  0, 100-a20.abs_error_pct_2020) as forecast_accuracy_pct_2020,
if(a21.abs_error_pct_2021 > 100,  0, 100-a21.abs_error_pct_2021) as forecast_accuracy_pct_2021
from abs_error_table_2020 a20
join
abs_error_table_2021 a21
using(customer_code)
join 
dim_customer c using(customer_code))
select *, (forecast_accuracy_pct_2021-forecast_accuracy_pct_2020) as forecast_accuracy_change 
from forecast_accuracy_table 
having forecast_accuracy_change <0 
order by forecast_accuracy_change;
#if where is used here then (forecast_accuracy_pct_2021-forecast_accuracy_pct_2020) has to be used since forecast_accuracy_change is calculated after where filtereing
#improving performance by setting indexes
show indexes in fact_act_est;
explain analyze
select * from fact_act_est where fiscal_year = 2020;