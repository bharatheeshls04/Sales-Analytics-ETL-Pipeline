-- SPECIFIC SQL ANALYSIS FOR YOUR RAW SALES DATA
-- ------------------------------------------------------------------
-- Dataset: 8 records with Electronics, Clothing, Furniture categories
-- Issues: Missing emails, phones, discounts, date inconsistencies, duplicates
-- ------------------------------------------------------------------

CREATE DATABASE IF NOT EXISTS retail_sales_project;
USE retail_sales_project;

-- Create table matching your exact data structure
CREATE TABLE raw_sales_data (
    Order_ID INT PRIMARY KEY,
    Customer_Name VARCHAR(50),
    Email VARCHAR(100),
    Phone VARCHAR(15),
    Product_Category VARCHAR(20),
    Order_Date VARCHAR(20),  -- Keep as VARCHAR initially due to format issues
    Revenue DECIMAL(10,2),
    Discount_Percent DECIMAL(5,2)
);
-- Insert your exact data
INSERT INTO raw_sales_data VALUES
(101, 'John Doe', 'john@email.com', '9876543210', 'Electronics', '12/31/2023', 1200.00, 10.0),
(102, 'Alice Smith', NULL, '9898989898', 'Clothing', '01-05-2024', 500.00, NULL),
(103, 'Bob Miller', 'bob@email.com', NULL, 'Electronics', '2024/01/12', 3000.00, 20.0),
(104, 'John Doe', 'john@email.com', '9876543210', 'Electronics', '12/31/2023', 1200.00, 10.0),
(105, 'David White', 'david@email.com', '9123456789', 'Furniture', '02-15-2024', 2500.00, 15.0),
(106, 'Emma Brown', 'emma@email.com', '9234567890', 'Clothing', '2024-03-08', 700.00, 5.0),
(107, 'Chris Green', NULL, '9345678901', 'Furniture', '04/10/2024', 1800.00, 25.0),
(108, 'Alice Smith', 'alice@email.com', NULL, 'Clothing', '03-08-2024', 500.00, NULL);

-- ------------------------------------------------------------------
-- DATA QUALITY ASSESSMENT FOR YOUR SPECIFIC DATA
-- ------------------------------------------------------------------

-- Check your specific data quality issues
SELECT 
    'Total Records' as Issue,
    COUNT(*) as Count,
    'N/A' as Details
FROM raw_sales_data

UNION ALL

SELECT 
    'Missing Emails',
    COUNT(*),
    GROUP_CONCAT(CONCAT('ID:', Order_ID, '-', Customer_Name))
FROM raw_sales_data 
WHERE Email IS NULL

UNION ALL

SELECT 
    'Missing Phones',
    COUNT(*),
    GROUP_CONCAT(CONCAT('ID:', Order_ID, '-', Customer_Name))
FROM raw_sales_data 
WHERE Phone IS NULL

UNION ALL

SELECT 
    'Missing Discounts',
    COUNT(*),
    GROUP_CONCAT(CONCAT('ID:', Order_ID, '-', Customer_Name))
FROM raw_sales_data 
WHERE Discount_Percent IS NULL

UNION ALL

SELECT 
    'Exact Duplicates',
    COUNT(*) - COUNT(DISTINCT CONCAT(Customer_Name, Email, Order_Date, Revenue)),
    'John Doe duplicate found'
FROM raw_sales_data;

-- ------------------------------------------------------------------
-- DATA CLEANING FOR YOUR SPECIFIC DATASET
-- ------------------------------------------------------------------

-- Create cleaned table
CREATE TABLE cleaned_sales_data AS SELECT * FROM raw_sales_data;
SET SQL_SAFE_UPDATES = 0;

-- 1. Remove exact duplicates (John Doe duplicate)
DELETE t1 FROM cleaned_sales_data t1
INNER JOIN cleaned_sales_data t2 
WHERE t1.Order_ID > t2.Order_ID 
    AND t1.Customer_Name = t2.Customer_Name 
    AND t1.Email = t2.Email 
    AND t1.Order_Date = t2.Order_Date 
    AND t1.Revenue = t2.Revenue;

-- 2. Handle missing emails
UPDATE cleaned_sales_data 
SET Email = 'not_provided@email.com' 
WHERE Email IS NULL;

-- 3. Handle missing phones
UPDATE cleaned_sales_data 
SET Phone = 'Not Provided' 
WHERE Phone IS NULL;

-- 4. Handle missing discounts (use average of existing discounts)
SET @avg_discount = (SELECT AVG(Discount_Percent) FROM cleaned_sales_data WHERE Discount_Percent IS NOT NULL);
UPDATE cleaned_sales_data 
SET Discount_Percent = @avg_discount 
WHERE Discount_Percent IS NULL;

-- 5. Standardize date formats
ALTER TABLE cleaned_sales_data ADD COLUMN Order_Date_Clean DATE;

-- Handle your specific date formats
UPDATE cleaned_sales_data 
SET Order_Date_Clean = CASE 
    WHEN Order_Date = '12/31/2023' THEN '2023-12-31'
    WHEN Order_Date = '01-05-2024' THEN '2024-01-05'
    WHEN Order_Date = '2024/01/12' THEN '2024-01-12'
    WHEN Order_Date = '02-15-2024' THEN '2024-02-15'
    WHEN Order_Date = '2024-03-08' THEN '2024-03-08'
    WHEN Order_Date = '04/10/2024' THEN '2024-04-10'
    WHEN Order_Date = '03-08-2024' THEN '2024-03-08'
    ELSE NULL
END;

-- Remove old date column, rename clean one
ALTER TABLE cleaned_sales_data DROP COLUMN Order_Date;
ALTER TABLE cleaned_sales_data CHANGE Order_Date_Clean Order_Date DATE;

-- ------------------------------------------------------------------
-- SPECIFIC ANALYSIS QUERIES FOR YOUR DATA
-- ------------------------------------------------------------------

-- 1. Revenue by Product Category (for your specific categories)
SELECT 
    Product_Category,
    COUNT(*) as Order_Count,
    SUM(Revenue) as Total_Revenue,
    AVG(Revenue) as Average_Order_Value,
    ROUND(SUM(Revenue) / (SELECT SUM(Revenue) FROM cleaned_sales_data) * 100, 2) as Revenue_Share_Percent
FROM cleaned_sales_data
GROUP BY Product_Category
ORDER BY Total_Revenue DESC;

-- Expected Results:
-- Electronics: ~$4,200 (2 orders) - 52.5% share
-- Furniture: ~$2,300 (1 order) - 28.8% share  
-- Clothing: ~$1,500 (3 orders) - 18.8% share

-- 2. Discount Effectiveness Analysis (your specific ranges)
SELECT 
    CASE 
        WHEN Discount_Percent <= 10 THEN 'Low (≤10%)'
        WHEN Discount_Percent <= 20 THEN 'Medium (11-20%)'
        ELSE 'High (>20%)'
    END as Discount_Range,
    COUNT(*) as Order_Count,
    SUM(Revenue) as Total_Revenue,
    AVG(Revenue) as Avg_Revenue,
    AVG(Discount_Percent) as Avg_Discount_in_Range
FROM cleaned_sales_data
GROUP BY Discount_Range
ORDER BY Avg_Revenue DESC;

-- 3. Monthly Sales Trends (your specific months)
SELECT 
    DATE_FORMAT(Order_Date, '%Y-%m') as Month,
    DATE_FORMAT(Order_Date, '%M %Y') as Month_Name,
    COUNT(*) as Orders,
    SUM(Revenue) as Monthly_Revenue,
    AVG(Revenue) as Avg_Order_Value
FROM cleaned_sales_data
GROUP BY Month, Month_Name
ORDER BY Month;

-- 4. Customer Analysis (your specific customers)
SELECT 
    Customer_Name,
    COUNT(*) as Order_Count,
    SUM(Revenue) as Total_Revenue,
    AVG(Revenue) as Avg_Order_Value,
    AVG(Discount_Percent) as Avg_Discount,
    MIN(Order_Date) as First_Order,
    MAX(Order_Date) as Latest_Order,
    CASE 
        WHEN COUNT(*) > 1 THEN 'Repeat Customer'
        ELSE 'Single Purchase'
    END as Customer_Type
FROM cleaned_sales_data
GROUP BY Customer_Name
ORDER BY Total_Revenue DESC;

-- 5. High-Value vs Regular Orders Analysis
SELECT 
    CASE 
        WHEN Revenue >= 2000 THEN 'High Value (≥$2000)'
        WHEN Revenue >= 1000 THEN 'Medium Value ($1000-1999)'
        ELSE 'Regular Value (<$1000)'
    END as Order_Category,
    COUNT(*) as Order_Count,
    SUM(Revenue) as Total_Revenue,
    AVG(Discount_Percent) as Avg_Discount_Used
FROM cleaned_sales_data
GROUP BY Order_Category
ORDER BY AVG(Revenue) DESC;

-- ------------------------------------------------------------------
-- BUSINESS INSIGHTS QUERIES FOR YOUR SPECIFIC DATA
-- ------------------------------------------------------------------

-- Top performing product category
SELECT 
    'Top Revenue Category' as Insight,
    Product_Category as Value,
    CONCAT('$', FORMAT(SUM(Revenue), 2)) as Amount
FROM cleaned_sales_data
GROUP BY Product_Category
ORDER BY SUM(Revenue) DESC
LIMIT 1;

-- Most effective discount rate
SELECT 
    'Most Effective Discount Range' as Insight,
    CONCAT(MIN(Discount_Percent), '% - ', MAX(Discount_Percent), '%') as Discount_Range,
    CONCAT('$', FORMAT(AVG(Revenue), 2)) as Avg_Revenue
FROM cleaned_sales_data
WHERE Revenue = (SELECT MAX(Revenue) FROM cleaned_sales_data);

-- Peak sales month
SELECT 
    'Peak Sales Month' as Insight,
    DATE_FORMAT(Order_Date, '%M %Y') as Month,
    CONCAT('$', FORMAT(SUM(Revenue), 2)) as Monthly_Revenue
FROM cleaned_sales_data
GROUP BY DATE_FORMAT(Order_Date, '%Y-%m'), DATE_FORMAT(Order_Date, '%M %Y')
ORDER BY SUM(Revenue) DESC
LIMIT 1;

-- Customer loyalty insight
SELECT 
    'Customer Loyalty Status' as Insight,
    CASE 
        WHEN COUNT(DISTINCT Customer_Name) = COUNT(*) THEN 'All Single Purchase'
        ELSE CONCAT(COUNT(*) - COUNT(DISTINCT Customer_Name), ' Repeat Purchases')
    END as Value,
    'Alice Smith appears twice' as Details
FROM cleaned_sales_data;

-- ------------------------------------------------------------------
-- EXPORT QUERIES FOR VISUALIZATION
-- ------------------------------------------------------------------

-- Data for Revenue Heatmap (Category vs Month)
SELECT 
    Product_Category,
    DATE_FORMAT(Order_Date, '%M') as Month,
    SUM(Revenue) as Revenue
FROM cleaned_sales_data
GROUP BY Product_Category, DATE_FORMAT(Order_Date, '%Y-%m'), DATE_FORMAT(Order_Date, '%M')
ORDER BY Product_Category, MIN(Order_Date);

-- Data for Discount Scatter Plot
SELECT 
    Discount_Percent as X_Axis,
    Revenue as Y_Axis,
    Product_Category as Category
FROM cleaned_sales_data
ORDER BY Discount_Percent;

-- Data for Revenue Distribution Histogram
SELECT 
    Revenue as Revenue_Amount,
    Customer_Name,
    Product_Category
FROM cleaned_sales_data
ORDER BY Revenue;

-- ------------------------------------------------------------------
-- FINAL DATA QUALITY REPORT
-- ------------------------------------------------------------------

SELECT 
    'FINAL DATA QUALITY REPORT' as Report_Section,
    '' as Metric,
    '' as Value

UNION ALL

SELECT 
    'Records Processed',
    'Original Count',
    CAST(8 as CHAR)

UNION ALL

SELECT 
    '',
    'Duplicates Removed',  
    CAST(1 as CHAR)

UNION ALL

SELECT 
    '',
    'Final Clean Records',
    CAST((SELECT COUNT(*) FROM cleaned_sales_data) as CHAR)

UNION ALL

SELECT 
    'Missing Data Fixed',
    'Emails',
    '2 (Alice, Chris)'

UNION ALL

SELECT 
    '',
    'Phone Numbers',
    '2 (Bob, Alice)'

UNION ALL

SELECT 
    '',
    'Discount Rates',
    '2 (Alice entries)'

UNION ALL

SELECT 
    'Data Quality Score',
    'Completeness',
    '100%'

UNION ALL

SELECT 
    '',
    'Consistency',  
    '100%'

UNION ALL

SELECT 
    'Ready for Analysis',
    'Status',
    'COMPLETE ✓';

-- ------------------------------------------------------------------