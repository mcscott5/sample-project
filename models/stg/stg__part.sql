with parts as (

    select * from {{ ref('snap__part') }} -- /snapshots/snap__part.sql (part snapshot)

),

renamed as (

    select
        p_partkey as part_id,
        INITCAP(trim(p_name)) as name,
        p_comment as comment,
        p_retailprice as retail_price,
        p_mfgr as manufacturer,
        p_size as size,
        p_container as container
    from
        parts
    where
        dbt_valid_to is null    -- filter to only the snapshot's currently active records
        )

select * from renamed