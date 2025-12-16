-- staging/stg_customers.sql
-- 生データから顧客情報を抽出するステージングモデル

SELECT
    customer_id,
    first_name,
    last_name,
    first_name || ' ' || last_name AS full_name,
    email,
    created_at
FROM {{ source('raw_data', 'customers') }}
