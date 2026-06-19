-- For previous year, if there is big structure/data change run the creation script: SQL/DDLs/nce_ese_lo_mastery_prev_year.sql

create or replace view bi_alefdw_dev.nce_ese_lo_mastery_view AS
with class_db as (select class_dw_id,
                         class_gen_subject,
                         class_status,
                         row_number() over (partition by class_dw_id order by class_created_time desc ) id
                  from alefdw.dim_class
                  where class_status = 1),

     db as (select fle_student_dw_id,
                   lower(trim(lo_title))                    AS lo_title,
                   lo_id,
                   max(dsc.school_name)                    AS school_name,
                   max(dg.grade_k12grade)                  AS curr_grade_name,
                   max(school_composition)                 AS school_composition,
                   max(class_gen_subject)                  AS subject,
                   max(school_city_name)                   AS school_city_name,
                   avg(fle_score)                          AS score,
                   max(school_organisation)                AS organisation_name,
                   date_part(year, dsc.academic_year_start_date) || '-' ||
                   date_part(year, dsc.academic_year_end_date) AS academic_year
            from alefdw.fact_learning_experience
                     inner join bi_alefdw.bi_student_dim_mv on fle_student_dw_id = student_dw_id
                     left join class_db on fle_class_dw_id = class_dw_id
                     inner join bi_alefdw.bi_active_schools_dim_mv dsc on student_school_dw_id = dsc.school_dw_id
                     inner join alefdw.dim_grade dg
                         on student_grade_dw_id = dg.grade_dw_id
                         and md5(dsc.academic_year_id) = md5(dg.academic_year_id)
                     left join alefdw.dim_learning_objective on fle_lo_dw_id = lo_dw_id
            where fle_lesson_category = 'INSTRUCTIONAL_LESSON'
              and fle_lesson_type = 'SA'
              and organisation_dw_id = 17 -- NCE content repository code
              and grade_status = 1
              and student_status = 1
            group by fle_student_dw_id, lower(trim(lo_title)), lo_id, academic_year_start_date, academic_year_end_date)

select school_name,
       fle_student_dw_id,
       academic_year,
       school_composition,
       school_city_name,
       subject,
       lo_title,
       organisation_name,
       curr_grade_name,
       score fle_score
from db

union all

select *
from bi_alefdw.nce_ese_lo_mastery_prev_year

with no schema binding;