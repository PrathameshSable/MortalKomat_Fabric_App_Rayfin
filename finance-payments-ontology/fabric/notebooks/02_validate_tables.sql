-- ============================================================================
-- Contoso Bank — Lakehouse validation
-- Run in the Lakehouse SQL analytics endpoint after 01_build_lakehouse_tables.
-- Confirms row counts, referential integrity and the headline KPIs the Data
-- Agent will be asked about.
-- ============================================================================

-- 1) Row counts per entity ---------------------------------------------------
SELECT 'dim_customer'                 AS entity, COUNT(*) AS rows FROM dim_customer
UNION ALL SELECT 'dim_account',                 COUNT(*) FROM dim_account
UNION ALL SELECT 'dim_card',                    COUNT(*) FROM dim_card
UNION ALL SELECT 'dim_merchant',                COUNT(*) FROM dim_merchant
UNION ALL SELECT 'dim_channel',                 COUNT(*) FROM dim_channel
UNION ALL SELECT 'dim_product',                 COUNT(*) FROM dim_product
UNION ALL SELECT 'dim_branch',                  COUNT(*) FROM dim_branch
UNION ALL SELECT 'dim_currency',                COUNT(*) FROM dim_currency
UNION ALL SELECT 'dim_date',                    COUNT(*) FROM dim_date
UNION ALL SELECT 'fact_transaction',            COUNT(*) FROM fact_transaction
UNION ALL SELECT 'fact_fraud_alert',            COUNT(*) FROM fact_fraud_alert
UNION ALL SELECT 'fact_account_balance_daily',  COUNT(*) FROM fact_account_balance_daily
UNION ALL SELECT 'fact_customer_daily_snapshot',COUNT(*) FROM fact_customer_daily_snapshot
UNION ALL SELECT 'fact_branch_daily_snapshot',  COUNT(*) FROM fact_branch_daily_snapshot
ORDER BY entity;

-- 2) Referential integrity: every transaction FK must resolve ---------------
SELECT
    SUM(CASE WHEN c.CustomerKey IS NULL THEN 1 ELSE 0 END) AS orphan_customer,
    SUM(CASE WHEN a.AccountKey  IS NULL THEN 1 ELSE 0 END) AS orphan_account,
    SUM(CASE WHEN m.MerchantKey IS NULL THEN 1 ELSE 0 END) AS orphan_merchant,
    SUM(CASE WHEN ch.ChannelKey IS NULL THEN 1 ELSE 0 END) AS orphan_channel
FROM fact_transaction t
LEFT JOIN dim_customer c ON t.CustomerKey = c.CustomerKey
LEFT JOIN dim_account  a ON t.AccountKey  = a.AccountKey
LEFT JOIN dim_merchant m ON t.MerchantKey = m.MerchantKey
LEFT JOIN dim_channel ch ON t.ChannelKey  = ch.ChannelKey;

-- 3) Every alert must point at a real transaction ---------------------------
SELECT COUNT(*) AS orphan_alerts
FROM fact_fraud_alert fa
LEFT JOIN fact_transaction t ON fa.TransactionKey = t.TransactionKey
WHERE t.TransactionKey IS NULL;

-- 4) Headline KPIs (should match the semantic-model measures) ---------------
SELECT
    COUNT(*)                                              AS total_transactions,
    ROUND(SUM(AmountUsd), 0)                              AS total_value_usd,
    ROUND(AVG(CASE WHEN Status='Approved' THEN 1.0 ELSE 0 END), 4) AS approval_rate,
    SUM(IsFraud)                                          AS fraud_transactions,
    ROUND(AVG(IsFraud), 4)                                AS fraud_rate,
    SUM(CASE WHEN FraudScore >= 0.75 THEN 1 ELSE 0 END)   AS high_risk_transactions
FROM fact_transaction;

-- 5) Top fraud corridors (great for the live map) ---------------------------
SELECT MerchantCountry, COUNT(*) AS fraud_txns, ROUND(SUM(AmountUsd),0) AS fraud_value
FROM fact_transaction
WHERE IsFraud = 1
GROUP BY MerchantCountry
ORDER BY fraud_value DESC
LIMIT 10;
