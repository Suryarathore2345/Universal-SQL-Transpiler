CREATE MATERIALIZED VIEW bi_alefdw_dev.adt_course_lo_student_report_detail_mv AS
WITH dim_school AS(
    SELECT DISTINCT tenant_name,
                    school_organisation,
                    organisation_dw_id,
                    school_dw_id,
                    school_id,
                    school_name,
                    school_city_name,
                    school_label,
                    school_composition
    FROM bi_alefdw.bi_all_schools_dim_mv
),
dim_student AS ( -- get the current school of the student, but keep other attributes at time of test
    SELECT ds.*,
           sc.*,
            student_current_status
    FROM bi_alefdw.bi_student_dim_mv ds
        INNER JOIN (SELECT student_dw_id,
                     student_school_dw_id  AS student_current_school_dw_id,
                     student_status        AS student_current_status,
                     ROW_NUMBER() OVER (PARTITION BY student_dw_id ORDER BY student_created_time DESC, student_status ASC ) AS rank
                    FROM bi_alefdw.bi_student_dim_mv ds2
                    QUALIFY rank = 1) st
              ON ds.student_dw_id = st.student_dw_id
        INNER JOIN dim_school sc
              ON st.student_current_school_dw_id = sc.school_dw_id
),
dim_test AS (
    SELECT lo.lo_dw_id AS test_dw_id,
           lo.lo_id AS test_id,
           si.step_instance_pool_id AS pool_id,
           -- hardcoded as result of query of 2 fact tables -- fle and fasr -- but avoid using them - data is expected static for lo tests
           CASE WHEN lo_dw_id IN (140884,146308) THEN 'READING'
                WHEN lo_dw_id = 147290 THEN 'LISTENING'
           ELSE 'UNKNOWN'  END  AS test_skill
    FROM alefdw.dim_learning_objective lo
    INNER JOIN alefdw.dim_step_instance si
        ON lo.lo_id = si.step_instance_lo_id
        AND si.step_instance_status = 1
        AND si.step_instance_attach_status = 1
    WHERE lo.lo_type = 'DIAGNOSTIC_TEST'
        AND lo_status = 1
),
adt_potential_students AS (
    SELECT ds.tenant_name,
           ds.school_organisation,
           ds.school_city_name,
           ds.school_composition,
           ds.school_name,
           ds.school_label,
           ds.school_id,
           ds.school_dw_id,
           CASE WHEN lower(dc.class_gen_subject) IN ('physics', 'biology', 'chemistry') then 'science' else lower(dc.class_gen_subject)  end as class_gen_subject,
           test.test_skill,
           test.pool_id,
           dg.grade_k12grade,
           ds.student_special_needs,
           ds.student_tags,
           ds.student_current_status,
           date_part_year(sc.academic_year_end_date) AS academic_year,
           count(DISTINCT dcu.class_user_user_dw_id) AS class_total_students
    FROM alefdw.dim_class dc
             INNER JOIN alefdw.dim_course_ability_test_association cata
                        ON dc.class_material_id = cata.cata_course_id
                        AND cata.cata_attach_status = 1
             INNER JOIN dim_test test
                        ON cata.cata_ability_test_activity_uuid = test.test_id
             INNER JOIN alefdw.dim_class_user dcu
                        ON dcu.class_user_class_dw_id = dc.class_dw_id
             INNER JOIN bi_alefdw.bi_all_schools_dim_mv sc
                        ON dc.class_school_id = sc.school_id
                        AND dc.class_academic_year_id = sc.academic_year_id
                        AND sc.academic_year_end_date >= DATE(cata.cata_created_time)
                        AND sc.academic_year_end_date <= COALESCE(DATE(cata.cata_updated_time),'9999-12-01')
                        AND sc.academic_year_start_date <= COALESCE(DATE(cata.cata_updated_time),'9999-12-01')
             INNER JOIN dim_student ds
                        ON dcu.class_user_user_dw_id = ds.student_dw_id
             JOIN alefdw.dim_grade dg ON dg.grade_id = dc.class_grade_id
    WHERE dcu.class_user_role_dw_id = 2
      AND dcu.class_user_attach_status = 1
      AND dc.class_status = 1
      AND dc.class_gen_subject != 'Alef Stars'
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
    UNION ALL
    SELECT  ds.tenant_name,
            ds.school_organisation,
            ds.school_city_name,
            ds.school_composition,
            ds.school_name,
            ds.school_label,
            ds.school_id,
            ds.school_dw_id,
            lower(dc.class_gen_subject)                        AS class_gen_subject,
            test.test_skill,
            test.pool_id,
            dg.grade_k12grade,
            ds.student_special_needs,
            ds.student_tags,
            ds.student_current_status,
            date_part_year(sch.academic_year_end_date)         AS academic_year,
            count(DISTINCT dcu.class_user_user_dw_id)          AS class_total_students
    FROM alefdw.dim_class dc
             INNER JOIN alefdw.dim_class_user dcu
                        ON dcu.class_user_class_dw_id = dc.class_dw_id
             INNER JOIN bi_alefdw.bi_all_schools_dim_mv sch
                        ON dc.class_academic_year_id = sch.academic_year_id
                        AND dc.class_school_id = sch.school_id
             INNER JOIN dim_student ds
                        ON dcu.class_user_user_dw_id = ds.student_dw_id
             INNER JOIN alefdw.dim_grade dg
                        ON dg.grade_id = dc.class_grade_id
             INNER JOIN alefdw.dim_instructional_plan dip
                        ON dip.instructional_plan_id = dc.class_material_id
                        AND dip.instructional_plan_status = 1
             INNER JOIN dim_test test
                        ON dip.instructional_plan_item_lo_dw_id = test.test_dw_id
    WHERE dcu.class_user_role_dw_id = 2
      AND dcu.class_user_attach_status = 1
      AND dc.class_status = 1
      AND lower(dc.class_gen_subject) IN ('math', 'english') -- --  previous academic year subjects - for prev years we identify classes with ADT
      AND date_part_year(sch.academic_year_end_date) >= 2022
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
),
     fact_adt AS (SELECT fasr.fasr_dw_id,
                         fasr.fasr_student_dw_id,
                         fasr.fasr_question_pool_id,
                         convert_timezone('UTC', sch.tenant_timezone, fasr.fasr_created_time) AS fasr_created_date,
                         date_part_year(sch.academic_year_end_date) AS academic_year,
                         fasr.fasr_attempt AS test_order,
                         LAG(fasr.fasr_final_score, 1)
                             OVER ( PARTITION BY fasr.fasr_class_subject_name, fasr.fasr_framework, fasr.fasr_student_dw_id
                                 ORDER BY fasr_created_time)  AS previous_score,
                         CASE lower(fasr_framework)
                             WHEN 'quantile' THEN (fasr.fasr_final_score * 0.5 + 200)::INT
	                         ELSE fasr.fasr_final_score
	                     END AS fasr_final_score,
                         CASE lower(fasr_framework)
                             WHEN 'alef' THEN
                                 fasr.fasr_final_grade::VARCHAR
                             WHEN 'quantile' THEN
                                 fasr.fasr_final_grade::VARCHAR
                             WHEN 'lexile' THEN
                                 fasr.fasr_secondary_result
                             ELSE fasr_final_result
                         END  AS fasr_final_result,
                         lower(fasr.fasr_class_subject_name) AS fasr_curriculum_subject_name,
                         CASE
                             WHEN fasr.fasr_total_time_spent >= 0 AND fasr.fasr_total_time_spent <= 5400 THEN fasr.fasr_total_time_spent
                             WHEN fasr.fasr_total_time_spent > 5400 THEN 5400
                             ELSE 0
                         END AS fasr_total_time_spent,
                         fasr.fasr_final_grade,
                         st.school_dw_id,       -- use the school defined in dim_student (current)
                         g.grade_k12grade,
                         st.student_special_needs,
                         st.student_tags,
                         st.student_current_status
        FROM alefdw.fact_adt_student_report fasr
        INNER JOIN dim_student st
            ON fasr_student_dw_id = st.student_dw_id
            AND fasr.fasr_created_time BETWEEN st.student_created_time
            AND coalesce(st.student_active_until, '9999-12-01')
        INNER JOIN bi_alefdw.bi_all_schools_dim_mv sch
            ON fasr.fasr_school_dw_id = sch.school_dw_id
            AND date(fasr_created_time) >= sch.academic_year_start_date
            AND date(fasr_created_time) <= sch.academic_year_end_date
        INNER JOIN alefdw.dim_grade g
            ON g.grade_dw_id = st.student_grade_dw_id
        WHERE fasr_status = 1
)
SELECT DISTINCT aps.tenant_name,
       aps.school_organisation,
       aps.school_city_name,
       aps.school_composition,
       aps.school_name,
       aps.school_id,
       aps.school_dw_id,
       aps.school_label,
       aps.class_gen_subject,
       aps.test_skill,
       aps.pool_id as test_id,
       aps.grade_k12grade AS grade,
       aps.student_special_needs,
       aps.student_tags,
       aps.student_current_status,
       aps.academic_year  AS academicyear,
       aps.class_total_students,
       fa.fasr_dw_id,
       fa.fasr_student_dw_id,
       fa.fasr_created_date,
       fa.academic_year,
       fa.test_order,
       fa.previous_score,
       fa.fasr_final_score,
       fa.fasr_final_result,
       null AS target_cefr_level, -- no arabic cefr in old framework
       fa.fasr_final_grade,
       fa.fasr_total_time_spent
FROM adt_potential_students aps
         LEFT JOIN fact_adt fa
                   ON aps.school_dw_id = fa.school_dw_id
                       AND aps.grade_k12grade = fa.grade_k12grade
                       AND aps.class_gen_subject = fa.fasr_curriculum_subject_name
                       AND aps.student_special_needs = fa.student_special_needs
                       AND aps.student_tags = fa.student_tags
                       AND aps.student_current_status = fa.student_current_status
                       AND aps.academic_year = fa.academic_year
                       AND aps.pool_id = fa.fasr_question_pool_id;
