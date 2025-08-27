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
-- results suggest ~6.7% of customers who are not monthly will churn,
-- and ~42.7% of monthly customers will churn

-- 1.4 Simple SQL-only risk score (transparent "rule-based")
ALTER TABLE customers_clean ADD COLUMN churn_score FLOAT;

UPDATE churn_project.customers_clean
SET churn_score =
    (CASE WHEN is_monthly = 1 THEN 0.45 ELSE 0 END) +
    (CASE WHEN auto_pay = 0 THEN 0.30 ELSE 0 END) +
    (CASE WHEN tenure < 12 THEN 0.25 ELSE 0 END);

SELECT * FROM churn_project.customers_clean
LIMIT 5;

-- 1.5 Logistic Regression - export features to CSV
SHOW VARIABLES LIKE 'secure_file_priv';

SELECT 
    customerID,
    is_monthly,
    auto_pay,
    CASE WHEN tenure < 12 THEN 1 ELSE 0 END AS short_tenure,
    churn
INTO OUTFILE '/var/lib/mysql-files/churn_regression.csv'  -- adjust path per your setup
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM customers_clean;

-- User setup for external connections (optional)
CREATE USER 'churn'@'%' IDENTIFIED BY 'churnpw';
GRANT ALL PRIVILEGES ON churn_project.* TO 'churn'@'%';
FLUSH PRIVILEGES;
