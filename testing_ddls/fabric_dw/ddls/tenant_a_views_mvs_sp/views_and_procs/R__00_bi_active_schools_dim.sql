CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_bi_active_schools_dim
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.bi_active_schools_dim_staging;

        -- --------------------------------------------------------
        -- Step 2: CTAS - Build staging table with full transformation
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.bi_active_schools_dim_staging
        WITH (CLUSTER BY (school_dw_id, school_id))
        AS
        WITH active_academic_year AS
        (
            SELECT
                saya.saya_school_id,
                ay.academic_year_dw_id,
                ay.academic_year_id,
                ay.academic_year_type,
                CASE
                    WHEN ay2.academic_year_start_date IS NULL
                            OR ay.academic_year_start_date <= ay2.academic_year_start_date
                        THEN ay.academic_year_start_date
                    ELSE ay2.academic_year_start_date
                END AS academic_year_start_date,
                ay.academic_year_end_date
            FROM ${rs_coredw}.dim_school_academic_year_association AS saya
            INNER JOIN ${rs_coredw}.dim_academic_year AS ay
                ON saya.saya_academic_year_id = ay.academic_year_id
            LEFT JOIN ${rs_coredw}.dim_academic_year AS ay2
                ON saya.saya_previous_academic_year_id = ay2.academic_year_id
                AND ay2.academic_year_is_roll_over_completed = 0
                AND ay2.academic_year_status = 1
                AND saya.saya_type = 'SWITCH'
            WHERE saya.saya_status = 1
                AND ay.academic_year_status = 1
                AND ay.academic_year_is_roll_over_completed = 0
        )
        SELECT DISTINCT
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
            dtn.tenant_name,
            dtn.tenant_timezone,
            dtn.windows_timezone,
            ISNULL(dtg.tag_name, 'NA')                          AS school_label,
            FIRST_VALUE(dsc.school_created_time) OVER
            (
                PARTITION BY dsc.school_dw_id
                ORDER BY dsc.school_created_time ASC
                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            )                                                   AS school_created_time,
            aay.saya_school_id,
            aay.academic_year_dw_id,
            aay.academic_year_id,
            aay.academic_year_type,
            aay.academic_year_start_date,
            aay.academic_year_end_date
        FROM ${rs_coredw}.dim_school AS dsc
        INNER JOIN active_academic_year AS aay
            ON dsc.school_id = aay.saya_school_id
        LEFT JOIN
        (
            SELECT
                tag_association_id,
                STRING_AGG(CONVERT(VARCHAR(1024), tag_name), ',') WITHIN GROUP (ORDER BY tag_name) AS tag_name
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
        WHERE dsc.school_status = 1
            AND ISNULL(dtg.tag_name, 'NA') NOT LIKE '%core_test_schools%';

        -- --------------------------------------------------------
        -- Step 3: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.bi_active_schools_dim;

        -- --------------------------------------------------------
        -- Step 4: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.bi_active_schools_dim_staging', 'bi_active_schools_dim';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
