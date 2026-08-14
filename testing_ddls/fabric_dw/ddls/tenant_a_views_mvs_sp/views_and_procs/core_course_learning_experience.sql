CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_core_course_learning_experience
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.core_course_learning_experience_staging;

        -- --------------------------------------------------------
        -- Step 2: CTAS - Build staging table with full transformation
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.core_course_learning_experience_staging
        WITH (CLUSTER BY (fle_class_dw_id, fle_lo_dw_id))
        AS
        SELECT
            fle.fle_class_dw_id,
            ISNULL(fle.fle_section_dw_id, 10001)       AS fle_section_dw_id,
            fle.fle_lo_dw_id,
            ISNULL(fle.fle_source, 'NA')               AS fle_source,
            COUNT(DISTINCT fle.fle_student_dw_id)      AS total_students_fact,
            COUNT(DISTINCT CASE
                WHEN fle.fle_completion_node = 1
                    THEN fle.fle_student_dw_id
            END)                                       AS total_completed_students,
            COUNT(DISTINCT CASE
                WHEN fle.fle_completion_node = 1
                 AND lo.lo_max_stars > 0
                    THEN fle.fle_student_dw_id
            END)                                       AS total_completed_students_score,
            SUM(
                CASE
                    WHEN fle.fle_completion_node = 1
                     AND lo.lo_max_stars > 0
                     AND fle.fle_is_retry = 0
                        THEN ISNULL(fle.fle_total_score, fle.fle_score)
                END
            )                                          AS fle_score,
            COUNT(DISTINCT CASE
                WHEN fle.fle_completion_node = 1
                 AND lo.lo_max_stars > 0
                 AND fle.fle_is_retry = 0
                 AND ISNULL(fle.fle_total_score, fle.fle_score) >= 70
                    THEN fle.fle_student_dw_id
            END)                                       AS meets_completed_students,
            COUNT(DISTINCT CASE
                WHEN fle.fle_completion_node = 1
                 AND lo.lo_max_stars > 0
                 AND fle.fle_is_retry = 0
                 AND ISNULL(fle.fle_total_score, fle.fle_score) >= 50
                 AND ISNULL(fle.fle_total_score, fle.fle_score) < 70
                    THEN fle.fle_student_dw_id
            END)                                       AS approaching_completed_students,
            COUNT(DISTINCT CASE
                WHEN fle.fle_completion_node = 1
                 AND lo.lo_max_stars > 0
                 AND fle.fle_is_retry = 0
                 AND ISNULL(fle.fle_total_score, fle.fle_score) < 50
                 AND ISNULL(fle.fle_total_score, fle.fle_score) >= 0
                    THEN fle.fle_student_dw_id
            END)                                       AS below_completed_students,
            SUM(
                CASE
                    WHEN fle.fle_total_time <= 900 THEN fle.fle_total_time
                    WHEN fle.fle_total_time > 900  THEN 900
                    ELSE 0
                END
            )                                          AS session_time
        FROM coredw.fact_learning_experience AS fle
        JOIN coredw.dim_learning_objective AS lo
            ON lo.lo_dw_id   = fle.fle_lo_dw_id
           AND lo.lo_status  = 1
        WHERE fle.fle_abbreviation <> 'NA'
          AND fle.fle_activity_type NOT IN ('INTERIM_CHECKPOINT', 'DIAGNOSTIC_TEST')
          AND fle.fle_material_type <> 'PATHWAY'
          AND fle.fle_is_additional_resource <> 1
          AND ISNULL(fle.fle_lesson_category, 'NA') <> 'EXPERIENTIAL_LESSON'
          AND fle.fle_ls_id NOT IN (
                SELECT DISTINCT fle_ls_id
                FROM coredw.fact_learning_experience
                WHERE fle_state = 4
          )
        GROUP BY
            fle.fle_class_dw_id,
            ISNULL(fle.fle_section_dw_id, 10001),
            fle.fle_lo_dw_id,
            ISNULL(fle.fle_source, 'NA');

        -- --------------------------------------------------------
        -- Step 3: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.core_course_learning_experience;

        -- --------------------------------------------------------
        -- Step 4: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.core_course_learning_experience_staging', 'core_course_learning_experience';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
