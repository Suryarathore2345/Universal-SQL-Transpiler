CREATE or Replace MATERIALIZED LAKE VIEW {{os_bi_coredw}}.adt_course_lo_student_report_detail_mv
AS
WITH dim_school AS (
    SELECT DISTINCT
        tenant_name,
        school_organisation,
        organisation_dw_id,
        school_dw_id,
        school_id,
        school_name,
        school_city_name,
        school_label,
        school_composition
    FROM {{rs_bi_coredw}}.bi_all_schools_dim
),

-- get the current school of the student, but keep other attributes at time of test
dim_student AS (
    SELECT
        ds.student_dw_id,
        ds.student_id,
        ds.student_username,
        ds.student_school_dw_id,
        ds.student_section_dw_id,
        ds.student_grade_dw_id,
        ds.student_created_time,
        ds.student_active_until,
        ds.student_status,
        ds.student_tags,
        ds.student_special_needs,
        ds.student_first_created_date,
        sc.tenant_name,
        sc.school_organisation,
        sc.organisation_dw_id,
        sc.school_dw_id,
        sc.school_id,
        sc.school_name,
        sc.school_city_name,
        sc.school_label,
        sc.school_composition,
        st.student_current_status
    FROM {{rs_bi_coredw}}.bi_student_dim AS ds
    INNER JOIN (
        SELECT
            x.student_dw_id,
            x.student_school_dw_id  AS student_current_school_dw_id,
            x.student_status        AS student_current_status
        FROM (
            SELECT
                ds2.student_dw_id,
                ds2.student_school_dw_id,
                ds2.student_status,
                ds2.student_created_time,
                ROW_NUMBER() OVER (
                    PARTITION BY ds2.student_dw_id
                    ORDER BY ds2.student_created_time DESC , student_status ASC 
                ) AS rn
            FROM {{rs_bi_coredw}}.bi_student_dim AS ds2
        ) AS x
        WHERE x.rn = 1
    ) AS st
        ON ds.student_dw_id = st.student_dw_id
    INNER JOIN dim_school AS sc
        ON st.student_current_school_dw_id = sc.school_dw_id
),

dim_test AS (
    SELECT
        lo.lo_dw_id              AS test_dw_id,
        lo.lo_id                 AS test_id,
        si.step_instance_pool_id AS pool_id,
        -- hardcoded as result of query of 2 fact tables -- fle and fasr -- but avoid using them - data is expected static for lo tests
        CASE
            WHEN lo.lo_dw_id IN (140884, 146308) THEN 'READING'
            WHEN lo.lo_dw_id = 147290 THEN 'LISTENING'
            ELSE 'UNKNOWN'
        END AS test_skill
    FROM {{rs_coredw}}.dim_learning_objective AS lo
    INNER JOIN {{rs_coredw}}.dim_step_instance AS si
        ON lo.lo_id = si.step_instance_lo_id
       AND si.step_instance_status = 1
       AND si.step_instance_attach_status = 1
    WHERE lo.lo_type = 'DIAGNOSTIC_TEST'
      AND lo.lo_status = 1
),

adt_potential_students AS (
    -- PART 1: course_ability_test_association-based classes
    SELECT
        ds.tenant_name,
        ds.school_organisation,
        ds.school_city_name,
        ds.school_composition,
        ds.school_name,
        ds.school_label,
        ds.school_id,
        ds.school_dw_id,
        CASE
            WHEN LOWER(dc.class_gen_subject) IN ('physics', 'biology', 'chemistry') THEN 'science'
            ELSE LOWER(dc.class_gen_subject)
        END AS class_gen_subject,
        test.test_skill,
        test.pool_id,
        dg.grade_k12grade,
        ds.student_special_needs,
        ds.student_tags,
        ds.student_current_status,
        YEAR(sc.academic_year_end_date) AS academic_year,
        COUNT(DISTINCT dcu.class_user_user_dw_id) AS class_total_students
    FROM {{rs_coredw}}.dim_class AS dc
    INNER JOIN {{rs_coredw}}.dim_course_ability_test_association AS cata
        ON dc.class_material_id = cata.cata_course_id
       AND cata.cata_attach_status = 1
    INNER JOIN dim_test AS test
        ON cata.cata_ability_test_activity_uuid = test.test_id
    INNER JOIN {{rs_coredw}}.dim_class_user AS dcu
        ON dcu.class_user_class_dw_id = dc.class_dw_id
    INNER JOIN {{rs_bi_coredw}}.bi_all_schools_dim AS sc
        ON dc.class_school_id = sc.school_id
       AND dc.class_academic_year_id = sc.academic_year_id
       AND sc.academic_year_end_date >= DATE(cata.cata_created_time)
       AND sc.academic_year_end_date <= COALESCE(DATE(cata.cata_updated_time), DATE('9999-12-01'))
       AND sc.academic_year_start_date <= COALESCE(DATE(cata.cata_updated_time), DATE('9999-12-01'))
    INNER JOIN dim_student AS ds
        ON dcu.class_user_user_dw_id = ds.student_dw_id
    INNER JOIN {{rs_coredw}}.dim_grade AS dg
        ON dg.grade_id = dc.class_grade_id
    WHERE dcu.class_user_role_dw_id = 2
      AND dcu.class_user_attach_status = 1
      AND dc.class_status = 1
      AND dc.class_gen_subject <> 'Core Stars'
    GROUP BY
        ds.tenant_name,
        ds.school_organisation,
        ds.school_city_name,
        ds.school_composition,
        ds.school_name,
        ds.school_label,
        ds.school_id,
        ds.school_dw_id,
        CASE
            WHEN LOWER(dc.class_gen_subject) IN ('physics', 'biology', 'chemistry') THEN 'science'
            ELSE LOWER(dc.class_gen_subject)
        END,
        test.test_skill,
        test.pool_id,
        dg.grade_k12grade,
        ds.student_special_needs,
        ds.student_tags,
        ds.student_current_status,
        YEAR(sc.academic_year_end_date)

    UNION ALL

    -- PART 2: instructional_plan-based classes (math/english from 2022)
    SELECT
        ds.tenant_name,
        ds.school_organisation,
        ds.school_city_name,
        ds.school_composition,
        ds.school_name,
        ds.school_label,
        ds.school_id,
        ds.school_dw_id,
        LOWER(dc.class_gen_subject) AS class_gen_subject,
        test.test_skill,
        test.pool_id,
        dg.grade_k12grade,
        ds.student_special_needs,
        ds.student_tags,
        ds.student_current_status,
        YEAR(sch.academic_year_end_date) AS academic_year,
        COUNT(DISTINCT dcu.class_user_user_dw_id) AS class_total_students
    FROM {{rs_coredw}}.dim_class AS dc
    INNER JOIN {{rs_coredw}}.dim_class_user AS dcu
        ON dcu.class_user_class_dw_id = dc.class_dw_id
    INNER JOIN {{rs_bi_coredw}}.bi_all_schools_dim AS sch
        ON dc.class_academic_year_id = sch.academic_year_id
       AND dc.class_school_id = sch.school_id
    INNER JOIN dim_student AS ds
        ON dcu.class_user_user_dw_id = ds.student_dw_id
    INNER JOIN {{rs_coredw}}.dim_grade AS dg
        ON dg.grade_id = dc.class_grade_id
    INNER JOIN {{rs_coredw}}.dim_instructional_plan AS dip
        ON dip.instructional_plan_id = dc.class_material_id
       AND dip.instructional_plan_status = 1
    INNER JOIN dim_test AS test
        ON dip.instructional_plan_item_lo_dw_id = test.test_dw_id
    WHERE dcu.class_user_role_dw_id = 2
      AND dcu.class_user_attach_status = 1
      AND dc.class_status = 1
      AND LOWER(dc.class_gen_subject) IN ('math', 'english')  -- previous academic year subjects
      AND YEAR(sch.academic_year_end_date) >= 2022
    GROUP BY
        ds.tenant_name,
        ds.school_organisation,
        ds.school_city_name,
        ds.school_composition,
        ds.school_name,
        ds.school_label,
        ds.school_id,
        ds.school_dw_id,
        LOWER(dc.class_gen_subject),
        test.test_skill,
        test.pool_id,
        dg.grade_k12grade,
        ds.student_special_needs,
        ds.student_tags,
        ds.student_current_status,
        YEAR(sch.academic_year_end_date)
),

fact_adt AS (
    SELECT
        fasr.fasr_dw_id,
        fasr.fasr_student_dw_id,
        fasr.fasr_question_pool_id,
        from_utc_timestamp(fasr.fasr_created_time, sch.tenant_timezone) AS fasr_created_date,
        YEAR(sch.academic_year_end_date) AS academic_year,
        fasr.fasr_attempt AS test_order,
        LAG(fasr.fasr_final_score, 1) OVER (
            PARTITION BY
                fasr.fasr_class_subject_name,
                fasr.fasr_framework,
                fasr.fasr_student_dw_id
            ORDER BY fasr.fasr_created_time
        ) AS previous_score,
        CASE LOWER(fasr.fasr_framework)
            WHEN 'quantile' THEN CAST(fasr.fasr_final_score * 0.5 + 200 AS INT)
            ELSE fasr.fasr_final_score
        END AS fasr_final_score,
        CASE LOWER(fasr.fasr_framework)
            WHEN 'core'     THEN CAST(fasr.fasr_final_grade AS STRING)
            WHEN 'quantile' THEN CAST(fasr.fasr_final_grade AS STRING)
            WHEN 'lexile'   THEN fasr.fasr_secondary_result
            ELSE fasr.fasr_final_result
        END AS fasr_final_result,
        LOWER(fasr.fasr_class_subject_name) AS fasr_curriculum_subject_name,
        CASE
            WHEN fasr.fasr_total_time_spent >= 0
             AND fasr.fasr_total_time_spent <= 5400 THEN fasr.fasr_total_time_spent
            WHEN fasr.fasr_total_time_spent > 5400 THEN 5400
            ELSE 0
        END AS fasr_total_time_spent,
        fasr.fasr_final_grade,
        st.school_dw_id,  -- use the school defined in dim_student (current)
        g.grade_k12grade,
        st.student_special_needs,
        st.student_tags,
        st.student_current_status
    FROM {{rs_coredw}}.fact_adt_student_report AS fasr
    INNER JOIN dim_student AS st
        ON fasr.fasr_student_dw_id = st.student_dw_id
       AND fasr.fasr_created_time BETWEEN st.student_created_time
           AND COALESCE(st.student_active_until, TIMESTAMP('9999-12-01'))
    INNER JOIN {{rs_bi_coredw}}.bi_all_schools_dim AS sch
        ON fasr.fasr_school_dw_id = sch.school_dw_id
       AND DATE(fasr.fasr_created_time) >= sch.academic_year_start_date
       AND DATE(fasr.fasr_created_time) <= sch.academic_year_end_date
    INNER JOIN {{rs_coredw}}.dim_grade AS g
        ON g.grade_dw_id = st.student_grade_dw_id
    WHERE fasr.fasr_status = 1
)

SELECT DISTINCT
    aps.tenant_name,
    aps.school_organisation,
    aps.school_city_name,
    aps.school_composition,
    aps.school_name,
    aps.school_id,
    aps.school_dw_id,
    aps.school_label,
    aps.class_gen_subject,
    aps.test_skill,
    aps.pool_id AS test_id,
    aps.grade_k12grade AS grade,
    aps.student_special_needs,
    aps.student_tags,
    aps.student_current_status,
    aps.academic_year AS academicyear,
    aps.class_total_students,
    fa.fasr_dw_id,
    fa.fasr_student_dw_id,
    fa.fasr_created_date,
    fa.academic_year,
    fa.test_order,
    fa.previous_score,
    fa.fasr_final_score,
    fa.fasr_final_result,
    CAST(NULL AS STRING) AS target_cefr_level, -- no arabic cefr in old framework
    fa.fasr_final_grade,
    fa.fasr_total_time_spent
FROM adt_potential_students AS aps
LEFT JOIN fact_adt AS fa
    ON aps.school_dw_id          = fa.school_dw_id
   AND aps.grade_k12grade        = fa.grade_k12grade
   AND aps.class_gen_subject     = fa.fasr_curriculum_subject_name
   AND aps.student_special_needs = fa.student_special_needs
   AND aps.student_tags          = fa.student_tags
   AND aps.student_current_status= fa.student_current_status
   AND aps.academic_year         = fa.academic_year
   AND aps.pool_id               = fa.fasr_question_pool_id;