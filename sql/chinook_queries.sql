/* =====================================================================
   CHINOOK MUSIC STORE — STUDENT ANSWER TEMPLATE
   ===================================================================== */

USE chinook;


/* =====================================================================
   OBJECTIVE QUESTIONS
   ===================================================================== */

-- O1
-- Does any table have missing values or duplicates? If yes how would you
-- handle it ?
-- To Check for duplicate customer primary keys
SELECT
    customer_id,
    COUNT(*) AS cnt
FROM customer
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- To Count NULL values in selected customer fields
SELECT
    SUM(company IS NULL) AS null_company,
    SUM(state IS NULL) AS null_state,
    SUM(postal_code IS NULL) AS null_postal_code,
    SUM(phone IS NULL) AS null_phone,
    SUM(fax IS NULL) AS null_fax
FROM customer;


-- To Count NULL values in selected track fields
SELECT
    SUM(composer IS NULL) AS null_composer,
    SUM(album_id IS NULL) AS null_album_id,
    SUM(genre_id IS NULL) AS null_genre_id
FROM track;


-- O2
-- Find the top-selling tracks and top artist in the USA and identify their
-- most famous genres.
-- Top 5 selling tracks in the USA
SELECT t.name AS track_name, ar.name AS artist_name, g.name AS genre_name,
       ROUND(SUM(il.unit_price * il.quantity), 2) AS revenue,
       SUM(il.quantity) AS units_sold
FROM invoice_line il
JOIN invoice i       ON il.invoice_id = i.invoice_id
JOIN track t         ON il.track_id = t.track_id
LEFT JOIN album al   ON t.album_id = al.album_id
LEFT JOIN artist ar  ON al.artist_id = ar.artist_id
LEFT JOIN genre g    ON t.genre_id = g.genre_id
WHERE i.billing_country = 'USA'
GROUP BY t.track_id, t.name, ar.name, g.name
ORDER BY revenue DESC, units_sold DESC
limit 5;

-- Top 5 artist in the USA by revenue 
SELECT ar.name AS artist_name,
       ROUND(SUM(il.unit_price * il.quantity), 2) AS revenue,
       SUM(il.quantity) AS units_sold
FROM invoice_line il
JOIN invoice i  ON il.invoice_id = i.invoice_id
JOIN track t    ON il.track_id = t.track_id
JOIN album al   ON t.album_id = al.album_id
JOIN artist ar  ON al.artist_id = ar.artist_id
WHERE i.billing_country = 'USA'
GROUP BY ar.artist_id, ar.name
ORDER BY revenue DESC
limit 5;



-- O3
-- What is the customer demographic breakdown (age, gender, location) of
-- Chinook's customer base?
-- Customers by country/state/city
SELECT country, state, city, COUNT(*) AS customer_count
FROM customer
GROUP BY country, state, city
ORDER BY country, state, city;
 
-- Customers per country
SELECT country, COUNT(*) AS customer_count
FROM customer
GROUP BY country
ORDER BY customer_count DESC;



-- O4
-- Calculate the total revenue and number of invoices for each country, state,
-- and city:
SELECT billing_country AS country, billing_state AS state, billing_city AS city,
       COUNT(*) AS num_invoices,
       ROUND(SUM(total), 2) AS total_revenue
FROM invoice
GROUP BY billing_country, billing_state, billing_city
ORDER BY country, state, city;


-- O5
-- Find the top 5 customers by total revenue in each country
WITH customer_revenue AS (
    SELECT
        c.country,
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        SUM(i.total) AS total_revenue
    FROM customer AS c
    JOIN invoice AS i
        ON c.customer_id = i.customer_id
    GROUP BY
        c.country,
        c.customer_id,
        c.first_name,
        c.last_name
),
ranked_customers AS (
    SELECT
        country,
        customer_name,
        total_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY country
            ORDER BY total_revenue DESC, customer_name
        ) AS rnk
    FROM customer_revenue
)
SELECT
    country,
    customer_name,
    ROUND(total_revenue, 2) AS total_revenue,
    rnk
FROM ranked_customers
WHERE rnk <= 5
ORDER BY country, rnk;


-- O6
-- Identify the top-selling track for each customer
WITH track_sales AS (
    SELECT
        i.customer_id,
        t.name AS track_name,
        SUM(il.quantity) AS units
    FROM invoice AS i
    JOIN invoice_line AS il
        ON i.invoice_id = il.invoice_id
    JOIN track AS t
        ON il.track_id = t.track_id
    GROUP BY
        i.customer_id,
        t.track_id,
        t.name
),
ranked_tracks AS (
    SELECT
        customer_id,
        track_name,
        units,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY units DESC, track_name
        ) AS rnk
    FROM track_sales
)
SELECT
    customer_id,
    track_name,
    units
FROM ranked_tracks
WHERE rnk = 1
ORDER BY customer_id;


-- O7
-- Are there any patterns or trends in customer purchasing behavior (e.g.,
-- frequency of purchases, preferred payment methods, average order value)?
-- Store-wide purchasing averages
WITH invoice_track_counts AS (
    SELECT invoice_id, SUM(quantity) AS tracks_per_invoice
    FROM invoice_line
    GROUP BY invoice_id
),
customer_invoice_counts AS (
    SELECT c.customer_id, COUNT(i.invoice_id) AS invoice_count
    FROM customer AS c
    LEFT JOIN invoice AS i ON i.customer_id = c.customer_id
    GROUP BY c.customer_id
)
SELECT
    (SELECT ROUND(AVG(total), 2) FROM invoice) AS avg_order_value,
    (SELECT ROUND(AVG(invoice_count), 2)
     FROM customer_invoice_counts) AS avg_invoices_per_customer,
    (SELECT ROUND(AVG(tracks_per_invoice), 2)
     FROM invoice_track_counts) AS avg_tracks_per_invoice;


-- Per-customer purchasing behavior profile
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(i.invoice_id) AS num_orders,
    ROUND(AVG(i.total), 2) AS avg_order_value,
    ROUND(SUM(i.total), 2) AS total_spend,
    DATEDIFF(MAX(i.invoice_date), MIN(i.invoice_date)) AS tenure_days
FROM customer AS c
JOIN invoice AS i
    ON c.customer_id = i.customer_id
GROUP BY
    c.customer_id, c.first_name, c.last_name
ORDER BY c.customer_id;


-- O8
-- What is the customer churn rate?
WITH dataset_end AS (
    SELECT MAX(invoice_date) AS end_date
    FROM invoice
),
customer_last_purchase AS (
    SELECT c.customer_id, MAX(i.invoice_date) AS last_purchase_date
    FROM customer AS c
    LEFT JOIN invoice AS i
        ON c.customer_id = i.customer_id
    GROUP BY c.customer_id
)
SELECT
    COUNT(*) AS total_customers, SUM(
        CASE
            WHEN clp.last_purchase_date IS NULL
              OR clp.last_purchase_date < DATE_SUB(de.end_date, INTERVAL 3 MONTH)
            THEN 1 ELSE 0
        END) AS churned_customers,
    ROUND( 100.0 * SUM(
            CASE
                WHEN clp.last_purchase_date IS NULL
                  OR clp.last_purchase_date < DATE_SUB(de.end_date, INTERVAL 3 MONTH)
                THEN 1 ELSE 0
            END) / COUNT(*), 2) AS churn_rate_pct
FROM customer_last_purchase AS clp
CROSS JOIN dataset_end AS de;


-- O9
-- Calculate the percentage of total sales contributed by each genre in the
-- USA and identify the best-selling genres and artists.
WITH genre_revenue AS (
    SELECT
        g.name AS genre, SUM(il.unit_price * il.quantity) AS genre_revenue
    FROM invoice AS i
    JOIN invoice_line AS il ON i.invoice_id = il.invoice_id
    JOIN track AS t ON il.track_id = t.track_id
    JOIN genre AS g ON t.genre_id = g.genre_id
    WHERE i.billing_country = 'USA'
    GROUP BY g.genre_id, g.name
),
usa_total AS (
    SELECT SUM(genre_revenue) AS total_usa_revenue
    FROM genre_revenue
)
SELECT
    gr.genre,
    ROUND(gr.genre_revenue, 2) AS genre_revenue,
    ROUND(100.0 * gr.genre_revenue / ut.total_usa_revenue, 2) AS pct_of_usa_sales
FROM genre_revenue AS gr
CROSS JOIN usa_total AS ut
ORDER BY gr.genre_revenue DESC;


-- O10
-- Find customers who have purchased tracks from at least 3 different genres
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(DISTINCT t.genre_id) AS distinct_genres
FROM customer AS c
JOIN invoice AS i ON c.customer_id = i.customer_id
JOIN invoice_line AS il ON i.invoice_id = il.invoice_id
JOIN track AS t ON il.track_id = t.track_id
GROUP BY
    c.customer_id, c.first_name, c.last_name
HAVING COUNT(DISTINCT t.genre_id) >= 3
ORDER BY c.customer_id;


-- O11
-- Rank genres based on their sales performance in the USA
WITH genre_revenue AS (
    SELECT g.genre_id, g.name AS genre, SUM(il.unit_price * il.quantity) AS revenue
    FROM invoice AS i
    JOIN invoice_line AS il ON i.invoice_id = il.invoice_id
    JOIN track AS t ON il.track_id = t.track_id
    JOIN genre AS g ON t.genre_id = g.genre_id
    WHERE i.billing_country = 'USA'
    GROUP BY g.genre_id, g.name
)
SELECT genre, ROUND(revenue, 2) AS revenue, RANK() OVER (ORDER BY revenue DESC) AS sales_rank
FROM genre_revenue
ORDER BY sales_rank, genre;


-- O12
-- Identify customers who have not made a purchase in the last 3 months
WITH dataset_end AS (
    SELECT MAX(invoice_date) AS end_date
    FROM invoice
),
customer_last_purchase AS (
    SELECT c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name, c.country, MAX(i.invoice_date) AS last_purchase_date
    FROM customer AS c
    LEFT JOIN invoice AS i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.country
)
SELECT
    clp.customer_id, clp.customer_name, clp.country, clp.last_purchase_date
FROM customer_last_purchase AS clp
CROSS JOIN dataset_end AS de
WHERE clp.last_purchase_date IS NULL
   OR clp.last_purchase_date < DATE_SUB(de.end_date, INTERVAL 3 MONTH)
ORDER BY clp.customer_id;



/* =====================================================================
   SUBJECTIVE QUESTIONS
   ===================================================================== */

-- S1
-- Recommend the three albums from the new record label that should be
-- prioritised for advertising and promotion in the USA based on genre
-- sales analysis.
SELECT al.title AS album_title, ar.name AS artist_name, g.name AS genre,
    ROUND(SUM(il.unit_price * il.quantity), 2) AS usa_revenue, SUM(il.quantity) AS units_sold
FROM invoice AS i
JOIN invoice_line AS il ON i.invoice_id = il.invoice_id
JOIN track AS t ON il.track_id = t.track_id
JOIN album AS al ON t.album_id = al.album_id
JOIN artist AS ar ON al.artist_id = ar.artist_id
JOIN genre AS g ON t.genre_id = g.genre_id
WHERE i.billing_country = 'USA'
GROUP BY al.album_id, al.title, ar.name, g.name
ORDER BY usa_revenue DESC
LIMIT 3;


-- S2
-- Determine the top-selling genres in countries other than the USA and
-- identify any commonalities or differences.
WITH country_genre_sales AS (
    SELECT i.billing_country AS country, g.genre_id, g.name AS genre,
        SUM(il.unit_price * il.quantity) AS revenue
    FROM invoice AS i
    JOIN invoice_line AS il ON i.invoice_id = il.invoice_id
    JOIN track AS t ON il.track_id = t.track_id
    JOIN genre AS g ON t.genre_id = g.genre_id
    WHERE i.billing_country <> 'USA'
    GROUP BY i.billing_country, g.genre_id, g.name
),
ranked_genres AS (
    SELECT country, genre, revenue,
        RANK() OVER (PARTITION BY country ORDER BY revenue DESC
        ) AS sales_rank
    FROM country_genre_sales
)
SELECT
    country, genre, ROUND(revenue, 2) AS revenue, sales_rank
FROM ranked_genres
WHERE sales_rank <= 3
ORDER BY country, sales_rank, genre;


-- S3
-- Customer Purchasing Behavior Analysis: How do the purchasing habits
-- (frequency, basket size, spending amount) of long-term customers differ
-- from those of new customers? What insights can these patterns provide
-- about customer loyalty and retention strategies?
WITH invoice_track_counts AS (
    SELECT invoice_id, SUM(quantity) AS tracks_per_invoice
    FROM invoice_line
    GROUP BY invoice_id
),
customer_metrics AS (
    SELECT
        c.customer_id,
        COUNT(i.invoice_id) AS orders,
        SUM(it.tracks_per_invoice) AS tracks,
        SUM(i.total) AS total_spend,
        DATEDIFF(MAX(i.invoice_date), MIN(i.invoice_date)) AS tenure_days
    FROM customer AS c
    JOIN invoice AS i ON i.customer_id = c.customer_id
    JOIN invoice_track_counts AS it ON it.invoice_id = i.invoice_id
    GROUP BY c.customer_id
)
SELECT
    CASE
        WHEN tenure_days < 730 THEN '1 to under 2 years'
        WHEN tenure_days < 1095 THEN '2 to under 3 years'
        ELSE '3 years or more'
    END AS tenure_group,
    COUNT(*) AS customer_count,
    ROUND(AVG(orders * 365.25 / (tenure_days + 1)), 2) AS avg_orders_per_year,
    ROUND(AVG(tracks * 1.0 / orders), 2) AS avg_tracks_per_order,
    ROUND(AVG(total_spend), 2) AS avg_spend_per_customer
FROM customer_metrics
GROUP BY tenure_group
ORDER BY tenure_group;


-- S4
-- Product Affinity Analysis: Which music genres, artists, or albums are
-- frequently purchased together by customers? How can this information
-- guide product recommendations and cross-selling initiatives?
WITH purchases AS (
    SELECT DISTINCT i.invoice_id, g.genre_id, g.name AS genre
    FROM invoice AS i
    JOIN invoice_line AS il ON i.invoice_id = il.invoice_id
    JOIN track AS t ON il.track_id = t.track_id
    JOIN genre AS g ON t.genre_id = g.genre_id
)
SELECT
    a.genre AS genre_1, b.genre AS genre_2, COUNT(*) AS invoices_together
FROM purchases AS a
JOIN purchases AS b ON a.invoice_id = b.invoice_id
AND a.genre_id < b.genre_id
GROUP BY a.genre_id, a.genre, b.genre_id, b.genre
ORDER BY invoices_together DESC
LIMIT 5;

WITH purchases AS (
    SELECT DISTINCT i.invoice_id, ar.artist_id, ar.name AS artist
    FROM invoice AS i
    JOIN invoice_line AS il ON i.invoice_id = il.invoice_id
    JOIN track AS t ON il.track_id = t.track_id
    JOIN album AS al ON t.album_id = al.album_id
    JOIN artist AS ar ON al.artist_id = ar.artist_id
)
SELECT
    a.artist AS artist_1, b.artist AS artist_2,
    COUNT(*) AS invoices_together
FROM purchases AS a
JOIN purchases AS b ON a.invoice_id = b.invoice_id
   AND a.artist_id < b.artist_id
GROUP BY a.artist_id, a.artist, b.artist_id, b.artist
ORDER BY invoices_together DESC
LIMIT 5;

WITH purchases AS (
    SELECT DISTINCT i.invoice_id, al.album_id, al.title AS album
    FROM invoice AS i
    JOIN invoice_line AS il ON i.invoice_id = il.invoice_id
    JOIN track AS t ON il.track_id = t.track_id
    JOIN album AS al ON t.album_id = al.album_id
)
SELECT
    a.album AS album_1,
    b.album AS album_2,
    COUNT(*) AS invoices_together
FROM purchases AS a
JOIN purchases AS b ON a.invoice_id = b.invoice_id
   AND a.album_id < b.album_id
GROUP BY a.album_id, a.album, b.album_id, b.album
ORDER BY invoices_together DESC
LIMIT 5;


-- S5
-- Regional Market Analysis: Do customer purchasing behaviors and churn rates
-- vary across different geographic regions or store locations? How might
-- these correlate with local demographic or economic factors?
WITH customer_activity AS (
    SELECT c.customer_id, c.country,
        COUNT(i.invoice_id) AS invoice_count,
        COALESCE(SUM(i.total), 0) AS customer_spend,
        MAX(i.invoice_date) AS last_purchase_date
    FROM customer AS c
    LEFT JOIN invoice AS i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, c.country
),
dataset_end AS (
    SELECT MAX(invoice_date) AS end_date
    FROM invoice
)
SELECT
    ca.country,
    COUNT(*) AS customer_count,
    SUM(ca.invoice_count) AS invoice_count,
    ROUND(SUM(ca.customer_spend), 2) AS total_revenue,
    ROUND(SUM(ca.customer_spend) / NULLIF(SUM(ca.invoice_count), 0), 2)
        AS avg_invoice_value,
    SUM( CASE
            WHEN ca.last_purchase_date IS NULL
              OR ca.last_purchase_date < DATE_SUB(de.end_date, INTERVAL 3 MONTH)
            THEN 1 ELSE 0
        END ) AS inactive_customers,
    ROUND( 100.0 * SUM(
            CASE
                WHEN ca.last_purchase_date IS NULL
                  OR ca.last_purchase_date < DATE_SUB(de.end_date, INTERVAL 3 MONTH)
                THEN 1 ELSE 0
            END ) / COUNT(*), 2 ) AS inactive_customer_pct
FROM customer_activity AS ca
CROSS JOIN dataset_end AS de
GROUP BY ca.country
ORDER BY total_revenue DESC;


-- S6
-- Customer Risk Profiling: Based on customer profiles (age, gender, location,
-- purchase history), which customer segments are more likely to churn or
-- pose a higher risk of reduced spending? What factors contribute to this
-- risk?
WITH dataset_end AS (
    SELECT MAX(invoice_date) AS end_date
    FROM invoice
),
customer_profile AS (
    SELECT
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.country,
        COUNT(i.invoice_id) AS num_orders,
        ROUND(COALESCE(SUM(i.total), 0), 2) AS total_spend,
        MAX(i.invoice_date) AS last_purchase_date
    FROM customer AS c
    LEFT JOIN invoice AS i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.country
)
SELECT
    cp.customer_id, cp.customer_name, cp.country, cp.num_orders, cp.total_spend, cp.last_purchase_date
FROM customer_profile AS cp
CROSS JOIN dataset_end AS de
WHERE cp.last_purchase_date IS NULL
   OR cp.last_purchase_date < DATE_SUB(de.end_date, INTERVAL 3 MONTH)
ORDER BY cp.total_spend DESC, cp.last_purchase_date;


-- S7
-- Customer Lifetime Value Modeling: How can you leverage customer data
-- (tenure, purchase history, engagement) to predict the lifetime value of
-- different customer segments? This could inform targeted marketing and
-- loyalty program strategies. Can you observe any common characteristics
-- or purchase patterns among customers who have stopped purchasing?
WITH dataset_end AS (
    SELECT MAX(invoice_date) AS end_date
    FROM invoice
)
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.country,
    COUNT(i.invoice_id) AS num_orders,
    ROUND(COALESCE(SUM(i.total), 0), 2) AS total_spend,
    ROUND(AVG(i.total), 2) AS avg_order_value,
    MAX(i.invoice_date) AS last_purchase_date,
    DATEDIFF(de.end_date, MAX(i.invoice_date)
    ) AS days_since_last_purchase
FROM customer AS c
LEFT JOIN invoice AS i ON c.customer_id = i.customer_id
CROSS JOIN dataset_end AS de
GROUP BY
    c.customer_id, c.first_name, c.last_name, c.country, de.end_date
ORDER BY total_spend DESC;


-- S8
-- If data on promotional campaigns (discounts, events, email marketing) is
-- available, how could you measure their impact on customer acquisition,
-- retention, and overall sales?



-- S9
-- How would you approach this problem, if the objective and subjective
-- questions weren't given?
SHOW TABLES;

DESCRIBE customer;
DESCRIBE invoice;
DESCRIBE invoice_line;
DESCRIBE track;
DESCRIBE album;
DESCRIBE artist;
DESCRIBE genre;

SELECT
    COUNT(*) AS invoice_count,
    COUNT(DISTINCT customer_id) AS purchasing_customers,
    MIN(invoice_date) AS first_invoice_date,
    MAX(invoice_date) AS last_invoice_date,
    ROUND(SUM(total), 2) AS total_revenue
FROM invoice;

SELECT
    YEAR(invoice_date) AS sales_year,
    COUNT(*) AS invoice_count,
    ROUND(SUM(total), 2) AS revenue
FROM invoice
GROUP BY YEAR(invoice_date)
ORDER BY sales_year;

SELECT
    g.name AS genre,
    ROUND(SUM(il.unit_price * il.quantity), 2) AS revenue,
    SUM(il.quantity) AS units_sold
FROM invoice AS i
JOIN invoice_line AS il ON i.invoice_id = il.invoice_id
JOIN track AS t ON il.track_id = t.track_id
JOIN genre AS g ON t.genre_id = g.genre_id
GROUP BY g.genre_id, g.name
ORDER BY revenue DESC
LIMIT 10;

SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(i.invoice_id) AS num_orders,
    ROUND(COALESCE(SUM(i.total), 0), 2) AS total_spend,
    MAX(i.invoice_date) AS last_purchase_date
FROM customer AS c
LEFT JOIN invoice AS i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spend DESC;


-- S10
-- How can you alter the "Albums" table to add a new column named
-- "ReleaseYear" of type INTEGER to store the release year of each album?
ALTER TABLE album
ADD COLUMN ReleaseYear INT;


-- S11
-- Chinook is interested in understanding the purchasing behavior of customers
-- based on their geographical location. They want to know the average
-- total amount spent by customers from each country, along with the number
-- of customers and the average number of tracks purchased per customer.
-- Write an SQL query to provide this information.
WITH customer_spending AS (
    SELECT c.customer_id, c.country,
        COALESCE(SUM(i.total), 0) AS total_spent
    FROM customer AS c
    LEFT JOIN invoice AS i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, c.country
),
customer_tracks AS (
    SELECT c.customer_id,
        COALESCE(SUM(il.quantity), 0) AS tracks_purchased
    FROM customer AS c
    LEFT JOIN invoice AS i ON c.customer_id = i.customer_id
    LEFT JOIN invoice_line AS il ON i.invoice_id = il.invoice_id
    GROUP BY c.customer_id
)
SELECT
    cs.country,
    ROUND(AVG(cs.total_spent), 2) AS avg_total_spent_per_customer,
    COUNT(*) AS customer_count,
    ROUND(AVG(ct.tracks_purchased), 2) AS avg_tracks_per_customer
FROM customer_spending AS cs
JOIN customer_tracks AS ct ON cs.customer_id = ct.customer_id
GROUP BY cs.country
ORDER BY avg_total_spent_per_customer DESC;


/* ===================================== END OF FILE ===================================== */
