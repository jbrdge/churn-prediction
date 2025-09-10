-- 010_validation.sql
-- Validation checks for customers, churn_labels
-- Assumed schema:
--   customers(customer_id PK, ...)
--   churn_labels(customer_id FK, label boolean, label_date date)
\echo '--- [V1] Row counts by table'
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM churn.customers
UNION ALL
SELECT 'churn_labels', COUNT(*) FROM churn.churn_labels
ORDER BY table_name;

\echo '--- [V2] Orphaned labels (labels without a matching customer) — should be 0'
SELECT COUNT(*) AS orphan_labels
FROM churn.churn_labels l
LEFT JOIN churn.customers c USING (customer_id)
WHERE c.customer_id IS NULL;

\echo '--- [V3] Churn snapshot on most recent label_date'
WITH latest AS (SELECT MAX(label_date) AS d FROM churn.churn_labels)
SELECT
  (SELECT d FROM latest)                                       AS latest_label_date,
  COUNT(*) FILTER (WHERE label = TRUE)  AS churn_true_count,
  COUNT(*) FILTER (WHERE label = FALSE) AS churn_false_count,
  COUNT(*)                               AS total_rows_on_latest
FROM churn.churn_labels
WHERE label_date = (SELECT d FROM latest);
