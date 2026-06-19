CREATE OR REPLACE VIEW bi_alefdw_dev.teacher_score_idn_report_view AS
(
WITH holidays_dimension AS (SELECT DISTINCT cast(holiday_date AS DATE) AS holiday_date
                                          , holiday_organisation_dw_id
                            FROM alefdw.dim_holiday),
     class_teachers AS (SELECT dc.class_dw_id
                             , teacher_dw_id
                             , listagg(DISTINCT teacher_id, ',') WITHIN
             GROUP (
             ORDER BY class_user_created_time
             ) AS teacher_ids
                        FROM alefdw.dim_class dc
                                 JOIN alefdw.dim_class_user dcu ON dcu.class_user_class_dw_id = dc.class_dw_id
                                 LEFT JOIN alefdw.dim_teacher dt ON dcu.class_user_user_dw_id = dt.teacher_dw_id
                            AND dt.teacher_status = 1
                        WHERE class_status = 1
                          AND dcu.class_user_role_dw_id = 1
                          AND class_course_status = 'ACTIVE'
                          AND class_user_status = 1
                        GROUP BY 1, 2),
     active_teachers AS (SELECT temp_tab.*,
                                CAST(date_trunc('month', login_date) as date) as login_start_month,
                                CASE
                                    WHEN start_ay_flag = 1 then DATEDIFF('day', academic_year_start_date,
                                                                         LAST_DAY(academic_year_start_date))+1
                                    WHEN end_ay_flag = 1 then DATEDIFF('day', date_trunc('month', academic_year_end_date),
                                                                       LAST_DAY(academic_year_end_date))+1
                                    ELSE EXTRACT(DAY FROM LAST_DAY(login_date))
                                    END                                       as total_days_in_month,
                                CASE
                                    WHEN start_ay_flag = 1 then
                                        (DATEDIFF('day', academic_year_start_date, LAST_DAY(academic_year_start_date)))+1
                                            - (DATEDIFF('week', academic_year_start_date,
                                                        LAST_DAY(academic_year_start_date)) * 2)
                                            - (CASE WHEN DATE_PART(dow, academic_year_start_date) = 0 THEN 1 ELSE 0 END)
                                            - (CASE
                                                   WHEN DATE_PART(dow, LAST_DAY(academic_year_start_date)) = 6 THEN 1
                                                   ELSE 0 END)
                                     WHEN end_ay_flag = 1 then
                                        (DATEDIFF('day', date_trunc('month', academic_year_end_date), academic_year_end_date))+1
                                            -
                                        (DATEDIFF('week', date_trunc('month', academic_year_end_date), academic_year_end_date) * 2)
                                            - (CASE WHEN DATE_PART(dow, academic_year_end_date) = 0 THEN 1 ELSE 0 END)
                                            - (CASE
                                                   WHEN DATE_PART(dow, LAST_DAY(academic_year_end_date)) = 6 THEN 1
                                                   ELSE 0 END)
                                    ELSE (DATEDIFF('day', date_trunc('month', login_date), LAST_DAY(login_date)))+1
                                        -  (DATEDIFF('week', date_trunc('month', login_date), LAST_DAY(login_date)) * 2)
                                        - (CASE WHEN DATE_PART(dow, login_date) = 0 THEN 1 ELSE 0 END)
                                        - (CASE WHEN DATE_PART(dow, login_date) = 6 THEN 1 ELSE 0 END)
                                    END                                       as business_days
                         FROM (SELECT DISTINCT trunc(login_local_date_time)                AS login_date
                                             , dt.teacher_id
                                             , dt.teacher_status
                                             , tl.teacher_dw_id                            AS active_teacher_dw_id
                                             , dt.teacher_dw_id                            AS available_teacher_dw_id
                                             , dsc.organisation_dw_id
                                             , dsc.school_organisation
                                             , dsc.school_city_name
                                             , dsc.school_name
                                             , dsc.school_country_name
                                             , dsc.school_id
                                             , dsc.school_dw_id
                                             , dsc.school_label
                                             , dsc.tenant_name
                                             , dsc.academic_year_start_date
                                             , dsc.academic_year_end_date
                                             , CASE
                                                   WHEN
                                                        date_trunc('month',dsc.academic_year_start_date) =
                                                        date_trunc('month',login_local_date_time)
                                                       THEN 1 -- Flag for same month
                                                   ELSE 0 -- Flag for different month
                                 END                                                       AS start_ay_flag
                                             , CASE
                                                   WHEN
                                                   date_trunc('month',dsc.academic_year_end_date) =
                                                        date_trunc('month',login_local_date_time)
                                                       THEN 1 -- Flag for same month
                                                   ELSE 0 -- Flag for different month
                                 END                                                       AS end_ay_flag
                                             , date_part(year, dsc.academic_year_start_date) || '-' ||
                                               date_part(year, dsc.academic_year_end_date) AS academic_year
                               FROM bi_alefdw.teacher_login tl
                                        INNER JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                                                   ON dsc.school_dw_id = tl.school_dw_id
                                        INNER JOIN alefdw.dim_teacher dt ON dt.teacher_dw_id = tl.teacher_dw_id
                                        LEFT JOIN holidays_dimension dh
                                                  ON dh.holiday_date = trunc(tl.login_local_date_time)
                                                      AND holiday_organisation_dw_id = dsc.organisation_dw_id
                               WHERE trunc(tl.login_local_date_time) BETWEEN dsc.academic_year_start_date
                                   AND dsc.academic_year_end_date
                                 AND dsc.tenant_name = 'idn'
                                 AND (
                                   (
                                       teacher_status = 2
                                           AND trunc(tl.login_local_date_time) >=
                                               trunc(convert_timezone('UTC', dsc.tenant_timezone,
                                                                      dt.teacher_created_time))
                                           AND trunc(tl.login_local_date_time) <
                                               trunc(convert_timezone('UTC', dsc.tenant_timezone,
                                                                      dt.teacher_active_until))
                                       )
                                       OR
                                   (
                                       teacher_status = 1
                                           AND trunc(tl.login_local_date_time) >=
                                               trunc(convert_timezone('UTC', dsc.tenant_timezone,
                                                                      dt.teacher_created_time))
                                       )
                                   )
                                 AND dh.holiday_date IS NULL
                                 AND EXTRACT(dow FROM tl.login_local_date_time) NOT IN (0, 6)
                                 AND dt.teacher_id NOT IN
                                     (SELECT DISTINCT teacher_id FROM bi_alefdw.exclude_teacher_id)) temp_tab),
     date_dimension AS (SELECT DISTINCT calendar_month_start_date as month_start_date
                        FROM alefdw.dim_date dt
                        WHERE dt.full_date >= Trunc(sysdate) - 365
                          AND dt.full_date <= Trunc(sysdate)),
     min_max_date AS (Select min(month_start_date) as start_date,
                             max(month_start_date) as end_date
                      from date_dimension),
     active_students AS (select distinct date_trunc('month',
                                                    convert_timezone('UTC', dt.tenant_timezone, fsta.fsta_start_time)) as month_start_date,
                                         fsta_school_dw_id,
                                         fsta_grade_dw_id,
                                         dcu.class_user_class_dw_id                                                    as class_dw_id,
                                         fsta_section_dw_id,
                                         count(distinct fsta_student_dw_id)                                            as monthly_active
                         FROM alefdw.fact_student_activities fsta
                                  JOIN alefdw.dim_tenant dt
                                       on fsta.fsta_tenant_dw_id = dt.tenant_dw_id
                                  LEFT JOIN alefdw.dim_class_user dcu
                                            ON dcu.class_user_user_dw_id = fsta.fsta_student_dw_id
                                  LEFT JOIN alefdw.dim_class dc on dcu.class_user_class_dw_id = dc.class_dw_id
                         WHERE split_part(fsta_object_id, '/', 5)
                             IN (select distinct lo_id
                                 from alefdw.dim_learning_objective)
                           AND tenant_name = 'idn'
                           AND class_user_role_dw_id = 2
                           AND dc.class_status = 1
                           AND dc.class_course_status = 'ACTIVE'
                           AND date_trunc('month',
                                          convert_timezone('UTC', dt.tenant_timezone, fsta.fsta_start_time)) between (select start_date from min_max_date)
                             and (select end_date from min_max_date)
                           AND date_trunc('month',
                                          convert_timezone('UTC', dt.tenant_timezone, fsta.fsta_start_time)) >=
                               dcu.class_user_created_time
                         group by 1, 2, 3, 4, 5),
     total_in_curriculum AS
         (SELECT month_start_date,
                 sc.tenant_name,
                 sc.school_organisation,
                 sc.school_dw_id,
                 sc.school_name,
                 dg.grade_dw_id,
                 dg.grade_name,
                 dc.class_dw_id,
                 date_part(year, sc.academic_year_start_date) || '-' ||
                 date_part(year, sc.academic_year_end_date) AS academic_year,
                 NVL(dse.section_dw_id, '10001')            as section_dw_id,
                 initcap(NVL(dse.section_name, 'NA'))       as section_name,
                 count(DISTINCT ds.student_dw_id)           AS class_total_students
          FROM alefdw.dim_class dc
                   JOIN alefdw.dim_class_user dcu
                        on dcu.class_user_class_dw_id = dc.class_dw_id
                   JOIN bi_alefdw.bi_active_schools_dim_mv sc
                        ON md5(dc.class_school_id) = md5(sc.school_id)
                            AND md5(dc.class_academic_year_id) = md5(sc.academic_year_id)
                   LEFT JOIN bi_alefdw.bi_student_dim_mv ds
                             ON dcu.class_user_user_dw_id = ds.student_dw_id
                                 AND sc.school_dw_id = ds.student_school_dw_id
                   JOIN alefdw.dim_grade dg on dg.grade_dw_id = ds.student_grade_dw_id
                   LEFT JOIN alefdw.dim_section dse
                             on dse.section_dw_id = ds.student_section_dw_id
                   CROSS JOIN date_dimension dd
          WHERE (
              ((ds.student_status = 2
                  AND dd.month_start_date >= date_trunc('month', ds.student_created_time)
                  AND dd.month_start_date < date_trunc('month', ds.student_active_until))
                  OR (ds.student_status = 1 AND dd.month_start_date >=
                                                date_trunc('month', ds.student_created_time))) --if the student is active i.e status = 1 then count him active till date else count him active till his active until date
                  AND ((dcu.class_user_attach_status =
                        2 -- is the user is unenrolled count him till his active until date else count him till date
                  AND dd.month_start_date >= date_trunc('month', class_user_created_time)
                  AND dd.month_start_date < date_trunc('month', class_user_active_until))
                  OR (dcu.class_user_attach_status = 1 AND
                      dd.month_start_date >= date_trunc('month', class_user_created_time))
                  OR (dcu.class_user_attach_status = 2 AND
                      date_trunc('month', class_user_active_until) is null)
                  )
              )
            AND class_user_role_dw_id = 2
            AND dc.class_status = 1
            AND dc.class_course_status = 'ACTIVE'
            AND sc.tenant_name = 'idn'
          GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11),
     monthly_students_data as (SELECT DISTINCT tc.month_start_date,
                                               tc.academic_year,
                                               tc.school_name,
                                               tc.school_organisation,
                                               tc.school_dw_id,
                                               tc.grade_name,
                                               tc.grade_dw_id,
                                               tc.section_dw_id,
                                               tc.section_name,
                                               tc.tenant_name,
                                               tc.class_dw_id,
                                               ct.teacher_dw_id,
                                               ct.teacher_ids,
                                               ac.monthly_active,
                                               tc.class_total_students
                               FROM total_in_curriculum tc
                                        LEFT JOIN active_students ac
                                                  ON tc.school_dw_id = ac.fsta_school_dw_id
                                                      AND tc.section_dw_id = ac.fsta_section_dw_id
                                                      AND tc.grade_dw_id = ac.fsta_grade_dw_id
                                                      AND tc.month_start_date = ac.month_start_date
                                                      AND tc.class_dw_id = ac.class_dw_id
                                        LEFT JOIN CLASS_TEACHERS ct ON ct.class_dw_id = tc.class_dw_id),
     teacher_login_stats as (SELECT login_start_month,
                                    teacher_id,
                                    active_teacher_dw_id,
                                    available_teacher_dw_id,
                                    teacher_status,
                                    organisation_dw_id,
                                    school_organisation,
                                    school_city_name,
                                    school_name,
                                    school_country_name,
                                    school_id,
                                    school_dw_id,
                                    school_label,
                                    tenant_name,
                                    academic_year,
                                    count(active_teacher_dw_id)                                                as teacher_logins,
                                    max(business_days)                                                         as business_days_total,
                                    round(100.0 * count(active_teacher_dw_id) / max(nvl(business_days, 0)),
                                          2)                                                                   as login_percentage_per_teacher
                             from active_teachers
                             group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
SELECT temp.*
from (SELECT act.login_start_month,
             act.teacher_id,
             act.active_teacher_dw_id,
             act.available_teacher_dw_id,
             act.teacher_status,
             act.organisation_dw_id,
             act.school_organisation,
             act.school_city_name,
             act.school_name,
             act.school_country_name,
             act.school_id,
             act.school_dw_id,
             act.school_label,
             act.tenant_name,
             login_percentage_per_teacher,
             teacher_logins,
             business_days_total           as business_days,
             sum(mst.monthly_active)       as total_active_students,
             sum(mst.class_total_students) as total_students,
             count(distinct class_dw_id)   as total_classes,
             count(distinct section_name)  as total_sections,
             count(distinct grade_name)    as total_grades
      FROM teacher_login_stats act
               LEFT JOIN monthly_students_data mst
                         ON act.login_start_month = mst.month_start_date
                             AND act.teacher_id = mst.teacher_ids
                             AND act.school_dw_id = mst.school_dw_id
                             AND act.academic_year = mst.academic_year
      group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17) temp
where login_start_month <> DATE_TRUNC('MONTH', CURRENT_DATE)
    )
WITH NO SCHEMA BINDING;
