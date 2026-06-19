------===== DATA MART FOR SLIDE INSLIGHTS   =======----
create materialized view bi_alefdw_dev.slide_type_completion_progress_mv as
(
with fact_progress_per_slide as (select date_trunc('week', local_date) AS local_week,
                                        class_dw_id,
                                        school_dw_id,
                                        grade_name,
                                        tenant_dw_id,
                                        fle_lo_dw_id,
                                        fle_student_dw_id,
                                        slide_id,
                                        widget_id,
                                        max(idle_time_spent)           as idle_time_per_slide,
                                        max(active_time_spent)         as active_time_per_slide,
                                        max(total_time_spent)          as total_time_per_slide,
                                        MAX(class_total_students)      AS class_total_students
                                 from bi_alefdw.fact_slide_progress_mv
                                 group by class_dw_id,
                                          school_dw_id,
                                          grade_name,
                                          tenant_dw_id,
                                          fle_lo_dw_id,
                                          fle_student_dw_id,
                                          slide_id,
                                          widget_id,
                                          date_trunc('week', local_date)),
     student_progress_per_slide as (select local_week,
                                           class_dw_id,
                                           school_dw_id,
                                           tenant_dw_id,
                                           widget_id,
                                           slide_id,
                                           grade_name,
                                           SUM(idle_time_per_slide)                                       as sum_idle_time_per_slide,
                                           SUM(active_time_per_slide)                                     as sum_active_time_per_slide,
                                           SUM(total_time_per_slide)                                      as sum_total_time_per_slide,
                                           COUNT(DISTINCT fle_student_dw_id)                              as total_students_per_slide,
                                           SUM(idle_time_per_slide) / count(distinct fle_student_dw_id)   as avg_idle_time_per_slide,
                                           SUM(active_time_per_slide) / count(distinct fle_student_dw_id) as avg_active_time_per_slide,
                                           SUM(total_time_per_slide) / count(distinct fle_student_dw_id)  as avg_total_time_per_slide
                                    from fact_progress_per_slide
                                    group by class_dw_id,
                                             widget_id,
                                             grade_name,
                                             school_dw_id,
                                             tenant_dw_id,
                                             slide_id,
                                             local_week),
     unique_attempts_per_widget_type as ((SELECT date_trunc('week', local_date)               as local_week,
                                                 fsl.school_dw_id,
                                                 fsl.class_dw_id,
                                                 fsl.tenant_dw_id,
                                                 fsl.grade_name,
                                                 fsl.class_gen_subject,
                                                 fsl.class_title,
                                                 fsl.widget_id,
                                                 count(DISTINCT concat(slide_id, student_id)) AS slide_student_attempts
                                          FROM bi_alefdw.fact_slide_progress_mv fsl
                                          GROUP BY date_trunc('week', local_date),
                                                   fsl.school_dw_id,
                                                   fsl.class_dw_id,
                                                   fsl.class_title,
                                                   fsl.class_gen_subject,
                                                   fsl.tenant_dw_id,
                                                   fsl.grade_name,
                                                   fsl.class_gen_subject,
                                                   fsl.class_title,
                                                   fsl.widget_id)),

     time_spent_per_slide as (select local_week,
                                     class_dw_id,
                                     school_dw_id,
                                     tenant_dw_id,
                                     grade_name,
                                     widget_id,
                                     sum(sum_idle_time_per_slide)   as total_idle_time_per_slide,
                                     sum(sum_active_time_per_slide) as total_active_time_per_slide,
                                     sum(sum_total_time_per_slide)  as total_total_time_per_slide,
                                     count(distinct slide_id)       as total_slides_used_per_slide_type,
                                     avg(avg_idle_time_per_slide)   as avg_idle_time_per_slide,
                                     avg(avg_active_time_per_slide) as avg_active_time_per_slide,
                                     avg(avg_total_time_per_slide)  as avg_total_time_per_slide
                              from student_progress_per_slide spps
                              group by class_dw_id,
                                       school_dw_id,
                                       tenant_dw_id,
                                       widget_id,
                                       grade_name,
                                       local_week)

SELECT trunc(tsps.local_week) AS local_week,
       dsc.tenant_name,
       dsc.school_organisation,
       dsc.school_name,
       tsps.tenant_dw_id,
       tsps.school_dw_id,
       tsps.class_dw_id,
       tsps.widget_id,
       tsps.grade_name,
       dc.class_gen_subject   AS class_subject,
       dc.class_title,
       tsps.total_slides_used_per_slide_type,
       tsps.total_total_time_per_slide,
       tsps.total_idle_time_per_slide,
       tsps.total_active_time_per_slide,
       tsps.avg_total_time_per_slide,
       tsps.avg_idle_time_per_slide,
       tsps.avg_active_time_per_slide,
       ust.slide_student_attempts
FROM time_spent_per_slide tsps
         JOIN bi_alefdw.bi_active_schools_dim_mv dsc
              ON dsc.school_dw_id = tsps.school_dw_id
         JOIN alefdw.dim_class dc ON dc.class_dw_id = tsps.class_dw_id
    AND dc.class_status = 1
         JOIN unique_attempts_per_widget_type ust
              ON ust.grade_name = tsps.grade_name
                  AND ust.school_dw_id = tsps.school_dw_id
                  AND ust.tenant_dw_id = tsps.tenant_dw_id
                  AND ust.widget_id = tsps.widget_id
                  AND ust.class_dw_id = tsps.class_dw_id
                  AND ust.local_week = tsps.local_week
    );