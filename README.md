# Cowrywise Data Analytics Assessment

This repository contains a series of PostgreSQL query solutions to some business-analytics questions. Each query lives in its own `.sql` file and is accompanied by detailed explanations below. Note that the database in connection to these solutions isn't in this repo to align with submission instructions but can be provided on request. Thank you.

---

## Table of Contents

1. [Introduction](#intro)
2. [Question 1: Customers with Funded Savings & Investments](#q1) 
3. [Question 2: Transaction Frequency Categories](#q2)  
4. [Question 3: Inactive Accounts (No Transactions in 365 Days)](#q3)  
5. [Question 4: Customer Lifetime Value (CLV)](#q4)  

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
