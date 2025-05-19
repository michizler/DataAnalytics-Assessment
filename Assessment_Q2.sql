-- Step 1: Calculate total transactions and activity period (first and last month) per customer
WITH transaction_counts AS (
  SELECT
    ssa.owner_id,  -- Customer ID
    COUNT(*) AS total_transactions,  -- Total number of transactions
    DATE_TRUNC('month', MIN(ssa.created_on)) AS first_month,  -- First month of activity
    DATE_TRUNC('month', MAX(ssa.created_on)) AS last_month    -- Last month of activity
  FROM savings_savingsaccount ssa
  GROUP BY ssa.owner_id
),

-- Step 2: Calculating average transactions per month, per-customer
avg_transactions AS (
  SELECT
    tc.owner_id,
    tc.total_transactions,

    -- Calculated the number of months between the first and last month (inclusive),
    -- This part is to avoid divide-by-zero errors
    GREATEST(
      (DATE_PART('year', tc.last_month)::int * 12 + DATE_PART('month', tc.last_month)::int) -
      (DATE_PART('year', tc.first_month)::int * 12 + DATE_PART('month', tc.first_month)::int) + 1,
      1
    ) AS total_months,

    -- Average transactions per month, rounded to 2 decimal places
    ROUND(
      (
        tc.total_transactions::numeric /
        GREATEST(
          (DATE_PART('year', tc.last_month)::int * 12 + DATE_PART('month', tc.last_month)::int) -
          (DATE_PART('year', tc.first_month)::int * 12 + DATE_PART('month', tc.first_month)::int) + 1,
          1
        )
      )::numeric,
      2
    ) AS avg_transactions_per_month
  FROM transaction_counts tc
  -- Join to get user names
  JOIN users_customuser u ON u.id = tc.owner_id
),

-- Step 3: Categorize each customer based on their average transaction frequency
categorized AS (
  SELECT
    owner_id,
    -- Frequency category is based on stipulated thresholds:
    -- 10 or more: High, 3 to 9: Medium, less than 3: Low
    CASE
      WHEN avg_transactions_per_month >= 10 THEN 'High Frequency'
      WHEN avg_transactions_per_month BETWEEN 3 AND 9 THEN 'Medium Frequency'
      ELSE 'Low Frequency'
    END AS frequency_category,
    avg_transactions_per_month
  FROM avg_transactions
)

-- Step 4: Aggregate the categorized data to get final summary
SELECT
  frequency_category,  -- High, Medium, or Low frequency
  COUNT(*) AS customer_count,  -- Number of customers in each category
  ROUND(AVG(avg_transactions_per_month)::numeric, 2) AS avg_transactions_per_month  -- Average of the customers' averages
FROM categorized
GROUP BY frequency_category
-- Sort the output for readability: High → Medium → Low
ORDER BY
  CASE frequency_category
    WHEN 'High Frequency' THEN 1
    WHEN 'Medium Frequency' THEN 2
    WHEN 'Low Frequency' THEN 3
  END;

