-- STEP 1: For each plan, find the date of its most recent transaction
WITH last_tx AS (
  SELECT
    ssa.savings_id                AS plan_id,                  -- FK to plans_plan.id
    MAX(ssa.created_on)::date     AS last_transaction_date     -- latest transaction date
  FROM savings_savingsaccount ssa
  GROUP BY ssa.savings_id
)

-- STEP 2: Select active plans with no transactions in the past 365 days
SELECT
  p.id                           AS plan_id,                  -- plan/account identifier
  p.owner_id                     AS owner_id,                 -- customer/owner identifier

  -- Deduction of type of inactive account
  CASE
    WHEN p.is_regular_savings = 1  THEN 'Savings'
    WHEN p.is_fixed_investment = 1 THEN 'Investment'
    ELSE 'Other'
  END                             AS type,

  lt.last_transaction_date,                                  -- last transaction date (or NULL)

  -- Count number of inactivity days:
  (CURRENT_DATE
   - COALESCE(lt.last_transaction_date, p.created_on::date)
  )::int                         AS inactivity_days

FROM plans_plan p
LEFT JOIN last_tx lt
  ON lt.plan_id = p.id

-- Only include “active” plans
WHERE p.is_deleted = 0
  AND (
    -- either last transaction was over a year ago
    lt.last_transaction_date < CURRENT_DATE - INTERVAL '365 days'
    -- or there have been no transactions at all
    OR lt.last_transaction_date IS NULL
  )
-- Sort from highest inactivity to least
ORDER BY inactivity_days DESC;

