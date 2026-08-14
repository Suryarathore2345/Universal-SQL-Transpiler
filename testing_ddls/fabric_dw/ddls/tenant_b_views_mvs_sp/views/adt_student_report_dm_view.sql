CREATE OR ALTER VIEW ${OS_EAGLES_COREDW}.adt_student_report_dm_view
AS
WITH dim_student AS (
    SELECT
        ds.student_dw_id,
        ds.student_created_time,
        ds.student_active_until,
        ds.student_grade_dw_id,
        st.student_school_dw_id AS student_current_school_dw_id,
        st.student_section_dw_id AS student_current_section_dw_id
    FROM ${RS_BI_COREDW}.bi_student_dim ds
    LEFT JOIN ${RS_BI_COREDW}.bi_student_dim st
        ON ds.student_dw_id = st.student_dw_id
       AND st.student_status = 1
),

dim_test AS (
    SELECT
        dw_id AS test_dw_id,
        id AS test_id,
        id AS test_pool_id,
        UPPER(skill) AS test_skill
    FROM ${RS_COREDW}.dim_testpart
    WHERE status = 1

    UNION ALL

    SELECT
        lo.lo_dw_id AS test_dw_id,
        lo.lo_id AS test_id,
        si.step_instance_pool_id AS test_pool_id,
        CASE
            WHEN lo.lo_dw_id IN (140884,146308) THEN 'READING'
            WHEN lo.lo_dw_id = 147290 THEN 'LISTENING'
            ELSE 'UNKNOWN'
        END AS test_skill
    FROM ${RS_COREDW}.dim_learning_objective lo
    INNER JOIN ${RS_COREDW}.dim_step_instance si
        ON lo.lo_id = si.step_instance_lo_id
       AND si.step_instance_status = 1
       AND si.step_instance_attach_status = 1
    WHERE lo.lo_type = 'DIAGNOSTIC_TEST'
      AND lo.lo_status = 1
),

student_course_association AS (
    SELECT
        dc.class_gen_subject,
        dc.class_material_id,
        dc.class_school_id,
        dc.class_grade_id,
        dc.class_section_id,
        dc.class_dw_id,
        dc.class_title,
        dc.class_academic_year_id,
        dcu.class_user_class_dw_id,
        dcu.class_user_user_dw_id,
        ROW_NUMBER() OVER (
            PARTITION BY dcu.class_user_user_dw_id, dc.class_material_id
            ORDER BY dcu.class_user_created_time DESC
        ) AS rn
    FROM ${RS_COREDW}.dim_class dc
    INNER JOIN ${RS_COREDW}.dim_class_user dcu
        ON dc.class_dw_id = dcu.class_user_class_dw_id
    WHERE dcu.class_user_role_dw_id = 2
      AND dcu.class_user_status = 1
      AND dcu.class_user_attach_status = 1
      AND dc.class_course_status = 'ACTIVE'
      AND dc.class_status = 1
      AND dc.class_gen_subject <> 'Core Stars'
),

adt_potential_students AS (
    SELECT
        sc.school_name,
        sc.school_id,
        sc.school_dw_id,
        CASE
            WHEN sca.class_gen_subject IN ('physics','biology','chemistry') THEN 'science'
            WHEN dcsa.cs_subject_id IS NULL THEN LOWER(sca.class_gen_subject)
            ELSE 'arabits'
        END AS class_gen_subject,
        test.test_skill,
        test.test_pool_id,
        sca.class_grade_id,
        sca.class_user_class_dw_id,
        ISNULL(sca.class_section_id, CONVERT(varchar(50), sca.class_dw_id)) AS class_section_id,
        sca.class_title,
        dg.grade_k12grade,
        ds.student_section_dw_id,
        sn.section_name,
        sn.section_alias,
        sca.class_academic_year_id,
        aat.aat_attempt_number,
        aat.aat_attempt_title,
        aat.aat_attempt_start_time,
        aat.aat_attempt_end_time,
        DATEPART(year, sc.academic_year_end_date) AS academic_year,
        COUNT(DISTINCT sca.class_user_user_dw_id) AS class_total_students
    FROM student_course_association sca
    INNER JOIN ${RS_COREDW}.dim_course_ability_test_association cata
        ON sca.class_material_id = cata.cata_course_id
       AND cata.cata_attach_status = 1
    INNER JOIN dim_test test
        ON cata.cata_ability_test_activity_uuid = test.test_id
    INNER JOIN ${RS_COREDW}.dim_grade dg
        ON dg.grade_id = sca.class_grade_id
       AND dg.grade_status = 1
    INNER JOIN ${RS_BI_COREDW}.bi_active_schools_dim sc
        ON sca.class_school_id = sc.school_id
       AND dg.academic_year_id = sc.academic_year_id
       AND sc.academic_year_end_date >= CONVERT(date, cata.cata_created_time)
       AND sc.academic_year_end_date <= ISNULL(CONVERT(date, cata.cata_updated_time),'9999-12-01')
       AND sc.academic_year_start_date <= ISNULL(CONVERT(date, cata.cata_updated_time),'9999-12-01')
    INNER JOIN ${RS_BI_COREDW}.bi_student_dim ds
        ON sca.class_user_user_dw_id = ds.student_dw_id
       AND sc.school_dw_id = ds.student_school_dw_id
       AND ds.student_status = 1
    INNER JOIN ${RS_COREDW}.dim_section sn
        ON sn.section_dw_id = ds.student_section_dw_id
    INNER JOIN ${RS_COREDW}.dim_adt_attempt_threshold aat
        ON aat.aat_school_dw_id = sc.school_dw_id
       AND CONVERT(date, aat.aat_attempt_start_time) >= DATEADD(day,-1,sc.academic_year_start_date)
       AND CONVERT(date, aat.aat_attempt_end_time) <= sc.academic_year_end_date
       AND aat.aat_status = 1
    LEFT JOIN ${RS_COREDW}.dim_course_subject_association dcsa
        ON dcsa.cs_course_id = cata.cata_course_id
       AND dcsa.cs_status = 1
       AND dcsa.cs_subject_dw_id IN (129,503)
    WHERE sca.rn = 1
    GROUP BY
        sc.school_name, sc.school_id, sc.school_dw_id,
        CASE
            WHEN sca.class_gen_subject IN ('physics','biology','chemistry') THEN 'science'
            WHEN dcsa.cs_subject_id IS NULL THEN LOWER(sca.class_gen_subject)
            ELSE 'arabits'
        END,
        test.test_skill, test.test_pool_id,
        sca.class_grade_id, sca.class_user_class_dw_id,
        ISNULL(sca.class_section_id, CONVERT(varchar(50), sca.class_dw_id)),
        sca.class_title, dg.grade_k12grade,
        ds.student_section_dw_id, sn.section_name, sn.section_alias,
        sca.class_academic_year_id,
        aat.aat_attempt_number, aat.aat_attempt_title,
        aat.aat_attempt_start_time, aat.aat_attempt_end_time,
        DATEPART(year, sc.academic_year_end_date)
),

fasr AS (
    SELECT
        fasr_dw_id,
        fasr_fle_ls_uuid,
        fasr_question_pool_id AS fasr_test_id,
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
    FROM ${RS_COREDW}.fact_adt_student_report
    WHERE fasr_status = 1
      AND CONVERT(date, fasr_created_time) >= '2025-08-01'

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
    FROM ${RS_COREDW}.fact_candidate_assessment_progress
    WHERE event_type = 'CandidateReportGeneratedDataEvent'
),

percentile_adt AS (
    SELECT
        COALESCE(a1.grade,a2.grade,a3.grade) AS grade,
        a1.percentile, a1.attempt_1_min, a1.attempt_1_max,
        a2.percentile AS percentile2, a2.attempt_2_min, a2.attempt_2_max,
        a3.percentile AS percentile3, a3.attempt_3_min, a3.attempt_3_max
    FROM ${RS_BI_COREDW}.adt_attempt1_percentile a1
    FULL JOIN ${RS_BI_COREDW}.adt_attempt2_percentile a2
        ON a1.grade = a2.grade AND a1.percentile = a2.percentile
    FULL JOIN ${RS_BI_COREDW}.adt_attempt3_percentile a3
        ON a1.grade = a3.grade AND a1.percentile = a3.percentile
),

fact_adt AS (
    SELECT
        fasr.fasr_dw_id,
        fasr.fasr_student_dw_id,
        fasr.fasr_test_id,
        CONVERT(datetime2, fasr.fasr_created_time AT TIME ZONE 'UTC'
            AT TIME ZONE ISNULL(sch.windows_timezone,'UTC')) AS fasr_created_date,
        DATEPART(year, sch.academic_year_end_date) AS academic_year,
        fasr.fasr_attempt AS test_order,
        LAG(fasr.fasr_final_score) OVER (
            PARTITION BY fasr.fasr_framework, fasr.fasr_student_dw_id
            ORDER BY fasr.fasr_created_time
        ) AS previous_score,
        fasr.fasr_final_score,
        CASE fasr.fasr_framework
            WHEN 'core' THEN CONVERT(varchar(50), fasr.fasr_final_grade)
            WHEN 'core scale' THEN CONVERT(varchar(50), fasr.fasr_final_grade)
            WHEN 'lexile' THEN fasr.fasr_secondary_result
            WHEN 'lexile®' THEN fasr.fasr_secondary_result
            WHEN 'cefr' THEN cefr.cefr_level
            ELSE fasr.fasr_final_category
        END AS fasr_final_result,
        CASE WHEN fasr.fasr_framework = 'cefr'
            THEN cefr.target_cefr_level
        END AS target_cefr_level,
        fasr.fasr_class_subject_name,
        fasr.fasr_total_time_spent,
        fasr.fasr_final_grade,
        sch.school_dw_id,
        g.grade_k12grade,
        st.student_current_section_dw_id AS student_section_dw_id
    FROM fasr
    INNER JOIN dim_student st
        ON fasr.fasr_student_dw_id = st.student_dw_id
       AND fasr.fasr_created_time BETWEEN st.student_created_time
                                      AND ISNULL(st.student_active_until,'9999-12-01')
    INNER JOIN ${RS_BI_COREDW}.bi_active_schools_dim sch
        ON st.student_current_school_dw_id = sch.school_dw_id
        AND CONVERT(DATE, fasr_created_time) >= sch.academic_year_start_date
        AND CONVERT(DATE, fasr_created_time) <= sch.academic_year_end_date
    INNER JOIN ${RS_COREDW}.dim_grade g
        ON g.grade_dw_id = st.student_grade_dw_id
    LEFT JOIN ${RS_BI_COREDW}.adt_cefr_level_mapping cefr
        ON g.grade_k12grade = cefr.grade
       AND fasr.fasr_final_score BETWEEN cefr.min_scale_score AND cefr.max_scale_score
),

fact_adt_percentile AS (
    SELECT
        fa.fasr_dw_id,
        MAX(
            CASE
                WHEN fa.fasr_class_subject_name = 'math'
                     AND fa.test_order = 1
                     AND fa.fasr_final_score BETWEEN p.attempt_1_min AND ISNULL(p.attempt_1_max,9999)
                    THEN p.percentile
                WHEN fa.fasr_class_subject_name = 'math'
                     AND fa.test_order = 2
                     AND fa.fasr_final_score BETWEEN p.attempt_2_min AND ISNULL(p.attempt_2_max,9999)
                    THEN p.percentile2
                WHEN fa.fasr_class_subject_name = 'math'
                     AND fa.test_order = 3
                     AND fa.fasr_final_score BETWEEN p.attempt_3_min AND ISNULL(p.attempt_3_max,9999)
                    THEN p.percentile3
            END
        ) AS percentile_rank
    FROM fact_adt fa
    LEFT JOIN percentile_adt p
        ON p.grade = fa.grade_k12grade
    GROUP BY fa.fasr_dw_id
)

SELECT
    aps.school_name,
    aps.school_id,
    aps.school_dw_id,
    aps.class_gen_subject,
    aps.test_skill,
    aps.class_grade_id,
    aps.grade_k12grade AS grade,
    aps.class_user_class_dw_id,
    aps.class_title,
    aps.student_section_dw_id,
    aps.class_section_id,
    aps.section_name,
    aps.section_alias,
    aps.academic_year AS academicyear,
    aps.aat_attempt_number,
    aps.aat_attempt_title,
    aps.aat_attempt_start_time,
    aps.aat_attempt_end_time,
    aps.class_total_students,
    fa.fasr_dw_id,
    fa.fasr_class_subject_name AS fasr_curriculum_subject_name,
    fa.fasr_student_dw_id,
    fa.fasr_created_date,
    fa.academic_year,
    fa.test_order,
    fa.previous_score,
    fa.fasr_final_score,
    fa.fasr_final_result,
    fa.target_cefr_level,
    fa.fasr_final_grade,
    fap.percentile_rank,
    fa.fasr_total_time_spent,
    fa.grade_k12grade
FROM adt_potential_students aps
LEFT JOIN fact_adt fa
    ON aps.school_dw_id = fa.school_dw_id
   AND aps.grade_k12grade = fa.grade_k12grade
   AND aps.student_section_dw_id = fa.student_section_dw_id
   AND aps.aat_attempt_number = fa.test_order
   AND aps.academic_year = fa.academic_year
   AND aps.test_pool_id = fa.fasr_test_id
LEFT JOIN fact_adt_percentile fap
    ON fap.fasr_dw_id = fa.fasr_dw_id;