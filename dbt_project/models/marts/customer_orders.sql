-- marts/customer_orders.sql
-- 顧客ごとの注文サマリーを作成するマートモデル

WITH customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),

orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),

customer_order_summary AS (
    SELECT
        c.customer_id,
        c.full_name,
        c.email,
        COUNT(o.order_id) AS total_orders,
        COALESCE(SUM(CASE WHEN o.status = 'completed' THEN o.amount ELSE 0 END), 0) AS total_spent,
        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS last_order_date
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.full_name, c.email
)

SELECT
    customer_id,
    full_name,
    email,
    total_orders,
    total_spent,
    first_order_date,
    last_order_date,
    CASE
        WHEN total_spent >= 3000 THEN 'Gold'
        WHEN total_spent >= 1500 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_tier
FROM customer_order_summary
