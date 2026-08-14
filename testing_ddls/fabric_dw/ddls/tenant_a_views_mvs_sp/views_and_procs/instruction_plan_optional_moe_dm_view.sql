CREATE OR ALTER VIEW ${os_bi_coredw}.instruction_plan_optional_moe_dm_view
AS
WITH Learning_Objective AS (
    SELECT
        lo_dw_id,
        lo_code,
        lo_title,
        lo_created_time
    FROM ${rs_coredw}.dim_learning_objective dip_dlo
    WHERE ISNULL(dip_dlo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
      AND lo_status = 1
      AND lo_code IN (
            'CD_MLO_001_EN_V1','CD_MLO_002_EN_V1','CD_MLO_003_EN_V1','CD_MLO_004_EN_V1','CD_MLO_005_EN_V1',
            'CD_MLO_001_AR','CD_MLO_002_AR','CD_MLO_003_AR','CD_MLO_004_AR','CD_MLO_005_AR'
      )
),

Civil_lo AS (
    SELECT *
    FROM (
        SELECT
            caa_course_id,
            lo_code,
            caa_course_dw_id,
            caa_created_time,
            caa_activity_id,
            caa_activity_dw_id,
            caa_activity_pacing,
            caa_activity_is_optional,
            caa_activity_type,
            caa_attach_status,
            caa_status,
            ROW_NUMBER() OVER (
                PARTITION BY caa_course_id, caa_activity_id
                ORDER BY caa_created_time DESC
            ) AS rank
        FROM ${rs_coredw}.dim_course_activity_association
        JOIN Learning_Objective
            ON caa_activity_dw_id = lo_dw_id
        WHERE caa_activity_is_optional = 1
    ) t
    WHERE rank = 1
),

academic_year AS (
    SELECT
        school_dw_id,
        MAX(YEAR(academic_year_end_date)) AS max_year
    FROM ${database}.${rs_bi_coredw}.bi_all_schools_dim_mv
    GROUP BY school_dw_id
),

class_teachers AS (
    SELECT
        x.class_dw_id,
        x.class_user_attach_status,
        x.class_course_status,
        x.academic_year_end_date,
        STRING_AGG(x.teacher_id, ',') AS teacher_ids
    FROM (
        SELECT DISTINCT
            dc.class_dw_id,
            dcu.class_user_attach_status,
            dc.class_course_status,
            dsc.academic_year_end_date,
            dt.teacher_id
        FROM ${rs_coredw}.dim_class dc
        JOIN ${rs_coredw}.dim_class_user dcu
            ON dcu.class_user_class_dw_id = dc.class_dw_id
           AND dcu.class_user_role_dw_id = 1
        JOIN ${database}.${rs_bi_coredw}.bi_all_schools_dim_mv dsc
            ON dsc.school_id = dc.class_school_id
           AND dsc.academic_year_id = dc.class_academic_year_id
        LEFT JOIN ${rs_coredw}.dim_teacher dt
            ON dcu.class_user_user_dw_id = dt.teacher_dw_id
           AND dt.teacher_id NOT IN (
                SELECT teacher_id
                FROM ${rs_bi_coredw}.exclude_teacher_id
           )
        JOIN academic_year ay
            ON dsc.school_dw_id = ay.school_dw_id
        WHERE dc.class_material_type <> 'PATHWAY'
          AND (
                (YEAR(dsc.academic_year_end_date) = ay.max_year
                 AND dc.class_course_status = 'ACTIVE'
                 AND dcu.class_user_attach_status = 1)
             OR (YEAR(dsc.academic_year_end_date) < ay.max_year
                 AND dc.class_course_status = 'CONCLUDED')
          )
    ) x
    GROUP BY
        x.class_dw_id,
        x.class_user_attach_status,
        x.class_course_status,
        x.academic_year_end_date
),

COMPLETED_LESSONS AS (
    SELECT *
    FROM (
        SELECT
            fle.fle_ls_id,
            fle.fle_dw_id,
            lo.lo_dw_id,
            lo.lo_title,
            fle.fle_student_dw_id,
            fle.fle_grade_dw_id,
            fle.fle_school_dw_id,
            fle.fle_section_dw_id,
            ac.academic_year_start_date,
            ac.academic_year_end_date,
            CAST(fle.fle_created_time AS DATE) AS lesson_progress_date,
            'Completed' AS lo_status,
            CASE WHEN lo.lo_max_stars > 0 THEN fle.fle_score END AS fle_score,
            ROW_NUMBER() OVER (
                PARTITION BY fle.fle_ls_id
                ORDER BY fle.fle_created_time DESC
            ) AS rnk
        FROM ${rs_coredw}.fact_learning_experience fle
        JOIN ${rs_coredw}.dim_learning_objective lo
            ON lo.lo_dw_id = fle.fle_lo_dw_id
        JOIN Learning_Objective cd
            ON cd.lo_code = lo.lo_code
        JOIN ${database}.${rs_bi_coredw}.bi_all_schools_dim_mv ac
            ON ac.school_dw_id = fle.fle_school_dw_id
           AND ac.academic_year_dw_id = fle.fle_academic_year_dw_id
        WHERE fle.fle_completion_node = 1
          AND fle.fle_activity_type <> 'INTERIM_CHECKPOINT'
          AND fle.fle_material_type <> 'PATHWAY'
          AND ISNULL(lo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
    ) z
    WHERE rnk = 1
),

INPROGRESS_LESSONS AS (
    SELECT
        fle_dw_id,
        lo_dw_id,
        lo_title,
        fle_student_dw_id,
        fle_grade_dw_id,
        fle_school_dw_id,
        fle_section_dw_id,
        academic_year_start_date,
        academic_year_end_date,
        lesson_progress_date,
        0 AS fle_score,
        'In-Progress' AS lo_status
    FROM (
        SELECT
            fle_ls_id,
            lo.lo_dw_id,
            lo.lo_title,
            fle.fle_student_dw_id,
            fle.fle_grade_dw_id,
            fle.fle_school_dw_id,
            fle.fle_section_dw_id,
            ac.academic_year_start_date,
            ac.academic_year_end_date,
            MAX(fle.fle_dw_id) AS fle_dw_id,
            CAST(MAX(fle.fle_created_time) AS DATE) AS lesson_progress_date
        FROM ${rs_coredw}.fact_learning_experience fle
        JOIN Learning_Objective lo
            ON lo.lo_dw_id = fle.fle_lo_dw_id
        JOIN ${database}.${rs_bi_coredw}.bi_all_schools_dim_mv ac
            ON ac.school_dw_id = fle.fle_school_dw_id
           AND ac.academic_year_dw_id = fle.fle_academic_year_dw_id
        WHERE fle.fle_ls_id NOT IN (
            SELECT fle_ls_id FROM COMPLETED_LESSONS
        )
          AND fle.fle_attempt = 1
          AND fle.fle_activity_type <> 'INTERIM_CHECKPOINT'
          AND fle.fle_material_type <> 'PATHWAY'
          AND fle.fle_abbreviation <> 'NA'
        GROUP BY
            fle_ls_id,
            lo.lo_dw_id,
            lo.lo_title,
            fle.fle_student_dw_id,
            fle.fle_grade_dw_id,
            fle.fle_school_dw_id,
            fle.fle_section_dw_id,
            ac.academic_year_start_date,
            ac.academic_year_end_date
    ) a
),

LESSON_PROGRESS AS (
    SELECT
        fle_dw_id,
        lo_dw_id,
        lo_title,
        fle_student_dw_id,
        fle_grade_dw_id,
        fle_school_dw_id,
        fle_section_dw_id,
        academic_year_start_date,
        academic_year_end_date,
        fle_score,
        lo_status,
        lesson_progress_date
    FROM INPROGRESS_LESSONS
    UNION ALL
    SELECT
        fle_dw_id,
        lo_dw_id,
        lo_title,
        fle_student_dw_id,
        fle_grade_dw_id,
        fle_school_dw_id,
        fle_section_dw_id,
        academic_year_start_date,
        academic_year_end_date,
        fle_score,
        lo_status,
        lesson_progress_date
    FROM COMPLETED_LESSONS
),

student_lessons_assigned AS (
    SELECT DISTINCT
        dcu.class_user_user_dw_id,
        dcu.class_user_class_dw_id,
        dcs.curr_subject_dw_id,
        lo.lo_dw_id,
        lo.lo_title,
        dip.caa_activity_dw_id,
        ac.academic_year_start_date,
        ac.academic_year_end_date,
        ac.school_dw_id,
        dc.class_course_status
    FROM ${rs_coredw}.dim_class_user dcu
    JOIN ${rs_coredw}.dim_class dc
        ON dc.class_dw_id = dcu.class_user_class_dw_id
    JOIN ${rs_coredw}.dim_curriculum_subject dcs
        ON dc.class_curriculum_subject_id = dcs.curr_subject_id
    JOIN ${rs_coredw}.dim_course_activity_association dip
        ON dc.class_material_id = dip.caa_course_id
    JOIN Learning_Objective lo
        ON lo.lo_dw_id = dip.caa_activity_dw_id
    JOIN ${database}.${rs_bi_coredw}.bi_all_schools_dim_mv ac
        ON ac.school_id = dc.class_school_id
       AND ac.academic_year_id = dc.class_academic_year_id
    JOIN academic_year ay
        ON ac.school_dw_id = ay.school_dw_id
    WHERE dcu.class_user_role_dw_id = 2
      AND dc.class_material_type <> 'PATHWAY'
      AND (
            (YEAR(ac.academic_year_end_date) = ay.max_year
             AND dc.class_course_status = 'ACTIVE'
             AND dcu.class_user_attach_status = 1
             AND dip.caa_attach_status = 1
             AND dip.caa_status = 1)
         OR (YEAR(ac.academic_year_end_date) < ay.max_year
             AND dc.class_course_status = 'CONCLUDED')
      )
),

class_total_students_civil_defense AS (
    SELECT
        dc.class_dw_id,
        lo_code,
        lo_title,
        class_material_id,
        class_title,
        class_gen_subject,
        class_curriculum_id,
        class_academic_year_id,
        academic_year_start_date,
        ac.academic_year_end_date,
        class_content_academic_year,
        dc.class_course_status,
        class_material_type,
        class_grade_id,
        class_section_id,
        class_curriculum_grade_id,
        ac.school_dw_id,
        ISNULL(dsec.section_dw_id, '10001') AS class_section_dw_id,
        UPPER(ISNULL(dsec.section_name,'NA')) AS class_section_name,
        dcg.curr_grade_dw_id,
        dcg.curr_grade_name,
        dg.grade_name,
        dcs.curr_subject_dw_id,
        dcs.curr_subject_name,
        ct.teacher_ids,
        COUNT(DISTINCT dcu.class_user_user_dw_id) AS class_total_students
    FROM ${rs_coredw}.dim_class dc
    JOIN ${rs_coredw}.dim_class_user dcu
        ON dc.class_dw_id = dcu.class_user_class_dw_id
    JOIN ${database}.${rs_bi_coredw}.bi_all_schools_dim_mv ac
        ON ac.school_id = dc.class_school_id
       AND ac.academic_year_id = dc.class_academic_year_id
    JOIN ${rs_coredw}.dim_curriculum_subject dcs
        ON dc.class_curriculum_subject_id = dcs.curr_subject_id
    JOIN ${rs_coredw}.dim_course_activity_association dip
        ON dc.class_material_id = dip.caa_course_id
    JOIN Learning_Objective lo
        ON lo.lo_dw_id = dip.caa_activity_dw_id
    JOIN academic_year ay
        ON ac.school_dw_id = ay.school_dw_id
    LEFT JOIN ${rs_coredw}.dim_curriculum_grade dcg
        ON dc.class_curriculum_grade_id = dcg.curr_grade_id
    LEFT JOIN ${rs_coredw}.dim_grade dg
        ON dg.grade_id = dc.class_grade_id
    LEFT JOIN ${rs_coredw}.dim_section dsec
        ON dsec.section_id = dc.class_section_id
    LEFT JOIN class_teachers ct
        ON ct.class_dw_id = dc.class_dw_id
    WHERE dcu.class_user_role_dw_id = 2
      AND (
            (YEAR(ac.academic_year_end_date) = ay.max_year
             AND dc.class_course_status = 'ACTIVE'
             AND dcu.class_user_attach_status = 1
             AND dip.caa_attach_status = 1
             AND dc.class_active_until IS NULL
             AND dip.caa_status = 1)
         OR (YEAR(ac.academic_year_end_date) < ay.max_year
             AND dc.class_course_status = 'CONCLUDED')
      )
    GROUP BY
        dc.class_dw_id, lo_code, lo_title, class_material_id, class_title, class_gen_subject,
        class_curriculum_id, class_academic_year_id, academic_year_start_date,
        ac.academic_year_end_date, class_content_academic_year, dc.class_course_status,
        class_material_type, class_grade_id, class_section_id, class_curriculum_grade_id,
        ac.school_dw_id, dsec.section_dw_id, dsec.section_name, dcg.curr_grade_dw_id,
        dcg.curr_grade_name, dg.grade_name, dcs.curr_subject_dw_id, dcs.curr_subject_name,
        ct.teacher_ids
),

students_learning_progress_civil_defense AS (
    SELECT
        fl.*,
        ISNULL(lps.fle_score, 0) AS fle_score,
        lps.lo_status,
        lps.lesson_progress_date
    FROM (
        SELECT DISTINCT
            dd.full_date AS local_date,
            dcu.class_user_class_dw_id AS fle_class_dw_id,
            fle_lo_dw_id AS lo_attempted,
            lo_code,
            fle_lesson_category,
            fle_dw_id,
            fle_ls_id,
            ds.student_dw_id,
            ds.student_section_dw_id,
            fle_academic_year_dw_id,
            ds.student_tags,
            dg.grade_k12grade,
            ac.academic_year_start_date,
            ac.academic_year_end_date,
            CASE
                WHEN fle.fle_total_time <= 900 THEN fle.fle_total_time
                WHEN fle.fle_total_time > 900 THEN 900
                ELSE 0
            END AS session_time
        FROM ${rs_coredw}.fact_learning_experience fle
        JOIN Learning_Objective
            ON fle_lo_dw_id = lo_dw_id
        JOIN ${database}.${rs_bi_coredw}.bi_all_schools_dim_mv ac
            ON ac.school_dw_id = fle.fle_school_dw_id
           AND ac.academic_year_dw_id = fle.fle_academic_year_dw_id
        JOIN ${rs_coredw}.dim_student ds
            ON fle.fle_student_dw_id = ds.student_dw_id
           AND ac.school_dw_id = ds.student_school_dw_id
        JOIN ${rs_coredw}.dim_grade dg
            ON dg.grade_dw_id = fle.fle_grade_dw_id
        JOIN ${rs_coredw}.dim_date dd
            ON fle.fle_date_dw_id = dd.date_id
        JOIN student_lessons_assigned dcu
            ON fle.fle_student_dw_id = dcu.class_user_user_dw_id
        WHERE fle_abbreviation <> 'NA'
          AND fle_activity_type <> 'INTERIM_CHECKPOINT'
          AND fle_material_type <> 'PATHWAY'
    ) fl
    JOIN LESSON_PROGRESS lps
        ON fl.fle_dw_id = lps.fle_dw_id
       AND fl.student_dw_id = lps.fle_student_dw_id
    WHERE ISNULL(fle_lesson_category, 'NA') <> 'EXPERIENTIAL_LESSON'
)

SELECT DISTINCT
    dsc.tenant_name,
    dsc.school_dw_id,
    dsc.school_id,
    dsc.school_name,
    dsc.school_alias AS school_adek_id,
    UPPER(dsc.school_country_name) AS school_country_name,
    UPPER(dsc.school_city_name) AS school_city_name,
    dsc.school_label,
    dsc.school_composition,
    dsc.school_organisation AS organisation_name,
    dsc.school_cx_cluster,
    cts.class_dw_id,
    cts.class_total_students,
    cts.class_title,
    cts.class_gen_subject,
    cts.class_section_dw_id AS section_dw_id,
    cts.class_section_name AS section_name,
    cts.curr_grade_name,
    cts.grade_name,
    cts.curr_subject_name,
    dip_dlo.lo_code,
    cip.caa_course_id,
    dip_dlo.lo_title,
    cip.caa_activity_dw_id AS lo_to_finish,
    lp.lo_attempted,
    lp.lo_status,
    lp.lesson_progress_date,
    ISNULL(lp.fle_score, 0) AS fle_score,
    lp.student_dw_id,
    ds.student_id,
    lp.local_date,
    lp.academic_year_start_date,
    lp.academic_year_end_date,
    CONCAT(YEAR(cts.academic_year_start_date), '-', YEAR(cts.academic_year_end_date)) AS academic_year,
    dd.calendar_week_number AS week_number,
    dd.calendar_week_of AS week_start_date,
    DATEADD(DAY, 6, dd.calendar_week_of) AS week_end_date,
    cip.caa_activity_pacing,
    cip.caa_activity_is_optional,
    cip.caa_activity_type,
    ISNULL(dtrm.actp_teaching_period_order, 1) AS org_term,
    ISNULL(dtrm.actp_teaching_period_start_date, dsc.academic_year_start_date) AS term_start_date,
    ISNULL(dtrm.actp_teaching_period_end_date, dsc.academic_year_end_date) AS term_end_date,
    ISNULL(lp.session_time, 0) AS session_time,
    lp.grade_k12grade,
    cts.teacher_ids
FROM class_total_students_civil_defense cts
JOIN Civil_lo cip
    ON cts.class_material_id = cip.caa_course_id
JOIN ${database}.${rs_bi_coredw}.bi_all_schools_dim_mv dsc
    ON cts.school_dw_id = dsc.school_dw_id
   AND cts.class_academic_year_id = dsc.academic_year_id
JOIN ${rs_coredw}.dim_academic_calendar dac
    ON dsc.organisation_dw_id = dac.academic_calendar_organization_dw_id
   AND dac.academic_calendar_academic_year_dw_id = dsc.academic_year_dw_id
JOIN ${rs_coredw}.dim_academic_calendar_teaching_period dtrm
    ON dac.academic_calendar_id = dtrm.actp_academic_calendar_id
   AND dtrm.actp_status = 1
JOIN Learning_Objective dip_dlo
    ON cip.caa_activity_dw_id = dip_dlo.lo_dw_id
LEFT JOIN students_learning_progress_civil_defense lp
    ON cts.class_dw_id = lp.fle_class_dw_id
   AND cts.class_section_dw_id = lp.student_section_dw_id
   AND dip_dlo.lo_dw_id = lp.lo_attempted
LEFT JOIN ${rs_coredw}.dim_student ds
    ON ds.student_dw_id = lp.student_dw_id
LEFT JOIN ${rs_coredw}.dim_date dd
    ON dd.full_date = lp.local_date
WHERE dsc.tenant_name IN ('MOE','Private');
