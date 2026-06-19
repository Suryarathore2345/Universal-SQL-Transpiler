CREATE OR REPLACE VIEW bi_alefdw_dev.arabits_lesson_student_scores AS
select trunc(fle.fle_created_time)                              as datestamp,
       fle.fle_lo_dw_id,
       lo.lo_title,
       fle.fle_student_dw_id,
       st.student_id,
       dc.class_title,
       MAX(case when fle_lesson_type = 'PT' then fle_score end) as PT_score,
       MAX(case when fle_lesson_type = 'FT' then fle_score end) as FT_score
from (SELECT *
      FROM (SELECT *,
                   ROW_NUMBER() OVER (
                       PARTITION BY fle_lo_dw_id, fle_student_dw_id, fle_lesson_type
                       ORDER BY fle_score desc, fle_created_time desc
                       ) AS rank
            FROM alefdw.fact_learning_experience
            WHERE fle_lesson_type IN ('PT', 'FT')) sub
      WHERE sub.rank = 1) fle
         join bi_alefdw.bi_active_schools_dim_mv dsc
              ON fle_school_dw_id = dsc.school_dw_id
                AND trunc(fle_created_time) >= dsc.academic_year_start_date
                AND trunc(fle_created_time) <= dsc.academic_year_end_date
         join alefdw.dim_learning_objective lo
              ON lo.lo_dw_id = fle.fle_lo_dw_id
         join bi_alefdw.bi_student_dim_mv st
              ON st.student_dw_id = fle.fle_student_dw_id
         join alefdw.dim_class dc
              ON dc.class_dw_id = fle.fle_class_dw_id
                  AND dc.class_status = 1
                  AND dc.class_course_status = 'ACTIVE'
where fle_school_dw_id = 4225 --requirement is to include only this school
group by 1, 2, 3, 4, 5, 6
WITH NO SCHEMA BINDING;