# Cowrywise Data Analytics Assessment

This repository contains a series of PostgreSQL query solutions to some business-analytics questions. Each query lives in its own `.sql` file and is accompanied by detailed explanations below. Note that the database in connection to these solutions isn't in this repo to align with submission instructions but can be provided on request. Thank you.

---

## Table of Contents

1. [Introduction](#intro)
2. [Question 1: Customers with Funded Savings & Investments](#q1) 
3. [Question 2: Transaction Frequency Categories](#q2)  
4. [Question 3: Inactive Accounts (No Transactions in 365 Days)](#q3)  
5. [Question 4: Customer Lifetime Value (CLV)](#q4)
6. [Credits](#credits)

---

<a name="intro"></a>
## Introduction: Setting up a confirmatory system for attempted solutions

This was neccessary to validate the queries to serve as solutions to the business enqueries.

### Challenges
* The database file was written in mySQL DDL as opposed to Postgresql which I'm more familiar with
* Very few SQL playgorunds supported importing spreadsheet files.
* Some data wrangling was required for consistency.

### Approach
* I started out by downloading postgreSQL 17 with its accompanying pgAdmin4 and setting up its querying environments.
* Next, I wrote some python code to convert the ddl package into its component tables and stored them in seperate csv files.
* For some tables, I altered the options to import null values correctly
* For others, I used the psql tool to import the csv files. This was especially useful for cases with escape cahracters.
* Still, others imports required some data cleaning of the csv file to improve consistency with quotes and comma seperation.

---

<a name="q1"></a>
## Question 1: Customers with Funded Savings & Investments
I was required to write a query to find customers with at least one funded savings plan and one funded investment plan, sorted by total deposits.

### Approach
- CTE inflows
  * Summed confirmed_amount per (owner_id, plan_id).

- CTE funded_plans
  * Filtered inflows to those with total_inflow > 0.

- CTE plan_types
  * Labeled plans via flags in plans_plan: is_regular_savings = 1 → “savings”; is_a_fund = 1 → “investment”

- CTE customer_plan_types
  * Joined funded plans to their types, discarded NULL types.

- CTE customer_type_counts
  * Counted distinct savings and investment plan IDs per customer.

- CTE total_customer_deposits
  * Summed all total_inflow per customer and ROUND()ed to two decimals.

- Final SELECT
  * Joined counts & deposits, filtered for customers having ≥ 1 savings and ≥ 1 investment, joined names, and ordered by deposits descending.

 ### Challenges & Resolution
-  Pivoting plan counts from rows into two columns (savings_count, investment_count).
 * Solution: Used COUNT(DISTINCT CASE WHEN plan_type = … THEN plan_id END) inside a grouped query.

- Matching foreign-key names: Ensured ssa.plan_id and w.plan_id aligned with the schema rather than savings_id.

 ---

<a name="q2"></a>
## Question 2: Transaction Frequency Categories
The goal was to classify customers as High/Medium/Low frequency based on their average monthly transactions.

### Approach
- CTE transaction_counts
 * Counted total transactions per customer.

- Captured first and last month of activity via DATE_TRUNC('month', MIN/MAX(created_on)).
 * CTE avg_transactions

- Calculated the number of months active with DATE_PART arithmetic + GREATEST(...,1) guard.
 * Computed avg_transactions_per_month → ROUND((total_transactions / total_months)::numeric, 2).

- Final SELECT
 * Assigned frequency_category via a CASE on the rounded average.
 * Aggregated counts and averaged the per-customer averages to produce: frequency_category | customer_count | avg_transactions_per_month

### Challenges And Resolution
- Division by zero if a customer had only one month of activity.
 * Solution: Used GREATEST(calculated_months, 1) to enforce a minimum of 1 month.

- Type mismatches in ROUND().
 * Solution: Cast the expression to numeric before rounding.

---

<a name="q3"></a>
## Question 3: Inactive Accounts (No Transactions in 365 Days)
The goal was to find all active accounts (savings or investments) with no transactions in the last year.

### Approach
- CTE last_tx
 * Retrieved each account’s most recent transaction date.

- Main Query
 * Left-joined plans_plan to last_tx so accounts with zero transactions still appear.
 * Computed inactivity_days by subtracting the last_transaction_date (or created_on) from CURRENT_DATE.
 * Filtered for status = active (or is_deleted = 0) and (last_tx < current_date - INTERVAL '365 days' OR last_tx IS NULL)

### Challenges & Resolution
- Date arithmetic quirks: Initially tried EXTRACT(DAY FROM date1 - date2) which fails when the difference is an integer.
 * Solution: Subtracted dates directly → yields an integer for days difference.

---

<a name="q4"></a>
## Question 4: Customer Lifetime Value (CLV)
I was required to calculate for each customer, account tenure (months since signup), total transactions and estimated CLV = (transactions/tenure) * 12 * avg_profit_per_transaction - assuming profit per transaction is 0.1%.

### Approach
- CTE user_tx
 * Aggregated COUNT(*) → total_transactions and AVG(amount) → avg_tx_value.

- CTE user_stats
 * Computed tenure in months:
 ```
 GREATEST(
   (year_diff * 12 + month_diff),
   1
 ) AS tenure_months
 ```
 * Joined to bring in total_transactions and avg_tx_value.

- Final SELECT
 * Calculated transactions-per-month → total_transactions / tenure_months.
 * Multiplied by 12 and by profit per transaction (avg_tx_value * 0.001).
 * Rounded to two decimals.

### Challenges & Resolution
- ROUND(double precision, integer) error: Found that ROUND() expects a numeric first argument.
 * Solution: Cast intermediate result to numeric before applying ROUND(...,2)

---

<a name="credits"></a>
## Credits: Research and help Links
These helped with refreshing my mind on how to use certain functions in producing envisioned results.

- [Coalesce]("https://www.geeksforgeeks.org/postgresql-coalesce/")
- [Joins]("https://www.geeksforgeeks.org/postgresql-joins/")
- [Importing a CSV file ]("https://www.geeksforgeeks.org/postgresql-import-csv-file-into-table/")
