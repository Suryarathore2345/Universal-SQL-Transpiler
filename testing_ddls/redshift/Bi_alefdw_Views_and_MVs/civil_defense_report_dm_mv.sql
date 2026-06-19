CREATE MATERIALIZED VIEW bi_alefdw_dev.civil_defense_report_dm_mv AS
WITH
    learning_objective AS (
        SELECT
            lo_dw_id,
            lo_code,
            lo_title,
             CASE
                WHEN lo_code LIKE 'CD_MLO_001%' THEN 10001
                WHEN lo_code LIKE 'CD_MLO_002%' THEN 10002
                WHEN lo_code LIKE 'CD_MLO_003%' THEN 10003
                WHEN lo_code LIKE 'CD_MLO_004%' THEN 10004
                WHEN lo_code LIKE 'CD_MLO_005%' THEN 10005
                WHEN lo_code LIKE 'CD_C3_L001%' THEN 20001
                WHEN lo_code LIKE 'CD_C3_L002%' THEN 20002
                WHEN lo_code LIKE 'CD_C3_L003%' THEN 20003
                WHEN lo_code LIKE 'CD_C3_L004%' THEN 20004
                WHEN lo_code LIKE 'CD_C3_L006%' THEN 20005
            END AS unified_lesson_id,
            FIRST_VALUE(CASE WHEN lo_code LIKE '%_EN%' THEN lo_title END  IGNORE NULLS) OVER (PARTITION BY
            CASE
                WHEN lo_code LIKE 'CD_MLO_001%' THEN 1.1
                WHEN lo_code LIKE 'CD_MLO_002%' THEN 1.2
                WHEN lo_code LIKE 'CD_MLO_003%' THEN 1.3
                WHEN lo_code LIKE 'CD_MLO_004%' THEN 1.4
                WHEN lo_code LIKE 'CD_MLO_005%' THEN 1.5
                WHEN lo_code LIKE 'CD_C3_L001%' THEN 2.1
                WHEN lo_code LIKE 'CD_C3_L002%' THEN 2.2
                WHEN lo_code LIKE 'CD_C3_L003%' THEN 2.3
                WHEN lo_code LIKE 'CD_C3_L004%' THEN 2.4
                WHEN lo_code LIKE 'CD_C3_L006%' THEN 2.5
            END) AS unified_lesson_title
        FROM
            alefdw.dim_learning_objective dip_dlo
        WHERE
            NVL(dip_dlo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
            AND lo_status = 1
            AND lo_code IN (
                'CD_MLO_001_EN_V1', 'CD_MLO_002_EN_V1', 'CD_MLO_003_EN_V1', 'CD_MLO_004_EN_V1', 'CD_MLO_005_EN_V1',
                'CD_MLO_001_AR',   'CD_MLO_002_AR',   'CD_MLO_003_AR',   'CD_MLO_004_AR',   'CD_MLO_005_AR',
                'CD_C3_L001', 'CD_C3_L002', 'CD_C3_L003', 'CD_C3_L004', 'CD_C3_L006', 'CD_C3_L001_EN', 'CD_C3_L002_EN',
                'CD_C3_L003_EN', 'CD_C3_L004_EN', 'CD_C3_L006_EN'
            )
    ),
    program_courses_start AS (
        SELECT DISTINCT
            caa_course_id,
            DATE(DATE_TRUNC('month', MIN(caa_created_time))) AS program_start_date
        FROM
            alefdw.dim_course_activity_association
        INNER JOIN
            learning_objective
                ON caa_activity_dw_id = lo_dw_id
        WHERE
            caa_attach_status = 1 AND caa_status = 1
        GROUP BY
            1
    ),
    class_total_students_civil_defense AS (
        SELECT
            dd.calendar_month_start_date AS program_month,
            lo.unified_lesson_id,
            lo.unified_lesson_title,
            dg.grade_k12grade AS grade_name,
            sch.academic_year_start_date,
            sch.academic_year_end_date,
            CAST(date_part_year(sch.academic_year_start_date) AS VARCHAR)
            || '-' || CAST(date_part_year(sch.academic_year_end_date) AS VARCHAR) AS academic_year,
            sch.school_organisation,
            sch.school_composition,
            sch.school_id,
            sch.school_dw_id,
            sch.school_name,
            sch.school_country_name,
            sch.school_city_name,
            sch.tenant_name,
            COUNT(DISTINCT dcu.class_user_user_dw_id) AS class_total_students
        FROM
            alefdw.dim_class dc
        INNER JOIN
            bi_alefdw.bi_all_schools_dim_mv sch
                ON sch.school_id = dc.class_school_id AND sch.academic_year_id = dc.class_academic_year_id
        INNER JOIN
            alefdw.dim_class_user dcu
                ON dc.class_dw_id = dcu.class_user_class_dw_id
        INNER JOIN
            bi_alefdw.bi_student_dim_mv st
                ON st.student_dw_id = dcu.class_user_user_dw_id
        INNER JOIN
            program_courses_start pc
                ON pc.caa_course_id = dc.class_material_id
        INNER JOIN
            alefdw.dim_date dd
                ON dd.calendar_month_start_date between pc.program_start_date
                    and DATEADD('year', 1, sch.academic_year_start_date)
        INNER JOIN
            alefdw.dim_grade dg
                ON dg.grade_id = dc.class_grade_id
        INNER JOIN
            alefdw.dim_course_activity_association dip
                ON dc.class_material_id = dip.caa_course_id
        INNER JOIN
            learning_objective lo
                ON lo.lo_dw_id = dip.caa_activity_dw_id
        WHERE
            dcu.class_user_role_dw_id = 2
            AND dcu.class_user_attach_status = 1
            AND (
                (dcu.class_user_status = 1 AND date_trunc('month', dcu.class_user_created_time) <= dd.calendar_month_start_date)  --
                -- students that are attached after program start should not be taken into consideration before
            OR (dcu.class_user_status = 2 -- for inactive but withing the period range
                AND DATE(dcu.class_user_active_until) >= dd.calendar_month_start_date
                AND dcu.class_user_created_time <= dd.calendar_month_start_date) --
               -- if a student is now 2 we should check as well when it joined - so it is not accounted for the months before that
            )
            AND (
                (st.student_status = 1 AND date_trunc('month',st.student_created_time) <= dd.calendar_month_start_date)
            OR (st.student_status = 2
                AND DATE(st.student_active_until) >= dd.calendar_month_start_date
                AND st.student_created_time <= dd.calendar_month_start_date)
            )
            AND dc.class_status = 1
        GROUP BY
            1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
    ),
    completed_lessons AS (
        SELECT
            cd.unified_lesson_id,
            g.grade_k12grade,
            fle.fle_school_dw_id,
            fle.fle_student_dw_id,
            DATE(DATE_TRUNC('month', fle.fle_created_time)) AS local_date,
            CAST('Completed' AS VARCHAR(20)) AS lo_status,
            fle_total_score,
            CAST(date_part_year(dsc.academic_year_start_date) AS VARCHAR)
            || '-' || CAST(date_part_year(dsc.academic_year_end_date) AS VARCHAR) AS academic_year,
            ROW_NUMBER() OVER (PARTITION BY cd.unified_lesson_id, fle.fle_student_dw_id ORDER BY fle_created_time DESC) AS rnk
        FROM
            alefdw.fact_learning_experience fle
        INNER JOIN
            learning_objective cd
                ON cd.lo_dw_id = fle.fle_lo_dw_id
        INNER JOIN alefdw.dim_grade g
                ON g.grade_dw_id = fle.fle_grade_dw_id
        JOIN bi_alefdw.bi_all_schools_dim_mv dsc
                                               ON fle_school_dw_id = dsc.school_dw_id
                                                   AND trunc(fle_created_time) >= dsc.academic_year_start_date
                                                   AND trunc(fle_created_time) <= dsc.academic_year_end_date
        WHERE
            fle_completion_node IS TRUE
        QUALIFY rnk = 1
    )
SELECT
    cts.program_month,
    cts.tenant_name,
    cts.school_organisation AS organisation_name,
    cts.school_dw_id,
    cts.school_name,
    UPPER(cts.school_country_name) AS school_country_name,
    UPPER(cts.school_city_name) AS school_city_name,
    cts.school_composition,
    cts.grade_name,
    cts.academic_year,
    cts.unified_lesson_id,
    cts.unified_lesson_title,
    cts.class_total_students,
    cl.local_date,
    cl.fle_student_dw_id,
    cl.lo_status,
    cl.fle_total_score AS fle_score
FROM
    class_total_students_civil_defense cts
LEFT JOIN
    completed_lessons cl
        ON cts.school_dw_id = cl.fle_school_dw_id
        AND cts.grade_name = cl.grade_k12grade
        AND cts.unified_lesson_id = cl.unified_lesson_id
        AND cts.program_month = cl.local_date
        AND cts.academic_year = cl.academic_year
WHERE cts.program_month < CURRENT_DATE;
