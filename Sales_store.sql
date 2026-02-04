CREATE DATABASE sales_store;
Go

USE sales_store;
Go

CREATE TABLE sales_store (
transaction_id VARCHAR(15),
customer_id	VARCHAR (15),
customer_name VARCHAR (30),
customer_age INT,
gender	VARCHAR (15),
product_id VARCHAR (15),
product_name VARCHAR (30),
product_category VARCHAR (30),
quantiy INT,
prce INT,
payment_mode VARCHAR (30),
purchase_date DATE,
time_of_purchase TIME,
status VARCHAR (15) 
);

SELECT * FROM sales_store;
GO

SET DATEFORMAT dmy --Convert DD-MM-YYYY to YYYY-MM-DD
BULK INSERT sales_store 
FROM 'E:\SQL\Project\sales_store.CSV'
      WITH (
          FIRSTROW = 2 ,
          FIELDTERMINATOR= ',',
          ROWTERMINATOR= '\n'
          );
          GO

--Data cleaning 

SELECT * FROM sales_store;
GO
SELECT * INTO sales FROM sales_store;
GO

SELECT * FROM sales;
GO 

--DATA CLEANING 
--STEP 1: to Check for duplicate 
SELECT transaction_id,
count (*)
FROM sales 
GROUP BY transaction_id 
HAVING COUNT (transaction_id)>1;


WITH CTE AS (
SELECT *,
ROW_NUMBER () OVER (PARTITION BY transaction_id ORDER BY transaction_id) AS Row_Num
FROM SALES 
)
--DELETE FROM CTE 
--WHERE Row_Num = 2;

SELECT * FROM CTE 
WHERE transaction_id IN ('TXN240646','TXN342128','TXN855235','TXN981773')

--STEP 2: Correction of header issue
EXEC sp_rename 'sales.quantiy', 'quantity', 'COLUMN'
EXEC sp_rename 'sales.prce', 'price', 'COLUMN'

--Check Data type 
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME= 'sales'

--Step-4: To check Null Values 
--copy a code and change the table name 
DECLARE @SQL NVARCHAR(MAX) = '';

SELECT @SQL = STRING_AGG(
    'SELECT ''' + COLUMN_NAME + ''' AS ColumnName, ' +
    'COUNT(*) AS NullCount ' +
    'FROM ' + QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) + ' ' +
    'WHERE ' + QUOTENAME(COLUMN_NAME) + ' IS NULL',
    ' UNION ALL '
)
WITHIN GROUP (ORDER BY COLUMN_NAME)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sales';

-- Execute the dynamic SQL
EXEC sp_executesql @SQL;

--Treating null values 
SELECT * FROM sales
WHERE transaction_id IS NULL 
OR 
customer_id IS NULL
OR 
customer_name IS NULL
OR 
customer_age IS NULL 
OR 
gender IS NULL
OR 
payment_mode IS NULL 
OR
purchase_date IS NULL 
OR
status IS NULL 
OR 
time_of_purchase IS NULL;
GO


-- delete null transaction id 
DELETE FROM sales 
WHERE transaction_id IS NULL;
GO

SELECT * FROM sales 
WHERE customer_name = 'Ehsaan Ram'

UPDATE sales 
SET customer_id = 'CUST9494'
WHERE transaction_id = 'TXN977900'

SELECT * FROM sales 
WHERE customer_name = 'Damini Raju'

UPDATE sales 
SET customer_id = 'CUST1401'
WHERE transaction_id = 'TXN985663'

SELECT * FROM sales 
WHERE customer_id = 'CUST1003'

UPDATE sales 
SET customer_name = 'Mahika Saini', customer_age= 35, gender = 'Male'
WHERE transaction_id = 'TXN432798'

SELECT * FROM sales;

--STEP:5 Data cleaning 
SELECT DISTINCT gender
FROM sales;

UPDATE sales 
SET gender = 'Male'
WHERE gender= 'M';

UPDATE sales 
SET gender = 'Female'
WHERE gender= 'F';

SELECT DISTINCT payment_mode
FROM sales;

UPDATE sales 
SET payment_mode = 'Credit Card'
WHERE payment_mode= 'CC';



--Data analysis 
--1. What are the top 5 most selling product by quantity?
SELECT * FROM sales;

SELECT DISTINCT status
FROM sales;

SELECT TOP 5 product_name, SUM (quantity) AS total_quantity_sold
FROM sales 
WHERE status = 'delivered'
GROUP BY product_name
ORDER BY total_quantity_sold DESC;

--Business problem: We don't know which products are most in demand.
--Business Impact: Help prioritize stock and boost sales through targeted promotion.


--------------------------------------------------------------------------------------------

--2. which products are most frequently canceled?
SELECT TOP 5 product_name, COUNT(*) AS total_canceled
FROM sales
WHERE status = 'cancelled'
GROUP BY product_name 
ORDER BY total_canceled DESC;

--Business Problem: Frequent cancellations affects revenue and customer trust.
--Business Impact: Identify poor-performing products tom improve quality or remove from catalog.

------------------------------------------------------------------------------------------------

--3. What time of the day has the highest number of purchase?

SELECT * FROM sales;

SELECT 
CASE 
    WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
    WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
    WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
    WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
END AS time_of_day,
COUNT(*) total_order 
FROM sales 
GROUP BY 
CASE 
    WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
    WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
    WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
    WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
END 
ORDER BY total_order DESC;

--Business problem solved: Find peak sales time.
--Business Impact: Optimizing staffing, promotions, and server loads.

-------------------------------------------------------------------------------

--4. WHo are the top5 highest spending customer?

SELECT * FROM sales;

SELECT TOP 5 customer_name, 
       FORMAT(SUM(price * quantity),'C0') AS Total_spent
FROM sales 
GROUP BY customer_name
ORDER BY SUM(price * quantity) DESC;

--Business problem solved: Identify VIP customers.
--Business Impact: Personalized offers, loyalty rewards, and retention. 

--------------------------------------------------------------------------------------

--Which product categories generate the highest revenue?

SELECT * FROM sales;

SELECT product_category, 
         FORMAT(SUM(price * quantity),'C0') AS revenue 
FROM sales 
GROUP BY product_category
ORDER BY SUM(price * quantity) DESC;

--Business problem solved: Identify top-performing categories.
--Business impact: Refine product strategy, supply chain, and promotions.
--allowing the business to invest more in high demand catagories.

--------------------------------------------------------------------------

--6. What is the return/cancelation rate per product category,
SELECT * FROM sales;

--Cancallation
SELECT product_category,
       FORMAT(COUNT(CASE WHEN status= 'cancelled' THEN 1 END)*100.0/COUNT(*),'N3')+'%' AS cancelled_product
 FROM sales 
 GROUP BY product_category
 ORDER BY cancelled_product DESC;

--Business problem solved: Monitor dissatisfaction trends per category
--Business impact: Reduce returns, improve product discriptions/expectation.
--Helps identify and fix product or logistic issues.

-------------------------------------------------------------------------------------

--7. WHat is the most preferred payment mode?

SELECT * FROM sales;

SELECT payment_mode, COUNT(payment_mode) AS total_count 
FROM sales 
GROUP BY payment_mode
ORDER BY total_count DESC;


--Business problem solved: TO know wich payment method customers prefer.

--Business Impact: Streamline payment processing, prioritize popular mode.

------------------------------------------------------------------------------------

--8. How does age group affect purchasing behaviour.

SELECT * FROM sales;

--SELECT MIN(customer_age), MAX(customer_age)
--FROM sales;

SELECT 
     CASE
        WHEN customer_age BETWEEN 18 AND 25 THEN '18-25'
        WHEN customer_age BETWEEN 26 AND 35 THEN '26-35'
        WHEN customer_age BETWEEN 36 AND 45 THEN '36-45'
        ELSE '51+'
     END AS customer_age,
    FORMAT( SUM(price*quantity), 'C0') AS total_purchase
FROM sales 
GROUP BY CASE
        WHEN customer_age BETWEEN 18 AND 25 THEN '18-25'
        WHEN customer_age BETWEEN 26 AND 35 THEN '26-35'
        WHEN customer_age BETWEEN 36 AND 45 THEN '36-45'
        ELSE '51+'
     END
ORDER BY total_purchase DESC;

--Business Problem solved: understand customer demographics.
--Business Impact: Targeted marketing and product recommendations by age group.

---------------------------------------------------------------------------------------


--9. WHAT'S the monthly sales trend? 
SELECT * FROM sales;

--Method 1 

SELECT FORMAT(purchase_date, 'yyyy-MM') AS Year_Month,
       FORMAT(SUM(price*quantity), 'C0') AS total_sales,
       SUM(quantity) AS total_quantity
  FROM sales
  GROUP BY FORMAT(purchase_date, 'yyyy-MM')

--MEthod 2 
SELECT 
     YEAR(purchase_date) AS Years,
     MONTH(purchase_date)AS Months,
     FORMAT(SUM(price*quantity), 'C0') AS total_sales,
       SUM(quantity) AS total_quantity
  FROM sales
  GROUP BY YEAR(purchase_date), MONTH(purchase_date)
  ORDER BY Months;

 ---IF only months.
 
SELECT 
     --YEAR(purchase_date) AS Years,
     MONTH(purchase_date)AS Months,
     FORMAT(SUM(price*quantity), 'C0') AS total_sales,
       SUM(quantity) AS total_quantity
  FROM sales
  GROUP BY  MONTH(purchase_date)
  ORDER BY Months;


--Business problem solved: Sales fluctuation go unnoticed.
--Business Impact: Plan inventory and marketiing according to seasonal treands.


--10. Are certain genders buying more specific product categories?

SELECT * FROM sales;

--Method 1 
SELECT gender, product_category, COUNT(product_category) AS total_purchase
FROM sales 
GROUP BY gender, product_category
Order BY gender, total_purchase desc;

--Method 2

SELECT * 
FROM (
    SELECT gender,product_category
    FROM sales 
    ) AS source_table 
PIVOT (
COUNT(gender)
FOR gender IN ([Male],[Female])
) AS pivot_table
ORDER BY product_category;

--Business Problem solved: Gender based product preferences.
--Business impact Personalized ads, gender focused campaigns.
-----------------------------------------------------------------------------------






















