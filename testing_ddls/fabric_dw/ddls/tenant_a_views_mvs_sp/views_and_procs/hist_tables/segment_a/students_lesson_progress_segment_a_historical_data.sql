DROP TABLE IF EXISTS ${os_bi_coredw}.students_lesson_progress_military_historical_data;

CREATE TABLE ${os_bi_coredw}.students_lesson_progress_military_historical_data
AS
WITH COMPLETED_LESSONS AS (
    SELECT
        fle_ls_id,
        fle_dw_id,
        fle_score
    FROM (
        SELECT
            fle.fle_ls_id,
            fle.fle_dw_id,
            CASE
                WHEN YEAR(dsc.academic_year_end_date) > 2021
                     AND lo.lo_max_stars > 0
                    THEN fle.fle_total_score
                WHEN YEAR(dsc.academic_year_end_date) <= 2021
                    THEN fle.fle_score
            END AS fle_score,
            ROW_NUMBER() OVER (
                PARTITION BY fle.fle_ls_id
                ORDER BY fle.fle_created_time DESC
            ) AS rnk
        FROM ${rs_coredw}.fact_learning_experience fle
        JOIN ${rs_coredw}.dim_learning_objective lo
            ON lo.lo_dw_id = fle.fle_lo_dw_id
        JOIN ${rs_bi_coredw}.bi_all_schools_dim dsc
            ON fle.fle_school_dw_id = dsc.school_dw_id
           AND CONVERT(DATE, fle.fle_created_time)
               BETWEEN dsc.academic_year_start_date AND dsc.academic_year_end_date
           AND dsc.academic_year_is_roll_over_completed = 1
           AND dsc.school_organisation = 'MHS'
        WHERE
            fle.fle_completion_node = 1
            AND fle.fle_activity_type <> 'INTERIM_CHECKPOINT'
            AND fle.fle_material_type <> 'PATHWAY'
            AND fle.fle_is_additional_resource <> 1
    ) x
    WHERE rnk = 1
),

LESSON_PROGRESS AS (
    SELECT fle_dw_id, 0 AS fle_score, 'In-Progress' AS lo_status
    FROM (
        SELECT
            fle.fle_ls_id,
            MAX(fle.fle_dw_id) AS fle_dw_id
        FROM ${rs_coredw}.fact_learning_experience fle
        JOIN ${rs_bi_coredw}.bi_all_schools_dim dsc
            ON fle.fle_school_dw_id = dsc.school_dw_id
           AND CONVERT(DATE, fle.fle_created_time)
               BETWEEN dsc.academic_year_start_date AND dsc.academic_year_end_date
           AND dsc.academic_year_is_roll_over_completed = 1
        WHERE
            fle.fle_ls_id NOT IN (SELECT fle_ls_id FROM COMPLETED_LESSONS)
            AND fle.fle_attempt = 1
            AND fle.fle_activity_type <> 'INTERIM_CHECKPOINT'
            AND fle.fle_material_type <> 'PATHWAY'
            AND fle.fle_is_additional_resource <> 1
            AND fle.fle_abbreviation <> 'NA'
            AND dsc.school_organisation = 'MHS'
        GROUP BY fle.fle_ls_id
    ) y

    UNION ALL

    SELECT fle_dw_id, fle_score, 'Completed'
    FROM COMPLETED_LESSONS
),

student_lessons_assigned AS (
    SELECT DISTINCT
        dcu.class_user_user_dw_id,
        dcu.class_user_class_dw_id,
        cac.activity_dw_id AS lo_dw_id
    FROM ${rs_coredw}.dim_class_user dcu
    JOIN ${rs_bi_coredw}.core_class_activity_content cac
        ON cac.class_dw_id = dcu.class_user_class_dw_id
    WHERE
        cac.school_organisation = 'MHS'
        AND dcu.class_user_role_dw_id = 2
),

pre_agg_time AS (
    SELECT
        fle.fle_student_dw_id,
        fle.fle_lo_dw_id,
        CONVERT(DATE,
            fle.fle_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
        ) AS local_date,
        SUM(
            CASE
                WHEN YEAR(dsc.academic_year_start_date) = 2024 THEN
                    CASE
                        WHEN fle.fle_total_time <= 900 THEN fle.fle_total_time
                        WHEN fle.fle_total_time > 900 THEN 900
                        ELSE 0
                    END
                ELSE
                    CASE
                        WHEN CONVERT(DATE, fle.fle_start_time)
                             = CONVERT(DATE, fle.fle_end_time)
                             AND fle.fle_total_time > 1200
                             AND fle.fle_total_time <= 3600
                            THEN 1200
                        WHEN fle.fle_total_time <= 1200 THEN fle.fle_total_time
                        ELSE 180
                    END
            END
        ) AS session_time,
        SUM(
            CASE
                WHEN YEAR(dsc.academic_year_start_date) = 2024 THEN
                    CASE
                        WHEN fle.fle_total_time <= 900 THEN fle.fle_total_time
                        WHEN fle.fle_total_time > 900 THEN 900
                        ELSE 0
                    END
                ELSE
                    CASE
                        WHEN CONVERT(DATE, fle.fle_start_time)
                             = CONVERT(DATE, fle.fle_end_time)
                             AND fle.fle_total_time > 1200
                             AND fle.fle_total_time <= 3600
                            THEN 1200
                        WHEN fle.fle_total_time <= 1200 THEN fle.fle_total_time
                        ELSE 600
                    END
            END
        ) AS fle_session_time
    FROM ${rs_coredw}.fact_learning_experience fle
    JOIN ${rs_bi_coredw}.bi_all_schools_dim dsc
        ON fle.fle_school_dw_id = dsc.school_dw_id
       AND CONVERT(DATE, fle.fle_created_time)
           BETWEEN dsc.academic_year_start_date AND dsc.academic_year_end_date
       AND dsc.academic_year_is_roll_over_completed = 1
    WHERE
        dsc.school_organisation = 'MHS'
        AND fle.fle_abbreviation <> 'NA'
        AND fle.fle_activity_type <> 'INTERIM_CHECKPOINT'
        AND fle.fle_material_type <> 'PATHWAY'
        AND fle.fle_is_additional_resource <> 1
    GROUP BY
        fle.fle_student_dw_id,
        fle.fle_lo_dw_id,
        CONVERT(DATE,
            fle.fle_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
        )
)

SELECT DISTINCT
    fl.local_date,
    fl.fle_class_dw_id,
    fl.lo_attempted,
    fl.fle_lesson_category,
    fl.student_dw_id,
    fl.student_id,
    fl.school_dw_id,
    fl.school_name,
    fl.class_gen_subject,
    fl.student_section_dw_id,
    fl.fle_academic_year_dw_id,
    fl.grade_k12grade,
    dtc.session_time,
    dtc.fle_session_time,
    fl.academic_year_start_date,
    fl.academic_year_end_date,
    lps.fle_score,
    lps.lo_status
FROM (
    SELECT DISTINCT
        CONVERT(DATE,
            fle.fle_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
        ) AS local_date,
        dcu.class_user_class_dw_id AS fle_class_dw_id,
        fle.fle_lo_dw_id AS lo_attempted,
        fle.fle_lesson_category,
        fle.fle_dw_id,
        dst.student_dw_id,
        dst.student_id,
        fle.fle_school_dw_id AS school_dw_id,
        CASE
            WHEN dsc.school_name IS NULL OR dsc.school_name = ''
            THEN dsc.school_name
            ELSE UPPER(dsc.school_name)
        END AS school_name,
        dcl.class_gen_subject,
        dst.student_section_dw_id,
        fle.fle_academic_year_dw_id,
        dg.grade_k12grade,
        dsc.academic_year_start_date,
        dsc.academic_year_end_date
    FROM ${rs_coredw}.fact_learning_experience fle
    JOIN ${rs_coredw}.dim_academic_year ay
        ON fle.fle_academic_year_dw_id = ay.academic_year_dw_id
       AND ay.academic_year_is_roll_over_completed = 1
    JOIN (
    SELECT
        bs.student_dw_id,
        bs.student_id,
        bs.student_section_dw_id,
        bs.student_created_time,
        bs.student_active_until,
        bs.student_school_dw_id,
        dg.academic_year_id,
        sch.academic_year_start_date,
        sch.academic_year_end_date,
        ROW_NUMBER() OVER (
            PARTITION BY bs.student_dw_id
            ORDER BY bs.student_created_time DESC
        ) AS rnk
        FROM ${rs_bi_coredw}.bi_student_dim bs
        JOIN ${rs_coredw}.dim_grade dg
            ON bs.student_grade_dw_id = dg.grade_dw_id
        JOIN ${rs_bi_coredw}.bi_all_schools_dim sch
            ON bs.student_school_dw_id = sch.school_dw_id
        AND dg.academic_year_id 
            = sch.academic_year_id 
        WHERE
            bs.student_created_time <= sch.academic_year_end_date
            AND (
                bs.student_active_until >= sch.academic_year_start_date
                OR bs.student_active_until IS NULL
            )
    ) dst
        ON fle.fle_student_dw_id = dst.student_dw_id
       AND fle.fle_academic_year_dw_id = ay.academic_year_dw_id
       AND dst.rnk = 1
    JOIN ${rs_coredw}.dim_grade dg
        ON dg.grade_dw_id = fle.fle_grade_dw_id
    JOIN student_lessons_assigned dcu
        ON fle.fle_student_dw_id = dcu.class_user_user_dw_id
       AND fle.fle_lo_dw_id = dcu.lo_dw_id
       AND fle.fle_class_dw_id = dcu.class_user_class_dw_id
    JOIN ${rs_bi_coredw}.bi_all_schools_dim dsc
        ON fle.fle_school_dw_id = dsc.school_dw_id
       AND CONVERT(DATE, fle.fle_created_time)
           BETWEEN dsc.academic_year_start_date AND dsc.academic_year_end_date
       AND dsc.academic_year_is_roll_over_completed = 1
    JOIN ${rs_coredw}.dim_class dcl
        ON dcu.class_user_class_dw_id = dcl.class_dw_id
    WHERE
        fle.fle_abbreviation <> 'NA'
        AND fle.fle_activity_type <> 'INTERIM_CHECKPOINT'
        AND fle.fle_material_type <> 'PATHWAY'
        AND fle.fle_is_additional_resource <> 1
        AND dsc.school_organisation = 'MHS'
        AND YEAR(dsc.academic_year_end_date) <
            (
                SELECT MAX(YEAR(academic_year_end_date))
                FROM ${rs_bi_coredw}.bi_all_schools_dim
                WHERE school_organisation = 'MHS'
            )
) fl
JOIN LESSON_PROGRESS lps
    ON fl.fle_dw_id = lps.fle_dw_id
JOIN pre_agg_time dtc
    ON fl.student_dw_id = dtc.fle_student_dw_id
   AND fl.lo_attempted = dtc.fle_lo_dw_id
   AND fl.local_date = dtc.local_date
WHERE ISNULL(fl.fle_lesson_category, 'NA') <> 'EXPERIENTIAL_LESSON';