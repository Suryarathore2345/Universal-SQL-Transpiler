CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_prev_ay_bi_schools
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.prev_ay_bi_schools_staging;

        -- --------------------------------------------------------
        -- Step 2: CTAS - Build staging table with full transformation
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.prev_ay_bi_schools_staging
        WITH (CLUSTER BY (school_dw_id, school_id))
        AS
        SELECT DISTINCT
            dsc.school_dw_id,
            dsc.school_id,
            UPPER(TRIM(dsc.school_name))                        AS school_name,
            dsc.school_city_name,
            org.content_repository_name                         AS school_organisation,
            org.content_repository_dw_id                        AS organisation_dw_id,
            dsc.school_country_name,
            dsc.school_composition,
            dsc.school_latitude,
            dsc.school_longitude,
            dsc.school_cx_cluster,
            dsc.school_alias,
            dtn.tenant_id,
            dtn.tenant_name,
            dtn.tenant_timezone,
            dtn.windows_timezone,
            ISNULL(dtg.tag_name, 'NA')                          AS school_label,
            FIRST_VALUE(dsc.school_created_time) OVER (
                PARTITION BY dsc.school_dw_id
                ORDER BY dsc.school_created_time ASC
                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            )                                                   AS school_created_time
        FROM ${rs_coredw}.dim_school AS dsc
        LEFT JOIN (
            SELECT DISTINCT
                tag_association_id,
                STRING_AGG(CONVERT(VARCHAR(1024), tag_name), ',') WITHIN GROUP (ORDER BY tag_name) AS tag_name
            FROM ${rs_coredw}.dim_tag AS dt
            WHERE tag_status = 1
                AND tag_association_attach_status = 1
            GROUP BY tag_association_id
        ) AS dtg
            ON dtg.tag_association_id = dsc.school_id
        LEFT JOIN ${rs_coredw}.dim_tenant AS dtn
            ON dtn.tenant_id = dsc.school_tenant_id
        LEFT JOIN ${rs_coredw}.dim_content_repository AS org
            ON dsc.school_content_repository_dw_id = org.content_repository_dw_id
        WHERE LOWER(ISNULL(dtg.tag_name, 'NA')) NOT LIKE '%core_test_schools%';

        -- --------------------------------------------------------
        -- Step 3: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.prev_ay_bi_schools;

        -- --------------------------------------------------------
        -- Step 4: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.prev_ay_bi_schools_staging', 'prev_ay_bi_schools';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
