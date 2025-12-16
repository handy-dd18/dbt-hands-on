-- marts/order_status_summary.sql
-- 注文ステータス別のサマリーを作成

WITH orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),

status_lookup AS (
    SELECT * FROM {{ ref('order_status_master') }}
)

SELECT
    o.status,
    sl.status_label,
    COUNT(*) AS order_count,
    SUM(o.amount) AS total_amount,
    AVG(o.amount) AS avg_amount
FROM orders o
LEFT JOIN status_lookup sl ON o.status = sl.status_code
GROUP BY o.status, sl.status_label
ORDER BY order_count DESC
