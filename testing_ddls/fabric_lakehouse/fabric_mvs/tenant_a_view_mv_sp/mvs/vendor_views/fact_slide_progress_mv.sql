CREATE or Replace MATERIALIZED LAKE VIEW {{os_bi_coredw}}.fact_slide_progress_mv
AS
WITH class_total AS (
    SELECT DISTINCT
        dc.class_dw_id,
        dc.class_id,
        dcr.course_id                    AS course_id,
        sc.school_dw_id,
        sc.school_id,
        dc.class_school_id,
        UPPER(dc.class_title)          AS class_title,
        UPPER(dc.class_gen_subject)    AS class_gen_subject,
        COUNT(DISTINCT ds.student_dw_id) AS class_total_students
    FROM {{rs_coredw}}.dim_class AS dc
    JOIN {{rs_coredw}}.dim_class_user AS dcu
        ON dcu.class_user_class_dw_id = dc.class_dw_id
    JOIN {{rs_bi_coredw}}.bi_student_dim AS ds
        ON ds.student_dw_id = dcu.class_user_user_dw_id
    JOIN {{rs_bi_coredw}}.bi_active_schools_dim AS sc
        ON dc.class_school_id = sc.school_id
       AND sc.school_dw_id = ds.student_school_dw_id
    JOIN {{rs_coredw}}.dim_course AS dcr
        ON dcr.course_id = dc.class_material_id
    WHERE dcu.class_user_status       = 1
      AND dcu.class_user_role_dw_id   = 2
      AND dcu.class_user_attach_status = 1
      AND ds.student_status           = 1
      AND dcr.course_status           = 1
      AND dcr.course_type             = 'CORE'
      AND dc.class_status             = 1
      AND dc.class_course_status      = 'ACTIVE'
      AND dc.class_material_type     <> 'PATHWAY'
    GROUP BY
        dc.class_dw_id,
        dc.class_id,
        dcr.course_id,
        sc.school_dw_id,
        sc.school_id,
        dc.class_school_id,
        dc.class_title,
        dc.class_gen_subject
),
FACT_SLIDE_COMPLETED AS (
    SELECT DISTINCT
        CAST(
            from_utc_timestamp(
                fssp.created_time,
                dsc.tenant_timezone
            ) AS DATE
        )                                           AS local_date,
        fssp.activity_dw_id                         AS fle_lo_dw_id,
        fssp.student_dw_id                          AS fle_student_dw_id,
        fssp.student_id,
        fssp.grade_id,
        dg.grade_k12grade                           AS grade_name,
        fssp.class_dw_id,
        dc.class_title,
        dc.class_gen_subject,
        fssp.school_dw_id,
        fssp.tenant_dw_id,
        fssp.material_id,
        fssp.academic_year_tag,
        fssp.learning_session_id                    AS fle_ls_id,
        fssp.content_section_dw_id,
        fssp.content_section_id,
        fssp.slide_id,
        fssp.widget_id,
        ct.class_total_students,
        fssp.active_time                            AS active_time_spent,
        fssp.idle_time                              AS idle_time_spent,
        fssp.total_time_spent                       AS total_time_spent,
        fssp.status                                 AS slide_completion_status,
        ROW_NUMBER() OVER (
            PARTITION BY
                fssp.experience_id,
                fssp.content_section_id,
                fssp.status,
                fssp.slide_id,
                dst.student_id
            ORDER BY
                fssp.created_time DESC, fssp.attempt DESC, fssp.total_time_spent DESC, dst.student_status ASC , result ASC
        )                                           AS rnk
    FROM {{rs_coredw}}.fact_student_slide_progress AS fssp
    JOIN {{rs_bi_coredw}}.bi_active_schools_dim AS dsc
        ON fssp.school_dw_id = dsc.school_dw_id
       AND CAST(fssp.created_time AS DATE) >= dsc.academic_year_start_date
       AND CAST(fssp.created_time AS DATE) <= dsc.academic_year_end_date
    JOIN class_total AS ct
        ON ct.class_dw_id = fssp.class_dw_id
       AND ct.school_id   = dsc.school_id
    JOIN {{rs_bi_coredw}}.bi_student_dim AS dst
        ON dst.student_dw_id = fssp.student_dw_id
       AND dsc.school_dw_id  = dst.student_school_dw_id
    JOIN {{rs_coredw}}.dim_class_user AS dcu
        ON dcu.class_user_class_dw_id = fssp.class_dw_id
    JOIN {{rs_coredw}}.dim_class AS dc
        ON dc.class_dw_id = fssp.class_dw_id
       AND dcu.class_user_user_dw_id = fssp.student_dw_id
    JOIN {{rs_coredw}}.dim_grade AS dg
        ON dg.grade_id = fssp.grade_id
    JOIN {{rs_coredw}}.dim_learning_objective AS lo
        ON lo.lo_dw_id = fssp.activity_dw_id
    WHERE fssp.material_type         = 'CORE'
      AND COALESCE(lo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
      AND lo.lo_status               = 1
      AND dg.grade_status            = 1
      AND dst.student_status         = 1
      AND dc.class_status            = 1
      AND dcu.class_user_status      = 1
      AND dcu.class_user_attach_status = 1
      AND dc.class_course_status     = 'ACTIVE'
      AND dc.class_material_type    <> 'PATHWAY'
      AND fssp.experience_id <>'29064cdc-4a43-4c7f-9cff-cd19615daf3f'
)
SELECT 
    local_date,
    fle_lo_dw_id,
    fle_student_dw_id,
    student_id,
    grade_id,
    grade_name,
    class_dw_id,
    class_title,
    class_gen_subject,
    school_dw_id,
    tenant_dw_id,
    material_id,
    academic_year_tag,
    fle_ls_id,
    content_section_dw_id,
    content_section_id,
    slide_id,
    widget_id,
    class_total_students,
    active_time_spent,
    idle_time_spent,
    total_time_spent,
    slide_completion_status,
    rnk
FROM FACT_SLIDE_COMPLETED
WHERE rnk = 1;