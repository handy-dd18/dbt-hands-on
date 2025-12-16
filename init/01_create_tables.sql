-- サンプルデータ用のスキーマとテーブルを作成
CREATE SCHEMA IF NOT EXISTS raw_data;

-- 顧客テーブル
CREATE TABLE raw_data.customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 注文テーブル
CREATE TABLE raw_data.orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES raw_data.customers(customer_id),
    order_date DATE,
    status VARCHAR(20),
    amount DECIMAL(10, 2)
);

-- サンプルデータの投入
INSERT INTO raw_data.customers (first_name, last_name, email) VALUES
    ('太郎', '山田', 'taro@example.com'),
    ('花子', '佐藤', 'hanako@example.com'),
    ('次郎', '鈴木', 'jiro@example.com'),
    ('美咲', '田中', 'misaki@example.com'),
    ('健太', '高橋', 'kenta@example.com');

INSERT INTO raw_data.orders (customer_id, order_date, status, amount) VALUES
    (1, '2024-01-15', 'completed', 1500.00),
    (1, '2024-02-20', 'completed', 2300.00),
    (2, '2024-01-22', 'completed', 800.00),
    (2, '2024-03-10', 'pending', 1200.00),
    (3, '2024-02-05', 'completed', 3500.00),
    (3, '2024-02-28', 'cancelled', 500.00),
    (4, '2024-03-01', 'completed', 2100.00),
    (5, '2024-03-15', 'pending', 900.00);
