CREATE MATERIALIZED VIEW bi_alefdw_dev.student_lesson_progress_sport_academy_mv
AS
WITH TOTAL_LESSONS_ASSIGNED AS (
    SELECT DISTINCT d_cu.class_user_user_dw_id,
                    d_cu.class_user_class_dw_id,
                    cac.activity_dw_id                                                   AS lo_to_finish,
                    dlo.lo_title,
                    dlo.lo_id,
                    cac.course_id,
                    cac.course_name,
                    cac.class_dw_id,
                    initcap(cac.class_title)                                             AS class_title,
                    initcap(cac.class_gen_subject)                                       AS class_gen_subject,
                    cac.tenant_name,
                    cac.school_dw_id,
                    cac.school_id,
                    cac.school_name,
                    cac.school_alias                                                     AS school_adek_id,
                    cac.school_country_name,
                    cac.school_city_name,
                    cac.school_label,
                    cac.school_organisation                                              AS organisation_name,
                    cac.school_cx_cluster,
                    cac.academic_year_start_date,
                    cac.academic_year_end_date,
                    NVL(CASE
                            WHEN cac.pacing = 'MONTH' THEN date_part(month, cac.week_start_date)
                            ELSE date_part(week, cac.week_start_date)
                        END, 1)                                                          AS week_number,
                    NVL(cac.week_start_date, cac.academic_year_start_date)               AS week_start_date,
                    NVL(cac.week_end_date, cac.academic_year_end_date)                   AS week_end_date,
                    NVL(cac.term_academic_period_order, 1)                               AS term_academic_period_order,
                    NVL(cac.instructional_plan_item_order, 1)                            AS activity_item_order,
                    NVL(cac.term_start_date, cac.academic_year_start_date)               AS term_start_date,
                    NVL(cac.term_end_date, cac.academic_year_end_date)                   AS term_end_date,
                    cac.pacing
    FROM alefdw.dim_class_user d_cu
             INNER JOIN bi_alefdw.core_class_activity_content_mv cac
                        ON cac.class_dw_id = d_cu.class_user_class_dw_id
             INNER JOIN alefdw.dim_class dc
                        ON dc.class_dw_id = d_cu.class_user_class_dw_id
             INNER JOIN alefdw.dim_course dcr
                        ON md5(dcr.course_id) = md5(class_material_id)
             INNER JOIN alefdw.dim_learning_objective dlo
                        ON dlo.lo_dw_id = cac.activity_dw_id
                            AND dlo.lo_status = 1
                            AND NVL(dlo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
    WHERE d_cu.class_user_attach_status = 1
      AND d_cu.class_user_status = 1
      AND d_cu.class_user_role_dw_id = 2
      AND school_dw_id = 132766
      AND course_type = 'CORE'
),
     COMPLETED_LESSONS AS
         (select *
          from (select TRUNC(CONVERT_TIMEZONE('UTC', dsc.tenant_timezone, fle_created_time)) AS local_date,
                       fle_ls_id,
                       fle_lo_dw_id,
                       fle_student_dw_id,
                       fle_attempt,
                       fle_dw_id,
                       case when lo.lo_max_stars > 0 then fle_total_score end                    AS fle_score,
                       ROW_NUMBER() over (PARTITION BY fle_ls_id ORDER BY fle_created_time desc) AS rnk
                FROM alefdw.fact_learning_experience
                         JOIN alefdw.dim_learning_objective lo
                              ON lo.lo_dw_id = fle_lo_dw_id
                                  AND lo.lo_status = 1
                         JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                              ON fle_school_dw_id = dsc.school_dw_id
                                  AND trunc(fle_created_time) >= dsc.academic_year_start_date
                                  AND trunc(fle_created_time) <= dsc.academic_year_end_date
                where fle_completion_node is true
                  AND fact_learning_experience.fle_activity_type <> 'INTERIM_CHECKPOINT'
                  AND fle_material_type <> 'PATHWAY'
                  AND school_dw_id = 132766
                  AND fle_is_additional_resource <> TRUE) as completed_lessons -- get latest completed record for a student lesson
          where rnk = 1),

     LESSON_PROGRESS AS
         (SELECT distinct local_date,
                          fle_ls_id,
                          fle_dw_id,
                          fle_lo_dw_id,
                          fle_student_dw_id,
                          fle_attempt,
                          0             as fle_score,
                          'In-Progress' AS lo_status
          FROM (SELECT TRUNC(CONVERT_TIMEZONE('UTC', dsc.tenant_timezone, fle_created_time)) AS local_date,
                       fle_ls_id,
                       fle_lo_dw_id,
                       fle_student_dw_id,
                       fle_attempt,
                       MAX(fle_dw_id) fle_dw_id
                FROM alefdw.fact_learning_experience
                         JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                              ON fle_school_dw_id = dsc.school_dw_id
                                  AND trunc(fle_created_time) >= dsc.academic_year_start_date
                                  AND trunc(fle_created_time) <= dsc.academic_year_end_date
                WHERE fle_ls_id NOT IN (select fle_ls_id from COMPLETED_LESSONS)
                  AND fle_attempt = 1
                  AND fact_learning_experience.fle_activity_type <> 'INTERIM_CHECKPOINT'
                  AND fle_material_type <> 'PATHWAY'
                  AND fle_is_additional_resource <> TRUE
                  AND fle_abbreviation <> 'NA'
                  AND school_dw_id = 132766
                GROUP BY 1, 2, 3,4,5) alias -- get any in-progress record for the student lesson

          UNION ALL

          SELECT distinct local_date, fle_ls_id, fle_dw_id, fle_lo_dw_id, fle_student_dw_id, fle_attempt, fle_score, 'Completed' AS lo_status
          FROM COMPLETED_LESSONS),

     STUDENT_LESSON_PROGRESS AS (SELECT fle.fle_student_dw_id,
                                        fle.fle_class_dw_id,
                                        fle.fle_lo_dw_id,
                                        fle_lesson_category,
                                        lp.fle_score,
                                        lp.local_date,
                                        COALESCE(lo_status, 'Not Started')                                                                as lo_status,
                                        lp.fle_dw_id,
                                        lp.fle_ls_id,
                                        fle.fle_academic_year_dw_id,
                                        dsc.academic_year_start_date,
                                        dsc.academic_year_end_date,
                                        dsc.school_name,
                                        dsc.school_dw_id,
                                        SUM((CASE
                                                 WHEN fle.fle_total_time <= 900 THEN fle.fle_total_time
                                                 WHEN fle.fle_total_time > 900 THEN 900
                                                 ELSE 0
                                            END))
                                        OVER (PARTITION BY fle_academic_year_dw_id,fle.fle_student_dw_id,fle.fle_lo_dw_id) AS session_time

                                 FROM alefdw.fact_learning_experience fle
                                          JOIN LESSON_PROGRESS lp
                                               ON lp.fle_ls_id = fle.fle_ls_id
                                                   AND lp.fle_lo_dw_id = fle.fle_lo_dw_id AND fle.fle_attempt = 1
                                          JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                                               on dsc.school_dw_id = fle_school_dw_id
                                                   AND trunc(fle_created_time) <= dsc.academic_year_end_date
                                                   AND school_dw_id = 132766
                                                   AND NVL(fle_lesson_category, 'NA') <> 'EXPERIENTIAL_LESSON'
                                                   AND fle_abbreviation <> 'NA'
                                                   AND fle.fle_activity_type <> 'INTERIM_CHECKPOINT'
                                                   AND fle_material_type <> 'PATHWAY'
                                                   AND fle_is_additional_resource <> TRUE
                                                   AND fle.fle_ls_id NOT IN
                                                       (select distinct fle_ls_id
                                                        from alefdw.fact_learning_experience
                                                        where fle_state = 4))

select DISTINCT sla.*,
                dst.student_tags,
                dst.student_special_needs,
                dst.student_id,
                dst.student_dw_id,
                dg.grade_k12grade,
                lps.fle_lo_dw_id                   as lo_attempted,
                lps.session_time,
                lps.fle_academic_year_dw_id,
                lps.fle_student_dw_id,
                COALESCE(lo_status, 'Not Started') as lo_status,
                lps.fle_score as fle_score,
                lps.local_date as local_date
from TOTAL_LESSONS_ASSIGNED sla
         JOIN bi_alefdw.bi_student_dim_mv dst ON dst.student_dw_id = sla.class_user_user_dw_id
         JOIN alefdw.dim_grade dg on dg.grade_dw_id = dst.student_grade_dw_id
         LEFT JOIN STUDENT_LESSON_PROGRESS lps on sla.lo_to_finish = lps.fle_lo_dw_id
    and sla.class_user_user_dw_id = lps.fle_student_dw_id;