-- STEP 1: Aggregating per-customer transactions and their average transaction amount
WITH user_tx AS (
  SELECT
    ssa.owner_id,                     -- Customer ID
    COUNT(*)                AS total_transactions,  -- Total number of transactions they’ve made
    AVG(ssa.amount)         AS avg_tx_value         -- Average value of their transactions
  FROM savings_savingsaccount ssa
  GROUP BY ssa.owner_id               -- One row per customer
),

-- STEP 2: Computing each customer’s tenure and attaching their transaction aggregates
user_stats AS (
  SELECT
    u.id                                    AS customer_id,    -- User’s unique ID
    CONCAT(u.first_name, ' ', u.last_name) AS name,           -- Full name

    -- Calculate tenure in months since signup:
    --   (current year * 12 + current month)
    --   minus
    --   (signup year * 12 + signup month)
    -- Use GREATEST(..., 1) to ensure at least 1 month
    GREATEST(
      (DATE_PART('year', CURRENT_DATE)::int * 12
       + DATE_PART('month', CURRENT_DATE)::int)
      -
      (DATE_PART('year', u.created_on)::int * 12
       + DATE_PART('month', u.created_on)::int),
      1
    )                                       AS tenure_months,

    COALESCE(ut.total_transactions, 0)      AS total_transactions,  -- Zero if no tx
    COALESCE(ut.avg_tx_value, 0)::numeric   AS avg_tx_value         -- Zero if no tx
  FROM users_customuser u
  LEFT JOIN user_tx ut
    ON ut.owner_id = u.id                   -- Bring in their transaction stats (if any)
)

-- STEP 3: Calculating Estimated CLV and ordering the results
SELECT
  customer_id,       -- User’s ID
  name,              -- User’s full name
  tenure_months,     -- Months since signup
  total_transactions,-- Total # of transactions

  -- CLV formula:
  --   (transactions per month) * 12 * (profit per tx)
  --   where profit per tx = avg_tx_value * 0.001 (i.e. 0.1%)
  ROUND(
    (
      (total_transactions::numeric / tenure_months) * 12
    )
    * (avg_tx_value * 0.001)
    ::numeric,  
    2           
  ) AS estimated_clv

FROM user_stats
ORDER BY estimated_clv DESC;  -- Sort highest‐value customers first

