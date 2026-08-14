CREATE OR ALTER VIEW ${OS_EAGLES_COREDW}.pathway_nlf_principal_dm_view
AS
WITH pathway_class_total_students AS (
    SELECT
        dsc.school_dw_id,
        dsc.school_id,
        dsc.school_name,
        dsc.tenant_timezone,
        dsc.academic_year_start_date,
        dsc.academic_year_end_date,
        CONVERT(VARCHAR(4), YEAR(dsc.academic_year_start_date)) + '-' +  
        CONVERT(VARCHAR(4), YEAR(dsc.academic_year_end_date)) AS academic_year, 
        dcu.class_user_user_dw_id AS pathway_student_dw_id,
        ds.student_id,
        ds.student_grade_dw_id,
        dg.grade_k12grade AS grade_name,
        dg.grade_id,
        sc.section_alias,
        CASE
            WHEN dc.class_gen_subject IN ('Physics', 'Biology', 'Chemistry') THEN 'Science'
            WHEN dcsa.cs_subject_dw_id IS NOT NULL THEN 'Arabits'
            ELSE dc.class_gen_subject
        END AS subject_name,
        dc.class_material_id,
        class_title, 
        class_dw_id 
    FROM ${RS_COREDW}.dim_class dc
    INNER JOIN ${RS_COREDW}.dim_class_user dcu
        ON dcu.class_user_class_dw_id = dc.class_dw_id
    INNER JOIN ${RS_BI_COREDW}.bi_active_schools_dim dsc
        ON dc.class_school_id  = dsc.school_id 
    INNER JOIN ${RS_BI_COREDW}.bi_student_dim ds
        ON dcu.class_user_user_dw_id = ds.student_dw_id
       AND dsc.school_dw_id = ds.student_school_dw_id
       AND ds.student_status = 1
    INNER JOIN ${RS_COREDW}.dim_grade dg
        ON dg.grade_dw_id = ds.student_grade_dw_id
       AND dsc.academic_year_id  = dg.academic_year_id 
       AND dg.grade_status = 1
    INNER JOIN ${RS_COREDW}.dim_section sc
        ON ds.student_section_dw_id = sc.section_dw_id
    LEFT JOIN ${RS_COREDW}.dim_course_subject_association dcsa
        ON dcsa.cs_course_id = dc.class_material_id
       AND dcsa.cs_status = 1
       AND dcsa.cs_subject_dw_id IN (129, 503)
    WHERE dcu.class_user_status = 1
      AND dcu.class_user_role_dw_id = 2
      AND dcu.class_user_attach_status = 1
      AND dc.class_course_status = 'ACTIVE'
      AND dc.class_material_type = 'PATHWAY'
      AND dc.class_status = 1
),
students_placed AS (
    SELECT DISTINCT
        cr.course_id,
        fpp_student_dw_id AS placed_student_dw_id
    FROM ${RS_COREDW}.fact_pathway_placement fpp
    INNER JOIN ${RS_COREDW}.dim_course cr
        ON cr.course_dw_id = fpp.fpp_course_dw_id
       AND cr.course_status = 1
),
adaptive_practice_fact AS (
    SELECT
        ap.student_dw_id,
        ap.pathway_id,
        ap.level_dw_id,
        DATETRUNC(month, ap.created_time) AS [month],
        ap.level_proficiency_tier,
        ROW_NUMBER() OVER (
            PARTITION BY ap.student_dw_id, ap.pathway_id, ap.level_dw_id, DATETRUNC(month, ap.created_time)
            ORDER BY ap.created_time DESC
        ) AS rn
    FROM ${RS_COREDW}.fact_adaptive_practice_progress ap
    WHERE ap.event_type = 'AdaptivePracticeAnswerSubmittedEvent'
),
adaptive_practice_fact_dedup AS (
    SELECT
        student_dw_id,
        pathway_id,
        level_dw_id,
        [month],
        level_proficiency_tier
    FROM adaptive_practice_fact
    WHERE rn = 1
),
skills_started_fact AS (
    SELECT
        slp.student_dw_id,
        caa.caa_container_dw_id,
        caa.caa_course_id,
        DATETRUNC(month, slp.created_time) AS [month],
        COUNT(DISTINCT slp.skill_dw_id) AS skills_started
    FROM ${RS_COREDW}.fact_pathway_skill_learning_progress slp
    INNER JOIN ${RS_COREDW}.dim_course_activity_association caa
        ON caa.caa_course_id = slp.material_id
       AND caa.caa_activity_dw_id = slp.skill_dw_id
    WHERE slp.event_type = 'SkillExperienceStarted'
    GROUP BY
        slp.student_dw_id,
        caa.caa_container_dw_id,
        caa.caa_course_id,
        DATETRUNC(month, slp.created_time)
),
skills_active_fact AS (
    SELECT
        slp.student_dw_id,
        caa.caa_container_dw_id,
        caa.caa_course_id,
        DATETRUNC(month, slp.created_time) AS [month],
        COUNT(DISTINCT slp.skill_dw_id) AS skills_active
    FROM ${RS_COREDW}.fact_pathway_skill_learning_progress slp
    INNER JOIN ${RS_COREDW}.dim_course_activity_association caa
        ON caa.caa_course_id = slp.material_id
       AND caa.caa_activity_dw_id = slp.skill_dw_id
    WHERE slp.event_type = 'SkillExperienceFinished'
    GROUP BY
        slp.student_dw_id,
        caa.caa_container_dw_id,
        caa.caa_course_id,
        DATETRUNC(month, slp.created_time)
),
skills_to_review AS (
    SELECT
        sgt.student_dw_id,
        sgt.level_dw_id,
        DATETRUNC(month, sgt.created_time) AS [month],
        COUNT(DISTINCT sgt.skill_dw_id) AS skills_to_review
    FROM ${RS_COREDW}.fact_pathway_skill_gap_tracker sgt
    WHERE sgt.status = 'INTRODUCED'
      AND NOT EXISTS (
            SELECT 1
            FROM ${RS_COREDW}.fact_pathway_skill_gap_tracker sgt2
            WHERE sgt.student_dw_id = sgt2.student_dw_id
              AND sgt.skill_dw_id = sgt2.skill_dw_id
              AND sgt2.status = 'RESOLVED'
        )
    GROUP BY
        sgt.student_dw_id,
        sgt.level_dw_id,
        DATETRUNC(month, sgt.created_time)
),
fact_table AS (
    SELECT
        COALESCE(ap.student_dw_id, sk.student_dw_id) AS started_student_dw_id,
        COALESCE(ap.student_dw_id, sa.student_dw_id) AS active_student_dw_id,
        COALESCE(ap.pathway_id, sk.caa_course_id)    AS course_id,
        ap.level_dw_id,
        CAST(COALESCE(ap.[month], sk.[month]) AS DATE) AS [month],
        ap.level_proficiency_tier,
        sk.skills_started,
        sa.skills_active,
        str.skills_to_review
    FROM skills_started_fact sk
    FULL OUTER JOIN adaptive_practice_fact_dedup ap
        ON ap.student_dw_id = sk.student_dw_id
       AND ap.level_dw_id   = sk.caa_container_dw_id
       AND ap.[month]       = sk.[month]
    LEFT JOIN skills_active_fact sa
        ON sk.student_dw_id     = sa.student_dw_id
       AND sk.caa_container_dw_id = sa.caa_container_dw_id
       AND sk.[month]           = sa.[month]
    LEFT JOIN skills_to_review str
        ON ap.student_dw_id = str.student_dw_id
       AND ap.level_dw_id   = str.level_dw_id
       AND ap.[month]       = str.[month]
)
SELECT
    pcts.school_dw_id,
    pcts.school_id,
    pcts.school_name,
    pcts.tenant_timezone,
    pcts.academic_year_start_date,
    pcts.academic_year_end_date,
    pcts.academic_year,
    pcts.pathway_student_dw_id,
    pcts.student_id,
    pcts.student_grade_dw_id,
    pcts.grade_name,
    pcts.grade_id,
    pcts.section_alias,
    pcts.subject_name,
    pcts.class_material_id,
    pcts.class_title,
    pcts.class_dw_id,
    sp.placed_student_dw_id,
    ft.started_student_dw_id,
    ft.active_student_dw_id,
    ft.course_id,
    ft.level_dw_id,
    ft.[month],
    ft.level_proficiency_tier,
    ft.skills_started,
    ft.skills_active,
    ft.skills_to_review,
    dcac.course_activity_container_domain     AS domain,
    dcac.course_activity_container_longname   AS level_name
FROM pathway_class_total_students pcts
LEFT JOIN students_placed sp
    ON sp.course_id          = pcts.class_material_id
   AND sp.placed_student_dw_id = pcts.pathway_student_dw_id
LEFT JOIN fact_table ft
    ON pcts.class_material_id    = ft.course_id
   AND pcts.pathway_student_dw_id = ft.started_student_dw_id
   AND ft.[month] BETWEEN DATETRUNC(month, pcts.academic_year_start_date)
                       AND DATETRUNC(month, pcts.academic_year_end_date)
LEFT JOIN ${RS_COREDW}.dim_course_activity_container dcac
    ON dcac.course_activity_container_dw_id    = ft.level_dw_id
   AND dcac.course_activity_container_status   = 1;