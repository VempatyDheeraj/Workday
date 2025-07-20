-- Insert data less than current date 
-- 1. Expire old records if there are changes
UPDATE salesforce-465614.cust_analytics.dim_customers AS tgt
SET is_current = FALSE,
    end_date = CURRENT_DATE()
FROM salesforce-465614.cust_analytics.stage_customers AS src
WHERE tgt.customer_id = src.customer_id
  AND tgt.is_current = TRUE
  AND (
      tgt.name        != src.name OR
      tgt.email       != src.email OR
      tgt.age         != src.age OR
      tgt.signup_date != src.signup_date
  )
  AND DATE(src.signup_date) < CURRENT_DATE()
  AND src.age >= 0 AND src.age <= 100;

-- 2. Insert new or changed records as current
INSERT INTO salesforce-465614.cust_analytics.dim_customers (
    customer_id, name, email, age, signup_date, is_current, effective_date, end_date
)
SELECT
    src.customer_id,
    src.name,
    src.email,
    src.age,
    src.signup_date,
    TRUE AS is_current,
    CURRENT_DATE() AS effective_date,
    NULL AS end_date
FROM salesforce-465614.cust_analytics.stage_customers AS src
LEFT JOIN salesforce-465614.cust_analytics.dim_customers AS tgt
  ON src.customer_id = tgt.customer_id AND tgt.is_current = TRUE
WHERE
    (tgt.customer_id IS NULL -- new customer
     OR tgt.name        != src.name
     OR tgt.email       != src.email
     OR tgt.age         != src.age
     OR tgt.signup_date != src.signup_date)
    AND DATE(src.signup_date) < CURRENT_DATE()
    AND src.age >= 15 AND src.age <= 100;

