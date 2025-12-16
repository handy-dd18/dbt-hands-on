-- tests/assert_positive_order_amounts.sql
-- 注文金額が正の値であることを確認するカスタムテスト

SELECT
    order_id,
    amount
FROM {{ ref('stg_orders') }}
WHERE amount <= 0
