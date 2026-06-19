CREATE OR REPLACE VIEW eagles_alefdw_dev.adt_student_report_dm_view AS
WITH dim_student AS (                 -- get the current school of the student, but keep other attributes at time of test
    SELECT
    ds.*,
    st.student_school_dw_id AS student_current_school_dw_id,
    st.student_section_dw_id AS student_current_section_dw_id
    FROM bi_alefdw.bi_student_dim_mv ds
    LEFT JOIN bi_alefdw.bi_student_dim_mv st
        ON ds.student_dw_id = st.student_dw_id
        AND st.student_status = 1
    ),
dim_test AS (
    SELECT dw_id  AS test_dw_id,
            id           AS test_id,
            id           AS test_pool_id,
            UPPER(skill) AS test_skill
    FROM alefdw.dim_testpart
    WHERE status = 1
    UNION ALL
    SELECT lo.lo_dw_id AS test_dw_id,
           lo.lo_id AS test_id,
           si.step_instance_pool_id AS test_pool_id,
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
        ROW_NUMBER() OVER (PARTITION BY dcu.class_user_user_dw_id, dc.class_material_id
            ORDER BY dcu.class_user_created_time DESC) AS rn
    FROM alefdw.dim_class dc
    INNER JOIN alefdw.dim_class_user dcu
        ON dc.class_dw_id = dcu.class_user_class_dw_id
    WHERE dcu.class_user_role_dw_id = 2
	    AND dcu.class_user_status = 1
        AND dcu.class_user_attach_status = 1
	    AND dc.class_course_status = 'ACTIVE'
        AND dc.class_status = 1
        AND dc.class_gen_subject != 'Alef Stars'
),
adt_potential_students AS (
    SELECT
	sc.school_name,
	sc.school_id,
	sc.school_dw_id,
	CASE WHEN lower(sca.class_gen_subject) IN ('physics', 'biology', 'chemistry') THEN 'science'
	     WHEN dcsa.cs_subject_id IS NULL THEN lower(sca.class_gen_subject)
         ELSE 'arabits' END AS class_gen_subject,
	test.test_skill,
	test.test_pool_id,
	sca.class_grade_id,
	sca.class_user_class_dw_id,
	nvl(sca.class_section_id, sca.class_dw_id::varchar)   AS class_section_id,
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
	date_part_year(sc.academic_year_end_date) AS academic_year,
	count(DISTINCT sca.class_user_user_dw_id) AS class_total_students
    FROM student_course_association sca
    INNER JOIN alefdw.dim_course_ability_test_association cata
        ON sca.class_material_id = cata.cata_course_id
        AND cata.cata_attach_status = 1
    INNER JOIN dim_test test
        ON cata.cata_ability_test_activity_uuid = test.test_id
    INNER JOIN alefdw.dim_grade dg
        ON dg.grade_id = sca.class_grade_id
        AND dg.grade_status = 1
    INNER JOIN bi_alefdw.bi_active_schools_dim_mv sc
	    ON sca.class_school_id = sc.school_id
        AND dg.academic_year_id = sc.academic_year_id
        AND sc.academic_year_end_date >= DATE(cata.cata_created_time)
        AND sc.academic_year_end_date <= COALESCE(DATE(cata.cata_updated_time),'9999-12-01')
        AND sc.academic_year_start_date <= COALESCE(DATE(cata.cata_updated_time),'9999-12-01')
    INNER JOIN bi_alefdw.bi_student_dim_mv ds
	    ON sca.class_user_user_dw_id = ds.student_dw_id
		AND sc.school_dw_id = ds.student_school_dw_id
        AND ds.student_status = 1
    INNER JOIN alefdw.dim_section sn
        ON sn.section_dw_id = ds.student_section_dw_id
    INNER JOIN alefdw.dim_adt_attempt_threshold aat
        ON aat.aat_school_dw_id = sc.school_dw_id
        AND trunc(aat.aat_attempt_start_time) >= sc.academic_year_start_date - 1
        AND trunc(aat.aat_attempt_end_time) <= sc.academic_year_end_date
        AND aat_status = 1
    LEFT JOIN alefdw.dim_course_subject_association dcsa
        ON dcsa.cs_course_id = cata.cata_course_id
        AND dcsa.cs_status=1
        AND dcsa.cs_subject_dw_id IN (129, 503)
    WHERE sca.rn = 1
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
),
fasr AS (-- -- getting student' test last record by same learning session
SELECT fasr_dw_id,
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
         FROM alefdw.fact_adt_student_report
         WHERE fasr_status = 1
           AND DATE(fasr_created_time) >= '2025-08-01'
     UNION ALL
        SELECT  dw_id AS fasr_dw_id,
                test_level_session_id AS fasr_fle_ls_uuid,
                test_level_id AS fasr_test_id,
                school_dw_id AS fasr_school_dw_id,
                candidate_dw_id AS fasr_student_dw_id,
                created_time AS fasr_created_time,
                attempt_number AS fasr_attempt,
                subject AS fasr_class_subject_name,
                framework AS fasr_framework,
                final_score AS fasr_final_score,
                final_grade AS fasr_final_grade,
                null AS fasr_final_result,
                null AS fasr_secondary_result,
                final_category AS fasr_final_category,
                total_timespent AS fasr_total_time_spent
         FROM alefdw.fact_candidate_assessment_progress fcap
         WHERE event_type = 'CandidateReportGeneratedDataEvent'
	),
percentile_adt AS (
    SELECT
        CASE WHEN a1.grade IS NULL AND a2.grade IS NULL THEN a3.grade
             WHEN a1.grade IS NULL AND a3.grade IS NULL THEN a2.grade
             ELSE a1.grade
        END as grade,
    a1.percentile, a1.attempt_1_min, a1.attempt_1_max,
    a2.percentile as percentile2, a2.attempt_2_min, a2.attempt_2_max,
    a3.percentile as percentile3, a3.attempt_3_min, a3.attempt_3_max
    FROM bi_alefdw.adt_attempt1_percentile a1
    FULL OUTER JOIN bi_alefdw.adt_attempt2_percentile a2 ON a1.grade = a2.grade and a1.percentile = a2.percentile
    FULL OUTER JOIN bi_alefdw.adt_attempt3_percentile a3 ON a1.grade = a3.grade and a1.percentile = a3.percentile
    ),
fact_adt AS (
SELECT fasr.fasr_dw_id,
	fasr.fasr_student_dw_id,
	fasr.fasr_test_id,
	convert_timezone('UTC', sch.tenant_timezone, fasr.fasr_created_time) AS fasr_created_date,
	date_part_year(sch.academic_year_end_date) AS academic_year,
	fasr.fasr_attempt AS test_order,
    LAG(fasr.fasr_final_score, 1) OVER ( PARTITION BY fasr.fasr_framework,fasr.fasr_student_dw_id
	            ORDER BY fasr_created_time) as previous_score,
    fasr.fasr_final_score,
	CASE lower(fasr_framework)
        WHEN 'alef'  THEN  fasr.fasr_final_grade::VARCHAR
	    WHEN 'alef scale' THEN  fasr.fasr_final_grade::VARCHAR
        WHEN 'lexile'  THEN fasr.fasr_secondary_result
	    WHEN 'lexile®' THEN fasr.fasr_secondary_result
	    WHEN 'cefr' THEN cefr.cefr_level
        ELSE fasr_final_category
    END    AS fasr_final_result,
    CASE WHEN lower(fasr_framework) = 'cefr'
        THEN cefr.target_cefr_level
    END    AS target_cefr_level,
	fasr.fasr_class_subject_name,
	fasr.fasr_total_time_spent,
	fasr.fasr_final_grade,
	sch.school_dw_id,
	g.grade_k12grade,
	st.student_current_section_dw_id AS student_section_dw_id
    FROM fasr
    INNER JOIN dim_student st ON fasr_student_dw_id = st.student_dw_id
	    AND fasr.fasr_created_time BETWEEN st.student_created_time
            AND COALESCE(st.student_active_until, '9999-12-01')
    INNER JOIN bi_alefdw.bi_active_schools_dim_mv sch
        ON st.student_current_school_dw_id = sch.school_dw_id
            AND trunc(fasr_created_time) >= sch.academic_year_start_date
            AND trunc(fasr_created_time) <= sch.academic_year_end_date
    INNER JOIN alefdw.dim_grade g
        ON g.grade_dw_id = st.student_grade_dw_id
    LEFT JOIN bi_alefdw.adt_cefr_level_mapping_mv cefr
        ON g.grade_k12grade = cefr.grade
        AND fasr.fasr_final_score >= cefr.min_scale_score
	    AND fasr.fasr_final_score <= cefr.max_scale_score
),
fact_adt_percentile AS(
    SELECT fa.fasr_dw_id,
    MAX(
     CASE
	    WHEN lower(fa.fasr_class_subject_name) = 'math' AND fa.test_order = 1 AND fa.fasr_final_score >= p.attempt_1_min AND fa.fasr_final_score <= COALESCE(p.attempt_1_max,9999) THEN p.percentile
	    WHEN lower(fa.fasr_class_subject_name) = 'math' AND fa.test_order = 2 AND fa.fasr_final_score >= p.attempt_2_min AND fa.fasr_final_score <= COALESCE(p.attempt_2_max,9999) THEN p.percentile2
	    WHEN lower(fa.fasr_class_subject_name) = 'math' AND fa.test_order = 3 AND fa.fasr_final_score >= p.attempt_3_min AND fa.fasr_final_score <= COALESCE(p.attempt_3_max,9999) THEN p.percentile3
	END) as percentile_rank
    FROM fact_adt fa
    LEFT JOIN percentile_adt p ON p.grade =  fa.grade_k12grade
    GROUP BY 1
)
SELECT
	aps.school_name,
	aps.school_id,
	aps.school_dw_id,
	aps.class_gen_subject,
	aps.test_skill,
	aps.class_grade_id,
	aps.grade_k12grade      AS grade,
	aps.class_user_class_dw_id,
	aps.class_title,
	aps.student_section_dw_id,
	aps.class_section_id,
	aps.section_name,
	aps.section_alias,
	aps.academic_year       AS academicyear,
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
    LEFT JOIN fact_adt_percentile fap ON fap.fasr_dw_id = fa.fasr_dw_id
WITH NO SCHEMA BINDING;