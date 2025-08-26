DROP DATABASE IF EXISTS churn_project;
CREATE DATABASE churn_project;
DROP TABLE IF EXISTS churn_project.customers;
USE churn_project;

-- 1.0 CREATE TABLE customers, then import data
CREATE TABLE customers (
	customerID VARCHAR(20) PRIMARY KEY,
    gender VARCHAR(10),
    SeniorCitizen TINYINT,
    Partner VARCHAR(10),
    Dependents VARCHAR(10),
    tenure INT,
    PhoneService VARCHAR(10),
    MultipleLines VARCHAR(30),
    InternetService VARCHAR(30),
    OnlineSecurity VARCHAR(30),
    OnlineBackup VARCHAR(30),
    DeviceProtection VARCHAR(30),
    TechSupport VARCHAR(30),
    StreamingTV VARCHAR(30),
    StreamingMovies VARCHAR(30),
    Contract VARCHAR(30),
    PaperlessBilling VARCHAR(10),
    PaymentMethod VARCHAR(50),
    MonthlyCharges DECIMAL(10,2),
    TotalCharges VARCHAR(20),
    Churn VARCHAR(10)
);

USE churn_project;

-- 1.1 Normalize blanks -> NULL, convert TotalCharges to DECIMAL
UPDATE customers
SET TotalCharges = NULL
WHERE TRIM(TotalCharges) = '' OR TotalCharges IS NULL;

ALTER TABLE customers
MODIFY COLUMN TotalCharges DECIMAL(10,2);

-- 1.1a Read Table
SELECT * from customers
LIMIT 0,5;


-- 1.2 Build a clean/engineered table for analytics
DROP TABLE IF EXISTS customers_clean;
CREATE TABLE customers_clean AS
SELECT
	customerID,
    gender,
    CASE WHEN SeniorCitizen = 1 THEN 'Senior' ELSE 'Non-Senior' END AS age_group,
    COALESCE(Partner, 'No')		AS Partner,
    COALESCE(Dependents, 'No') 	AS Dependents,
    tenure,
    Contract, 
    PaperlessBilling,
    PaymentMethod,
    MonthlyCharges,
    TotalCharges,
    CASE WHEN Contract = 'Month-to-month' THEN 1 ELSE 0 END AS is_monthly,
    CASE WHEN LOWER(PaymentMethod) LIKE '%automatic%' THEN 1 ELSE 0 END AS auto_pay,
    CASE
		WHEN tenure < 6 THEN '0-5'
        WHEN tenure < 12 THEN '6-11'
        WHEN tenure < 24 THEN '12-23'
        WHEN tenure < 36 THEN '24-35'
        ELSE '36+'
	END AS tenure_bucket,
    CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END AS churn
FROM customers;
    
-- 3.3 Basic Sanity checks
-- Basic table check
SELECT * FROM churn_project.customers_clean
WHERE auto_pay=1
LIMIT 5;

-- Overall churn rate
SELECT ROUND(100 * AVG(churn),2) AS churn_rate_pct FROM customers_clean;

-- Churn by contract type
SELECT is_monthly, COUNT(*) AS n, ROUND(100 * AVG(churn),2) AS churn_rate_pct
FROM customers_clean GROUP BY is_monthly;
-- results suggest ~6.7% of customers who are not monthly will churn, and ~42.7% of monthly customers will churn

-- 1.4 Simple SQL-only risk score (transparent "rule-based")
-- Add churn score column 
ALTER TABLE customers_clean ADD COLUMN churn_score FLOAT;

-- Use a weighted rule-of-thumb for churn prediction
/* 
	Here, I will give arbitrary wieghts to the features:
    0.45 for monthly customers, 
    0.3 for aut_pay, and
    0.25 for less than 12 tenure
    then afterward will run regression analysis
	These values are weights for the categories, 
    ie a customer who is in all three categories will have
    weight 1.0 for their likelihood of churn
*/
UPDATE churn_project.customers_clean
SET churn_score =
	(CASE WHEN is_monthly = 1 THEN 0.45 ELSE 0 END) +
    (CASE WHEN auto_pay = 0 THEN 0.30 ELSE 0 END) +
    (CASE WHEN tenure < 12 THEN 0.25 ELSE 0 END);
    
SELECT * FROM churn_project.customers_clean
LIMIT 5;    
    
-- 1.5 Logistic Regression
-- First, Get the data out of SQL

/*
	For Windows save to secure file location, then manually move.
	Since this will be ported into python anyway, another option
    is to just upload the original database into python and then modify
    the table afterward.
*/
SHOW VARIABLES LIKE 'secure_file_priv';

SELECT 
	customerID,
	is_monthly,
    auto_pay,
    CASe WHEN tenure < 12 THEN 1 ELSE 0 END AS short_tenure,
    churn
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/churn_regression.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM customers_clean;

    
    
    
    
    
    
    
    
    
    
    