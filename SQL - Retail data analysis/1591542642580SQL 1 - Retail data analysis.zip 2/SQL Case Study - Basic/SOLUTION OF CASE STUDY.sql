--caes study basic Retail store
--Table maping....

/*ALTER TABLE Transactions
ADD CONSTRAINT FK_Transactions_Customer
FOREIGN KEY (Cust_id) REFERENCES Customer(customer_id)

ALTER TABLE Transactions
ADD CONSTRAINT FK_Transactions_ProductCategory
FOREIGN KEY (prod_cat_code) REFERENCES prod_cat_info(prod_cat_code)
 
 *Note- First remove the dublicate values from the table to make it Primery key 
 ( As a row can not be made primery key if it is having dublicate values)

ALTER TABLE prod_cat_info
ADD CONSTRAINT PK_prod_cat_info_prod_cat_code PRIMARY KEY (prod_cat_code);
*/

--DATA PREPARATION AND UNDERSTANDING.

--BEGIN
--Q1. What is the total number of row in each of the 3 tables in the database ?

SELECT 
  (SELECT COUNT(*) FROM Customer) AS total_rows_customer,
  (SELECT COUNT(*) FROM Transactions) AS total_rows_transactions,
  (SELECT COUNT(*) FROM prod_cat_info) AS total_rows_product_category;

--Q2. What is the total number of the transaction that have a return?

SELECT COUNT(*) AS total_return_transactions
FROM Transactions WHERE total_amt < 0;

--Q3. As you have noticed , dates are not correctly formated we have to fomate the dates in the corret fromate before procceding?

SELECT CONVERT(VARCHAR, CONVERT(DATE, DOB, 103), 103) AS DOB   
FROM Customer;

SELECT CONVERT(VARCHAR, CONVERT(DATE, tran_date, 103), 103) AS Tran_date 
FROM Transactions;

--Q4 What is the time range of the transaction data available for analysis? show the output in nuber of days, month and year simultaneously in diffrent columns.

-- Calculate the minimum and maximum transaction dates
SELECT 
    MIN(CONVERT(DATE, tran_date, 103)) AS min_transaction_date,
    MAX(CONVERT(DATE, tran_date, 103)) AS max_transaction_date,
    -- Calculate the number of days between the minimum and maximum dates
    DATEDIFF(DAY, MIN(CONVERT(DATE, tran_date, 103)), MAX(CONVERT(DATE, tran_date, 103))) AS days_range,
    -- Calculate the number of months between the minimum and maximum dates
    DATEDIFF(MONTH, MIN(CONVERT(DATE, tran_date, 103)), MAX(CONVERT(DATE, tran_date, 103))) AS months_range,
    -- Calculate the number of years between the minimum and maximum dates
    DATEDIFF(YEAR, MIN(CONVERT(DATE, tran_date, 103)), MAX(CONVERT(DATE, tran_date, 103))) AS years_range
FROM  Transactions;

--Q5 Which product category does the sub-catogory 'DIY" belongs to?

SELECT  prod_cat
FROM  prod_cat_info
WHERE  prod_subcat = 'DIY';
	                      					 
--END

--DATA ANALYSIS

--BEGIN

--Q1 Which channel is most frequently used for transactions
-- Top key word is used for showing the top Result here 3;

SELECT  
    Store_type AS Most_Frequent_Channel,
	--Count is used to count the total no of transaction by store type.
    COUNT(*) AS Transaction_Count  
FROM Transactions
GROUP BY  Store_type
ORDER BY  COUNT(*) DESC 

--Q2 What is the count of Male and Female customers in the database?
SELECT  Gender, COUNT(*) AS Customer_Count
FROM   customer
	WHERE Gender IS NOT NULL -- Filter out rows where Gender is null
GROUP BY  Gender;
--Q3 From which city do we have the maximum number of customers and how many? 

SELECT TOP 1
    c.city_code,
    COUNT(*) AS Customer_Count
FROM  customer AS c
GROUP BY  c.city_code 
ORDER BY  COUNT(*) DESC;

--Q4. How many sub-categories are there under the Books category?

--counts the number of distinct sub-categories (avoiding duplicates) associated with the Books category.
SELECT COUNT(DISTINCT prod_subcat) AS Subcategory_Count
FROM prod_cat_info
WHERE prod_cat = 'Books';

--Q5 What is the maximum quantity of products ever ordered?

--calculates the maximum value in the Qty column, which represents the quantity of products ordered.
SELECT MAX(Qty) AS Max_Quantity FROM transactions;

--Q6 What is the net total revenue generated in categories Electronics and Books?

SELECT 
-- calculates the total revenue (total amount) for each category.
   ROUND(SUM(total_amt),4) AS Net_Total_Revenue  --ROUND() function use to round up the sum total amount to 4 decimal place
FROM 
    transactions AS t
--The JOIN clause joins the transactions table with the prod_cat_info table based on the prod_cat_code
JOIN 
    prod_cat_info AS pci ON t.prod_cat_code = pci.prod_cat_code
WHERE 
    pci.prod_cat IN ('Electronics', 'Books');

--Q7 How many customers have >10 transactions with us, excluding returns

   SELECT COUNT(*) AS Customer_count
   FROM (SELECT cust_id  FROM Transactions WHERE total_amt > 0 -- Exclude returns
   GROUP BY cust_id HAVING COUNT(*) > 10 --- count the transaction having count more that 10.
   )AS Transactions

--Q8 What is the combined revenue earned from the "Electronics" & "Clothing" categories, from "Flagship stores"?

SELECT Round(SUM(total_amt),4) AS Combined_Revenue  --calculates the total revenue for the specified categories and store type.
FROM Transactions AS t 
JOIN prod_cat_info As pci ON T.prod_cat_code =pci.prod_cat_code
WHERE prod_cat IN( 'Electronics', 'Clothing') AND Store_type = 'Flagship Store'


--Q9 What is the total revenue generated from "Male" customers in "Electronics" category? Output should display total revenue by prod sub-cat.

SELECT 
	PCI.prod_subcat AS Product_Subcategory,
	ROUND(SUM(T.total_amt),4) AS Total_Revenue  FROM Transactions AS T
JOIN Customer AS C ON T.cust_id =C.customer_Id 
JOIN prod_cat_info AS PCI ON T.prod_cat_code=PCI.prod_cat_code
WHERE C.Gender IN('MALE','M') AND PCI.prod_cat='Electronics' 
GROUP BY PCI.prod_subcat

--Q10 What is percentage of sales and returns by product sub category; display only top 5 sub categories in terms of sales?

SELECT TOP 5
    -- Select the product sub-category
    pci.prod_subcat AS Product_Subcategory,
    -- Calculate the count of sales for each sub-category
    SUM(CASE WHEN t.total_amt > 0 THEN 1 ELSE 0 END) AS Sales_Count,
    -- Calculate the count of returns for each sub-category
    SUM(CASE WHEN t.total_amt < 0 THEN 1 ELSE 0 END) AS Return_Count,
    -- Calculate the percentage of sales for each sub-category
   ROUND(CAST(SUM(CASE WHEN t.total_amt > 0 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100,3)  AS Sales_Percentage,
    -- Calculate the percentage of returns for each sub-category
   ROUND(CAST(SUM(CASE WHEN t.total_amt < 0 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100,3)  AS Return_Percentage
FROM 
    -- Join the transactions table with the product category info table
    transactions AS t
JOIN  prod_cat_info AS pci ON t.prod_cat_code = pci.prod_cat_code
GROUP BY 
    -- Group the results by product sub-category
    pci.prod_subcat
ORDER BY 
    -- Order the results by the count of transactions in descending order
    COUNT(*) DESC;

--Q11 For all customers aged between 25 to 35 years find what is the net total revenue generated by these consumers in last 30 days of transactions from max transaction date available in the data?


SELECT  ROUND ( SUM(total_amt),3) AS Net_Total_Revenue -- Summing up the total amount to get net total revenue
FROM   Transactions AS T
JOIN  Customer AS C ON T.cust_id = C.customer_Id
WHERE  -- Filtering transactions from the last 30 days based on the maximum transaction date available in the data
    tran_date BETWEEN DATEADD(DAY, -30, (SELECT MAX(tran_date) FROM Transactions)) AND (SELECT MAX(tran_date) FROM Transactions) 
    AND YEAR(GETDATE()) - YEAR(DOB) BETWEEN 25 AND 35; -- Selecting customers aged between 25 to 35 years

--Q12. Which product category has seen the max value of returns in the last 3 months of transactions?

SELECT TOP 1
    pc.prod_cat AS product_category,
    SUM(tr.total_amt) AS total_returns
FROM Transactions AS tr

INNER JOIN prod_cat_info AS pc ON tr.prod_cat_code = pc.prod_cat_code
WHERE 
    tr.tran_date >= DATEADD(month, -3, '2014-02-28')
    AND tr.tran_date <= '2014-02-28' -- Assuming '2014-02-28' is the current date
    AND tr.total_amt < 0 -- Considering only returns (negative total_amt)
GROUP BY  pc.prod_cat
ORDER BY total_returns DESC; -- Ordering by total returns in descending order


--Q13. Which store-type sells the maximum products; by value of sales amount and by quantity sold?

SELECT top 3
    Store_type,
	-- This part of the query calculates the maximum total value by sales amount for each store type.
    MAX(CASE WHEN Metric = 'By Sales Amount' THEN Total_Value END) AS Total_Value_By_Sales,
    -- This part of the query calculates the maximum total value by quantity sold for each store type.
   MAX(CASE WHEN Metric = 'By Quantity Sold' THEN Total_Value END) AS Total_Value_By_Quantity
FROM (
  -- is this part of the subquery calculates the total value by sales amount for each store type.
		SELECT 
			'By Sales Amount' AS Metric,  -- We assign a label 'By Sales Amount' to indicate the metric.
			Store_type,
			SUM(total_amt) AS Total_Value
		FROM Transactions GROUP BY Store_type
 
		UNION ALL
    -- In This part of the subquery calculates the total value by quantity sold for each store type.
			SELECT 
				'By Quantity Sold' AS Metric,
				Store_type,
				CAST(SUM(Qty) AS DECIMAL) AS Total_Value
			FROM Transactions GROUP BY Store_type
		) AS CombinedData
-- Finally, we group the combined data by store type to get the maximum total values for each metric.
GROUP BY  Store_type;


--Q14. What are the categories for which average revenue is above the overall average. 

-- Calculate the overall average revenue
WITH OverallAverage AS (
			SELECT AVG(total_amt) AS overall_avg_revenue
			FROM Transactions
		),

-- Calculate average revenue for each category
CategoryAverage AS (
		SELECT 
			pc.prod_cat AS product_category,
			AVG(tr.total_amt) AS avg_revenue
		FROM Transactions tr
			INNER JOIN prod_cat_info pc ON tr.prod_cat_code = pc.prod_cat_code
			GROUP BY pc.prod_cat
			)

-- Select categories with average revenue above the overall average
SELECT  product_category, avg_revenue
FROM CategoryAverage
CROSS JOIN OverallAverage
-- condition which select categories Where averrage revenue is above the overall average 
WHERE avg_revenue > overall_avg_revenue; 
--Q15. Find the average and total revenue by each subcategory for the categories which are among top 5 categories in terms of quantity sold.

-- Calculate the top 5 categories by quantity sold
WITH Top5Categories AS (
    SELECT 
        pc.prod_cat AS product_category,
        SUM(tr.Qty) AS total_quantity_sold  -- Sum of qty as total quantity sold
    FROM Transactions tr
    INNER JOIN prod_cat_info AS pc ON tr.prod_cat_code = pc.prod_cat_code
    GROUP BY pc.prod_cat
    ORDER BY total_quantity_sold DESC
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY -- to select only top 5 categories
)

-- Calculate average and total revenue by subcategory for top 5 categories
SELECT 
    pc.prod_cat AS product_category,
    pc.prod_subcat AS product_subcategory,
   ROUND( AVG(tr.total_amt),3) AS avg_revenue,
   ROUND( SUM(tr.total_amt),3)AS total_revenue
FROM Transactions AS tr

/*we directly join the Transactions and prod_cat_info tables to calculate 
 the average and total revenue for each subcategory within the top 5 categories.*/

INNER JOIN prod_cat_info AS pc ON tr.prod_cat_code = pc.prod_cat_code
INNER JOIN Top5Categories AS t5 ON pc.prod_cat = t5.product_category
--Finally, the results are ordered by product category and product subcategory.
GROUP BY pc.prod_cat, pc.prod_subcat
ORDER BY product_category, product_subcategory;

----END