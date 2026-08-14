CREATE OR ALTER VIEW ${os_bi_coredw}.guardian_joint_activity_dm_view AS
WITH fact_guardian_joint_activity AS (
    SELECT DISTINCT fgja.fgja_dw_id,
           fgja.fgja_student_dw_id,
           fgja.fgja_guardian_dw_id,
           fgja.fgja_school_dw_id,
           fgja.fgja_class_dw_id,
           fgja.fgja_pathway_dw_id,
           fgja.fgja_course_dw_id,
           fgja.fgja_course_activity_container_dw_id,
           fgja.fgja_created_time,
           fgja.fgja_state,
           fgja.fgja_attempt,
           fgja.fgja_rating,
           fgja.fgja_k12_grade,
           fgja.fgja_completed_time,
           dcaa.caa_activity_dw_id,
           dcaa.caa_activity_type,
           lo.lo_dw_id,
           lo.lo_title,
           lo.lo_language
    FROM (
        SELECT fgja.fgja_dw_id,
               fgja.fgja_student_dw_id,
               fgja.fgja_guardian_dw_id,
               fgja.fgja_school_dw_id,
               fgja.fgja_class_dw_id,
               fgja.fgja_pathway_dw_id,
               fgja.fgja_course_dw_id,
               fgja.fgja_course_activity_container_dw_id,
               fgja.fgja_created_time,
               fgja.fgja_state,
               fgja.fgja_attempt,
               fgja.fgja_rating,
               fgja.fgja_k12_grade,
               fgja_completed.fgja_completed_time
        FROM (
            SELECT fgja_dw_id,
                   fgja_student_dw_id,
                   fgja_guardian_dw_id,
                   fgja_school_dw_id,
                   fgja_class_dw_id,
                   fgja_pathway_dw_id,
                   fgja_course_dw_id,
                   fgja_course_activity_container_dw_id,
                   fgja_created_time,
                   fgja_state,
                   fgja_attempt,
                   fgja_rating,
                   fgja_k12_grade,
                   ROW_NUMBER() OVER (
                       PARTITION BY fgja_student_dw_id, fgja_guardian_dw_id, fgja_dw_id, ISNULL(fgja_attempt, 1)  /* OPT-9: Replaced COALESCE with ISNULL (2 args) */
                       ORDER BY fgja_created_time DESC
                   ) AS [Row]
            FROM ${rs_coredw}.fact_guardian_joint_activity
        ) AS fgja
        LEFT JOIN (
            SELECT DISTINCT fgja_student_dw_id,
                   fgja_guardian_dw_id,
                   fgja_attempt,
                   fgja_created_time AS fgja_completed_time
            FROM ${rs_coredw}.fact_guardian_joint_activity AS fgja
            WHERE fgja.fgja_state = 3
        ) AS fgja_completed
            ON fgja.fgja_student_dw_id = fgja_completed.fgja_student_dw_id
           AND fgja.fgja_guardian_dw_id = fgja_completed.fgja_guardian_dw_id
           AND fgja.fgja_attempt = fgja_completed.fgja_attempt
        WHERE fgja.[Row] = 1
    ) AS fgja
    JOIN ${rs_coredw}.dim_course dcr
        ON fgja.fgja_course_dw_id = dcr.course_dw_id
       AND dcr.course_status = 1
       AND dcr.course_type = 'PATHWAY'
    JOIN ${rs_coredw}.dim_course_activity_container dcac
        ON fgja.fgja_course_activity_container_dw_id = dcac.course_activity_container_dw_id
       AND fgja.fgja_course_dw_id = dcr.course_dw_id
    JOIN ${rs_coredw}.dim_course_activity_association dcaa
        ON dcaa.caa_course_dw_id = dcr.course_dw_id
       AND dcaa.caa_status = 1
       AND dcaa.caa_attach_status = 1
       AND dcaa.caa_is_joint_parent_activity = 1
    JOIN ${rs_coredw}.dim_learning_objective lo
        ON dcaa.caa_activity_dw_id = lo.lo_dw_id
       AND lo.lo_language LIKE 'EN_%'  -- OPT-4
       AND lo.lo_status = 1
),

class_grade_section_title AS (
    SELECT DISTINCT
        dc.class_dw_id,
        UPPER(dc.class_title) AS class_title,
        UPPER(ISNULL(dse.section_name, 'NA')  /* OPT-9: Replaced COALESCE with ISNULL (2 args) */) AS section_name,
        dg.grade_dw_id
    FROM ${rs_coredw}.dim_class AS dc
    JOIN ${rs_coredw}.dim_class_user AS dcu
        ON dc.class_dw_id = dcu.class_user_class_dw_id
    JOIN ${rs_coredw}.dim_grade dg
        ON dg.grade_id = dc.class_grade_id
    JOIN ${rs_coredw}.dim_section dse
        ON dc.class_section_id = dse.section_id
    JOIN ${rs_coredw}.dim_course dcr
        ON dc.class_material_id = dcr.course_id
       AND dcr.course_status = 1
       AND dcr.course_type = 'PATHWAY'
    WHERE dc.class_status = 1
      AND dc.class_course_status = 'ACTIVE'
      AND dc.class_material_type = 'PATHWAY'
      AND dg.grade_status = 1
      AND dse.section_status = 1
      AND dcu.class_user_role_dw_id = 2
      AND dcu.class_user_attach_status = 1
      AND dcu.class_user_status = 1
)

SELECT DISTINCT
    CONVERT(DATE,  -- OPT-1
        CONVERT(DATETIME2, fgja.fgja_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC'))
    ) AS local_date,

    CONVERT(DATETIME2, fgja.fgja_created_time
            AT TIME ZONE 'UTC'
            AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')) AS fgja_created_time,

    CONVERT(DATETIME2, fgja.fgja_completed_time
            AT TIME ZONE 'UTC'
            AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')) AS fgja_completed_time,

    fgja.fgja_dw_id,
    dsc.academic_year_dw_id,
    dsc.tenant_id,
    dsc.organisation_dw_id,
    fgja.fgja_school_dw_id AS school_dw_id,
    fgja.fgja_class_dw_id  AS class_dw_id,
    cgst.grade_dw_id,
    fgja.fgja_pathway_dw_id AS pathway_dw_id,
    fgja.fgja_student_dw_id AS student_dw_id,
    fgja.fgja_guardian_dw_id AS guardian_dw_id,
    fgja.caa_activity_dw_id AS plaa_activity_dw_id,
    fgja.lo_dw_id,
    dsc.academic_year_start_date,
    dsc.academic_year_end_date,
    CONVERT(VARCHAR(4), DATEPART(year, dsc.academic_year_start_date))
        + '-' +
    CONVERT(VARCHAR(4), DATEPART(year, dsc.academic_year_end_date)) AS academic_year,
    dsc.tenant_name,
    dsc.school_organisation,
    dsc.school_country_name,
    dsc.school_city_name,
    dsc.school_name,
    cgst.class_title,
    fgja.fgja_k12_grade AS k12_grade,
    cgst.section_name,
    fgja.caa_activity_type AS plaa_activity_type,
    fgja.fgja_attempt AS attempt,
    fgja.fgja_rating AS rating,
    fgja.fgja_state AS state,
    CASE fgja.fgja_state
        WHEN 1 THEN 'Assigned'
        WHEN 2 THEN 'Started'
        WHEN 3 THEN 'Completed'
        WHEN 4 THEN 'Rated'
        ELSE 'Invalid State'
    END AS state_status,
    fgja.lo_title,
    fgja.lo_language,
    gsa.total_guardians
FROM fact_guardian_joint_activity AS fgja
JOIN ${rs_bi_coredw}.bi_student_dim AS dst
    ON dst.student_dw_id = fgja.fgja_student_dw_id
   AND dst.student_status = 1
JOIN ${rs_bi_coredw}.bi_active_schools_dim AS dsc
    ON dsc.school_dw_id = dst.student_school_dw_id
JOIN class_grade_section_title AS cgst
    ON cgst.class_dw_id = fgja.fgja_class_dw_id
JOIN (
    SELECT DISTINCT school_dw_id,
           COUNT(DISTINCT guardian_dw_id) AS total_guardians
    FROM ${rs_bi_coredw}.guardian_student_association_dm_view
    GROUP BY school_dw_id
) AS gsa
    ON gsa.school_dw_id = fgja.fgja_school_dw_id
WHERE CONVERT(DATE, fgja.fgja_created_time
              AT TIME ZONE 'UTC'
              AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')) >= dsc.academic_year_start_date
  AND CONVERT(DATE, fgja.fgja_created_time
              AT TIME ZONE 'UTC'
              AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')) <= dsc.academic_year_end_date;
