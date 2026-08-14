CREATE or Replace MATERIALIZED LAKE VIEW {{os_bi_coredw}}.civil_defense_report_dm_mv AS

WITH learning_objective AS (
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
        FIRST_VALUE(
            CASE WHEN lo_code LIKE '%_EN%' THEN lo_title END
        ) IGNORE NULLS
        OVER (
            PARTITION BY
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
            END
        ) AS unified_lesson_title
    FROM {{rs_coredw}}.dim_learning_objective dip_dlo
    WHERE COALESCE(dip_dlo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
      AND lo_status = 1
      AND lo_code IN (
          'CD_MLO_001_EN_V1','CD_MLO_002_EN_V1','CD_MLO_003_EN_V1',
          'CD_MLO_004_EN_V1','CD_MLO_005_EN_V1',
          'CD_MLO_001_AR','CD_MLO_002_AR','CD_MLO_003_AR',
          'CD_MLO_004_AR','CD_MLO_005_AR',
          'CD_C3_L001','CD_C3_L002','CD_C3_L003','CD_C3_L004','CD_C3_L006',
          'CD_C3_L001_EN','CD_C3_L002_EN','CD_C3_L003_EN',
          'CD_C3_L004_EN','CD_C3_L006_EN'
      )
),

program_courses_start AS (
    SELECT
        caa_course_id,
        CAST(DATE_TRUNC('month', MIN(caa_created_time)) AS DATE) AS program_start_date
    FROM {{rs_coredw}}.dim_course_activity_association
    INNER JOIN learning_objective
        ON caa_activity_dw_id = lo_dw_id
    WHERE caa_attach_status = 1
      AND caa_status = 1
    GROUP BY caa_course_id
),

class_total_students_civil_defense AS (
    SELECT
        dd.calendar_month_start_date AS program_month,
        lo.unified_lesson_id,
        lo.unified_lesson_title,
        dg.grade_k12grade AS grade_name,
        sch.academic_year_start_date,
        sch.academic_year_end_date,
        CAST(YEAR(sch.academic_year_start_date) AS VARCHAR(4))
        || '-' ||
        CAST(YEAR(sch.academic_year_end_date) AS VARCHAR(4)) AS academic_year,
        sch.school_organisation,
        sch.school_composition,
        sch.school_id,
        sch.school_dw_id,
        sch.school_name,
        sch.school_country_name,
        sch.school_city_name,
        sch.tenant_name,
        COUNT(DISTINCT dcu.class_user_user_dw_id) AS class_total_students
    FROM {{rs_coredw}}.dim_class dc
    INNER JOIN {{rs_bi_coredw}}.bi_all_schools_dim sch
        ON sch.school_id = dc.class_school_id
       AND sch.academic_year_id = dc.class_academic_year_id
    INNER JOIN {{rs_coredw}}.dim_class_user dcu
        ON dc.class_dw_id = dcu.class_user_class_dw_id
    INNER JOIN {{rs_bi_coredw}}.bi_student_dim st
        ON st.student_dw_id = dcu.class_user_user_dw_id
    INNER JOIN program_courses_start pc
        ON pc.caa_course_id = dc.class_material_id
    INNER JOIN {{rs_coredw}}.dim_date dd
        ON dd.calendar_month_start_date
           BETWEEN pc.program_start_date
               AND ADD_MONTHS(sch.academic_year_start_date, 12)
    INNER JOIN {{rs_coredw}}.dim_grade dg
        ON dg.grade_id = dc.class_grade_id
    INNER JOIN {{rs_coredw}}.dim_course_activity_association dip
        ON dc.class_material_id = dip.caa_course_id
    INNER JOIN learning_objective lo
        ON lo.lo_dw_id = dip.caa_activity_dw_id
    WHERE dcu.class_user_role_dw_id = 2
      AND dcu.class_user_attach_status = 1
      AND (
            (dcu.class_user_status = 1
             AND DATE_TRUNC('month', dcu.class_user_created_time) <= dd.calendar_month_start_date)
         OR (dcu.class_user_status = 2
             AND CAST(dcu.class_user_active_until AS DATE) >= dd.calendar_month_start_date
             AND dcu.class_user_created_time <= dd.calendar_month_start_date)
      )
      AND (
            (st.student_status = 1
             AND DATE_TRUNC('month', st.student_created_time) <= dd.calendar_month_start_date)
         OR (st.student_status = 2
             AND CAST(st.student_active_until AS DATE) >= dd.calendar_month_start_date
             AND st.student_created_time <= dd.calendar_month_start_date)
      )
      AND dc.class_status = 1
    GROUP BY
        1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
),

completed_lessons AS (
    SELECT
        unified_lesson_id,
        grade_k12grade,
        fle_school_dw_id,
        fle_student_dw_id,
        local_date,
        lo_status,
        fle_total_score,
        academic_year,
        rnk
    FROM (
        SELECT
            cd.unified_lesson_id,
            g.grade_k12grade,
            fle.fle_school_dw_id,
            fle.fle_student_dw_id,
            CAST(DATE_TRUNC('month', fle.fle_created_time) AS DATE) AS local_date,
            CAST('Completed' AS VARCHAR(20)) AS lo_status,
            fle_total_score,
            CAST(YEAR(dsc.academic_year_start_date) AS VARCHAR(4))
            || '-' ||
            CAST(YEAR(dsc.academic_year_end_date) AS VARCHAR(4)) AS academic_year,
            ROW_NUMBER() OVER (
                PARTITION BY cd.unified_lesson_id, fle.fle_student_dw_id
                ORDER BY fle_created_time DESC
            ) AS rnk
        FROM {{rs_coredw}}.fact_learning_experience fle
        INNER JOIN learning_objective cd
            ON cd.lo_dw_id = fle.fle_lo_dw_id
        INNER JOIN {{rs_coredw}}.dim_grade g
            ON g.grade_dw_id = fle.fle_grade_dw_id
        INNER JOIN {{rs_bi_coredw}}.bi_all_schools_dim dsc
            ON fle.fle_school_dw_id = dsc.school_dw_id
           AND CAST(fle.fle_created_time AS DATE) >= dsc.academic_year_start_date
           AND CAST(fle.fle_created_time AS DATE) <= dsc.academic_year_end_date
        WHERE fle_completion_node = TRUE
    ) x
    WHERE rnk = 1
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
FROM class_total_students_civil_defense cts
LEFT JOIN completed_lessons cl
    ON cts.school_dw_id = cl.fle_school_dw_id
   AND cts.grade_name = cl.grade_k12grade
   AND cts.unified_lesson_id = cl.unified_lesson_id
   AND cts.program_month = cl.local_date
   AND cts.academic_year = cl.academic_year
WHERE cts.program_month < CURRENT_DATE;