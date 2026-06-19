CREATE OR REPLACE VIEW bi_alefdw_dev.agg_student_learning_progress_view AS
With class_total_students AS (
SELECT
                '9999' as curr_subject_name,
                '9999' as curr_grade_name,
                 999 as curr_grade_dw_id,
                999 as curr_subject_dw_id,
                st.class_gen_subject,
                st.school_dw_id,
                st.section_dw_id,
                st.class_dw_id,
                st.class_title,
                st.instructional_plan_id,
                st.grade_name,
                st.section_name,
                st.content_academic_year_name,
                st.class_total_students
        FROM bi_alefdw.class_total_students_mv st join bi_alefdw.bi_active_schools_dim_mv ach
              on st.school_dw_id = ach.school_dw_id
          UNION ALL
          SELECT
                st.curr_subject_name,
                st.curr_grade_name,
                st.curr_grade_dw_id,
                st.curr_subject_dw_id,
                st.class_gen_subject,
                st.school_dw_id,
                st.section_dw_id,
                st.class_dw_id,
                st.class_title,
                st.instructional_plan_id,
                st.grade_name,
                st.section_name,
                st.content_academic_year_name,
                st.class_total_students
          from bi_alefdw.ip_class_total_students_mv st join bi_alefdw.bi_active_schools_dim_mv ach
              on st.school_dw_id = ach.school_dw_id
),
students_progress AS (SELECT slp.local_date,
                                  slp.lo_attempted,
                                  slp.lo_status,
                                  slp.student_dw_id,
                                  slp.fle_class_dw_id,
                                  slp.student_section_dw_id,
                                  slp.student_tags,
                                  slp.student_special_needs,
                                  slp.session_time,
                                  slp.fle_session_time,
                                  cts.class_gen_subject,
                                  cts.grade_name,
                                  cts.section_name,
                                  cts.school_dw_id,
                                  cts.content_academic_year_name,
                                  CASE
                                      WHEN slp.lo_status = 'Completed'
                                          AND slp.fle_score >= 0 THEN 1 END                                          AS completed_lesson,
                                  MAX(CASE
                                          WHEN slp.lo_status = 'Completed'
                                              AND slp.fle_score >= 0
                                              THEN CAST(slp.fle_score AS DECIMAL(10, 2)) END)                        AS average_score
                           FROM bi_alefdw.students_lesson_progress_mv slp
                                    JOIN class_total_students cts
                                         ON cts.class_dw_id = slp.fle_class_dw_id
                                             AND cts.section_dw_id = slp.student_section_dw_id
                                    JOIN alefdw.dim_course_activity_association dcaa
                                         ON md5(dcaa.caa_course_id) = md5(cts.instructional_plan_id)
                                             AND dcaa.caa_activity_type = 1
                                             AND dcaa.caa_status = 1
                                             AND dcaa.caa_activity_type = 1
                                             AND dcaa.caa_activity_is_optional IS FALSE
                                    JOIN alefdw.dim_learning_objective dip_dlo
                                         ON dcaa.caa_activity_dw_id = dip_dlo.lo_dw_id
                                             AND slp.lo_attempted = dip_dlo.lo_dw_id
                                             AND NVL(dip_dlo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
                                             AND dip_dlo.lo_status=1
                                             AND COALESCE(lo_template_uuid, 'DISTINCT_VALUE') NOT IN ('235229fa-4707-4286-8ec2-85f70347096a', '15295fd1-b5e3-46f9-9045-86ee3b13552b')
                           WHERE lower(class_title) NOT LIKE '%power skills%'
                             AND lower(class_title) NOT LIKE '%extra resources%'
                             AND lower(class_gen_subject) != 'alef stars'
                           GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16)

SELECT sp.local_date,
       sp.student_dw_id,
       sch.school_id,
       sch.school_dw_id,
       sch.school_name,
       sch.school_label,
       sch.school_city_name,
       sch.tenant_name,
       sch.school_organisation,
       sch.school_country_name,
       sp.grade_name,
       sp.section_name,
       sp.student_tags,
       sp.student_special_needs,
       sp.class_gen_subject,
       sp.content_academic_year_name,
       sum(sp.average_score)                                                 AS total_score,
       count(DISTINCT CASE sp.completed_lesson WHEN 1 THEN lo_attempted END) AS completed_lessons,
       sum(sp.session_time)                                                  AS session_time,
       sum(sp.fle_session_time) as fle_session_time
FROM students_progress sp
         INNER JOIN bi_alefdw.bi_active_schools_dim_mv sch
                    ON sch.school_dw_id = sp.school_dw_id
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
WITH NO SCHEMA BINDING;
