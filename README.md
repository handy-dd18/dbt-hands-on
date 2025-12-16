# dbt入門ハンズオン（30分で完了）

> **Note**
> このハンズオン資料は生成AI（Claude）を活用して作成されました。
> 内容の正確性には注意を払っていますが、誤りや古い情報が含まれている可能性があります。
> 実際の業務で使用する際は、公式ドキュメントも併せてご確認ください。

このハンズオンでは、dbt（data build tool）の基本的な使い方を学びます。
Docker環境を使用してローカルPCで完結します。

## dbtとは？

dbt（data build tool）は、データウェアハウス内でのデータ変換を行うツールです。

**特徴：**
- ELT（Extract, Load, Transform）の「T（Transform）」を担当
- SQLベースでデータ変換パイプラインを構築
- バージョン管理、テスト、ドキュメント生成が可能
- ソフトウェアエンジニアリングのベストプラクティスをデータ分析に適用

## 前提条件

- Docker / Docker Compose がインストールされていること
- ターミナル（コマンドライン）の基本操作ができること

## ハンズオン構成

```
dbt_handson/
├── docker-compose.yml    # Docker環境定義
├── Dockerfile            # dbtコンテナのビルド設定
├── init/                 # PostgreSQL初期化スクリプト
│   └── 01_create_tables.sql
└── dbt_project/          # dbtプロジェクト
    ├── dbt_project.yml   # プロジェクト設定
    ├── profiles.yml      # 接続設定
    ├── models/           # SQLモデル
    │   ├── staging/      # ステージング層
    │   └── marts/        # マート層
    ├── seeds/            # CSVマスターデータ
    ├── tests/            # カスタムテスト
    └── macros/           # 再利用可能なSQL関数
```

---

## Step 1: 環境の起動（5分）

### 1.1 プロジェクトディレクトリに移動

```bash
cd dbt_handson
```

### 1.2 Dockerコンテナを起動

```bash
docker compose up -d
```

PostgreSQLとdbtコンテナが起動します。

### 1.3 dbtコンテナに入る

```bash
docker compose exec dbt bash
```

これ以降のコマンドはdbtコンテナ内で実行します。

### 1.4 接続確認

```bash
dbt debug
```

`All checks passed!` と表示されれば接続成功です。

---

## Step 2: dbtプロジェクトの構造を理解する（5分）

### 2.1 主要ファイルの確認

**dbt_project.yml** - プロジェクトの設定ファイル

```yaml
name: 'dbt_handson'         # プロジェクト名
version: '1.0.0'

model-paths: ["models"]      # モデルの格納場所
seed-paths: ["seeds"]        # シードデータの格納場所
test-paths: ["tests"]        # テストの格納場所
```

**profiles.yml** - データベース接続設定

```yaml
dbt_handson:
  target: dev
  outputs:
    dev:
      type: postgres
      host: postgres
      user: postgres
      password: postgres
      port: 5432
      dbname: dbt_handson
      schema: dbt_dev
```

### 2.2 モデルの階層構造

```
models/
├── staging/          # ステージング層：生データのクリーニング
│   ├── stg_customers.sql
│   ├── stg_orders.sql
│   ├── sources.yml   # ソース定義
│   └── schema.yml    # テスト・ドキュメント
└── marts/            # マート層：ビジネスロジックの適用
    ├── customer_orders.sql
    ├── order_status_summary.sql
    └── schema.yml
```

---

## Step 3: Seedの実行（3分）

Seedは、CSVファイルをデータベースにロードする機能です。

### 3.1 Seedファイルを確認

```bash
cat seeds/order_status_master.csv
```

注文ステータスのマスターデータ（CSVファイル）が定義されています。

### 3.2 Seedを実行

```bash
dbt seed
```

CSVファイルがPostgreSQLのテーブルとして作成されます。

---

## Step 4: モデルの実行（7分）

### 4.1 ステージングモデルを確認

**models/staging/stg_customers.sql**

```sql
SELECT
    customer_id,
    first_name,
    last_name,
    first_name || ' ' || last_name AS full_name,  -- データ加工
    email,
    created_at
FROM {{ source('raw_data', 'customers') }}  -- ソースの参照
```

ポイント：
- `{{ source('raw_data', 'customers') }}` - ソーステーブルを参照
- `full_name` - 姓と名を結合して新しいカラムを作成

### 4.2 マートモデルを確認

**models/marts/customer_orders.sql**

```sql
WITH customers AS (
    SELECT * FROM {{ ref('stg_customers') }}  -- 他のモデルを参照
),
orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),
...
```

ポイント：
- `{{ ref('stg_customers') }}` - 他のdbtモデルを参照
- dbtが依存関係を自動解決し、正しい順序で実行

### 4.3 全モデルを実行

```bash
dbt run
```

出力例：
```
Running with dbt=1.x.x
Found 4 models, 1 seed, ...

Concurrency: 4 threads (target='dev')

1 of 4 START sql view model dbt_dev.stg_customers
2 of 4 START sql view model dbt_dev.stg_orders
1 of 4 OK created sql view model dbt_dev.stg_customers
2 of 4 OK created sql view model dbt_dev.stg_orders
3 of 4 START sql table model dbt_dev.customer_orders
4 of 4 START sql table model dbt_dev.order_status_summary
...
Finished running 2 view models, 2 table models
```

### 4.4 特定のモデルだけ実行

```bash
dbt run --select stg_customers
```

または、特定のモデルとその下流すべて：

```bash
dbt run --select stg_customers+
```

---

## Step 5: テストの実行（5分）

### 5.1 組み込みテストの種類

dbtには4種類の組み込みテストがあります：

| テスト | 説明 |
|--------|------|
| `unique` | 値が一意であること |
| `not_null` | NULLがないこと |
| `accepted_values` | 指定した値のみを含むこと |
| `relationships` | 参照整合性があること |

### 5.2 schema.ymlでのテスト定義

**models/staging/schema.yml** より：

```yaml
columns:
  - name: customer_id
    tests:
      - unique
      - not_null
  - name: status
    tests:
      - accepted_values:
          values: ['completed', 'pending', 'cancelled']
```

### 5.3 テストを実行

```bash
dbt test
```

すべてのテストが `PASS` になれば成功です。

### 5.4 カスタムテスト

**tests/assert_positive_order_amounts.sql**

```sql
SELECT order_id, amount
FROM {{ ref('stg_orders') }}
WHERE amount <= 0
```

このクエリが0行を返せばテスト成功、1行以上返せば失敗です。

---

## Step 6: ドキュメントの生成（3分）

### 6.1 ドキュメント生成

```bash
dbt docs generate
```

### 6.2 ドキュメントをブラウザで確認

```bash
dbt docs serve --port 8080
```

ブラウザで http://localhost:8080 を開くと、データリネージ（依存関係図）やカラムの説明を確認できます。

**Ctrl+C** で停止します。

---

## Step 7: その他の便利なコマンド（2分）

### 7.1 コンパイル済みSQLの確認

```bash
dbt compile
```

Jinja構文が展開されたSQLを `target/compiled/` で確認できます。

### 7.2 特定モデルの依存関係を確認

```bash
dbt ls --select +customer_orders
```

### 7.3 全体のクリーンアップ

```bash
dbt clean
```

---

## まとめ

このハンズオンで学んだこと：

1. **Source** - 外部データソースの定義
2. **Model** - SQLによるデータ変換
3. **Seed** - CSVマスターデータのロード
4. **Test** - データ品質のテスト
5. **Documentation** - 自動ドキュメント生成

### dbtの主要コマンド

| コマンド | 説明 |
|----------|------|
| `dbt debug` | 接続確認 |
| `dbt seed` | CSVをテーブルにロード |
| `dbt run` | モデルを実行 |
| `dbt test` | テストを実行 |
| `dbt docs generate` | ドキュメント生成 |
| `dbt docs serve` | ドキュメントをブラウザで表示 |

### 後片付け

```bash
exit  # dbtコンテナから抜ける
docker compose down -v  # コンテナとボリュームを削除
```

---

## 参考リソース

- [dbt公式ドキュメント](https://docs.getdbt.com/)
- [dbt Developer Hub - Seeds](https://docs.getdbt.com/docs/build/seeds)
- [dbt + PostgreSQL on Docker 開発環境セットアップ手順（Qiita）](https://qiita.com/rabut/items/981251b96cdf8806815f)
- [dbtを手軽に試す！Dockerを利用してPostgreSQLと一緒に簡単セットアップ（DevelopersIO）](https://dev.classmethod.jp/articles/dbt-easy-setup-with-psql/)
- [dbtで始めるデータパイプライン構築〜入門から実践〜（Zenn）](https://zenn.dev/dbt_tokyo/books/537de43829f3a0)
