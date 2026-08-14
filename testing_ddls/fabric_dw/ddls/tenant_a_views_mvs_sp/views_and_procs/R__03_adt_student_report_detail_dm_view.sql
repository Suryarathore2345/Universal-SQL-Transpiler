CREATE OR ALTER VIEW ${os_bi_coredw}.adt_student_report_detail_dm_view
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
    FROM ${rs_bi_coredw}.bi_all_schools_dim
),

dim_student AS (
    SELECT
        ds.student_dw_id,
        ds.student_school_dw_id,
        ds.student_grade_dw_id,
        ds.student_created_time,
        ds.student_active_until,
        ds.student_special_needs,
        ds.student_tags,
        ds.student_status,
        st.student_current_school_dw_id,
        st.student_current_status,
        sc.tenant_name,
        sc.school_organisation,
        sc.organisation_dw_id,
        sc.school_dw_id,
        sc.school_id,
        sc.school_name,
        sc.school_city_name,
        sc.school_label,
        sc.school_composition
    FROM ${rs_bi_coredw}.bi_student_dim ds
    INNER JOIN (
        SELECT
            student_dw_id,
            student_school_dw_id AS student_current_school_dw_id,
            student_status       AS student_current_status
        FROM (
            SELECT
                   student_dw_id,
                   student_school_dw_id,
                   student_grade_dw_id,
                   student_created_time,
                   student_active_until,
                   student_special_needs,
                   student_tags,
                   student_status,
                   ROW_NUMBER() OVER (
                       PARTITION BY student_dw_id
                       ORDER BY student_created_time DESC , student_status ASC
                   ) AS rn
            FROM ${rs_bi_coredw}.bi_student_dim
        ) x
        WHERE rn = 1
    ) st
        ON ds.student_dw_id = st.student_dw_id
    INNER JOIN dim_school sc
        ON st.student_current_school_dw_id = sc.school_dw_id
),

dim_test AS (
    SELECT
        dw_id AS test_dw_id,
        id    AS test_id,
        UPPER(skill) AS test_skill
    FROM ${rs_coredw}.dim_testpart
    WHERE status = 1
),

adt_potential_students AS (
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
            WHEN dc.class_gen_subject IN ('physics','biology','chemistry')
                THEN 'SCIENCE'
            WHEN dcsa.cs_subject_id IS NULL
                THEN UPPER(dc.class_gen_subject)
            ELSE 'ARABITS'
        END AS class_gen_subject,

        test.test_skill AS test_skill,
        test.test_id AS test_id,

        dg.grade_k12grade,
        ds.student_special_needs,
        ds.student_tags,
        ds.student_current_status,
        DATEPART(YEAR, sc.academic_year_end_date) AS academic_year,
        COUNT(DISTINCT dcu.class_user_user_dw_id) AS class_total_students
    FROM ${rs_coredw}.dim_class dc
    INNER JOIN ${rs_coredw}.dim_course_ability_test_association cata
        ON dc.class_material_id = cata.cata_course_id
       AND cata.cata_attach_status = 1
    INNER JOIN dim_test test
        ON cata.cata_ability_test_activity_uuid = test.test_id
    INNER JOIN ${rs_coredw}.dim_class_user dcu
        ON dcu.class_user_class_dw_id = dc.class_dw_id
    INNER JOIN ${rs_bi_coredw}.bi_all_schools_dim sc
        ON dc.class_school_id = sc.school_id
       AND dc.class_academic_year_id = sc.academic_year_id
       AND sc.academic_year_end_date >= CONVERT(DATE, cata.cata_created_time)
       AND sc.academic_year_end_date <= ISNULL(CONVERT(DATE, cata.cata_updated_time), CONVERT(DATE, '9999-12-01'))
       AND sc.academic_year_start_date <= ISNULL(CONVERT(DATE, cata.cata_updated_time), CONVERT(DATE, '9999-12-01'))
    INNER JOIN dim_student ds
        ON dcu.class_user_user_dw_id = ds.student_dw_id
    INNER JOIN ${rs_coredw}.dim_grade dg
        ON dg.grade_id = dc.class_grade_id
    LEFT JOIN ${rs_coredw}.dim_course_subject_association dcsa
        ON dcsa.cs_course_id = cata.cata_course_id
       AND dcsa.cs_status = 1
       AND dcsa.cs_subject_dw_id IN (129,503)
    WHERE dcu.class_user_role_dw_id = 2
      AND dcu.class_user_status = 1
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
            WHEN dc.class_gen_subject IN ('physics','biology','chemistry')
                THEN 'SCIENCE'
            WHEN dcsa.cs_subject_id IS NULL
                THEN UPPER(dc.class_gen_subject)
            ELSE 'ARABITS'
        END,
        test.test_skill,
        test.test_id,
        dg.grade_k12grade,
        ds.student_special_needs,
        ds.student_tags,
        ds.student_current_status,
        DATEPART(YEAR, sc.academic_year_end_date)
),

fasr AS (
    SELECT
        fasr_dw_id,
        fasr_fle_ls_uuid,
        fasr_test_id,
        fasr_school_dw_id,
        fasr_student_dw_id,
        fasr_created_time,
        fasr_attempt,
        fasr_class_subject_name,
        fasr_framework,
        fasr_final_score,
        fasr_final_grade,
        fasr_final_result,
        fasr_secondary_result,
        fasr_final_category,
        fasr_total_time_spent
    FROM ${rs_coredw}.fact_adt_student_report
    WHERE fasr_status = 1
      AND CONVERT(DATE, fasr_created_time) >= '2025-07-01'

    UNION ALL

    SELECT
        dw_id,
        test_level_session_id,
        test_level_id,
        school_dw_id,
        candidate_dw_id,
        created_time,
        attempt_number,
        subject,
        framework,
        final_score,
        final_grade,
        NULL,
        NULL,
        final_category,
        total_timespent
    FROM ${rs_coredw}.fact_candidate_assessment_progress
    WHERE event_type = 'CandidateReportGeneratedDataEvent'
),

fact_adt AS (
    SELECT
        fasr.fasr_dw_id,
        fasr.fasr_student_dw_id,
        fasr.fasr_test_id,
        CONVERT(
            DATE,
            fasr.fasr_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(sch.windows_timezone, 'UTC')
        ) AS fasr_created_date,
        DATEPART(YEAR, sch.academic_year_end_date) AS academic_year,
        fasr.fasr_attempt AS test_order,

        LAG(fasr.fasr_final_score) OVER (
            PARTITION BY fasr.fasr_class_subject_name,
                         fasr.fasr_framework,
                         fasr.fasr_student_dw_id
            ORDER BY fasr.fasr_created_time
        ) AS previous_score,

        fasr.fasr_final_score,

        CASE fasr.fasr_framework
            WHEN 'core'
                THEN CONVERT(VARCHAR(100), fasr.fasr_final_grade)
            WHEN 'core scale' 
                THEN CONVERT(VARCHAR(100), fasr.fasr_final_grade) 
            WHEN 'lexile'
                THEN fasr.fasr_secondary_result
            WHEN 'lexile®' 
                THEN fasr.fasr_secondary_result
            WHEN 'cefr'
                THEN cefr.cefr_level
            ELSE fasr.fasr_final_category
        END AS fasr_final_result,

        CASE
            WHEN fasr.fasr_framework = 'cefr'
                THEN cefr.target_cefr_level
        END AS target_cefr_level,

        SUM(
            CASE
                WHEN fasr.fasr_total_time_spent BETWEEN 0 AND 5400 THEN fasr.fasr_total_time_spent
                WHEN fasr.fasr_total_time_spent > 5400 THEN 5400
                ELSE 0
            END
        ) OVER (
            PARTITION BY CONVERT(DATE, fasr.fasr_created_time),
                         fasr.fasr_student_dw_id,
                         fasr.fasr_dw_id
        ) AS fasr_total_time_spent,

        fasr.fasr_final_grade,
        st.school_dw_id,
        g.grade_k12grade,
        st.student_special_needs,
        st.student_tags,
        st.student_current_status
    FROM fasr
    INNER JOIN dim_student st
        ON fasr.fasr_student_dw_id = st.student_dw_id
       AND fasr.fasr_created_time BETWEEN st.student_created_time
                                      AND ISNULL(st.student_active_until, '9999-12-01')
    INNER JOIN ${rs_bi_coredw}.bi_all_schools_dim sch
        ON fasr.fasr_school_dw_id = sch.school_dw_id
       AND fasr.fasr_created_time >= CONVERT(DATETIME2, sch.academic_year_start_date)
       AND fasr.fasr_created_time < DATEADD(day, 1, CONVERT(DATETIME2, sch.academic_year_end_date))

    INNER JOIN ${rs_coredw}.dim_grade g
        ON g.grade_dw_id = st.student_grade_dw_id
    LEFT JOIN ${rs_bi_coredw}.adt_cefr_level_mapping cefr
        ON g.grade_k12grade = cefr.grade
       AND fasr.fasr_final_score BETWEEN cefr.min_scale_score AND cefr.max_scale_score
)

SELECT
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
    aps.test_id,
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
    fa.target_cefr_level,
    fa.fasr_final_grade,
    fa.fasr_total_time_spent
FROM adt_potential_students aps
LEFT JOIN fact_adt fa
    ON aps.school_dw_id = fa.school_dw_id
   AND aps.grade_k12grade = fa.grade_k12grade
   AND aps.student_special_needs = fa.student_special_needs
   AND aps.student_tags = fa.student_tags
   AND aps.student_current_status = fa.student_current_status
   AND aps.academic_year = fa.academic_year
   AND aps.test_id = fa.fasr_test_id

UNION ALL

SELECT
    tenant_name,
    school_organisation,
    school_city_name,
    school_composition,
    school_name,
    school_id,
    school_dw_id,
    school_label,
    class_gen_subject,
    test_skill,
    test_id,
    grade,
    student_special_needs,
    student_tags,
    student_current_status,
    academicyear,
    class_total_students,
    fasr_dw_id,
    fasr_student_dw_id,
    fasr_created_date,
    academic_year,
    test_order,
    previous_score,
    fasr_final_score,
    fasr_final_result,
    target_cefr_level,
    fasr_final_grade,
    fasr_total_time_spent
FROM ${rs_bi_coredw}.adt_course_lo_student_report_detail;
