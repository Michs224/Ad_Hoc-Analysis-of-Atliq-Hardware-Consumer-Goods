-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its
-- business in the APAC region.

SELECT distinct(market) from dim_customer
where customer="Atliq Exclusive" AND region="APAC"
ORDER BY market;

select distinct(Market) as market, region from dim_customer;


-- 2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
-- unique_products_2020
-- unique_products_2021
-- percentage_chg

SELECT X.A as unique_product_2020, Y.B as unique_product_2021, ROUND((B-A)*100/X.A,2) AS percentage_chg
from (
(SELECT COUNT(distinct(product_code)) as A from fact_sales_monthly where fiscal_year=2020) as X,
(SELECT COUNT(distinct(product_code)) as B from fact_sales_monthly where fiscal_year=2021) as Y);


-- 3. Provide a report with all the unique product counts for each segment and sort them in descending order of
-- product counts. The final output contains 2 fields,
-- segment
-- product_count

select segment, count(distinct(product_code)) as product_count
from dim_product
group by segment
order by product_count desc;


-- 4. Follow-up: Which segment had the most increase in unique products in
-- 2021 vs 2020? The final output contains these fields,
-- segment
-- product_count_2020
-- product_count_2021
-- difference

WITH CTE1 AS
(SELECT segment as A,COUNT(distinct(p.product_code)) as B
from dim_product p join fact_sales_monthly m on p.product_code = m.product_code
where fiscal_year=2020
group by segment)
,
CTE2 AS
(SELECT segment as C,COUNT(distinct(p.product_code)) as D
from dim_product p join fact_sales_monthly m on p.product_code = m.product_code
where fiscal_year=2021
group by segment)

SELECT CTE1.A as segment, B as product_count_2020, D as product_count_2021, (D-B) as difference
from CTE1 join CTE2 on CTE1.A=CTE2.C
order by difference desc;


-- 5. Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cost

WITH CTE1 AS
(SELECT MAX(manufacturing_cost) AS A from dim_product p
join fact_manufacturing_cost c on c.product_code = p.product_code)
,
CTE2 AS
(SELECT MIN(manufacturing_cost) AS B from dim_product p
join fact_manufacturing_cost c on c.product_code = p.product_code
)

SELECT p.product_code, p.product, c.manufacturing_cost
FROM dim_product p
JOIN fact_manufacturing_cost c ON c.product_code = p.product_code
WHERE manufacturing_cost IN ((SELECT A from CTE1),(SELECT B FROM CTE2))
ORDER BY manufacturing_cost DESC;


-- 6. Generate a report which contains the top 5 customers who received an
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields,
-- customer_code
-- customer
-- average_discount_percentage

SELECT c.customer_code, customer, ROUND(AVG(pre_invoice_discount_pct),4) as average_discount_percentage
from fact_pre_invoice_deductions d
join dim_customer c on c.customer_code = d.customer_code
where fiscal_year=2021 and market="India"
group by customer_code,customer
order by average_discount_percentage desc
LIMIT 5;


-- 7. Get the complete report of the Gross sales amount for the customer “Atliq
-- Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.
-- The final report contains these columns:
-- Month
-- Year
-- Gross sales Amount

#1
SELECT DATE_FORMAT(date,"%M (%Y)") as Month, fsm.fiscal_year, ROUND(SUM(gross_price*sold_quantity),2) as "Gross sales Amount" from 
fact_sales_monthly fsm
join dim_customer dc on dc.customer_code = fsm.customer_code
join fact_gross_price fgp on fgp.product_code = fsm.product_code
where customer="Atliq Exclusive"
group by Month, fiscal_year
order by fiscal_year ASC;

#2 Data for visualization in Tableau
-- SELECT fsm.date, fsm.fiscal_year, ROUND(SUM(gross_price*sold_quantity),2) as "Gross sales Amount" from 
-- fact_sales_monthly fsm
-- join dim_customer dc on dc.customer_code = fsm.customer_code
-- join fact_gross_price fgp on fgp.product_code = fsm.product_code
-- where customer="Atliq Exclusive"
-- group by fsm.date, fiscal_year
-- order by fiscal_year ASC;


-- 8. In which quarter of 2020, got the maximum total_sold_quantity? 
-- The final output contains these fields sorted by the total_sold_quantity
-- Quarter
-- total_sold_quantity

#1
WITH CTE AS
(
SELECT YEAR(date) as Year, MONTH(date) as Month,
CASE 
	WHEN MONTH(date) in (9,10,11) THEN "Q1"
    WHEN MONTH(date) in (12,1,2) THEN "Q2"
    WHEN MONTH(date) in (3,4,5) THEN "Q3"
    WHEN MONTH(date) in (6,7,8) THEN "Q4"
    END AS quarter, sold_quantity
FROM fact_sales_monthly
where fiscal_year = 2020)

SELECT quarter, SUM(sold_quantity) as total_sold_quantity FROM CTE
GROUP BY quarter
ORDER BY total_sold_quantity DESC;

#2
WITH CTE AS
(
SELECT YEAR(date) as Year, MONTH(date) as Month,
CASE 
	WHEN MONTH(date) in (9,10,11) THEN CONCAT("Q1, ",MONTHNAME(date))
    WHEN MONTH(date) in (12,1,2) THEN CONCAT("Q2, ",MONTHNAME(date))
    WHEN MONTH(date) in (3,4,5) THEN CONCAT("Q3, ",MONTHNAME(date))
    WHEN MONTH(date) in (6,7,8) THEN CONCAT("Q4, ",MONTHNAME(date))
    END AS Quarter, sold_quantity
FROM fact_sales_monthly
where fiscal_year = 2020)

SELECT Quarter, SUM(sold_quantity) as total_sold_quantity FROM CTE
GROUP BY Quarter;


-- 9. Which channel helped to bring more gross sales in the fiscal year 2021
-- and the percentage of contribution? The final output contains these fields,
-- channel
-- gross_sales_mln
-- percentage


WITH CTE AS
(
SELECT channel, SUM(gross_price*sold_quantity) as Gross_sales_mln
from fact_sales_monthly fsm join fact_gross_price fgp on fgp.product_code = fsm.product_code
join dim_customer dc on dc.customer_code = fsm.customer_code
where fsm.fiscal_year=2021
GROUP BY channel)

SELECT channel, CONCAT(ROUND(Gross_sales_mln/1000000,2)," M") as Gross_sales_mln, 
CONCAT(ROUND(Gross_sales_mln*100/total,2),"%") as percentage
FROM
(
(SELECT SUM(Gross_sales_mln) as total from CTE) AS A,
(SELECT * FROM CTE) AS B
)
ORDER BY percentage DESC;


-- 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
-- The final output contains these fields,
-- division
-- product_code 
-- product
-- total_sold_quantity
-- rank_order


WITH CTE1 AS
(
SELECT division,dp.product_code, CONCAT(product," (",variant,")") as product, SUM(sold_quantity) as total_sold_quantity
FROM dim_product dp JOIN fact_sales_monthly fsm on fsm.product_code = dp.product_code
WHERE fiscal_year = 2021
GROUP BY division, product_code,product,variant
),
CTE2 AS
(
SELECT division,product_code, product, total_sold_quantity,
RANK() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS Rank_Order
FROM CTE1
)

SELECT C1.division, C1.product_code, C1.product, C1.Total_sold_quantity, Rank_Order
FROM CTE1 C1 JOIN CTE2 C2
ON C1.product_code = C2.product_code
WHERE Rank_Order IN (1,2,3);


# OR
# For Data Visualization in Tableau
WITH CTE AS
(
SELECT division,dp.product_code, product, variant,SUM(sold_quantity) as total_sold_quantity,
RANK() OVER(PARTITION BY division ORDER BY SUM(sold_quantity) DESC) AS Rank_Order
FROM dim_product dp JOIN fact_sales_monthly fsm on fsm.product_code = dp.product_code
WHERE fiscal_year = 2021
GROUP BY division, product_code,product,variant
)

SELECT division, product_code, product, variant,Total_sold_quantity, Rank_Order
FROM CTE
WHERE Rank_Order IN (1,2,3);

