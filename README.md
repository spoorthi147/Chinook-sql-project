# Chinook Music Store: SQL Analysis

A SQL analysis of the **Chinook** digital music store database, covering customers, invoices, tracks, albums, artists and genres. The project answers 12 objective and 11 subjective business questions on sales, customer behaviour, churn, regional markets and product affinity.

## Project Overview

Chinook is a sample database for a digital music store. In this project I used SQL to:

- Check data quality (duplicates and missing values)
- Find top-selling tracks, artists and genres, especially in the USA
- Break down customers and revenue by country, state and city
- Study purchasing behaviour, customer lifetime patterns and churn
- Find genres, artists and albums that are bought together, to guide cross-selling
- Compare markets by region and identify at-risk customers

## Tools Used

- **SQL (MySQL)**: joins, CTEs, window functions (`ROW_NUMBER`, `RANK`), aggregations, `CASE` logic, date functions
- **Microsoft Word**: written report with query outputs and explanations
- **Microsoft PowerPoint**: presentation of key findings

## Repository Structure

```
chinook-sql-project/
├── README.md
├── .gitignore
├── sql/
│   └── chinook_queries.sql
└── docs/
    ├── Chinook_Project_Report_Spoorthi.docx
    └── Chinook_Project_Presentation_Spoorthi.pptx
```

| File | Description |
|------|-------------|
| `sql/chinook_queries.sql` | All SQL queries for the objective (O1–O12) and subjective (S1–S11) questions |
| `docs/Chinook_Project_Report_Spoorthi.docx` | Report with the questions, outputs and written explanations |
| `docs/Chinook_Project_Presentation_Spoorthi.pptx` | Presentation summarising the approach and insights |

## Questions Covered

**Objective**

| # | Topic |
|---|-------|
| O1 | Missing values and duplicates |
| O2 | Top tracks and artists in the USA |
| O3 | Customer breakdown by location |
| O4 | Revenue and invoices by country, state, city |
| O5 | Top 5 customers per country |
| O6 | Top track for each customer |
| O7 | Purchasing patterns (order value, frequency) |
| O8 | Customer churn rate |
| O9 | Genre share of USA sales |
| O10 | Customers buying from 3+ genres |
| O11 | Genre ranking in the USA |
| O12 | Customers inactive for 3+ months |

**Subjective**

| # | Topic |
|---|-------|
| S1 | Albums to promote in the USA |
| S2 | Top genres outside the USA |
| S3 | Long-term vs newer customer behaviour |
| S4 | Product affinity (genres, artists, albums) |
| S5 | Regional market analysis |
| S6 | Customer risk profiling |
| S7 | Customer lifetime value |
| S8 | Measuring promotional campaign impact |
| S9 | Approaching the data without set questions |
| S10 | Altering the album table (`ReleaseYear`) |
| S11 | Average spend and tracks per customer by country |

## Key Insights

- **Data quality:** No duplicate primary keys were found. The NULLs in fields like company, fax, state and composer are genuine optional values, so I left them as NULL instead of imputing.
- **Rock leads:** Rock is the top genre in the USA and in 22 of the 23 other countries with sales. Argentina is the exception, where Alternative & Punk ranks first.
- **Top USA albums:** *Are You Experienced?*, *From The Muddy Banks Of The Wishkah [live]* and *The Doors* are the highest-revenue albums in the USA, all Rock.
- **USA is the biggest market:** The USA generated the highest country-level revenue ($1,040.49 across 131 invoices).
- **Cross-selling:** Rock and Metal are bought together most often (268 invoices), a good candidate for cross-recommendations.
- **Customer loyalty:** Long-term (3+ years) and mid-term (2–3 years) customers behave similarly, at about 3 orders per year. The dataset has no customers under 2 years, so new-customer retention cannot be compared directly.
- **Data limits:** The customer table has no age or gender, and the database has no record-label or campaign data, so some questions are answered with the closest available proxy (for example, purchase recency for churn risk).

## How to Run

1. Install MySQL and load the Chinook database (available from the [official Chinook repository](https://github.com/lerocha/chinook-database)).
2. Open `sql/chinook_queries.sql` in MySQL Workbench or any MySQL client.
3. Make sure the database is named `chinook` (the script starts with `USE chinook;`).
4. Run the queries one section at a time.

> **Note:** S10 runs an `ALTER TABLE` that adds a `ReleaseYear` column to the `album` table. Run it only on a copy of the database if you want to keep the original unchanged.

## Author

**Spoorthi**
Aspiring Data Analyst | SQL · Excel · Python
