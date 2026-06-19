CREATE MATERIALIZED VIEW bi_alefdw_dev.zoud_financial_report_mv AS
WITH learning_objective AS (
    SELECT
        lo_dw_id,
        lo_code,
        lo_title,
        -- DYNAMIC ID GENERATION (Using SPLIT_PART)
        CASE
            WHEN lo_code LIKE 'FL_G%' THEN
                -- Logic: FL_G5_L001 -> Split by '_' -> Part 2 is 'G5', Part 3 is 'L001'
                -- CAST('G5' without 'G') * 1000 + CAST('L001' without 'L')
                (CAST(REPLACE(SPLIT_PART(lo_code, '_', 2), 'G', '') AS INT) * 10000)
                                               +
                CAST(REPLACE(SPLIT_PART(lo_code, '_', 3), 'L', '') AS INT)
        END AS unified_lesson_id,
        MAX(CASE WHEN lo_code NOT LIKE '%_AR' THEN lo_title END) OVER (
            PARTITION BY
                CASE
                    WHEN lo_code LIKE 'FL_G%' THEN
                        -- Returns "5.1" for "FL_G5_L001"
                        REPLACE(SPLIT_PART(lo_code, '_', 2), 'G', '') || '.' ||
                        CAST(CAST(REPLACE(SPLIT_PART(lo_code, '_', 3), 'L', '') AS INT) AS VARCHAR)
                END
        ) AS unified_lesson_title
    FROM alefdw.dim_learning_objective dip_dlo
    WHERE NVL(dip_dlo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
      AND lo_status = 1
      AND lo_code IN (
          -- Grade 5
          'FL_G5_L001', 'FL_G5_L001_AR', 'FL_G5_L002', 'FL_G5_L002_AR', 'FL_G5_L003', 'FL_G5_L003_AR',
          'FL_G5_L004', 'FL_G5_L004_AR', 'FL_G5_L005', 'FL_G5_L005_AR', 'FL_G5_L006', 'FL_G5_L006_AR',
          'FL_G5_L007', 'FL_G5_L007_AR', 'FL_G5_L008', 'FL_G5_L008_AR', 'FL_G5_L009', 'FL_G5_L009_AR',

          -- Grade 6
          'FL_G6_L001', 'FL_G6_L001_AR', 'FL_G6_L002', 'FL_G6_L002_AR', 'FL_G6_L003', 'FL_G6_L003_AR',
          'FL_G6_L004', 'FL_G6_L004_AR', 'FL_G6_L005', 'FL_G6_L005_AR', 'FL_G6_L006', 'FL_G6_L006_AR',
          'FL_G6_L007', 'FL_G6_L007_AR', 'FL_G6_L008', 'FL_G6_L008_AR', 'FL_G6_L009', 'FL_G6_L009_AR',

          -- Grade 7
          'FL_G7_L001', 'FL_G7_L001_AR', 'FL_G7_L002', 'FL_G7_L002_AR', 'FL_G7_L003', 'FL_G7_L003_AR',
          'FL_G7_L004', 'FL_G7_L004_AR', 'FL_G7_L005', 'FL_G7_L005_AR', 'FL_G7_L006', 'FL_G7_L006_AR',
          'FL_G7_L007', 'FL_G7_L007_AR', 'FL_G7_L008', 'FL_G7_L008_AR', 'FL_G7_L009', 'FL_G7_L009_AR',

          -- Grade 8
          'FL_G8_L001', 'FL_G8_L001_AR', 'FL_G8_L002', 'FL_G8_L002_AR', 'FL_G8_L003', 'FL_G8_L003_AR',
          'FL_G8_L004', 'FL_G8_L004_AR', 'FL_G8_L005', 'FL_G8_L005_AR', 'FL_G8_L006', 'FL_G8_L006_AR',
          'FL_G8_L007', 'FL_G8_L007_AR', 'FL_G8_L008', 'FL_G8_L008_AR', 'FL_G8_L009', 'FL_G8_L009_AR',

          -- Grade 9
          'FL_G9_L001', 'FL_G9_L001_AR', 'FL_G9_L002', 'FL_G9_L002_AR', 'FL_G9_L003', 'FL_G9_L003_AR',
          'FL_G9_L004', 'FL_G9_L004_AR', 'FL_G9_L005', 'FL_G9_L005_AR', 'FL_G9_L006', 'FL_G9_L006_AR',
          'FL_G9_L007', 'FL_G9_L007_AR', 'FL_G9_L008', 'FL_G9_L008_AR', 'FL_G9_L009', 'FL_G9_L009_AR',

          -- Grade 10
          'FL_G10_L001', 'FL_G10_L001_AR', 'FL_G10_L002', 'FL_G10_L002_AR', 'FL_G10_L003', 'FL_G10_L003_AR',
          'FL_G10_L004', 'FL_G10_L004_AR', 'FL_G10_L005', 'FL_G10_L005_AR', 'FL_G10_L006', 'FL_G10_L006_AR',
          'FL_G10_L007', 'FL_G10_L007_AR', 'FL_G10_L008', 'FL_G10_L008_AR', 'FL_G10_L009', 'FL_G10_L009_AR',

          -- Grade 11
          'FL_G11_L001', 'FL_G11_L001_AR', 'FL_G11_L002', 'FL_G11_L002_AR', 'FL_G11_L003', 'FL_G11_L003_AR',
          'FL_G11_L004', 'FL_G11_L004_AR', 'FL_G11_L005', 'FL_G11_L005_AR', 'FL_G11_L006', 'FL_G11_L006_AR',
          'FL_G11_L007', 'FL_G11_L007_AR', 'FL_G11_L008', 'FL_G11_L008_AR', 'FL_G11_L009', 'FL_G11_L009_AR',

          -- Grade 12
          'FL_G12_L001', 'FL_G12_L001_AR', 'FL_G12_L002', 'FL_G12_L002_AR', 'FL_G12_L003', 'FL_G12_L003_AR',
          'FL_G12_L004', 'FL_G12_L004_AR', 'FL_G12_L005', 'FL_G12_L005_AR', 'FL_G12_L006', 'FL_G12_L006_AR',
          'FL_G12_L007', 'FL_G12_L007_AR', 'FL_G12_L008', 'FL_G12_L008_AR', 'FL_G12_L009', 'FL_G12_L009_AR'
      )
),
     program_courses_start AS (SELECT DISTINCT caa_course_id,
                                               DATE(DATE_TRUNC('month', MIN(caa_created_time))) AS program_start_date
                               FROM alefdw.dim_course_activity_association
                                        INNER JOIN
                                    learning_objective
                                    ON caa_activity_dw_id = lo_dw_id
                               WHERE caa_attach_status = 1
                                 AND caa_status = 1
                               GROUP BY 1),
     class_total_students_zoud_literacy AS (SELECT dd.calendar_month_start_date                                AS program_month,
                                                   lo.unified_lesson_id,
                                                   lo.unified_lesson_title,
                                                   dg.grade_k12grade                                           AS grade_name,
                                                   dg.grade_dw_id,
                                                   sch.academic_year_start_date,
                                                   sch.academic_year_end_date,
                                                   CAST(date_part_year(sch.academic_year_start_date) AS VARCHAR)
                                                       || '-' ||
                                                   CAST(date_part_year(sch.academic_year_end_date) AS VARCHAR) AS academic_year,
                                                   sch.school_organisation,
                                                   sch.school_composition,
                                                   sch.school_id,
                                                   sch.school_dw_id,
                                                   sch.school_name,
                                                   sch.school_country_name,
                                                   sch.school_city_name,
                                                   sch.tenant_name,
                                                   COUNT(DISTINCT dcu.class_user_user_dw_id)                   AS class_total_students
                                            FROM alefdw.dim_class dc
                                                     INNER JOIN
                                                 bi_alefdw.bi_all_schools_dim_mv sch
                                                 ON sch.school_id = dc.class_school_id AND
                                                    sch.academic_year_id = dc.class_academic_year_id
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
                                            WHERE dcu.class_user_role_dw_id = 2
                                              AND dcu.class_user_attach_status = 1
                                              AND (
                                                (dcu.class_user_status = 1 AND
                                                 date_trunc('month', dcu.class_user_created_time) <=
                                                 dd.calendar_month_start_date) --
                                                -- students that are attached after program start should not be taken into consideration before
                                                    OR (dcu.class_user_status =
                                                        2 -- for inactive but withing the period range
                                                    AND DATE(dcu.class_user_active_until) >=
                                                        dd.calendar_month_start_date
                                                    AND dcu.class_user_created_time <=
                                                        dd.calendar_month_start_date) --
                                                -- if a student is now 2 we should check as well when it joined - so it is not accounted for the months before that
                                                )
                                              AND (
                                                (st.student_status = 1 AND
                                                 date_trunc('month', st.student_created_time) <=
                                                 dd.calendar_month_start_date)
                                                    OR (st.student_status = 2
                                                    AND DATE(st.student_active_until) >=
                                                        dd.calendar_month_start_date
                                                    AND st.student_created_time <=
                                                        dd.calendar_month_start_date)
                                                )
                                              AND dc.class_status = 1
                                            GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16),
     completed_lessons AS (SELECT cd.unified_lesson_id,
                                  g.grade_k12grade,
                                  fle.fle_grade_dw_id,
                                  fle.fle_school_dw_id,
                                  fle.fle_student_dw_id,
                                  DATE(DATE_TRUNC('month', fle.fle_created_time))                                                AS local_month,
                                  DATE(fle.fle_created_time)                                                                     AS local_date,
                                  CAST('Completed' AS VARCHAR(20))                                                               AS lo_status,
                                  fle_total_score,
                                  ROW_NUMBER()
                                  OVER (PARTITION BY cd.unified_lesson_id, fle.fle_student_dw_id ORDER BY fle_created_time DESC) AS rnk
                           FROM alefdw.fact_learning_experience fle
                                    INNER JOIN
                                learning_objective cd
                                ON cd.lo_dw_id = fle.fle_lo_dw_id
                                    INNER JOIN alefdw.dim_grade g
                                               ON g.grade_dw_id = fle.fle_grade_dw_id
                           WHERE fle_completion_node IS TRUE
                           QUALIFY rnk = 1)
SELECT cts.program_month,
       cts.tenant_name,
       cts.school_organisation        AS organisation_name,
       cts.school_dw_id,
       cts.school_name,
       UPPER(cts.school_country_name) AS school_country_name,
       UPPER(cts.school_city_name)    AS school_city_name,
       cts.school_composition,
       cts.grade_name,
       cts.academic_year,
       cts.unified_lesson_id,
       cts.unified_lesson_title,
       cts.class_total_students,
       cl.local_date,
       cl.fle_student_dw_id,
       cl.lo_status,
       cl.fle_total_score             AS fle_score
FROM class_total_students_zoud_literacy cts
         LEFT JOIN
     completed_lessons cl
     ON cts.school_dw_id = cl.fle_school_dw_id
         AND cts.grade_dw_id = cl.fle_grade_dw_id
         AND cts.unified_lesson_id = cl.unified_lesson_id
         AND cts.program_month = cl.local_month
WHERE cts.program_month < CURRENT_DATE;