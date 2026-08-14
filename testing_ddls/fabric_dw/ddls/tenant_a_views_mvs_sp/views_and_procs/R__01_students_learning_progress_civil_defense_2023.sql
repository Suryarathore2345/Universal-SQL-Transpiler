CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_students_learning_progress_civil_defense_2023
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.students_learning_progress_civil_defense_2023_staging;

        -- --------------------------------------------------------
        -- Step 2: CTAS - Build staging table with full transformation
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.students_learning_progress_civil_defense_2023_staging
        WITH (CLUSTER BY (student_dw_id, fle_class_dw_id))
        AS
        WITH school_previousay AS (
            SELECT
                academic_year_id, academic_year_school_id, academic_year_dw_id,
                academic_year_start_date AS previous_academic_year_start_date,
                academic_year_end_date   AS previous_academic_year_end_date
            FROM (
                SELECT academic_year_id, academic_year_school_id, academic_year_dw_id,
                       academic_year_start_date, academic_year_end_date,
                       academic_year_is_roll_over_completed,
                    ROW_NUMBER() OVER (
                        PARTITION BY academic_year_school_id
                        ORDER BY academic_year_end_date DESC
                    ) AS rank
                FROM ${rs_coredw}.dim_academic_year
                WHERE academic_year_is_roll_over_completed = 1
            ) AS pr_ay
            WHERE YEAR(academic_year_end_date) = 2023
        ),
        Learning_Objective AS (
            SELECT lo_dw_id, lo_code, lo_title
            FROM ${rs_coredw}.dim_learning_objective AS dip_dlo
            WHERE ISNULL(dip_dlo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
              AND lo_code IN ('CD_MLO_000', 'CD_MLO_001', 'CD_MLO_002', 'CD_MLO_003', 'CD_MLO_004', 'CD_MLO_005')
        ),
        COMPLETED_LESSONS AS (
            SELECT fle_ls_id, fle_dw_id, fle_score
            FROM (
                SELECT
                    fle_ls_id, fle_dw_id,
                    CASE WHEN lo.lo_max_stars > 0 THEN fle_score END AS fle_score,
                    ROW_NUMBER() OVER (PARTITION BY fle_ls_id ORDER BY fle_created_time DESC) AS rnk
                FROM ${rs_coredw}.fact_learning_experience
                JOIN ${rs_coredw}.dim_learning_objective AS lo
                    ON lo.lo_dw_id = fle_lo_dw_id
                JOIN school_previousay AS ay
                    ON fle_academic_year_dw_id = ay.academic_year_dw_id
                WHERE fle_completion_node = 1
                  AND fle_activity_type <> 'INTERIM_CHECKPOINT'
                  AND fle_material_type <> 'PATHWAY'
                  AND lo_code IN ('CD_MLO_000', 'CD_MLO_001', 'CD_MLO_002', 'CD_MLO_003', 'CD_MLO_004', 'CD_MLO_005')
            ) AS subq
            WHERE rnk = 1
        ),
        LESSON_PROGRESS AS (
            SELECT fle_dw_id, 0 AS fle_score, 'In-Progress' AS lo_status
            FROM (
                SELECT fle_ls_id, MAX(fle_dw_id) AS fle_dw_id
                FROM ${rs_coredw}.fact_learning_experience
                JOIN school_previousay AS ay
                    ON fle_academic_year_dw_id = ay.academic_year_dw_id
                JOIN Learning_Objective
                    ON lo_dw_id = fle_lo_dw_id
                WHERE fle_ls_id NOT IN (SELECT fle_ls_id FROM COMPLETED_LESSONS)
                  AND fle_attempt = 1
                  AND fle_activity_type <> 'INTERIM_CHECKPOINT'
                  AND fle_material_type <> 'PATHWAY'
                  AND fle_abbreviation <> 'NA'
                  AND lo_code IN ('CD_MLO_000', 'CD_MLO_001', 'CD_MLO_002', 'CD_MLO_003', 'CD_MLO_004', 'CD_MLO_005')
                GROUP BY fle_ls_id
            ) AS subq
            UNION ALL
            SELECT fle_dw_id, fle_score, 'Completed' AS lo_status
            FROM COMPLETED_LESSONS
        ),
        student_lessons_assigned AS (
            SELECT DISTINCT
                d_cu.class_user_user_dw_id,
                d_cu.class_user_class_dw_id,
                dcs.curr_subject_dw_id,
                dip.instructional_plan_item_lo_dw_id AS lo_dw_id
            FROM ${rs_coredw}.dim_class_user AS d_cu
            INNER JOIN ${rs_coredw}.dim_class AS dc
                ON dc.class_dw_id = d_cu.class_user_class_dw_id
            INNER JOIN ${rs_coredw}.dim_curriculum_subject AS dcs
                ON dc.class_curriculum_subject_id = dcs.curr_subject_id
            INNER JOIN ${rs_coredw}.dim_instructional_plan AS dip
                ON dc.class_curriculum_grade_id = dip.instructional_plan_curriculum_grade_id
               AND dc.class_curriculum_subject_id = dip.instructional_plan_curriculum_subject_id
               AND dc.class_curriculum_id = dip.instructional_plan_curriculum_id
               AND dc.class_curriculum_instructional_plan_id = dip.instructional_plan_id
            INNER JOIN Learning_Objective
                ON lo_dw_id = dip.instructional_plan_item_lo_dw_id
            INNER JOIN school_previousay AS ay
                ON dc.class_academic_year_id = ay.academic_year_id
            WHERE d_cu.class_user_role_dw_id = 2
              AND dc.class_course_status = 'CONCLUDED'
              AND lo_code IN ('CD_MLO_000', 'CD_MLO_001', 'CD_MLO_002', 'CD_MLO_003', 'CD_MLO_004', 'CD_MLO_005')
        )
        SELECT
            fl.local_date, fl.fle_class_dw_id, fl.term_curriculum_id, fl.lo_attempted,
            fl.lo_code, fl.fle_lesson_category, fl.fle_dw_id, fl.student_dw_id,
            fl.student_section_dw_id, fl.fle_academic_year_dw_id, fl.student_tags,
            fl.student_special_needs, fl.grade_k12grade, fl.session_time,
            fl.previous_academic_year_start_date, fl.previous_academic_year_end_date,
            lps.fle_score, lps.lo_status
        FROM (
            SELECT DISTINCT
                dd.full_date                                        AS local_date,
                dcu.class_user_class_dw_id                          AS fle_class_dw_id,
                term_curriculum_id,
                fle_lo_dw_id                                        AS lo_attempted,
                lo_code,
                fle_lesson_category,
                fle_dw_id,
                dst.student_dw_id,
                dst.student_section_dw_id,
                fle_academic_year_dw_id,
                dst.student_tags,
                dst.student_special_needs,
                dg.grade_k12grade,
                SUM(
                    CASE
                        WHEN fle.fle_total_time <= 900 THEN fle.fle_total_time
                        WHEN fle.fle_total_time > 900  THEN 900
                        ELSE 0
                    END
                ) OVER (PARTITION BY dd.full_date, student_dw_id, fle_lo_dw_id) AS session_time,
                previous_academic_year_start_date,
                previous_academic_year_end_date
            FROM ${rs_coredw}.fact_learning_experience AS fle
            JOIN Learning_Objective
                ON fle_lo_dw_id = lo_dw_id
            JOIN ${rs_coredw}.dim_term AS fle_dtrm
                ON fle.fle_term_dw_id = fle_dtrm.term_dw_id
            JOIN ${rs_bi_coredw}.bi_student_dim AS dst
                ON fle.fle_student_dw_id = dst.student_dw_id
               AND (
                    (dst.student_status = 2
                     AND fle.fle_created_time >= dst.student_created_time
                     AND fle.fle_created_time < dst.student_active_until)
                    OR (student_status = 1 AND fle.fle_created_time >= dst.student_created_time)
               )
            JOIN ${rs_coredw}.dim_date AS dd
                ON fle.fle_date_dw_id = dd.date_id
            JOIN ${rs_coredw}.dim_grade AS dg
                ON dg.grade_dw_id = fle.fle_grade_dw_id
            JOIN student_lessons_assigned AS dcu
                ON fle_student_dw_id = dcu.class_user_user_dw_id
               AND fle_lo_dw_id = dcu.lo_dw_id
            JOIN school_previousay AS ay
                ON fle.fle_academic_year_dw_id = ay.academic_year_dw_id
            WHERE fle_abbreviation <> 'NA'
              AND fle.fle_activity_type <> 'INTERIM_CHECKPOINT'
              AND fle_material_type <> 'PATHWAY'
        ) AS fl
        JOIN LESSON_PROGRESS AS lps
            ON fl.fle_dw_id = lps.fle_dw_id
        WHERE ISNULL(fle_lesson_category, 'NA') <> 'EXPERIENTIAL_LESSON';

        -- --------------------------------------------------------
        -- Step 3: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.students_learning_progress_civil_defense_2023;

        -- --------------------------------------------------------
        -- Step 4: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.students_learning_progress_civil_defense_2023_staging', 'students_learning_progress_civil_defense_2023';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
