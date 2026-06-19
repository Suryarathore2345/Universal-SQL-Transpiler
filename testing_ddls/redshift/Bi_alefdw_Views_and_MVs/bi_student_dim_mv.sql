create materialized view bi_alefdw.bi_student_dim_mv as
with student_curr_info as
         (select distinct student_dw_id, student_tags, student_special_needs, student_first_created_date
          from (select student_dw_id,
                       CASE
                           WHEN NVL(trim(student_tags), '') <> 'AlefStars' AND
                                NVL(trim(student_tags), '') <> 'Elite' AND
                                NVL(trim(student_tags), '') <> 'Elite, AlefStars'
                               THEN 'Non Elite'
                           ELSE trim(student_tags)
                           END                                                       AS      student_tags,
                       CASE
                           WHEN NVL(trim(student_special_needs), 'n/a') <> 'n/a'
                               THEN 'Yes'
                           ELSE 'No'
                           END                                                       AS      student_special_needs,
                       first_value(
                       trunc(trunc(convert_timezone('UTC', ds.school_timezone, student_created_time))))
                       OVER (
                           PARTITION BY student_dw_id
                           ORDER BY student_created_time
                           ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS      student_first_created_date,
                       row_number()
                       over (partition by student_dw_id order by student_created_time desc ) rnk
                from alefdw.dim_student dst
                         inner join alefdw.dim_school ds on dst.student_school_dw_id = ds.school_dw_id
               )
          where rnk = 1
         )

SELECT DISTINCT sci.student_dw_id,
                student_id,
                student_username,
                student_school_dw_id,
                student_section_dw_id,
                student_grade_dw_id,
                student_created_time,
                student_active_until,
                student_status,
                sci.student_tags,
                sci.student_special_needs,
                sci.student_first_created_date
FROM alefdw.dim_student ds
         inner join student_curr_info sci
                    on ds.student_dw_id = sci.student_dw_id;
