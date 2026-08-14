CREATE OR ALTER  VIEW ${os_bi_coredw}.lesson_feedback_dm_view AS
SELECT DISTINCT
    sch.tenant_id,
    sch.tenant_name,
    grade_dw_id,
    grade_name,
    lesson_feedback_subject_dw_id,
    UPPER(dc.class_gen_subject) AS class_gen_subject,
    flf.lesson_feedback_created_time,
    CONVERT(
        DATE,
        flf.lesson_feedback_created_time
            AT TIME ZONE 'UTC'
            AT TIME ZONE ISNULL(sch.windows_timezone, 'UTC')
    ) AS local_date,

    (6.0 - flf.lesson_feedback_rating) AS rate,
    flf.lesson_feedback_student_dw_id,
    flf.lesson_feedback_rating_text,
    sch.school_dw_id,
    sch.school_organisation,
    sch.organisation_dw_id,
    sch.school_name,
    sch.school_city_name,
    dg.grade_k12grade,
    ds.section_dw_id,
    UPPER(ds.section_name) AS section_name,
    UPPER(dc.class_title) AS class_title,
    flf.lesson_feedback_lo_dw_id,
    dlo.lo_title,
    sdm.student_tags,
    sdm.student_special_needs AS special_needs,
    ISNULL(dtrm.actp_teaching_period_order, 1) AS term_academic_period_order,
    ISNULL(dtrm.actp_teaching_period_start_date, sch.academic_year_start_date) AS term_start_date,
    ISNULL(dtrm.actp_teaching_period_end_date, sch.academic_year_end_date)     AS term_end_date,

    CONVERT(VARCHAR(4), DATEPART(YEAR, sch.academic_year_start_date))
        + '-' +
    CONVERT(VARCHAR(4), DATEPART(YEAR, sch.academic_year_end_date)) AS academic_year

FROM ${rs_coredw}.fact_lesson_feedback flf
INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim sch
    ON sch.school_dw_id = flf.lesson_feedback_school_dw_id
   AND flf.lesson_feedback_created_time >= CONVERT(DATETIME2, sch.academic_year_start_date)  -- OPT-15: SARGable rewrite
   AND flf.lesson_feedback_created_time < DATEADD(DAY, 1, CONVERT(DATETIME2, sch.academic_year_end_date))  -- OPT-15: SARGable rewrite

INNER JOIN ${rs_coredw}.dim_grade dg
    ON dg.grade_dw_id = flf.lesson_feedback_grade_dw_id
INNER JOIN ${rs_coredw}.dim_section ds
    ON ds.section_dw_id = flf.lesson_feedback_section_dw_id
INNER JOIN ${rs_coredw}.dim_class_user dcu
    ON dcu.class_user_user_dw_id = flf.lesson_feedback_student_dw_id
INNER JOIN ${rs_coredw}.dim_class dc
    ON dc.class_dw_id = dcu.class_user_class_dw_id
   AND dc.class_dw_id = flf.lesson_feedback_class_dw_id
INNER JOIN ${rs_bi_coredw}.bi_student_dim sdm
    ON sdm.student_dw_id = flf.lesson_feedback_student_dw_id
LEFT JOIN ${rs_coredw}.dim_academic_calendar_teaching_period dtrm
    ON dtrm.actp_dw_id = flf.lesson_feedback_term_dw_id
   AND dtrm.actp_status = 1
INNER JOIN ${rs_coredw}.dim_learning_objective dlo
    ON dlo.lo_dw_id = flf.lesson_feedback_lo_dw_id
WHERE flf.lesson_feedback_rating > 0
  AND dg.grade_status = 1
  AND ds.section_status = 1
  AND sdm.student_status = 1
  AND dc.class_status = 1
  AND dcu.class_user_status = 1
  AND dcu.class_user_attach_status = 1
  AND dlo.lo_status = 1;
