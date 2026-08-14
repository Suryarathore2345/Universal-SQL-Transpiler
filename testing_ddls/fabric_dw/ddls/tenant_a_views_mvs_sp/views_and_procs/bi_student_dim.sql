CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_bi_student_dim
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.bi_student_dim_staging;

        -- --------------------------------------------------------
        -- Step 2: CTAS - Build staging table with full transformation
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.bi_student_dim_staging
        WITH (CLUSTER BY (student_dw_id, student_school_dw_id))
        AS
            WITH student_curr_info AS (
                SELECT DISTINCT
                    student_dw_id,
                    student_tags,
                    student_special_needs,
                    student_first_created_date
                FROM (
                    SELECT
                        dst.student_dw_id,
                        CASE
                            WHEN ISNULL(TRIM(dst.student_tags), '')
                                NOT IN ('CoreStars', 'Elite', 'Elite, CoreStars')
                            THEN 'Non Elite'
                            ELSE TRIM(dst.student_tags)
                        END AS student_tags,
                        CASE
                            WHEN ISNULL(TRIM(dst.student_special_needs), 'n/a') <> 'n/a'
                            THEN 'Yes'
                            ELSE 'No'
                        END AS student_special_needs,
                        FIRST_VALUE(
                            CAST(
                                CAST(dst.student_created_time AT TIME ZONE 'UTC' AT TIME ZONE ISNULL(ds.school_windows_timezone, 'UTC') AS DATETIME2(6))
                                AS DATE
                            )
                        ) OVER (
                            PARTITION BY dst.student_dw_id
                            ORDER BY dst.student_created_time
                            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                        ) AS student_first_created_date,
                        ROW_NUMBER() OVER (
                            PARTITION BY dst.student_dw_id
                            ORDER BY dst.student_created_time DESC
                        ) AS rnk
                    FROM ${rs_coredw}.dim_student AS dst
                    INNER JOIN ${rs_coredw}.dim_school AS ds
                        ON dst.student_school_dw_id = ds.school_dw_id
                ) AS subq
                WHERE rnk = 1
            )
            SELECT DISTINCT
                sci.student_dw_id,
                ds.student_id,
                ds.student_username,
                ds.student_school_dw_id,
                ds.student_section_dw_id,
                ds.student_grade_dw_id,
                ds.student_created_time,
                ds.student_active_until,
                ds.student_status,
                sci.student_tags,
                sci.student_special_needs,
                sci.student_first_created_date,
                CAST(
                    ds.student_created_time AT TIME ZONE 'UTC'
                        AT TIME ZONE ISNULL(t.windows_timezone, 'UTC')
                AS DATE) AS student_created_time_local,
                CAST(
                    ds.student_active_until AT TIME ZONE 'UTC'
                        AT TIME ZONE ISNULL(t.windows_timezone, 'UTC')
                AS DATE) AS student_active_until_local
            FROM ${rs_coredw}.dim_student AS ds
            INNER JOIN student_curr_info AS sci
                ON ds.student_dw_id = sci.student_dw_id
            INNER JOIN ${rs_coredw}.dim_school AS dsch
                ON dsch.school_dw_id = ds.student_school_dw_id
            INNER JOIN ${rs_coredw}.dim_tenant AS t
                ON t.tenant_id = dsch.school_tenant_id;
            -- --------------------------------------------------------
        -- Step 3: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.bi_student_dim;

        -- --------------------------------------------------------
        -- Step 4: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.bi_student_dim_staging', 'bi_student_dim';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
