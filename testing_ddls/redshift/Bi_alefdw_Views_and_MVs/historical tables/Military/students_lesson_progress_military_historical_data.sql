DROP TABLE IF EXISTS bi_alefdw_dev.students_lesson_progress_military_historical_data;
CREATE TABLE bi_alefdw_dev.students_lesson_progress_military_historical_data DISTKEY (school_dw_id)
                                                                             SORTKEY (local_date, student_dw_id) AS
WITH COMPLETED_LESSONS AS
         (SELECT *
          FROM (SELECT fle_ls_id,
                       fle_dw_id,
                       case
                           when (date_part_year(academic_year_end_date) > 2021 AND lo.lo_max_stars > 0) then fle_total_score
                           when (date_part_year(academic_year_end_date) <= 2021) then fle_score
                       end AS fle_score,
                       ROW_NUMBER() over (PARTITION BY fle_ls_id ORDER BY fle_created_time desc) rnk
                FROM (
                    SELECT
                        fle_ls_id, fle_dw_id, fle_total_score, fle_score, fle_created_time, fle_lo_dw_id, fle_school_dw_id FROM alefdw.fact_learning_experience
                        where
                            fle_completion_node IS true AND
                            fle_activity_type <> 'INTERIM_CHECKPOINT' AND
                            fle_material_type <> 'PATHWAY' AND
                            fle_is_additional_resource <> TRUE
                    ) fle
                         JOIN alefdw.dim_learning_objective lo
                              ON lo.lo_dw_id = fle_lo_dw_id
                         JOIN bi_alefdw.bi_all_schools_dim_mv dsc
                              ON fle_school_dw_id = dsc.school_dw_id
                                  AND trunc(fle_created_time) >= dsc.academic_year_start_date
                                  AND trunc(fle_created_time) <= dsc.academic_year_end_date
                                  AND DSC.academic_year_is_roll_over_completed = TRUE
                                  AND dsc.school_organisation = 'MHS'
                ) cl
          where rnk = 1),

     LESSON_PROGRESS AS
         (SELECT fle_dw_id, 0 AS fle_score, 'In-Progress' AS lo_status
          FROM (SELECT fle_ls_id,
                       MAX(fle_dw_id) fle_dw_id
                FROM alefdw.fact_learning_experience flee
                         JOIN bi_alefdw.bi_all_schools_dim_mv dsc
                              ON fle_school_dw_id = dsc.school_dw_id
                                  AND trunc(fle_created_time) >= dsc.academic_year_start_date
                                  AND trunc(fle_created_time) <= dsc.academic_year_end_date
                                  AND DSC.academic_year_is_roll_over_completed = TRUE
                WHERE fle_ls_id NOT IN (SELECT fle_ls_id FROM COMPLETED_LESSONS)
                  AND fle_attempt = 1
                  AND flee.fle_activity_type <> 'INTERIM_CHECKPOINT'
                  AND fle_material_type <> 'PATHWAY'
                  AND fle_is_additional_resource <> TRUE
                  AND fle_abbreviation <> 'NA'
                  AND dsc.school_organisation ='MHS'
                GROUP BY 1) lp

          UNION ALL

          SELECT fle_dw_id, fle_score, 'Completed' AS lo_status
          FROM COMPLETED_LESSONS),

     student_lessons_assigned AS (
    SELECT DISTINCT
           dcu.class_user_user_dw_id,
           dcu.class_user_class_dw_id,
           cac.activity_dw_id AS lo_dw_id
    FROM alefdw.dim_class_user dcu
    JOIN bi_alefdw.core_class_activity_content_mv cac
      ON cac.class_dw_id = dcu.class_user_class_dw_id
    WHERE cac.school_organisation = 'MHS'
      AND dcu.class_user_role_dw_id = 2
),
pre_agg_time AS (
    SELECT
        fle.fle_student_dw_id,
        fle.fle_lo_dw_id,
        TRUNC(CONVERT_TIMEZONE('UTC', dsc.tenant_timezone, fle.fle_created_time)) as local_date,
        SUM(
            CASE
                WHEN EXTRACT(YEAR FROM dsc.academic_year_start_date) = 2024 THEN
                    CASE
                        WHEN fle.fle_total_time <= 900 THEN fle.fle_total_time
                        WHEN fle.fle_total_time > 900 THEN 900
                        ELSE 0
                    END
                ELSE
                    CASE
                       WHEN trunc(fle.fle_start_time) = trunc(fle.fle_end_time) AND
                            fle.fle_total_time > 1200 AND fle.fle_total_time <= 3600
                           THEN 1200
                       WHEN fle.fle_total_time <= 1200 THEN fle.fle_total_time
                       ELSE 180
                    END
            END
        ) as session_time,
        SUM(
            CASE
                WHEN EXTRACT(YEAR FROM dsc.academic_year_start_date) = 2024 THEN
                    CASE
                        WHEN fle.fle_total_time <= 900 THEN fle.fle_total_time
                        WHEN fle.fle_total_time > 900 THEN 900
                        ELSE 0
                    END
                ELSE
                    CASE
                       WHEN trunc(fle.fle_start_time) = trunc(fle.fle_end_time) AND
                            fle.fle_total_time > 1200 AND fle.fle_total_time <= 3600
                           THEN 1200
                       WHEN fle.fle_total_time <= 1200 THEN fle.fle_total_time
                       ELSE 600
                    END
            END
        ) as fle_session_time
    FROM alefdw.fact_learning_experience fle
    JOIN bi_alefdw.bi_all_schools_dim_mv dsc
         ON fle.fle_school_dw_id = dsc.school_dw_id
         AND trunc(fle_created_time) >= dsc.academic_year_start_date
         AND trunc(fle_created_time) <= dsc.academic_year_end_date
         AND dsc.academic_year_is_roll_over_completed = TRUE
    WHERE dsc.school_organisation = 'MHS'
      AND fle_abbreviation <> 'NA'
      AND fle.fle_activity_type <> 'INTERIM_CHECKPOINT'
      AND fle_material_type <> 'PATHWAY'
      AND fle_is_additional_resource <> TRUE
    GROUP BY 1, 2, 3
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
      dtc.session_time AS session_time,
      dtc.fle_session_time AS fle_session_time,
      fl.academic_year_start_date,
      fl.academic_year_end_date,
      lps.fle_score,
      lps.lo_status
FROM (SELECT DISTINCT
                      TRUNC(CONVERT_TIMEZONE('UTC', dsc.tenant_timezone, fle.fle_created_time)) AS local_date,
                      dcu.class_user_class_dw_id                                  AS fle_class_dw_id,
                      fle_lo_dw_id                                                AS lo_attempted,
                      fle_lesson_category,
                      fle_dw_id,
                      fle_source,
                      dst.student_dw_id,
                      dst.student_id,
                      fle_school_dw_id                                            AS school_dw_id,
                      initcap(dsc.school_name) school_name,
                      class_gen_subject,
                      dst.student_section_dw_id,
                      fle_academic_year_dw_id,
                      dg.grade_k12grade,
                      dsc.academic_year_start_date,
                      dsc.academic_year_end_date
      FROM alefdw.fact_learning_experience fle
               JOIN alefdw.dim_academic_year ay ON fle.fle_academic_year_dw_id = ay.academic_year_dw_id
               AND ay.academic_year_is_roll_over_completed = TRUE
               JOIN (
                 SELECT
                    bs.student_dw_id,
                    bs.student_id,
                    bs.student_section_dw_id,
                    bs.student_grade_dw_id,
                    academic_year_start_date,
                    academic_year_end_date,
                    ROW_NUMBER() OVER (PARTITION BY bs.student_dw_id ORDER BY bs.student_created_time DESC) as rnk
                FROM
                    bi_alefdw.bi_student_dim_mv bs
                JOIN
                    alefdw.dim_grade
                    ON student_grade_dw_id = grade_dw_id
                JOIN
                    bi_alefdw.bi_all_schools_dim_mv
                    ON student_school_dw_id = school_dw_id AND dim_grade.academic_year_id = bi_all_schools_dim_mv.academic_year_id
                WHERE
                     bs.student_created_time <= academic_year_end_date
                     AND (bs.student_active_until >= academic_year_start_date OR bs.student_active_until IS NULL)
                ) dst
                    ON fle.fle_student_dw_id = dst.student_dw_id
                    AND fle.fle_academic_year_dw_id = ay.academic_year_dw_id
                    AND dst.rnk = 1
               JOIN alefdw.dim_grade dg ON dg.grade_dw_id = fle.fle_grade_dw_id
               JOIN student_lessons_assigned dcu
                    ON fle_student_dw_id = dcu.class_user_user_dw_id
                        AND fle_lo_dw_id = dcu.lo_dw_id
                        AND fle.fle_class_dw_id = dcu.class_user_class_dw_id
               JOIN bi_alefdw.bi_all_schools_dim_mv dsc
                    ON fle.fle_school_dw_id = dsc.school_dw_id
                        AND trunc(fle_created_time) >= dsc.academic_year_start_date
                        AND trunc(fle_created_time) <= dsc.academic_year_end_date
                        AND DSC.academic_year_is_roll_over_completed = TRUE
               JOIN alefdw.dim_class dcl
                    ON dcu.class_user_class_dw_id = dcl.class_dw_id
      WHERE fle_abbreviation <> 'NA'
        AND FLE.fle_activity_type <> 'INTERIM_CHECKPOINT'
        AND fle_material_type <> 'PATHWAY'
        AND fle_is_additional_resource <> TRUE
        AND dsc.school_organisation = 'MHS'
        AND extract(YEAR FROM dsc.academic_year_end_date) < (
            SELECT MAX(extract(year from academic_year_end_date))
            FROM bi_alefdw.bi_all_schools_dim_mv asd
            WHERE asd.school_organisation = 'MHS'
        )
     ) fl
         JOIN LESSON_PROGRESS lps ON fl.fle_dw_id = lps.fle_dw_id
         JOIN pre_agg_time dtc
            ON fl.student_dw_id = dtc.fle_student_dw_id
            AND fl.lo_attempted = dtc.fle_lo_dw_id
            AND fl.local_date = dtc.local_date
WHERE NVL(fle_lesson_category, 'NA') <> 'EXPERIENTIAL_LESSON';