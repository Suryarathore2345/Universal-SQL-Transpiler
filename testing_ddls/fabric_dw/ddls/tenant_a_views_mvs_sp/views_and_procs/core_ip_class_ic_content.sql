CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_core_ip_class_ic_content
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.ip_students_lesson_progress_staging;

        -- --------------------------------------------------------
        -- Step 2: CTAS - Build staging table with full transformation
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.ip_students_lesson_progress_staging
        WITH (CLUSTER BY (student_dw_id, fle_class_dw_id))
        AS
        WITH COMPLETED_LESSONS AS (
            SELECT 
                x.fle_ls_id,
                x.fle_dw_id,
                x.fle_score,
                x.rnk
            FROM (
                SELECT
                    fle_ls_id,
                    fle_dw_id,
                    CASE
                        WHEN lo.lo_max_stars > 0 THEN fle.fle_total_score
                    END AS fle_score,
                    ROW_NUMBER() OVER (
                        PARTITION BY fle_ls_id
                        ORDER BY fle.fle_created_time DESC
                    ) AS rnk
                FROM ${rs_coredw}.fact_learning_experience fle
                JOIN ${rs_coredw}.dim_learning_objective lo
                    ON lo.lo_dw_id = fle.fle_lo_dw_id
                AND lo.lo_status = 1
                JOIN ${rs_coredw}.dim_academic_year ay
                    ON fle.fle_academic_year_dw_id = ay.academic_year_dw_id
                AND ay.academic_year_is_roll_over_completed = 0
                AND ay.academic_year_status = 1
                WHERE fle.fle_completion_node = 1
                AND fle.fle_activity_type <> 'INTERIM_CHECKPOINT'
                AND fle.fle_material_type <> 'PATHWAY'
            ) x
            WHERE rnk = 1
        ),

        LESSON_PROGRESS AS (
            SELECT
                fle_dw_id,
                0 AS fle_score,
                'In-Progress' AS lo_status
            FROM (
                SELECT
                    fle_ls_id,
                    MAX(fle_dw_id) AS fle_dw_id
                FROM ${rs_coredw}.fact_learning_experience fle
                JOIN ${rs_coredw}.dim_academic_year ay
                    ON fle.fle_academic_year_dw_id = ay.academic_year_dw_id
                AND ay.academic_year_is_roll_over_completed = 0
                AND ay.academic_year_status = 1
                WHERE fle_ls_id NOT IN (
                    SELECT fle_ls_id FROM COMPLETED_LESSONS
                )
                AND fle.fle_attempt = 1
                AND fle.fle_activity_type <> 'INTERIM_CHECKPOINT'
                AND fle.fle_material_type <> 'PATHWAY'
                AND fle.fle_abbreviation <> 'NA'
                GROUP BY fle_ls_id
            ) sub1

            UNION ALL

            SELECT
                fle_dw_id,
                fle_score,
                'Completed' AS lo_status
            FROM COMPLETED_LESSONS
        ),

        student_lessons_assigned AS (
            SELECT DISTINCT
                d_cu.class_user_user_dw_id,
                d_cu.class_user_class_dw_id,
                dcs.curr_subject_dw_id,
                dip.instructional_plan_item_lo_dw_id AS lo_dw_id
            FROM ${rs_coredw}.dim_class_user d_cu
            INNER JOIN ${rs_coredw}.dim_class dc
                ON dc.class_dw_id = d_cu.class_user_class_dw_id
            INNER JOIN ${rs_coredw}.dim_curriculum_subject dcs
                ON dc.class_curriculum_subject_id = dcs.curr_subject_id
            INNER JOIN ${rs_coredw}.dim_instructional_plan dip
                ON dc.class_curriculum_grade_id = dip.instructional_plan_curriculum_grade_id
            AND dc.class_curriculum_subject_id = dip.instructional_plan_curriculum_subject_id
            AND dc.class_curriculum_id = dip.instructional_plan_curriculum_id
            AND dc.class_curriculum_instructional_plan_id = dip.instructional_plan_id
            AND dip.instructional_plan_status = 1
            WHERE d_cu.class_user_attach_status = 1
            AND d_cu.class_user_status = 1
            AND d_cu.class_user_role_dw_id = 2
            AND dc.class_course_status = 'ACTIVE'
            AND dc.class_status = 1
        )

        SELECT
            fl.local_date,
            fl.fle_class_dw_id,
            fl.term_curriculum_id,
            fl.lo_attempted,
            fl.fle_lesson_category,
            fl.fle_dw_id,
            fl.fle_source,
            fl.student_dw_id,
            fl.student_section_dw_id,
            fl.fle_academic_year_dw_id,
            fl.student_tags,
            fl.student_special_needs,
            fl.grade_k12grade,
            fl.session_time,
            fl.fle_session_time,
            fl.academic_year_start_date,
            fl.academic_year_end_date,
            lps.fle_score,
            lps.lo_status
        FROM (
            SELECT DISTINCT
                dd.full_date AS local_date,
                dcu.class_user_class_dw_id AS fle_class_dw_id,
                fle_dtrm.term_curriculum_id,
                fle.fle_lo_dw_id AS lo_attempted,
                fle.fle_lesson_category,
                fle.fle_dw_id,
                fle.fle_source,
                dst.student_dw_id,
                dst.student_section_dw_id,
                fle.fle_academic_year_dw_id,
                dst.student_tags,
                dst.student_special_needs,
                dg.grade_k12grade,
                SUM(
                    CASE
                        WHEN fle.fle_total_time <= 900 THEN fle.fle_total_time
                        WHEN fle.fle_total_time > 900 THEN 900
                        ELSE 0
                    END
                ) OVER (
                    PARTITION BY dd.full_date, dst.student_dw_id, fle.fle_lo_dw_id
                ) AS session_time,
                SUM(
                    CASE
                        WHEN fle.fle_total_time <= 900 THEN fle.fle_total_time
                        WHEN fle.fle_total_time > 900 THEN 900
                        ELSE 0
                    END
                ) OVER (
                    PARTITION BY dd.full_date, dst.student_dw_id, fle.fle_lo_dw_id
                ) AS fle_session_time,
                ay.academic_year_start_date,
                ay.academic_year_end_date
            FROM ${rs_coredw}.fact_learning_experience fle
            JOIN ${rs_coredw}.dim_term fle_dtrm
                ON fle.fle_term_dw_id = fle_dtrm.term_dw_id
            JOIN ${rs_bi_coredw}.bi_student_dim dst
                ON fle.fle_student_dw_id = dst.student_dw_id
            AND dst.student_status = 1
            JOIN ${rs_coredw}.dim_date dd
                ON fle.fle_date_dw_id = dd.date_id
            JOIN ${rs_coredw}.dim_grade dg
                ON dg.grade_dw_id = fle.fle_grade_dw_id
            JOIN student_lessons_assigned dcu
                ON fle.fle_student_dw_id = dcu.class_user_user_dw_id
            AND fle.fle_lo_dw_id = dcu.lo_dw_id
            JOIN ${rs_coredw}.dim_academic_year ay
                ON fle.fle_academic_year_dw_id = ay.academic_year_dw_id
            AND ay.academic_year_is_roll_over_completed = 0
            AND ay.academic_year_status = 1
            WHERE fle.fle_abbreviation <> 'NA'
            AND fle.fle_activity_type <> 'INTERIM_CHECKPOINT'
            AND fle.fle_material_type <> 'PATHWAY'
            AND fle.fle_ls_id NOT IN (
                SELECT DISTINCT fle_ls_id
                FROM ${rs_coredw}.fact_learning_experience
                WHERE fle_state = 4
            )
        ) fl
        JOIN LESSON_PROGRESS lps
            ON fl.fle_dw_id = lps.fle_dw_id
        WHERE ISNULL(fle_lesson_category, 'NA') <> 'EXPERIENTIAL_LESSON';


        -- --------------------------------------------------------
        -- Step 3: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.ip_students_lesson_progress;

        -- --------------------------------------------------------
        -- Step 4: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.ip_students_lesson_progress_staging', 'ip_students_lesson_progress';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
