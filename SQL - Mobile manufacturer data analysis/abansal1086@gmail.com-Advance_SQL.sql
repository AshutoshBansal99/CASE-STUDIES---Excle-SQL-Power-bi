--SQL Advance Case Study

--1. List all the states in which we have customers who have bought cellphones from 2005 till today.
--Q1--BEGIN  
SELECT DISTINCT L.[State]
FROM DIM_LOCATION L
INNER JOIN FACT_TRANSACTIONS T ON L.IDLocation = T.IDLocation
INNER JOIN DIM_DATE D ON T.Date = D.[DATE]
WHERE D.[YEAR] >= 2005;

--Q1--END
--2. What state in the US is buying the most 'Samsung' cell phones?
--Q2--BEGIN

SELECT TOP 1 L.[State]
FROM DIM_LOCATION L
INNER JOIN FACT_TRANSACTIONS T ON L.IDLocation = T.IDLocation
INNER JOIN DIM_MODEL M ON T.IDModel = M.IDModel
INNER JOIN DIM_MANUFACTURER MN ON M.IDManufacturer = MN.IDManufacturer
WHERE MN.Manufacturer_Name = 'Samsung'
GROUP BY L.[State]
ORDER BY COUNT(*) DESC;


--Q2--END
--3. Show the number of transactions for each model per zip code per state. 
--Q3--BEGIN      
	SELECT 
    L.State,
    L.ZipCode,
    M.Model_Name,
    COUNT(*) AS Transaction_Count
FROM  FACT_TRANSACTIONS AS FT
INNER JOIN DIM_LOCATION AS L ON FT.IDLocation = L.IDLocation
INNER JOIN  DIM_MODEL AS M ON FT.IDModel = M.IDModel
GROUP BY  L.State, L.ZipCode, M.Model_Name
ORDER BY  L.State, L.ZipCode, M.Model_Name;

--Q3--END
--4. Show the cheapest cellphone (Output should contain the price also)
--Q4--BEGIN
SElECT TOP 5 
			Model_Name,
			Unit_Price
FROM DIM_MODEL
ORDER BY Unit_price ASC






--Q4--END
--5. Find out the average price for each model in the top5 manufacturers in terms of sales quantity and order by average price.
--Q5--BEGIN

SELECT  
	mdl.Model_Name,				             -- Select model name
	m.Manufacturer_Name,					 -- Select manufacturer name
	AVG(mdl.Unit_price) AS Average_price	 -- Calculate average price
FROM DIM_MODEL AS mdl
INNER JOIN 
    DIM_MANUFACTURER m ON mdl.IDManufacturer = m.IDManufacturer
INNER JOIN 
		FACT_TRANSACTIONS AS ft ON mdl.IDModel = ft.IDModel
INNER JOIN
		( -- To identify  the top  5  Manufactures base on Sales quantity
			SELECT  
				m.IDManufacturer,
				SUM(ft.Quantity) AS Total_Quantity
			FROM DIM_MANUFACTURER AS m
			INNER JOIN  DIM_MODEL AS dml ON m.IDManufacturer = dml.IDManufacturer
			INNER JOIN FACT_TRANSACTIONS AS ft ON dml.IDModel = ft.IDModel
			GROUP BY 
				m.IDManufacturer
			ORDER BY 
					SUM(ft.Quantity) DESC -- Order by total quantity in descending order
			OFFSET 0 ROWS				  -- Start from the first row
			FETCH NEXT 5 ROWS ONLY        -- Fetch only the top 5 manufacturers
		) AS TopManufacturers ON mdl.IDManufacturer = TopManufacturers.IDManufacturer
GROUP BY mdl.Model_Name, m.Manufacturer_Name
ORDER BY Average_price     -- Order by average price

--Q5--END
--6. List the names of the customers and the average amount spent in 2009, where the average is higher than 500
--Q6--BEGIN

SELECT c.Customer_Name, AVG(ft.TotalPrice) AS Average_Spend
FROM DIM_CUSTOMER AS c
JOIN FACT_TRANSACTIONS AS ft ON c.IDCustomer =ft.IDCustomer
JOIN DIM_DATE AS d ON ft.Date =d.[DATE]
WHERE YEAR (d.[DATE]) = 2009
GROUP BY c.Customer_Name
HAVING AVG (ft.TotalPrice) > 500 

--Q6--END
--7. List if there is any model that was in the top 5 in terms of quantity, simultaneously in 2008, 2009 and 2010
--Q7--BEGIN  
	SELECT TOP 5 m.Model_Name
	FROM DIM_MODEL AS m
    JOIN FACT_TRANSACTIONS AS ft ON m.IDModel = ft.IDModel 
	JOIN DIM_DATE AS d ON ft.Date = d.DATE 
	WHERE YEAR (d.DATE) IN (2008,2009,2010)
	GROUP BY m.Model_Name 
	HAVING COUNT(DISTINCT CASE WHEN YEAR (d.DATE) = 2008 THEN d.DATE END)>0
	AND COUNT(DISTINCT CASE WHEN YEAR (d.DATE) = 2009 THEN d.DATE END)>0
	AND COUNT(DISTINCT CASE WHEN YEAR (d.DATE) = 2010 THEN d.DATE END)>0

--Q7--END	
--8. Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer with the 2nd top sales in the year of 2010.
--Q8--BEGIN
--The use of TOP 1 WITH TIES ensures that all manufacturers tied for the top sales position in each year are returned, providing comprehensive results.
SELECT  TOP 1 WITH TIES dm.Manufacturer_Name,YEAR(d.DATE) AS Sales_Year,SUM(ft.TotalPrice) AS Total_Sales
FROM DIM_MANUFACTURER AS dm
JOIN DIM_MODEL AS m ON dm.IDManufacturer = m.IDManufacturer
JOIN FACT_TRANSACTIONS AS ft ON  M.IDModel = ft.IDModel
JOIN DIM_DATE AS d ON ft.Date = d.DATE
WHERE YEAR(d.DATE) IN (2009,2010)
GROUP BY dm.Manufacturer_Name , YEAR(d.DATE)
ORDER BY ROW_NUMBER() OVER(PARTITION BY YEAR(d.DATE) ORDER BY SUM(ft.TotalPrice) DESC)


--Q8--END
--9. Show the manufacturers that sold cellphones in 2010 but did not in 2009.
--Q9--BEGIN
	 SELECT DISTINCT dm.Manufacturer_Name
	 FROM DIM_MANUFACTURER AS dm
	 JOIN DIM_MODEL AS m ON dm.IDManufacturer = m.IDManufacturer
LEFT JOIN FACT_TRANSACTIONS AS ft ON m.IDModel = ft.IDModel 
LEFT JOIN DIM_DATE AS d ON ft.Date = d.DATE 
WHERE YEAR (d.DATE) = 2010
AND NOT EXISTS( SELECT 1 FROM DIM_DATE WHERE YEAR(d.DATE) = 2009)

--Q9--END
--10. Find top 100 customers and their average spend, average quantity by each year. Also find the percentage of change in their spend. 
--Q10--BEGIN
	
SELECT  TTT.*,((TTT.Average_Spend - TTT.LAG_AVG) / TTT.LAG_AVG) AS Spend_Percentage_Change
FROM (
    SELECT  T.*,
        LAG(T.Average_Spend) OVER(PARTITION BY T.Customer_Name ORDER BY T.Sales_Year ASC) AS LAG_AVG
    FROM (  SELECT 
            c.Customer_Name,
            YEAR(ft.Date) AS Sales_Year,
            AVG(ft.TotalPrice) AS Average_Spend,
            AVG(ft.Quantity) AS Average_Quantity
        FROM  DIM_CUSTOMER c
        JOIN  FACT_TRANSACTIONS ft ON c.IDCustomer = ft.IDCustomer
        JOIN   DIM_DATE d ON ft.Date = d.DATE
        WHERE  c.Customer_Name IN (
                SELECT TOP 10  c.Customer_Name 
                FROM DIM_CUSTOMER AS c
                INNER JOIN  FACT_TRANSACTIONS AS b ON b.IDCustomer = c.IDCustomer
                GROUP BY  c.Customer_Name
                ORDER BY  SUM(b.TotalPrice) DESC
            ) GROUP BY  c.Customer_Name, YEAR(ft.Date)  ) AS T ) AS TTT;

--Q10--END
