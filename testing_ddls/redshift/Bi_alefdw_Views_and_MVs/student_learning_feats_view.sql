-- CREATING THIS VIEW TO REPLACE A CUSTOM DATA SOURCE FOR NCE OVERVIEW REPORT.
CREATE OR REPLACE VIEW bi_alefdw_dev.student_learning_feats_view AS

with  class_db as (select class_dw_id,
                         class_gen_subject,
                         class_status,
                         row_number() over (partition by class_dw_id order by class_created_time desc) id
                  from alefdw.dim_class),

     db as (select *
            from alefdw.fact_learning_experience
                   join alefdw.dim_student on fle_student_dw_id = student_dw_id
                   join bi_alefdw.bi_active_schools_dim_mv on student_school_dw_id = school_dw_id
                   join alefdw.dim_grade on student_grade_dw_id = grade_dw_id
                   join class_db on fle_class_dw_id = class_dw_id and id = 1
                   left join alefdw.dim_interim_checkpoint on fle_lo_dw_id = ic_dw_id
            where fle_date_dw_id >= 20220901
              and student_status = 1
              and grade_status = 1
              and class_status = 1
              and fle_lesson_category in ('INSTRUCTIONAL_LESSON', 'INTERIM_CHECKPOINT')
              and organisation_dw_id in (17)
              and fle_material_type != 'PATHWAY'
     )

select fle_student_dw_id, class_gen_subject, grade_k12grade,
                                  max(school_name) school_name,
                                  max(school_organisation) school_organization,
                                  max(school_composition) school_composition,
                                  max(school_city_name) school_city_name,
                         count(distinct ic_title) no_interim,
                         count(distinct fle_lo_dw_id) no_mlo_completed,
                         avg(case when fle_lesson_category = 'INTERIM_CHECKPOINT' then fle_score end) interim_score,
                         avg(case when fle_lesson_category = 'INSTRUCTIONAL_LESSON' then fle_score end) formative_score
       from db
where fle_lesson_type = 'SA'
group by fle_student_dw_id, grade_k12grade, class_gen_subject
WITH NO SCHEMA BINDING;