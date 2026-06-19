-------- ====== SUB SET FOR LESSON LEVEL INSIGHTS =======
CREATE MATERIALIZED VIEW bi_alefdw_dev.slide_progress_time_spent_mv
AS (
    WITH daily_time_spent_per_slide AS (SELECT    sl.local_date             AS local_date,
                                                  sl.fle_lo_dw_id,
                                                  sl.fle_student_dw_id,
                                                  sl.class_dw_id,
                                                  sl.school_dw_id,
                                                  sl.grade_id,
                                                  sl.grade_name,
                                                  sl.tenant_dw_id,
                                                  sl.slide_id,
                                                  sl.rnk,
                                                  sl.widget_id,
                                                  nvl(total_time_spent, 0)  as total_time_spent,
                                                  nvl(active_time_spent, 0) as active_time_spent,
                                                  nvl(idle_time_spent, 0)   as idle_time_spent
                                           FROM bi_alefdw.fact_slide_progress_mv sl
--                                            where rnk = 1
                                           ),

           daily_time_spent_per_student_per_activity as (select local_date,
                                                                 school_dw_id,
                                                                 class_dw_id,
                                                                 fle_student_dw_id,
                                                                 fle_lo_dw_id,
                                                                 grade_name,
                                                                 grade_id,
                                                                 tenant_dw_id,
                                                                 SUM(total_time_spent)  AS aggregated_total_timespent,
                                                                 SUM(active_time_spent) AS aggregated_active_timespent,
                                                                 SUM(idle_time_spent)   AS aggregated_idle_timespent
                                                          from daily_time_spent_per_slide
                                                          group by school_dw_id,
                                                                   class_dw_id,
                                                                   fle_student_dw_id,
                                                                   fle_lo_dw_id,
                                                                   grade_name,
                                                                   grade_id,
                                                                   tenant_dw_id,
                                                                   local_date),

           slides_completed_per_stud_per_lo as (select MAX(fsl.local_date)          as local_date,
                                                       fsl.fle_lo_dw_id,
                                                       fsl.fle_student_dw_id,
                                                       fsl.class_dw_id,
                                                       fsl.school_dw_id,
                                                       COUNT(DISTINCT fsl.slide_id) AS slides_completed_per_student
                                                from bi_alefdw.fact_slide_progress_mv fsl
                                                         join alefdw.dim_content_slide dcl
                                                              on dcl.id = fsl.slide_id
                                                                  AND dcl.status = 1
                                                GROUP BY fle_lo_dw_id,
                                                         class_dw_id,
                                                         fle_student_dw_id,
                                                         school_dw_id),
           slides_assigned_per_lo as (select activity_dw_id,
                                             count(distinct slide_id) as num_slides_per_lo
                                      from bi_alefdw.lo_structure_components_mv
                                      group by activity_dw_id),

           student_progress_per_lo as (select distinct pss.local_date,
                                                       fle_lo_dw_id,
                                                       fle_student_dw_id,
                                                       class_dw_id,
                                                       school_dw_id,
                                                       COALESCE((CASE
                                                                     WHEN max(pss.slides_completed_per_student) = MAX(num_slides_per_lo)
                                                                         THEN 'Completed'
                                                                     WHEN (max(pss.slides_completed_per_student) > 0 AND
                                                                           max(pss.slides_completed_per_student) <
                                                                           MAX(num_slides_per_lo))
                                                                         THEN 'In-Progress' END),
                                                                'NA') AS lesson_completion_status

                                       from slides_completed_per_stud_per_lo pss
                                                join slides_assigned_per_lo spl
                                                     on spl.activity_dw_id = pss.fle_lo_dw_id
                                       GROUP BY fle_lo_dw_id,
                                                fle_student_dw_id,
                                                class_dw_id,
                                                school_dw_id,
                                                pss.local_date),

           unique_students_finished_lo as (select pss.school_dw_id,
                                                  COALESCE(COUNT(DISTINCT CASE
                                                                              WHEN slides_completed_per_student = num_slides_per_lo
                                                                                  THEN fle_student_dw_id
                                                      END), 0) AS unique_students_finished

                                           from slides_completed_per_stud_per_lo pss
                                                    join slides_assigned_per_lo spl on spl.activity_dw_id = pss.fle_lo_dw_id
                                           group by pss.school_dw_id)

      SELECT wts.local_date,
             wts.fle_lo_dw_id,
             wts.fle_student_dw_id,
             wts.school_dw_id,
             wts.class_dw_id,
             wts.grade_id,
             wts.grade_name,
             wts.tenant_dw_id,
             wts.aggregated_active_timespent,
             wts.aggregated_idle_timespent,
             wts.aggregated_total_timespent,
             MAX(sapl.num_slides_per_lo)                as num_slides_per_lesson,
             max(scs.slides_completed_per_student) as slide_completed_by_student,
             sppl.lesson_completion_status,
             max(unique_students_finished)         as unique_students_completed_at_least_1_lo

      FROM daily_time_spent_per_student_per_activity wts

               JOIN slides_assigned_per_lo as sapl
                    on sapl.activity_dw_id = wts.fle_lo_dw_id

               JOIN slides_completed_per_stud_per_lo as scs
                    ON scs.fle_student_dw_id = wts.fle_student_dw_id
                        AND scs.fle_lo_dw_id = wts.fle_lo_dw_id
                        AND scs.class_dw_id = wts.class_dw_id

               INNER JOIN student_progress_per_lo sppl
                          ON sppl.fle_student_dw_id = wts.fle_student_dw_id
                              AND sppl.fle_lo_dw_id = wts.fle_lo_dw_id
                              and sppl.local_date = wts.local_date
               LEFT JOIN unique_students_finished_lo fle ON fle.school_dw_id = wts.school_dw_id
      GROUP BY wts.local_date,
               wts.fle_lo_dw_id,
               wts.fle_student_dw_id,
               wts.school_dw_id,
               wts.class_dw_id,
               wts.grade_id,
               wts.grade_name,
               wts.tenant_dw_id,
               sppl.lesson_completion_status,
               wts.aggregated_active_timespent,
               wts.aggregated_total_timespent,
               wts.aggregated_idle_timespent
      );