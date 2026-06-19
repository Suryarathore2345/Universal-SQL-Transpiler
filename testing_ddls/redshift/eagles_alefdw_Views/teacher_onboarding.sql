CREATE OR REPLACE VIEW eagles_alefdw.vw_teacher_onboarding
as
(
WITH total_teachers as (
    SELECT DISTINCT teacher_dw_id,
                    teacher_school_dw_id,
                    first_value(teacher_status)
                    OVER (PARTITION BY teacher_dw_id,teacher_school_dw_id
                        ORDER BY teacher_created_time DESC
                        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS teacher_status
    FROM alefdw.dim_teacher
    WHERE ((teacher_status = 2
                                AND
                                  trunc(sysdate) >= trunc(teacher_created_time)
                                AND
                                  trunc(sysdate) < trunc(teacher_active_until))
                                OR teacher_status = 1)),

     teacher_onboarding as (
         SELECT DISTINCT tl.teacher_dw_id,
                         ds.school_dw_id,
                         first_value(login_local_date_time)
                         OVER (
                             PARTITION BY tl.teacher_dw_id, ds.school_dw_id
                             ORDER BY tl.login_local_date_time
                             ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS teacher_first_login_date,
                         first_value(login_local_date_time)
                         OVER (
                             PARTITION BY tl.teacher_dw_id, ds.school_dw_id
                             ORDER BY tl.login_local_date_time DESC
                             ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS teacher_last_login_date
         FROM bi_alefdw.teacher_login tl
                  INNER JOIN bi_alefdw.bi_active_schools_dim_mv ds
                             ON ds.school_dw_id = tl.school_dw_id
                             AND trunc(login_local_date_time) >= ds.academic_year_start_date
     )
SELECT DISTINCT tch.teacher_dw_id,
                tch.teacher_school_dw_id as school_dw_id,
                tch.teacher_status,
                ton.teacher_first_login_date,
                ton.teacher_last_login_date
FROM total_teachers tch
         LEFT JOIN teacher_onboarding ton
                   ON tch.teacher_dw_id = ton.teacher_dw_id
                       AND tch.teacher_school_dw_id = ton.school_dw_id
    )
WITH NO SCHEMA BINDING;

grant delete, insert, references, select, trigger, update on eagles_alefdw.vw_teacher_onboarding to group business_intelligence;

grant delete, insert, references, select, trigger, update on eagles_alefdw.vw_teacher_onboarding to group datascience;

grant delete, insert, references, select, trigger, update on eagles_alefdw.vw_teacher_onboarding to group tdc;

grant select on eagles_alefdw.vw_teacher_onboarding to group ro_users;