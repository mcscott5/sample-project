{% snapshot snap__part %}

    {{ config(
        unique_key='p_partkey',
        strategy='check',
        check_cols=['p_retailprice', 'p_comment'],
    ) }}

    select * from {{ source('snowflake_sample_shop', 'part') }}

{% endsnapshot %}