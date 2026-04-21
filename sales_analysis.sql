/*
==============================================================
📊 PROJECT: Sales & Profitability Analysis (2022–2023)
==============================================================

Tools Used: SQL (PostgreSQL)
Dataset: Sales Transactions Data
OBJECTIVE:
- Analyze revenue distribution across dimensions
- Identify key profitability drivers
- Detect inefficiencies in product portfolio
- Support business decision-making with insights
==============================================================
*/
-- ==========================================================
-- 📊 BASE DATA (Filter: 2022–2023)
-- ==========================================================

CREATE TABLE base AS 
    SELECT *
    FROM factsales
    WHERE EXTRACT(YEAR FROM order_date) IN (2022, 2023)

-- ==========================================================
-- 📊 REVENUE ANALYSIS
-- ==========================================================
-- 1. Country vs Revenue
SELECT 
    country,
    ROUND(SUM(salesamount)) AS revenue,
    ROUND(SUM(salesamount) * 100.0 / SUM(SUM(salesamount)) OVER (), 2) || '%' AS pct_revenue
FROM base
GROUP BY country
ORDER BY revenue DESC;
-- Insight:
-- Revenue is evenly distributed across countries (~11–13%), indicating low dependency on a single market.

-- 2. Order Priority vs Revenue
SELECT 
    orderpriority,
    ROUND(SUM(salesamount)) AS revenue,
    ROUND(SUM(salesamount) * 100.0 / SUM(SUM(salesamount)) OVER (), 2) || '%' AS pct_revenue
FROM base
GROUP BY orderpriority
ORDER BY revenue DESC;
-- Insight:
-- Low-priority orders contribute ~50% of total revenue → potential misalignment in priority classification.

-- 3. Subcategory vs Revenue
SELECT 
    subcategory,
    ROUND(SUM(salesamount)) AS revenue,
    ROUND(SUM(salesamount) * 100.0 / SUM(SUM(salesamount)) OVER (), 2) || '%' AS pct_revenue
FROM base
GROUP BY subcategory
ORDER BY revenue DESC;
-- Insight:
-- Revenue is moderately concentrated in a few subcategories, while some (e.g., Audio) underperform significantly.

-- 4. Customer vs Revenue
SELECT 
    customername,
    ROUND(SUM(salesamount)) AS revenue,
    ROUND(SUM(salesamount) * 100.0 / SUM(SUM(salesamount)) OVER (), 2) || '%' AS pct_revenue
FROM base
GROUP BY customername
ORDER BY revenue DESC;
-- Insight:
-- Majority of customers contribute significant revenue(>100000)), indicating a strong high-value customer base.

-- 5. Loyalty Tier vs Revenue
SELECT 
    loyalty_tier,
    COUNT(customername) AS customer_count,
    ROUND(SUM(salesamount) * 100.0 / SUM(SUM(salesamount)) OVER (), 2) || '%' AS pct_revenue
FROM base
GROUP BY loyalty_tier;
-- Insight:
-- Revenue is heavily concentrated in Bronze tier → limited progression to higher-value tiers.

-- 6. Category vs Revenue
SELECT 
    category,
    COUNT(customername) AS customer_count,
    ROUND(SUM(salesamount) * 100.0 / SUM(SUM(salesamount)) OVER (), 2) || '%' AS pct_revenue
FROM base
GROUP BY category
ORDER BY pct_revenue DESC;
-- Insight:
--The business benefits from a mix of high-frequency (clothing, accessories) and high-value (electronics) categories, 
--creating a balanced demand structure
-- ==========================================================
-- 💰 PROFITABILITY ANALYSIS
-- ==========================================================
-- 7. Overall Gross Profit Margin
SELECT 
    SUM(salesamount) AS total_sales,
    SUM(totalcost) AS total_cogs,
    SUM(salesamount) - SUM(totalcost) AS gross_profit,
    ROUND((SUM(salesamount) - SUM(totalcost)) * 100.0 / SUM(salesamount), 2) || '%' AS gross_profit_margin
FROM base;
-- Insight:
-- Overall gross profit margin ≈ 35.56%.

-- 8. Product-level Profitability (Below Average)
SELECT 
    product,
    SUM(salesamount) AS revenue,
    SUM(totalcost) AS cogs,
    SUM(salesamount) - SUM(totalcost) AS profit,
    ROUND((SUM(salesamount) - SUM(totalcost)) * 100.0 / SUM(salesamount), 2) || '%' AS profit_margin
FROM base
GROUP BY product
HAVING ROUND((SUM(salesamount) - SUM(totalcost)) * 100.0 / SUM(salesamount), 2) < 35.56
ORDER BY profit_margin ASC;
-- Insight:
-- Over 50% of products are below average margin → indicates margin leakage.

-- 9. Profit Trend Over Time
SELECT 
    EXTRACT(YEAR FROM order_date) AS year,
    TO_CHAR(order_date, 'Month') AS month,
    SUM(salesamount) - SUM(totalcost) AS gross_profit
FROM base
GROUP BY 1, 2, EXTRACT(MONTH FROM order_date)
ORDER BY year, EXTRACT(MONTH FROM order_date);
-- Insight:
-- Seasonal pattern observed: peaks in Dec–Jan, dip in February.

-- 10. Profit by Channel
SELECT 
    channel,
    SUM(salesamount) AS revenue,
    SUM(totalcost) AS cogs,
    SUM(salesamount) - SUM(totalcost) AS profit,
    ROUND((SUM(salesamount) - SUM(totalcost)) * 100.0 / SUM(salesamount), 2) || '%' AS profit_margin
FROM base
GROUP BY channel;
-- Insight:
-- Profit margins are consistent across channels → potential missed optimization opportunities.

-- 11. Profit by Order Priority
SELECT 
    orderpriority,
    SUM(salesamount) AS revenue,
    SUM(totalcost) AS cogs,
    SUM(salesamount) - SUM(totalcost) AS profit,
    ROUND((SUM(salesamount) - SUM(totalcost)) * 100.0 / SUM(salesamount), 2) || '%' AS profit_margin
FROM base
GROUP BY orderpriority;
-- Insight:
-- Profitability is similar across priority levels → premium services not monetized effectively.

-- 12. Subcategory Profitability
SELECT 
    category,
    subcategory,
    SUM(salesamount) AS revenue,
    SUM(totalcost) AS cogs,
    SUM(salesamount) - SUM(totalcost) AS profit,
    ROUND((SUM(salesamount) - SUM(totalcost)) * 100.0 / SUM(salesamount), 2) || '%' AS profit_margin
FROM base
GROUP BY category, subcategory
ORDER BY profit_margin DESC;
-- Insight:
-- Electronics (especially phones) are key profit drivers with highest margins.


-- ==========================================================
-- PRODUCT EFFICIENCY MODEL (KEY ANALYSIS)
-- ==========================================================
CREATE TABLE product_summary AS
WITH product_data AS (
    SELECT 
        product,
        SUM(salesamount) AS revenue,
        SUM(profit) AS profit,
        SUM(totalcost) AS cogs
    FROM base
    GROUP BY product
),
totals AS (
    SELECT 
        SUM(profit) AS total_profit,
        SUM(totalcost) AS total_cogs
    FROM base
)
SELECT 
    p.product,
    p.revenue,
    p.profit,
    p.cogs,
p.profit * 100.0 / t.total_profit AS profit_pct,
    p.cogs * 100.0 / t.total_cogs AS cogs_pct,
-- Efficiency Score
    (p.profit * 1.0 / t.total_profit) 
    /
    (p.cogs * 1.0 / t.total_cogs) AS efficiency_score,
-- Product Classification
    CASE 
        WHEN (p.profit * 1.0 / t.total_profit) 
           / (p.cogs * 1.0 / t.total_cogs) < 0.5 THEN 'Bad Product'
        WHEN (p.profit * 1.0 / t.total_profit) 
           / (p.cogs * 1.0 / t.total_cogs) BETWEEN 0.5 AND 1 THEN 'Average Product'
        ELSE 'Good Product'
    END AS product_flag
FROM product_data p
CROSS JOIN totals t
ORDER BY efficiency_score ASC;

-- Insight:
-- Significant portion of products are inefficient → indicates portfolio optimization opportunity.

-- 13. Product Distribution by Efficiency
SELECT 
    product_flag,
    COUNT(*) AS product_count
FROM product_summary
GROUP BY product_flag;
-- Insight:
-- Large number of products are underperforming and underminig overall profitability.
-- ==========================================================
-- 📌 FINAL BUSINESS SUMMARY
-- ==========================================================
-- Key Findings:
-- 1. Revenue is evenly distributed across countries (low market dependency)
-- 2. Low-priority orders generate ~50% revenue (priority misalignment)
-- 3. Strong revenue concentration in Bronze-tier customers (loyalty inefficiency)
-- 4. Over 50% of products operate below average margin (margin leakage)
-- 5. Electronics (phones) are key profit drivers (high margin)
-- 6. Product portfolio shows inefficiency (30%+ underperforming products)
-- 7. Seasonal demand observed (Dec–Jan peak, Feb dip)

-- Business Impact:
-- - Opportunities for pricing optimization
-- - Product portfolio rationalization
-- - Customer segmentation improvement
-- - Better monetization of premium services
==============================================================

