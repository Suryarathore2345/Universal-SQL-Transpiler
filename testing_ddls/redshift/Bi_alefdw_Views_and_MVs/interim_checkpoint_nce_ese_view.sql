
create or replace view bi_alefdw_dev.interim_checkpoint_nce_ese_view as
with class_db as (select class_dw_id,
                         class_gen_subject,
                         class_status,
                         row_number() over (partition by class_dw_id order by class_created_time desc) id
                  from alefdw.dim_class
                  where class_status = 1),
     school_grade_cnt as (select school_dw_id,
                                 grade                              AS grade_k12grade,
                                 max(school_name)                   AS school_name,
                                 max(school_organisation)           AS organisation_name,
                                 max(school_composition)            AS school_composition,
                                 max(org_dw_id)      AS organisation_dw_id,
                                 sum(total_students.total_students) AS total_student
                          from bi_alefdw.total_students
                          where local_date = trunc(sysdate) - 1
                            and org_dw_id = 17 -- NCE org code
                          group by school_dw_id, grade_k12grade),

     db as (select fle_student_dw_id,
                   school_dw_id,
                   class_gen_subject,
                   nvl(dtrm.actp_teaching_period_order, 1) AS term_academic_period_order,
                   grade_k12grade,
                   avg(fle_score)                          AS fle_score,
                   date_part(year, dsc.academic_year_start_date) || '-' ||
                   date_part(year, dsc.academic_year_end_date) AS academic_year
            from alefdw.fact_learning_experience
                     inner join bi_alefdw.bi_student_dim_mv on fle_student_dw_id = student_dw_id
                     inner join bi_alefdw.bi_active_schools_dim_mv dsc on student_school_dw_id = dsc.school_dw_id
                     inner join alefdw.dim_grade g
                         on student_grade_dw_id = g.grade_dw_id
                         and dsc.academic_year_id = g.academic_year_id
                     inner join class_db on fle_class_dw_id = class_dw_id and id = 1

                     LEFT JOIN alefdw.dim_pacing_guide dpg
                            ON class_db.class_dw_id = dpg.pacing_class_dw_id
                            AND fle_lo_dw_id = dpg.pacing_activity_dw_id
                            AND dpg.pacing_status = 1
                    LEFT JOIN alefdw.dim_academic_calendar_teaching_period dtrm
                            ON md5(dpg.pacing_period_id) = md5(dtrm.actp_teaching_period_id)
                            AND dtrm.actp_status = 1
            where student_status = 1
              and organisation_dw_id = 17 -- NCE org code
              and fle_lesson_category = 'INTERIM_CHECKPOINT'
              and grade_status = 1
              and fle_lesson_type = 'SA'
            group by fle_student_dw_id, school_dw_id, class_gen_subject, nvl(dtrm.actp_teaching_period_order, 1), grade_k12grade,
                     academic_year_start_date, academic_year_end_date),

     db_1 as (select fle_student_dw_id,
                     db.grade_k12grade,
                     class_gen_subject,
                     school_name,
                     school_composition,
                     organisation_name,
                     term_academic_period_order,
                     fle_score,
                     academic_year,
                     total_student
              from db
                       inner join school_grade_cnt sgc on db.school_dw_id = sgc.school_dw_id
                  and db.grade_k12grade = sgc.grade_k12grade)

select *
from db_1

union all

select *
from bi_alefdw.interim_checkpint_test_nce_ese_prev_year

with no schema binding;