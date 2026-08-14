CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_students_ic_progress
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.students_ic_progress_staging;

        -- --------------------------------------------------------
        -- Step 2: CTAS - Build staging table with full transformation
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.students_ic_progress_staging
        WITH (CLUSTER BY (student_dw_id, fle_class_dw_id))
        AS
        WITH student_lessons_assigned AS (
            SELECT DISTINCT
                d_cu.class_user_user_dw_id,
                d_cu.class_user_class_dw_id,
                dcaa.caa_activity_dw_id AS lo_dw_id
            FROM ${rs_coredw}.dim_class_user AS d_cu
            INNER JOIN ${rs_coredw}.dim_class AS dc
                ON dc.class_dw_id = d_cu.class_user_class_dw_id
            INNER JOIN ${rs_coredw}.dim_course AS dcr
                ON dcr.course_id = dc.class_material_id
            INNER JOIN ${rs_coredw}.dim_course_activity_association AS dcaa
                ON dcaa.caa_course_id = dcr.course_id
            WHERE d_cu.class_user_attach_status = 1
              AND d_cu.class_user_status = 1
              AND d_cu.class_user_role_dw_id = 2
              AND dc.class_course_status = 'ACTIVE'
              AND dcr.course_status = 1
              AND dcr.course_type = 'CORE'
              AND dcaa.caa_status = 1
              AND dcaa.caa_attach_status = 1
              AND dc.class_status = 1
        )
        SELECT DISTINCT
            CONVERT(DATE, fle.fle_created_time AT TIME ZONE 'UTC' AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')) AS local_date,
            dcu.class_user_class_dw_id                              AS fle_class_dw_id,
            fle.fle_lo_dw_id,
            fle.fle_lesson_category,
            fle.fle_dw_id,
            fle.fle_source,
            CASE
                WHEN fle.fle_completion_node = 1 THEN 'Completed'
                ELSE 'In-Progress'
            END                                                     AS ic_status,
            dst.student_dw_id,
            dst.student_section_dw_id,
            dst.student_tags,
            dst.student_special_needs,
            dg.grade_k12grade,
            fle.fle_total_score,
            SUM(
                CASE
                    WHEN fle.fle_total_time <= 1200 THEN fle.fle_total_time
                    WHEN fle.fle_total_time > 1200  THEN 1200
                    ELSE 0
                END
            ) OVER (
                PARTITION BY
                    CONVERT(DATE, fle.fle_created_time AT TIME ZONE 'UTC' AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')),
                    dst.student_dw_id,
                    fle.fle_lo_dw_id
            )                                                       AS session_time,
            dsc.academic_year_start_date,
            dsc.academic_year_end_date
        FROM ${rs_coredw}.fact_learning_experience AS fle
        JOIN ${rs_bi_coredw}.bi_student_dim AS dst
            ON fle.fle_student_dw_id = dst.student_dw_id
           AND dst.student_status = 1
        JOIN ${rs_coredw}.dim_grade AS dg
            ON dg.grade_dw_id = fle.fle_grade_dw_id
        JOIN student_lessons_assigned AS dcu
            ON fle.fle_student_dw_id = dcu.class_user_user_dw_id
           AND fle.fle_lo_dw_id = dcu.lo_dw_id
        JOIN ${rs_bi_coredw}.bi_active_schools_dim AS dsc
            ON fle.fle_school_dw_id = dsc.school_dw_id
           AND CONVERT(DATE, fle.fle_created_time) >= dsc.academic_year_start_date
           AND CONVERT(DATE, fle.fle_created_time) <= dsc.academic_year_end_date
        WHERE fle.fle_abbreviation <> 'NA'
          AND fle.fle_activity_type = 'INTERIM_CHECKPOINT'
          AND fle.fle_material_type <> 'PATHWAY'
          AND fle.fle_ls_id NOT IN (
                SELECT DISTINCT fle_ls_id
                FROM ${rs_coredw}.fact_learning_experience
                WHERE fle_state = 4
          )
          AND ISNULL(fle.fle_lesson_category, 'NA') <> 'EXPERIENTIAL_LESSON';

        -- --------------------------------------------------------
        -- Step 3: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.students_ic_progress;

        -- --------------------------------------------------------
        -- Step 4: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.students_ic_progress_staging', 'students_ic_progress';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
