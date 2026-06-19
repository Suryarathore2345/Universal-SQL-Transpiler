CREATE MATERIALIZED VIEW bi_alefdw_dev.fact_slide_progress_mv
AS
(
WITH class_total AS (SELECT DISTINCT dc.class_dw_id,
                                     dc.class_id,
                                     dcr.course_id                    AS course_id,
                                     sc.school_dw_id,
                                     sc.school_id,
                                     dc.class_school_id,
                                     initcap(dc.class_title)          AS class_title,
                                     initcap(dc.class_gen_subject)    AS class_gen_subject,
                                     count(DISTINCT ds.student_dw_id) AS class_total_students
                     FROM alefdw.dim_class dc
                              JOIN alefdw.dim_class_user dcu
                                   ON dcu.class_user_class_dw_id = dc.class_dw_id
                              JOIN bi_alefdw.bi_student_dim_mv ds ON ds.student_dw_id = dcu.class_user_user_dw_id
                              JOIN bi_alefdw.bi_active_schools_dim_mv sc
                                   ON md5(dc.class_school_id) = md5(sc.school_id)
                                       AND sc.school_dw_id = ds.student_school_dw_id
                              JOIN alefdw.dim_course dcr
                                   ON dcr.course_id = dc.class_material_id
                     WHERE dcu.class_user_status = 1
                       AND dcu.class_user_role_dw_id = 2
                       AND dcu.class_user_attach_status = 1
                       AND ds.student_status = 1
                       AND dcr.course_status = 1
                       AND dcr.course_type = 'CORE'
                       AND class_status = 1
                       AND class_course_status = 'ACTIVE'
                       AND dc.class_material_type <> 'PATHWAY'
                     GROUP BY 1, 2, 3, 4, 5, 6, 7, 8)
   , FACT_SLIDE_COMPLETED AS
    (
    SELECT DISTINCT TRUNC(CONVERT_TIMEZONE('UTC'
        , dsc.tenant_timezone
        , fssp.created_time))                                                        AS local_date
                   , fssp.activity_dw_id                                             AS fle_lo_dw_id
                   , fssp.student_dw_id                                              AS fle_student_dw_id
                   , fssp.student_id
                   , fssp.grade_id
                   , dg.grade_k12grade                                               AS grade_name
                   , fssp.class_dw_id
                   , dc.class_title
                   , dc.class_gen_subject
                   , fssp.school_dw_id
                   , fssp.tenant_dw_id
                   , fssp.material_id
                   , fssp.academic_year_tag
                   , fssp.learning_session_id                                        AS fle_ls_id
                   , fssp.content_section_dw_id
                   , fssp.content_section_id
                   , fssp.slide_id
                   , fssp.widget_id
                   , ct.class_total_students
                   , fssp.active_time                                                AS active_time_spent
                   , fssp.idle_time                                                  AS idle_time_spent
                   , fssp.total_time_spent                                           AS total_time_spent
                   , fssp.status                                                     AS slide_completion_status
                   , ROW_NUMBER()
                     OVER (PARTITION BY fssp.experience_id
                         , content_section_id , fssp.status
                         , slide_id, dst.student_id ORDER BY fssp.created_time DESC, fssp.attempt DESC, fssp.total_time_spent DESC,  dst.student_status ASC, result ASC) AS rnk
     FROM alefdw.fact_student_slide_progress fssp
              JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                   ON fssp.school_dw_id = dsc.school_dw_id
                       AND trunc(fssp.created_time) >= dsc.academic_year_start_date
                       AND trunc(fssp.created_time) <= dsc.academic_year_end_date
              JOIN class_total ct ON ct.class_dw_id = fssp.class_dw_id
         AND ct.school_id = dsc.school_id
              JOIN bi_alefdw.bi_student_dim_mv dst
                   ON dst.student_dw_id = fssp.student_dw_id
                       AND dsc.school_dw_id = dst.student_school_dw_id
              JOIN alefdw.dim_class_user dcu ON dcu.class_user_class_dw_id = fssp.class_dw_id
              JOIN alefdw.dim_class dc on dc.class_dw_id = fssp.class_dw_id
         AND dcu.class_user_user_dw_id = fssp.student_dw_id
              JOIN alefdw.dim_grade dg ON dg.grade_id = fssp.grade_id
              JOIN alefdw.dim_learning_objective lo
                   ON lo.lo_dw_id = fssp.activity_dw_id
     WHERE fssp.material_type = 'CORE'
       AND nvl(lo.lo_type
               , 'NA') <> 'EXPERIENTIAL_LESSON'
       AND lo.lo_status = 1
       AND dg.grade_status = 1
       AND dst.student_status = 1
       AND dc.class_status = 1
       AND dcu.class_user_status = 1
       AND dcu.class_user_attach_status = 1
       AND dc.class_course_status = 'ACTIVE'
       AND dc.class_material_type <> 'PATHWAY'
       AND fssp.experience_id <>'29064cdc-4a43-4c7f-9cff-cd19615daf3f')
select *
from FACT_SLIDE_COMPLETED
where rnk = 1
);