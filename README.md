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

## dbtプロジェクトとは？

**dbtプロジェクト**は、データ変換に必要なファイルをまとめた「作業フォルダ」です。

### 身近な例えで理解する

料理に例えると、dbtプロジェクトは「レシピブック」のようなものです。

| 料理の世界 | dbtプロジェクト |
|------------|-----------------|
| レシピブック | dbtプロジェクト全体 |
| 各レシピ（調理手順） | models/（SQLファイル） |
| 調味料リスト | seeds/（CSVマスターデータ） |
| 味見のチェックリスト | tests/（データ品質テスト） |
| よく使う調理テクニック集 | macros/（再利用可能な処理） |
| 表紙・目次 | dbt_project.yml（プロジェクト設定） |

### 最小構成

dbtプロジェクトとして認識されるには、最低限 `dbt_project.yml` が必要です。

```
my_project/
├── dbt_project.yml   # 必須：これがあるフォルダがdbtプロジェクト
└── models/           # データ変換のSQLを置く場所
    └── my_model.sql
```

### dbtプロジェクトと接続設定の分離

dbtでは「何を変換するか」と「どこに接続するか」を分けて管理します。

```
┌─────────────────────────────────┐
│  dbtプロジェクト                │  ← 「何を変換するか」
│  （models, tests, seeds...）    │     Gitで管理・チームで共有
└─────────────────────────────────┘
              ↓ 参照
┌─────────────────────────────────┐
│  profiles.yml                   │  ← 「どこに接続するか」
│  （接続先、ユーザー名、パスワード）│     個人の環境に配置（~/.dbt/）
└─────────────────────────────────┘
```

**なぜ分けるのか？**

- **セキュリティ**：パスワードなどの秘密情報をGitにコミットしない
- **柔軟性**：同じプロジェクトで開発環境・本番環境を切り替え可能
- **チーム開発**：各メンバーが自分の接続設定を持てる

参考：[About dbt projects | dbt Developer Hub](https://docs.getdbt.com/docs/build/projects)

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

### なぜこの構成なのか？

#### Docker関連ファイル（プロジェクトルート）

| ファイル | 役割 |
|----------|------|
| `docker-compose.yml` | PostgreSQL（データベース）とdbt（変換ツール）の2つのコンテナを定義。これにより、ローカルPCに直接インストールせずに環境を構築できます |
| `Dockerfile` | dbtが動作するコンテナの設計図。Python環境にdbt-coreとdbt-postgresをインストールします |
| `init/` | PostgreSQLコンテナ起動時に自動実行されるSQLスクリプト。サンプルデータを事前に用意しておくことで、すぐにdbtの学習を始められます |

#### dbt_project/（dbtプロジェクト本体）

dbtプロジェクトは、**設定ファイル**と**機能別ディレクトリ**で構成されます。

**設定ファイル：**

| ファイル | 役割 |
|----------|------|
| `dbt_project.yml` | プロジェクト名やディレクトリ構成を定義。dbtがどこに何があるかを認識するために必要です |
| `profiles.yml` | データベースへの接続情報（ホスト名、ユーザー名、パスワードなど）。通常は秘密情報を含むためGit管理外にしますが、学習用のため同梱しています |

> **profiles.ymlの配置場所について**
>
> dbt CLIは、デフォルトで `~/.dbt/profiles.yml`（ホームディレクトリ直下の`.dbt`フォルダ）を参照します。
> これは、パスワードなどの秘密情報がGitリポジトリにコミットされるのを防ぐためです。
>
> **profiles.ymlの検索順序：**
> 1. `--profiles-dir` オプションで指定したディレクトリ
> 2. `DBT_PROFILES_DIR` 環境変数で指定したディレクトリ
> 3. カレントディレクトリ（dbt 1.3以降）
> 4. `~/.dbt/` ディレクトリ（デフォルト）
>
> このハンズオンでは、`docker-compose.yml`で `DBT_PROFILES_DIR=/dbt` を設定しているため、
> プロジェクト内の `profiles.yml` が使用されます。
>
> 参考：[About profiles.yml | dbt Developer Hub](https://docs.getdbt.com/docs/core/connect-data-platform/profiles.yml)

**機能別ディレクトリ：**

| ディレクトリ | 役割 | なぜ分けるのか |
|--------------|------|----------------|
| `models/` | データ変換のSQL | dbtのメイン機能。さらにstaging/martsに分けることで、データの流れを明確にします |
| `seeds/` | CSVマスターデータ | コードで管理したい小さなマスターデータ（ステータス定義など）を置きます |
| `tests/` | カスタムテスト | 組み込みテスト以外の独自チェックを定義します |
| `macros/` | 再利用可能な関数 | 複数のモデルで使う共通処理をまとめます |

#### models/の2層構造（staging → marts）

```
models/
├── staging/    # 第1層：生データのクリーニング
└── marts/      # 第2層：ビジネス向け集計テーブル
```

**なぜ2層に分けるのか？**

1. **staging層（ステージング）**
   - 生データ（raw_data）を「そのまま使える形」に整えます
   - 例：姓と名を結合してフルネームを作成
   - View（ビュー）として作成し、ストレージを節約

2. **marts層（マート）**
   - staging層のデータを組み合わせて、**ビジネスで使える集計テーブル**を作成
   - 例：顧客ごとの購入回数・合計金額・顧客ランク
   - Table（テーブル）として作成し、クエリ性能を向上

この階層構造により、**データの流れが追いやすく**、**変更の影響範囲を限定**できます。
生データの形式が変わっても、staging層だけ修正すればmarts層への影響を抑えられます。

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

> **トラブルシューティング**
>
> `dependency failed to start: container dbt_postgres exited (1)` のエラーが発生した場合、
> `init/01_create_tables.sql` のパーミッションが不足している可能性があります。
> 以下のコマンドで修正してください：
>
> ```bash
> chmod 644 init/01_create_tables.sql
> docker compose down -v
> docker compose up -d
> ```

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

### 2.1 設定ファイル

#### dbt_project.yml - プロジェクトの設定ファイル

```yaml
name: 'dbt_handson'           # プロジェクト名
version: '1.0.0'              # バージョン
config-version: 2             # 設定ファイルのフォーマットバージョン

profile: 'dbt_handson'        # profiles.ymlのどのプロファイルを使うか

model-paths: ["models"]       # モデル（SQL）の格納場所
analysis-paths: ["analyses"]  # 分析用SQLの格納場所
test-paths: ["tests"]         # カスタムテストの格納場所
seed-paths: ["seeds"]         # CSVデータの格納場所
macro-paths: ["macros"]       # マクロ（関数）の格納場所
snapshot-paths: ["snapshots"] # スナップショットの格納場所

clean-targets:                # dbt cleanで削除する対象
  - "target"
  - "dbt_packages"

models:
  dbt_handson:                # プロジェクト名に対応
    staging:
      +materialized: view     # staging層はViewとして作成（軽量・リアルタイム）
    marts:
      +materialized: table    # marts層はTableとして作成（高速クエリ）
```

**設定項目の意味：**

| 設定 | 意味 |
|------|------|
| `profile` | profiles.ymlのどの接続設定を使うか指定 |
| `*-paths` | 各種ファイルをどこに置くかを定義 |
| `+materialized: view` | ストレージを使わないビュー（生データ変更が即反映） |
| `+materialized: table` | 実テーブル作成（クエリ高速化） |

#### profiles.yml - データベース接続設定

```yaml
dbt_handson:                  # プロファイル名（dbt_project.ymlのprofileと対応）
  target: dev                 # デフォルトで使う環境
  outputs:
    dev:                      # 開発環境の設定
      type: postgres          # データベースの種類
      host: postgres          # ホスト名（docker-compose内のサービス名）
      user: postgres          # ユーザー名
      password: postgres      # パスワード
      port: 5432              # ポート番号
      dbname: dbt_handson     # データベース名
      schema: dbt_dev         # スキーマ名（dbtが作成するオブジェクトの配置先）
      threads: 4              # 並列実行数
```

**設定項目の意味：**

| 設定 | 意味 |
|------|------|
| `target: dev` | 本番環境(`prod`)と開発環境(`dev`)を切り替え可能 |
| `schema: dbt_dev` | dbtが作るテーブル/ビューはこのスキーマに作成される |
| `threads: 4` | 4つのモデルを同時に実行可能（高速化） |

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

### 2.3 ソース定義ファイル

#### sources.yml - 外部データソースの定義

```yaml
version: 2

sources:
  - name: raw_data                      # ソースの名前（参照時に使用）
    description: "ECサイトの生データ"
    database: dbt_handson               # データベース名
    schema: raw_data                    # スキーマ名
    tables:
      - name: customers                 # テーブル名
        description: "顧客マスターテーブル"
        columns:
          - name: customer_id
            description: "顧客ID（主キー）"
          # ... 他のカラム定義

      - name: orders
        description: "注文トランザクションテーブル"
        columns:
          - name: order_id
            description: "注文ID（主キー）"
          # ... 他のカラム定義
```

**このファイルの役割：**

- **dbtが管理していない外部テーブル**の所在を定義
- SQLモデル内で `{{ source('raw_data', 'customers') }}` と書くと、`raw_data.customers` テーブルを参照
- ドキュメント生成時にリネージ（依存関係）が可視化される

### 2.4 ステージング層（staging/）

#### stg_customers.sql - 顧客データのクリーニング

```sql
SELECT
    customer_id,
    first_name,
    last_name,
    first_name || ' ' || last_name AS full_name,  -- 姓名を結合して新カラム作成
    email,
    created_at
FROM {{ source('raw_data', 'customers') }}        -- sources.ymlで定義したソースを参照
```

**やっていること：**

- 生データ（raw_data.customers）を読み込む
- `full_name` という派生カラムを追加
- **View** として作成（dbt_project.ymlで設定）

#### stg_orders.sql - 注文データのクリーニング

```sql
SELECT
    order_id,
    customer_id,
    order_date,
    status,
    amount
FROM {{ source('raw_data', 'orders') }}
```

**やっていること：**

- 生データをそのまま整形（この例ではシンプルにカラム選択のみ）
- 実務では型変換やNULL処理などを行う

#### schema.yml - ステージング層のテスト・ドキュメント

```yaml
version: 2

models:
  - name: stg_customers
    description: "顧客データのステージングモデル"
    columns:
      - name: customer_id
        tests:
          - unique              # 重複がないことをチェック
          - not_null            # NULLがないことをチェック
      - name: email
        tests:
          - unique
          - not_null

  - name: stg_orders
    columns:
      - name: order_id
        tests:
          - unique
          - not_null
      - name: customer_id
        tests:
          - not_null
          - relationships:      # 外部キー制約のチェック
              to: ref('stg_customers')
              field: customer_id
      - name: status
        tests:
          - accepted_values:    # 許可された値のみかチェック
              values: ['completed', 'pending', 'cancelled']
```

**テストの種類：**

| テスト | 意味 |
|--------|------|
| `unique` | 値が重複していないこと |
| `not_null` | NULLがないこと |
| `relationships` | 参照先に値が存在すること（外部キー整合性） |
| `accepted_values` | 指定した値のみであること |

### 2.5 マート層（marts/）

#### customer_orders.sql - 顧客ごとの注文サマリー

```sql
WITH customers AS (
    SELECT * FROM {{ ref('stg_customers') }}   -- ステージングモデルを参照
),
orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),
customer_order_summary AS (
    SELECT
        c.customer_id,
        c.full_name,
        c.email,
        COUNT(o.order_id) AS total_orders,           -- 注文回数
        COALESCE(SUM(CASE WHEN o.status = 'completed'
                     THEN o.amount ELSE 0 END), 0) AS total_spent,  -- 完了注文の合計金額
        MIN(o.order_date) AS first_order_date,       -- 初回注文日
        MAX(o.order_date) AS last_order_date         -- 最新注文日
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.full_name, c.email
)
SELECT
    *,
    CASE
        WHEN total_spent >= 3000 THEN 'Gold'         -- 顧客ランク判定
        WHEN total_spent >= 1500 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_tier
FROM customer_order_summary
```

**ポイント：**

- `{{ ref('stg_customers') }}` → 他のdbtモデルを参照（依存関係を自動解決）
- ビジネスロジック（顧客ランク）を適用
- **Table** として作成（実テーブルで高速クエリ）

#### order_status_summary.sql - 注文ステータス別サマリー

```sql
WITH orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),
status_lookup AS (
    SELECT * FROM {{ ref('order_status_master') }}   -- Seedテーブルを参照
)
SELECT
    o.status,
    sl.status_label,                    -- 日本語ラベル（Seedから取得）
    COUNT(*) AS order_count,
    SUM(o.amount) AS total_amount,
    AVG(o.amount) AS avg_amount
FROM orders o
LEFT JOIN status_lookup sl ON o.status = sl.status_code
GROUP BY o.status, sl.status_label
ORDER BY order_count DESC
```

**ポイント：**

- `{{ ref('order_status_master') }}` → Seedで作成したマスターテーブルを参照
- ステータスコードに日本語ラベルを付与

#### schema.yml - マート層のテスト・ドキュメント

```yaml
version: 2

models:
  - name: customer_orders
    description: "顧客ごとの注文サマリー（マートモデル）"
    columns:
      - name: customer_id
        tests:
          - unique
          - not_null
      - name: customer_tier
        tests:
          - accepted_values:
              values: ['Gold', 'Silver', 'Bronze']   # ランクが3種類のみか確認

  - name: order_status_summary
    columns:
      - name: status
        tests:
          - unique
          - not_null
```

### 2.6 ファイルの役割まとめ

| ファイル | 役割 |
|----------|------|
| `dbt_project.yml` | プロジェクト全体の設定（名前、パス、マテリアライゼーション） |
| `profiles.yml` | DB接続情報（ホスト、認証情報、スキーマ） |
| `sources.yml` | 外部データソースの定義（dbt管理外テーブル） |
| `stg_*.sql` | 生データのクリーニング・標準化（View） |
| `marts/*.sql` | ビジネスロジック適用・集計（Table） |
| `schema.yml` | テスト定義とドキュメント |

---

## Step 3: Seedの実行（3分）

Seedは、CSVファイルをデータベースにロードする機能です。

### 3.1 Seedとは？

**Seed**は、コードで管理したい小さなマスターデータ（ステータス定義、カテゴリマスターなど）をCSVファイルからデータベーステーブルに変換する機能です。

**Seedが適しているケース：**
- ステータスコードと表示名のマッピング
- 国コードや地域コードのマスター
- 頻繁に変更されない小規模な参照データ

**Seedが適さないケース：**
- 大量のデータ（数千行以上）
- 頻繁に更新されるデータ
- 外部システムから取得するデータ

### 3.2 `dbt seed` コマンドの動作

```
dbt seed 実行時の流れ
┌─────────────────────────────────────────────────────────────────┐
│ 1. dbt_project.yml の seed-paths を参照                         │
│    → seeds/ ディレクトリを探す                                   │
│                                                                 │
│ 2. seeds/ 内のCSVファイルを検索                                  │
│    → order_status_master.csv を発見                             │
│                                                                 │
│ 3. CSVファイル名からテーブル名を決定                              │
│    → order_status_master（拡張子を除いた名前）                   │
│                                                                 │
│ 4. profiles.yml の接続先スキーマにテーブルを作成                  │
│    → dbt_dev.order_status_master テーブルが作成される            │
│                                                                 │
│ 5. CSVの内容をテーブルにINSERT                                   │
└─────────────────────────────────────────────────────────────────┘
```

### 3.3 参照されるファイルの関係

```
dbt_project.yml                 ← Seedの格納場所を定義
    │
    │  seed-paths: ["seeds"]
    ▼
seeds/
├── order_status_master.csv     ← 実際のデータ（CSVファイル）
└── schema.yml                  ← テスト・ドキュメント定義（任意）
```

#### dbt_project.yml（Seed関連の設定）

```yaml
seed-paths: ["seeds"]    # CSVファイルを探すディレクトリ
```

#### seeds/order_status_master.csv（マスターデータ）

```csv
status_code,status_label,description
completed,完了,注文が完了した状態
pending,処理中,注文が処理中の状態
cancelled,キャンセル,注文がキャンセルされた状態
```

**ポイント：**
- 1行目がカラム名（テーブルの列名になる）
- 2行目以降がデータ
- ファイル名（`order_status_master`）がそのままテーブル名になる

#### seeds/schema.yml（テスト・ドキュメント定義）

```yaml
version: 2

seeds:
  - name: order_status_master              # CSVファイル名と一致させる
    description: "注文ステータスのマスターデータ"
    columns:
      - name: status_code
        description: "ステータスコード"
        tests:
          - unique                         # 重複チェック
          - not_null                       # NULLチェック
      - name: status_label
        description: "ステータスの日本語ラベル"
```

**ポイント：**
- `seeds:`キーでSeed用の定義を記述（`models:`とは異なる）
- モデルと同様にテストを定義できる

### 3.4 Seedファイルを確認

```bash
cat seeds/order_status_master.csv
```

### 3.5 Seedを実行

```bash
dbt seed
```

出力例：
```
Running with dbt=1.x.x
Found 4 models, 1 seed, ...

Concurrency: 4 threads (target='dev')

1 of 1 START seed file dbt_dev.order_status_master
1 of 1 OK loaded seed file dbt_dev.order_status_master

Finished running 1 seed in 0.50s.
```

### 3.6 作成されたテーブルの確認

Seedを実行すると、以下のテーブルが作成されます：

| 項目 | 値 |
|------|-----|
| データベース | dbt_handson |
| スキーマ | dbt_dev（profiles.ymlで指定） |
| テーブル名 | order_status_master（CSVファイル名） |
| フルパス | `dbt_handson.dbt_dev.order_status_master` |

### 3.7 モデルからSeedを参照する方法

Seedで作成したテーブルは、`{{ ref() }}`関数で参照できます：

```sql
-- marts/order_status_summary.sql より
SELECT * FROM {{ ref('order_status_master') }}
```

dbtがコンパイルすると、以下のSQLに変換されます：

```sql
SELECT * FROM dbt_handson.dbt_dev.order_status_master
```

**ref()を使う理由：**
- スキーマ名を直接書かなくて良い（環境ごとに自動で切り替わる）
- 依存関係が自動的に記録される（Seedが先に実行される）

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

### 4.4 実行順序の仕組み

上記の出力を見ると、1と2が先に並列実行され、その後3と4が並列実行されています。
この順序は**特定の設定ファイルではなく、各SQLファイル内の `{{ ref() }}` と `{{ source() }}` で自動的に決まります**。

#### 依存関係による実行順序

```
┌─────────────────────────────────────────────────────────────┐
│  【第1フェーズ】1と2が並列実行                                │
│                                                             │
│  stg_customers.sql → {{ source('raw_data', 'customers') }}  │
│  stg_orders.sql    → {{ source('raw_data', 'orders') }}     │
│                                                             │
│  → どちらも source（生データ）のみを参照                      │
│  → 他のモデルに依存しない → 並列実行可能                      │
└─────────────────────────────────────────────────────────────┘
                           ↓ 完了後
┌─────────────────────────────────────────────────────────────┐
│  【第2フェーズ】3と4が並列実行                                │
│                                                             │
│  customer_orders.sql      → {{ ref('stg_customers') }}      │
│                           → {{ ref('stg_orders') }}         │
│                                                             │
│  order_status_summary.sql → {{ ref('stg_orders') }}         │
│                           → {{ ref('order_status_master') }}│
│                                                             │
│  → ステージング層に依存 → 第1フェーズ完了後に実行             │
│  → 3と4の間には相互依存がない → 並列実行可能                  │
└─────────────────────────────────────────────────────────────┘
```

#### 依存関係が定義されている場所

| モデル | ファイル | 依存先（ref/source） |
|--------|----------|---------------------|
| stg_customers | `models/staging/stg_customers.sql` | `source('raw_data', 'customers')` |
| stg_orders | `models/staging/stg_orders.sql` | `source('raw_data', 'orders')` |
| customer_orders | `models/marts/customer_orders.sql` | `ref('stg_customers')`, `ref('stg_orders')` |
| order_status_summary | `models/marts/order_status_summary.sql` | `ref('stg_orders')`, `ref('order_status_master')` |

#### ポイント

- **順序定義ファイルは存在しない** - dbtがSQLを解析して自動的に依存関係グラフ（DAG）を構築
- `{{ ref('モデル名') }}` を書くと、そのモデルへの依存が発生
- 依存関係のないモデル同士は並列実行される
- 最大並列数は `profiles.yml` の `threads: 4` で制御

### 4.5 特定のモデルだけ実行

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

出力例：
```
Running with dbt=1.x.x
Found 4 models, 17 data tests, 1 seed, 2 sources, 460 macros

Concurrency: 4 threads (target='dev')

1 of 17 START test accepted_values_customer_orders_customer_tier__Gold__Silver__Bronze
2 of 17 START test accepted_values_stg_orders_status__completed__pending__cancelled
3 of 17 START test assert_positive_order_amounts
...
17 of 17 PASS unique_stg_orders_order_id

Finished running 17 data tests in 0 hours 0 minutes and 2.51 seconds (2.51s).

Done. PASS=17 WARN=0 ERROR=0 SKIP=0 TOTAL=17
```

すべてのテストが `PASS` になれば成功です。

### 5.4 テスト名の読み方

dbtのテスト名は以下の規則で自動生成されます：

```
{テスト種類}_{モデル名}_{カラム名}[__{値}...]

例：accepted_values_stg_orders_status__completed__pending__cancelled
    └─────┬─────┘ └────┬────┘ └─┬─┘ └───────────┬───────────────┘
      テスト種類    モデル名   カラム名      許可される値（__区切り）
```

### 5.5 テストと定義ファイルの対応

17個のテストがどの定義ファイルに対応するかを示します。

#### カスタムテスト（tests/フォルダ）

| テスト名 | 定義ファイル |
|----------|--------------|
| `assert_positive_order_amounts` | `tests/assert_positive_order_amounts.sql` |

#### ステージング層（models/staging/schema.yml）

| テスト名 | モデル.カラム | テスト種類 |
|----------|---------------|------------|
| `not_null_stg_customers_customer_id` | stg_customers.customer_id | not_null |
| `unique_stg_customers_customer_id` | stg_customers.customer_id | unique |
| `not_null_stg_customers_email` | stg_customers.email | not_null |
| `unique_stg_customers_email` | stg_customers.email | unique |
| `not_null_stg_orders_order_id` | stg_orders.order_id | not_null |
| `unique_stg_orders_order_id` | stg_orders.order_id | unique |
| `not_null_stg_orders_customer_id` | stg_orders.customer_id | not_null |
| `relationships_stg_orders_customer_id__...` | stg_orders.customer_id | relationships |
| `accepted_values_stg_orders_status__...` | stg_orders.status | accepted_values |

#### マート層（models/marts/schema.yml）

| テスト名 | モデル.カラム | テスト種類 |
|----------|---------------|------------|
| `not_null_customer_orders_customer_id` | customer_orders.customer_id | not_null |
| `unique_customer_orders_customer_id` | customer_orders.customer_id | unique |
| `accepted_values_customer_orders_customer_tier__...` | customer_orders.customer_tier | accepted_values |
| `not_null_order_status_summary_status` | order_status_summary.status | not_null |
| `unique_order_status_summary_status` | order_status_summary.status | unique |

#### Seed（seeds/schema.yml）

| テスト名 | モデル.カラム | テスト種類 |
|----------|---------------|------------|
| `not_null_order_status_master_status_code` | order_status_master.status_code | not_null |
| `unique_order_status_master_status_code` | order_status_master.status_code | unique |

#### 定義ファイルとテスト名の対応例

```yaml
# models/staging/schema.yml
models:
  - name: stg_orders
    columns:
      - name: order_id
        tests:
          - unique    # → unique_stg_orders_order_id
          - not_null  # → not_null_stg_orders_order_id
      - name: status
        tests:
          - accepted_values:
              values: ['completed', 'pending', 'cancelled']
              # → accepted_values_stg_orders_status__completed__pending__cancelled
```

### 5.6 カスタムテスト

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

dbtコンテナ内で以下を実行します：

```bash
dbt docs generate
```

出力例：
```
Running with dbt=1.x.x
Found 4 models, 17 data tests, 1 seed, 2 sources, 460 macros

Building catalog
Catalog written to /dbt/target/catalog.json
```

### 6.2 ドキュメントをブラウザで確認

dbtドキュメントサーバはコンテナ内で起動するため、ホストPCのブラウザからアクセスするには**ポートマッピング**が必要です。

#### 方法1: dbtコンテナ内から起動（推奨）

docker-compose.ymlにポートマッピング（`8080:8080`）が設定されているため、dbtコンテナ内から直接起動できます：

```bash
# dbtコンテナ内で実行
dbt docs serve --port 8080
```

#### 方法2: 別ターミナルから起動

dbtコンテナ内で他の作業をしている場合は、**別のターミナル**を開いて以下を実行します：

```bash
# ホストPCの別ターミナルで実行（プロジェクトディレクトリで）
docker compose exec dbt dbt docs serve --port 8080
```

#### ブラウザでアクセス

サーバ起動後、ブラウザで以下のURLを開きます：

**http://localhost:8080**

データリネージ（依存関係図）やカラムの説明を確認できます。

```
ホストPC                          Dockerコンテナ
┌─────────────────┐              ┌─────────────────┐
│                 │    8080      │                 │
│  ブラウザ  ────────────────────▶  dbt docs serve │
│                 │   ポート     │   (port 8080)   │
│ localhost:8080  │  マッピング  │                 │
└─────────────────┘              └─────────────────┘
```

**Ctrl+C** で停止します。

> **Note**
> もしポート8080が使用中の場合は、別のポート（例：8081）を指定してください：
> ```bash
> dbt docs serve --port 8081
> ```
> その場合、docker-compose.ymlのポートマッピングも `"8081:8081"` に変更が必要です。

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
