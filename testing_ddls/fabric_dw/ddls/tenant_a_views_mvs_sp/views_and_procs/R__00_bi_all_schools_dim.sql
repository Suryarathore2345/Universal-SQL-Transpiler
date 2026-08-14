CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_bi_all_schools_dim
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.bi_all_schools_dim_staging;

        -- --------------------------------------------------------
        -- Step 2: CTAS - Build staging table with full transformation
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.bi_all_schools_dim_staging
        WITH (CLUSTER BY (school_dw_id, school_id))
        AS
        WITH school_academic_year AS (
            SELECT
                saya.saya_school_id,
                saya.academic_year_dw_id,
                saya.academic_year_id,
                saya.academic_year_type,
                LEAST(
                    saya.academic_year_start_date,
                    ISNULL(ay2.academic_year_start_date, saya.academic_year_start_date)
                ) AS academic_year_start_date,
                saya.academic_year_end_date,
                saya.academic_year_is_roll_over_completed
            FROM (
                SELECT
                    sayarn.saya_school_id,
                    sayarn.saya_previous_academic_year_id,
                    sayarn.saya_type,
                    sayarn.saya_created_time,
                    sayarn.saya_academic_year_id,
                    ay.academic_year_dw_id,
                    ay.academic_year_id,
                    ay.academic_year_type,
                    ay.academic_year_start_date,
                    ay.academic_year_end_date,
                    ay.academic_year_is_roll_over_completed,
                    ROW_NUMBER() OVER (
                        PARTITION BY sayarn.saya_school_id, YEAR(ay.academic_year_start_date)
                        ORDER BY sayarn.saya_created_time DESC
                    ) AS rn
                FROM ${rs_coredw}.dim_school_academic_year_association AS sayarn
                INNER JOIN ${rs_coredw}.dim_academic_year AS ay
                    ON sayarn.saya_academic_year_id = ay.academic_year_id
                WHERE ay.academic_year_status = 1
            ) AS saya
            LEFT JOIN ${rs_coredw}.dim_academic_year AS ay2
                ON saya.saya_previous_academic_year_id = ay2.academic_year_id
                AND ay2.academic_year_status = 1
                AND saya.saya_type = 'SWITCH'
            WHERE saya.rn = 1
        )
        SELECT
            dsc.school_dw_id,
            dsc.school_id,
            UPPER(TRIM(dsc.school_name))                        AS school_name,
            dsc.school_city_name,
            org.organization_name                               AS school_organisation,
            org.organization_dw_id                              AS organisation_dw_id,
            dsc.school_country_name,
            dsc.school_composition,
            dsc.school_latitude,
            dsc.school_longitude,
            dsc.school_cx_cluster,
            dsc.school_alias,
            dtn.tenant_id,
            dtn.tenant_dw_id,
            dtn.tenant_name,
            dtn.windows_timezone,
            CASE
                WHEN dtn.tenant_name = 'Private' THEN CONCAT('Private ', dsc.school_country_name)
                WHEN dsc.school_country_name = 'CANADA' THEN dsc.school_country_name
                ELSE dtn.tenant_name
            END                                                 AS tenant_name_alias,
            dtn.tenant_timezone,
            ISNULL(dtg.tag_name, 'NA')                          AS school_label,
            dsc.school_created_time,
            dsc.school_updated_time,
            dsc.school_status,
            aay.saya_school_id,
            aay.academic_year_dw_id,
            aay.academic_year_id,
            aay.academic_year_type,
            aay.academic_year_start_date,
            aay.academic_year_end_date,
            aay.academic_year_is_roll_over_completed
        FROM ${rs_coredw}.dim_school AS dsc
        INNER JOIN school_academic_year AS aay
            ON dsc.school_id = aay.saya_school_id
        LEFT JOIN (
            SELECT
                tag_association_id,
                STRING_AGG(tag_name, ',') WITHIN GROUP (ORDER BY tag_name) AS tag_name
            FROM ${rs_coredw}.dim_tag
            WHERE tag_status = 1
              AND tag_association_attach_status = 1
            GROUP BY tag_association_id
        ) AS dtg
            ON dtg.tag_association_id = dsc.school_id
        LEFT JOIN ${rs_coredw}.dim_tenant AS dtn
            ON dtn.tenant_id = dsc.school_tenant_id
        LEFT JOIN ${rs_coredw}.dim_organization AS org
            ON dsc.school_organization_dw_id = org.organization_dw_id
        WHERE LOWER(ISNULL(dtg.tag_name, 'NA')) NOT LIKE '%core_test_schools%'
          AND dsc.school_deleted_time IS NULL;

        -- --------------------------------------------------------
        -- Step 3: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.bi_all_schools_dim;

        -- --------------------------------------------------------
        -- Step 4: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.bi_all_schools_dim_staging', 'bi_all_schools_dim';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
