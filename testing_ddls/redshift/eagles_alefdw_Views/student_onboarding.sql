CREATE OR REPLACE VIEW eagles_alefdw_dev.vw_student_onboarding AS
(
WITH total_students AS
         (SELECT DISTINCT ds.student_school_dw_id,
                          ds.student_dw_id,
                          ds.student_id,
                          first_value(student_status)
                          OVER (PARTITION BY student_dw_id
                              ORDER BY student_created_time DESC, student_status ASC
                              ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS student_current_status

          FROM bi_alefdw.bi_student_dim_mv ds),

     student_onboarding AS (
        SELECT DISTINCT sl.student_dw_id,
                        ds.school_dw_id,
                        first_value(login_local_date_time) OVER (
                            PARTITION BY sl.student_dw_id ORDER BY login_local_date_time ASC rows BETWEEN unbounded preceding
                                AND unbounded following
                            ) AS student_first_login_date,
                        first_value(login_local_date_time) OVER (
                            PARTITION BY sl.student_dw_id ORDER BY login_local_date_time DESC rows BETWEEN unbounded preceding
                                AND unbounded following
                            ) AS student_last_login_date
        FROM bi_alefdw.student_login sl
                 INNER JOIN alefdw.dim_student st
                            ON sl.student_dw_id = st.student_dw_id
                                AND sl.school_dw_id = st.student_school_dw_id
                 INNER JOIN bi_alefdw.bi_active_schools_dim_mv ds
                            ON ds.school_dw_id = sl.school_dw_id
                            AND trunc(login_local_date_time) >= ds.academic_year_start_date
                            )

SELECT DISTINCT std.student_dw_id,
                std.student_id,
                std.student_school_dw_id as school_dw_id,
                sch.school_id,
                sch.school_name,
                std.student_current_status as student_status,
                son.student_first_login_date,
                son.student_last_login_date
FROM total_students std
INNER JOIN bi_alefdw.bi_active_schools_dim_mv    sch
         ON sch.school_dw_id = std.student_school_dw_id
         LEFT JOIN student_onboarding son
                   ON std.student_dw_id = son.student_dw_id
                       AND std.student_school_dw_id = son.school_dw_id
WHERE  std.student_current_status = 1
    )
WITH NO SCHEMA BINDING;

grant delete, insert, references, select, trigger, update on eagles_alefdw_dev.vw_student_onboarding to group business_intelligence;

grant delete, insert, references, select, trigger, update on eagles_alefdw_dev.vw_student_onboarding to group datascience;

grant delete, insert, references, select, trigger, update on eagles_alefdw_dev.vw_student_onboarding to group tdc;

grant select on eagles_alefdw_dev.vw_student_onboarding to group ro_users;