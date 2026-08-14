CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_student_login_activity_biweekly
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.student_login_activity_biweekly_staging;

        -- --------------------------------------------------------
        -- Step 2: CTAS - Build staging table with full transformation
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.student_login_activity_biweekly_staging
        WITH (CLUSTER BY (school_dw_id, local_date))
        AS
        WITH date_window AS
        (
            SELECT full_date
            FROM ${rs_coredw}.dim_date
            WHERE full_date BETWEEN DATEADD(DAY, -14, CONVERT(DATE, GETDATE()))
                                AND CONVERT(DATE, GETDATE())
        ),

        active_school_day AS
        (
            SELECT
                dw.full_date,
                dsc.tenant_name,
                dsc.school_dw_id,
                dsc.school_id,
                dsc.school_name,
                dsc.school_city_name,
                dsc.school_organisation,
                dsc.organisation_dw_id,
                dsc.school_country_name,
                dsc.school_composition,
                dsc.school_alias                                                 AS adek_id,
                dsc.school_created_time,
                CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_start_date))
                    + '-' +
                CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_end_date)) AS academic_year,
                dsc.academic_year_start_date,
                dsc.academic_year_end_date,
                dsc.academic_year_id,
                dsc.school_label,
                dsc.school_cx_cluster
            FROM ${rs_bi_coredw}.bi_active_schools_dim AS dsc
            INNER JOIN date_window AS dw
                ON dw.full_date BETWEEN dsc.academic_year_start_date
                                    AND dsc.academic_year_end_date
        ),

        total_students AS
        (
            SELECT DISTINCT
                dsc.full_date                                                    AS local_date,
                dsc.tenant_name,
                dsc.school_dw_id,
                dsc.school_id,
                dsc.school_name,
                dsc.school_city_name,
                dsc.school_organisation,
                dsc.organisation_dw_id,
                dsc.school_country_name,
                dsc.school_composition,
                dsc.adek_id,
                dsc.school_created_time,
                dsc.academic_year,
                dsc.academic_year_start_date,
                dsc.academic_year_end_date,
                dg.grade_k12grade                                                AS grade,
                ''                                                               AS class,
                dse.section_dw_id,
                dse.section_alias                                                AS section,
                ds.student_tags,
                ds.student_special_needs                                         AS special_needs,
                ds.student_dw_id                                                 AS available_student_dw_id,
                ds.student_id,
                ds.student_username,
                ds.student_first_created_date,
                FIRST_VALUE(ds.student_status) OVER
                (
                    PARTITION BY dsc.school_dw_id, dse.section_dw_id, ds.student_dw_id
                    ORDER BY ds.student_created_time DESC
                )                                                                AS student_current_status,
                dsc.school_label,
                dsc.school_cx_cluster
            FROM active_school_day AS dsc
            INNER JOIN ${rs_coredw}.dim_section AS dse
                ON dsc.school_id = dse.school_id
            INNER JOIN ${rs_bi_coredw}.bi_student_dim AS ds
                ON ds.student_section_dw_id = dse.section_dw_id
                AND
                (
                    (
                        ds.student_status = 2
                        AND dsc.full_date >= ds.student_created_time_local
                        AND dsc.full_date < ds.student_active_until_local
                    )
                    OR
                    (
                        ds.student_status = 1
                        AND dsc.full_date >= ds.student_created_time_local
                    )
                )
            INNER JOIN ${rs_coredw}.dim_grade AS dg
                ON dse.grade_id = dg.grade_id
                AND dg.grade_dw_id = ds.student_grade_dw_id
                AND dsc.school_id = dg.school_id
                AND dsc.academic_year_id = dg.academic_year_id
        ),

        active_students AS
        (
            SELECT DISTINCT
                CONVERT(DATE, sl.login_local_date_time)  AS login_date,
                ds.student_section_dw_id,
                ds.student_tags,
                ds.student_special_needs                 AS special_needs,
                sl.student_dw_id                         AS active_student_dw_id
            FROM ${rs_bi_coredw}.student_login AS sl
            INNER JOIN ${rs_bi_coredw}.bi_student_dim AS ds
                ON ds.student_dw_id = sl.student_dw_id
                AND
                (
                    (
                        ds.student_status = 2
                        AND CONVERT(DATE, sl.login_local_date_time) >= ds.student_created_time_local
                        AND CONVERT(DATE, sl.login_local_date_time) < ds.student_active_until_local
                    )
                    OR
                    (
                        ds.student_status = 1
                        AND CONVERT(DATE, sl.login_local_date_time) >= ds.student_created_time_local
                    )
                )
            WHERE CONVERT(DATE, sl.login_local_date_time)
                  BETWEEN DATEADD(DAY, -14, CONVERT(DATE, GETDATE()))
                      AND CONVERT(DATE, GETDATE())
        ),

        student_onboarding AS
        (
            SELECT DISTINCT
                sl.student_dw_id,
                sl.school_dw_id,
                FIRST_VALUE(sl.login_local_date_time) OVER
                (
                    PARTITION BY sl.student_dw_id, sl.school_dw_id
                    ORDER BY sl.login_local_date_time ASC
                )                                        AS student_first_login_date,
                FIRST_VALUE(sl.login_local_date_time) OVER
                (
                    PARTITION BY sl.student_dw_id, sl.school_dw_id
                    ORDER BY sl.login_local_date_time DESC
                )                                        AS student_last_login_date
            FROM ${rs_bi_coredw}.student_login AS sl
            WHERE EXISTS
            (
                SELECT 1
                FROM ${rs_bi_coredw}.bi_active_schools_dim AS dsc
                WHERE sl.school_dw_id = dsc.school_dw_id
                    AND CONVERT(DATE, sl.login_local_date_time)
                        BETWEEN dsc.academic_year_start_date
                            AND dsc.academic_year_end_date
            )
        ),

        school_previousay AS
        (
            SELECT
                school_dw_id,
                MAX(academic_year_start_date)            AS previous_academic_year_start_date,
                MAX(academic_year_end_date)              AS previous_academic_year_end_date
            FROM ${rs_bi_coredw}.bi_all_schools_dim
            WHERE academic_year_is_roll_over_completed = 1
            GROUP BY school_dw_id
        ),

        student_onboarding_pay AS
        (
            SELECT DISTINCT sl.student_dw_id
            FROM ${rs_bi_coredw}.student_login AS sl
            WHERE EXISTS
            (
                SELECT 1
                FROM school_previousay AS spay
                WHERE sl.school_dw_id = spay.school_dw_id
                    AND CONVERT(DATE, sl.login_local_date_time)
                        BETWEEN spay.previous_academic_year_start_date
                            AND spay.previous_academic_year_end_date
            )
        ),

        lessons_started AS
        (
            SELECT DISTINCT
                fle.fle_student_dw_id,
                MIN(CONVERT(DATE, fle.fle_created_time)) AS student_lesson_start_date
            FROM ${rs_coredw}.fact_learning_experience AS fle
            WHERE fle.fle_activity_type <> 'INTERIM_CHECKPOINT'
                AND EXISTS
                (
                    SELECT 1
                    FROM ${rs_bi_coredw}.bi_active_schools_dim AS dsc
                    WHERE dsc.school_dw_id = fle.fle_school_dw_id
                        AND CONVERT(DATE, fle.fle_created_time) >= dsc.academic_year_start_date
                )
            GROUP BY fle.fle_student_dw_id
        ),

        holidays_dimension AS
        (
            SELECT DISTINCT
                CONVERT(DATE, holiday_date)              AS holiday_date,
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
            UPPER(ts.class)                                                      AS class,
            UPPER(ts.section)                                                    AS section,
            ts.student_tags,
            ts.special_needs,
            ts.available_student_dw_id,
            CASE WHEN pay_st.student_dw_id IS NULL THEN 0 ELSE 1 END            AS repeat_student_previous_ay,
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
            CONVERT
            (
                BIT,
                CASE WHEN dh.holiday_date IS NULL THEN 0 ELSE 1 END
            )                                                                    AS holiday_flag,
            ts.school_cx_cluster
        FROM total_students AS ts
        LEFT JOIN active_students AS ast
            ON ts.section_dw_id             = ast.student_section_dw_id
            AND ts.local_date               = ast.login_date
            AND ts.student_tags             = ast.student_tags
            AND ts.special_needs            = ast.special_needs
            AND ts.available_student_dw_id  = ast.active_student_dw_id
        LEFT JOIN student_onboarding AS so
            ON ts.available_student_dw_id   = so.student_dw_id
            AND ts.school_dw_id             = so.school_dw_id
        LEFT JOIN student_onboarding_pay AS pay_st
            ON ts.available_student_dw_id   = pay_st.student_dw_id
        LEFT JOIN lessons_started AS ls
            ON ts.available_student_dw_id   = ls.fle_student_dw_id
        LEFT JOIN holidays_dimension AS dh
            ON dh.holiday_date              = ts.local_date
            AND dh.holiday_organisation_dw_id = ts.organisation_dw_id;

        -- --------------------------------------------------------
        -- Step 3: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.student_login_activity_biweekly;

        -- --------------------------------------------------------
        -- Step 4: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.student_login_activity_biweekly_staging', 'student_login_activity_biweekly';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;