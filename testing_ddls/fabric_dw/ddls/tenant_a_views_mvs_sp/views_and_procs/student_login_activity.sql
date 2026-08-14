CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_student_login_activity
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.student_login_activity_staging;

        -- --------------------------------------------------------
        -- Step 2: CTAS - Build staging table with full transformation
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.student_login_activity_staging
        WITH (CLUSTER BY (school_dw_id, available_student_dw_id))
        AS
        WITH total_students AS (
            SELECT DISTINCT
                full_date                                        AS local_date,
                tenant_name,
                dsc.school_dw_id,
                dsc.school_id,
                dsc.school_name,
                dsc.school_city_name,
                dsc.school_organisation,
                dsc.organisation_dw_id,
                dsc.school_country_name,
                dsc.school_composition,
                dsc.school_alias                                 AS adek_id,
                dsc.school_created_time,
                CONCAT(CONVERT(VARCHAR(4), YEAR(dsc.academic_year_start_date)), '-',
                       CONVERT(VARCHAR(4), YEAR(dsc.academic_year_end_date))) AS academic_year,
                dsc.academic_year_start_date,
                dsc.academic_year_end_date,
                dg.grade_k12grade                               AS grade,
                section_dw_id,
                section_name                                AS [section],
                ds.student_tags,
                ds.student_special_needs                        AS special_needs,
                ds.student_dw_id                                AS available_student_dw_id,
                ds.student_id,
                ds.student_username,
                ds.student_first_created_date,
                FIRST_VALUE(ds.student_status) OVER (
                    PARTITION BY dsc.school_dw_id, section_dw_id,ds.student_dw_id 
                    ORDER BY ds.student_created_time DESC
                    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                )                                               AS student_current_status,
                dsc.school_label,
                dsc.school_cx_cluster
            FROM (
                SELECT full_date, section_name, section_dw_id, grade_id, school_id, tenant_id, section_id
                FROM ${rs_coredw}.dim_section
                CROSS JOIN (
                    SELECT DISTINCT full_date
                    FROM ${rs_coredw}.dim_date AS dt
                    WHERE dt.full_date BETWEEN DATEADD(DAY, -90, CONVERT(DATE, GETDATE())) AND CONVERT(DATE, GETDATE())
                ) AS dates
                WHERE school_id IS NOT NULL
            ) AS dse_cj
            INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim AS dsc
                ON dsc.school_id = dse_cj.school_id
                AND (full_date >= dsc.academic_year_start_date AND full_date <= dsc.academic_year_end_date)
            INNER JOIN ${rs_bi_coredw}.bi_student_dim AS ds
                ON ds.student_section_dw_id = dse_cj.section_dw_id
                AND (
                    (ds.student_status = 2
                     AND full_date >= CONVERT(DATE, ds.student_created_time AT TIME ZONE 'UTC' AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC'))
                     AND full_date < CONVERT(DATE, ds.student_active_until AT TIME ZONE 'UTC' AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')))
                    OR (ds.student_status = 1
                        AND full_date >= CONVERT(DATE, ds.student_created_time AT TIME ZONE 'UTC' AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')))
                )
            INNER JOIN ${rs_coredw}.dim_grade AS dg
                ON dse_cj.grade_id = dg.grade_id
                AND dg.grade_dw_id = ds.student_grade_dw_id
                AND dsc.academic_year_id = dg.academic_year_id
            WHERE dsc.school_id = '3e9bf712-c13e-43e1-a64f-d5180ea9ee9c'
        ),
        active_students AS (
            SELECT DISTINCT
                login_date,
                student_section_dw_id,
                student_tags,
                special_needs,
                active_student_dw_id
            FROM (
                SELECT DISTINCT
                    CONVERT(DATE, sl.login_local_date_time)                 AS login_date,
                    bsd.student_section_dw_id,
                    bsd.student_tags,
                    bsd.student_special_needs                               AS special_needs,
                    sl.student_dw_id                                        AS active_student_dw_id
                FROM ${rs_bi_coredw}.student_login AS sl
                INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim AS dsc
                    ON dsc.school_dw_id = sl.school_dw_id
                INNER JOIN ${rs_bi_coredw}.bi_student_dim AS bsd
                    ON bsd.student_dw_id = sl.student_dw_id
                    AND (
                        (bsd.student_status = 2
                         AND CONVERT(DATE, sl.login_local_date_time) >= CONVERT(DATE, bsd.student_created_time AT TIME ZONE 'UTC' AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC'))
                         AND CONVERT(DATE, sl.login_local_date_time) < CONVERT(DATE, bsd.student_active_until AT TIME ZONE 'UTC' AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')))
                        OR (bsd.student_status = 1
                            AND CONVERT(DATE, sl.login_local_date_time) >= CONVERT(DATE, bsd.student_created_time AT TIME ZONE 'UTC' AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')))
                    )
                WHERE dsc.school_id = '3e9bf712-c13e-43e1-a64f-d5180ea9ee9c'
                    AND CONVERT(DATE, sl.login_local_date_time) >= DATEADD(DAY, -90, CONVERT(DATE, GETDATE() AT TIME ZONE 'UTC' AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')))
                    AND CONVERT(DATE, sl.login_local_date_time) <= CONVERT(DATE, GETDATE() AT TIME ZONE 'UTC' AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC'))
            ) AS sub
        ),
        student_onboarding AS (
            SELECT DISTINCT
                sl.student_dw_id,
                sl.school_dw_id,
                FIRST_VALUE(sl.login_local_date_time) OVER (
                    PARTITION BY sl.student_dw_id, sl.school_dw_id
                    ORDER BY sl.login_local_date_time ASC
                    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                ) AS student_first_login_date,
                FIRST_VALUE(sl.login_local_date_time) OVER (
                    PARTITION BY sl.student_dw_id, sl.school_dw_id
                    ORDER BY sl.login_local_date_time DESC
                    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                ) AS student_last_login_date
            FROM ${rs_bi_coredw}.student_login AS sl
            INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim AS dsc
                ON dsc.school_dw_id = sl.school_dw_id
                AND CONVERT(DATE, sl.login_local_date_time) >= dsc.academic_year_start_date
            WHERE dsc.school_id = '3e9bf712-c13e-43e1-a64f-d5180ea9ee9c'
        ),
        lessons_started AS (
            SELECT DISTINCT
                fle.fle_student_dw_id,
                MIN(CONVERT(DATE, fle.fle_created_time)) AS student_lesson_start_date
            FROM ${rs_coredw}.fact_learning_experience AS fle
            INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim AS dsc
                ON dsc.school_dw_id = fle.fle_school_dw_id
                AND CONVERT(DATE, fle.fle_created_time) >= dsc.academic_year_start_date
            WHERE fle.fle_activity_type <> 'INTERIM_CHECKPOINT'
                AND dsc.school_id = '3e9bf712-c13e-43e1-a64f-d5180ea9ee9c'
            GROUP BY fle.fle_student_dw_id
        ),
        holidays_dimension AS (
            SELECT DISTINCT
                CONVERT(DATE, holiday_date)             AS holiday_date,
                holiday_organisation_dw_id
            FROM ${rs_coredw}.dim_holiday
        )
        SELECT DISTINCT
            ts.local_date,
            ts.academic_year,
            ts.tenant_name,
            ts.school_dw_id,
            ts.school_id,
            ts.school_name,
            ts.school_created_time,
            ts.adek_id,
            ts.school_city_name,
            ts.school_organisation,
            ts.school_country_name,
            ts.school_composition,
            ts.school_label,
            ts.grade,
            UPPER(ts.section)                           AS section,
            ts.student_tags,
            ts.special_needs,
            ts.available_student_dw_id,
            ast.active_student_dw_id,
            ts.student_id,
            ts.student_username,
            ts.student_first_created_date,
            ts.student_current_status,
            so.student_first_login_date,
            so.student_last_login_date,
            ls.student_lesson_start_date,
            ts.academic_year_start_date,
            ts.academic_year_end_date,
            ts.section_dw_id,
            CASE 
                WHEN dh.holiday_date IS NULL THEN 'FALSE'
                ELSE 'TRUE'
            END AS holiday_flag,
            ts.school_cx_cluster
        FROM total_students AS ts
        LEFT JOIN active_students AS ast
            ON ts.section_dw_id = ast.student_section_dw_id
            AND ts.local_date = ast.login_date
            AND ts.student_tags = ast.student_tags
            AND ts.special_needs = ast.special_needs
            AND ts.available_student_dw_id = ast.active_student_dw_id
        LEFT JOIN student_onboarding AS so
            ON ts.available_student_dw_id = so.student_dw_id
            AND ts.school_dw_id = so.school_dw_id
        LEFT JOIN lessons_started AS ls
            ON ts.available_student_dw_id = ls.fle_student_dw_id
        LEFT JOIN holidays_dimension AS dh
            ON dh.holiday_date = ts.local_date
            AND dh.holiday_organisation_dw_id = ts.organisation_dw_id;

        -- --------------------------------------------------------
        -- Step 3: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.student_login_activity;

        -- --------------------------------------------------------
        -- Step 4: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.student_login_activity_staging', 'student_login_activity';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
