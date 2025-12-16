-- staging/stg_orders.sql
-- 生データから注文情報を抽出するステージングモデル

SELECT
    order_id,
    customer_id,
    order_date,
    status,
    amount
FROM {{ source('raw_data', 'orders') }}
