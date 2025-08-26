-- post_load_transforms.sql
USE churn_project;

-- Clean / convert TotalCharges
UPDATE customers SET TotalCharges = NULL WHERE TRIM(TotalCharges) = '' OR TotalCharges IS NULL;
ALTER TABLE customers MODIFY COLUMN TotalCharges DECIMAL(10,2);

-- Engineered table
DROP TABLE IF EXISTS customers_clean;
CREATE TABLE customers_clean AS
SELECT
  customerID,
  gender,
  CASE WHEN SeniorCitizen = 1 THEN 'Senior' ELSE 'Non-Senior' END AS age_group,
  COALESCE(Partner, 'No')     AS Partner,
  COALESCE(Dependents, 'No')  AS Dependents,
  tenure,
  Contract,
  PaperlessBilling,
  PaymentMethod,
  MonthlyCharges,
  TotalCharges,
  CASE WHEN Contract = 'Month-to-month' THEN 1 ELSE 0 END AS is_monthly,
  CASE WHEN LOWER(PaymentMethod) LIKE '%automatic%' THEN 1 ELSE 0 END AS auto_pay,
  CASE
    WHEN tenure < 6  THEN '0-5'
    WHEN tenure < 12 THEN '6-11'
    WHEN tenure < 24 THEN '12-23'
    WHEN tenure < 36 THEN '24-35'
    ELSE '36+'
  END AS tenure_bucket,
  CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END AS churn
FROM customers;

-- Rule-based score for comparison with ML
ALTER TABLE customers_clean ADD COLUMN IF NOT EXISTS churn_score FLOAT;
UPDATE customers_clean
SET churn_score =
  (CASE WHEN is_monthly = 1 THEN 0.45 ELSE 0 END) +
  (CASE WHEN auto_pay  = 0 THEN 0.30 ELSE 0 END) +
  (CASE WHEN tenure < 12 THEN 0.25 ELSE 0 END);
