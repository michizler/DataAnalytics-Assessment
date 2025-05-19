-- STEP 1: Aggregating confirmed inflows per plan per customer
WITH inflows AS (
  SELECT
    ssa.owner_id,                       -- Customer ID (FK to users_customuser.id)
    ssa.plan_id,                        -- Plan ID (FK to plans_plan.id)
    SUM(ssa.confirmed_amount) AS total_inflow  -- Total amount deposited into this plan
  FROM savings_savingsaccount ssa
  GROUP BY
    ssa.owner_id,
    ssa.plan_id
),

-- STEP 2: Filtering for “funded” plans (those with any positive inflow)
funded_plans AS (
  SELECT
    owner_id,
    plan_id
  FROM inflows
  WHERE total_inflow > 0              -- including plans only where the customer has deposited funds
),

-- STEP 3: Determine plan’s type
plan_types AS (
  SELECT
    p.id            AS plan_id,        -- Plan ID
    CASE
      WHEN p.is_regular_savings = 1 THEN 'savings'     -- indicating a Savings plan
      WHEN p.is_a_fund          = 1 THEN 'investment'  -- indicating an Investment plan
      ELSE NULL
    END             AS plan_type       -- ‘savings’ or ‘investment’
  FROM plans_plan p
),

-- STEP 4: Joining funded plans to their types
customer_plan_types AS (
  SELECT
    fp.owner_id,                       -- Customer ID
    pt.plan_type                       -- ‘savings’ or ‘investment’
  FROM funded_plans fp
  JOIN plan_types pt
    ON pt.plan_id = fp.plan_id
  WHERE
    pt.plan_type IS NOT NULL           -- Here I'm excluding any plans that are neither savings nor investment
),

-- STEP 5: Count distinct funded plans of each customer type
customer_type_counts AS (
  SELECT
    owner_id,
    COUNT(DISTINCT CASE WHEN plan_type = 'savings'    THEN owner_id || plan_type END)     AS savings_count,
    COUNT(DISTINCT CASE WHEN plan_type = 'investment' THEN owner_id || plan_type END)     AS investment_count
  FROM customer_plan_types
  GROUP BY
    owner_id
),

-- STEP 6: Summing total confirmed inflows across all plans for each customer
total_customer_deposits AS (
  SELECT
    owner_id,
    ROUND(SUM(total_inflow)::numeric, 2) AS total_deposits  -- Rounded to two decimal places
  FROM inflows
  GROUP BY
    owner_id
)

-- STEP 7: Select customers with at least one Savings and one Investment plan
SELECT
  u.id                                    AS owner_id,        -- Customer ID
  CONCAT(u.first_name, ' ', u.last_name)  AS name,            -- Customer full name
  ctc.savings_count,                                           -- Number of distinct Savings plans funded
  ctc.investment_count,                                       -- Number of distinct Investment plans funded
  tcd.total_deposits                                          -- Total amount deposited across all plans
FROM customer_type_counts ctc
JOIN total_customer_deposits tcd
  ON tcd.owner_id = ctc.owner_id
JOIN users_customuser u
  ON u.id = ctc.owner_id
WHERE
  ctc.savings_count    >= 1            -- Must have funded at least one Savings plan
  AND ctc.investment_count >= 1        -- Must have funded at least one Investment plan
ORDER BY
  tcd.total_deposits DESC;             -- Sort by highest

