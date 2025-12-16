-- macros/cents_to_dollars.sql
-- 金額をフォーマットするマクロの例

{% macro format_currency(amount, prefix='¥') %}
    {{ prefix }} || CAST({{ amount }} AS VARCHAR)
{% endmacro %}
