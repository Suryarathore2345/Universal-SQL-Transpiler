CREATE OR ALTER VIEW ${os_bi_coredw}.student_activity_military_py_view AS

/* Description
   This view is replicated from student_activity_py_view.sql. 
   It is created separately to handle the logic for Military Schools Absentee report as mentioned in following ticket
   https://coreeducation.atlassian.net/browse/CORE-37501
*/

SELECT DISTINCT
       cd.login_date_dw_id,
       cd.student_dw_id,
       cd.school_dw_id,
       cd.tenant_dw_id,
       CONVERT(DATETIME2, MIN(cd.local_login_time)) AS login_local_date_time,
       CONVERT(
           DATETIME2,
           MIN(cd.local_login_time)
               AT TIME ZONE ISNULL(cd.windows_timezone, 'UTC')
               AT TIME ZONE 'UTC'
       ) AS login_date_time
FROM (
         SELECT DISTINCT
                fsa.fsta_date_dw_id    AS login_date_dw_id,
                fsa.fsta_student_dw_id AS student_dw_id,
                fsa.fsta_tenant_dw_id  AS tenant_dw_id,
                fsa.fsta_school_dw_id  AS school_dw_id,
                CONVERT(
                    DATE,
                    fsa.fsta_start_time
                        AT TIME ZONE 'UTC'
                        AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
                ) AS local_login_date,
                MIN(
                    fsa.fsta_start_time
                        AT TIME ZONE 'UTC'
                        AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
                ) AS local_login_time,
                ds.windows_timezone
         FROM ${rs_coredw}.fact_student_activities AS fsa
         JOIN ${rs_bi_coredw}.bi_active_schools_dim AS ds
           ON fsa.fsta_school_dw_id = ds.school_dw_id
         WHERE ds.school_organisation = 'MHS'
           AND CONVERT(
                   TIME,
                   fsa.fsta_start_time
                       AT TIME ZONE 'UTC'
                       AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
               ) BETWEEN '07:00:00' AND '15:00:00'
         GROUP BY
             fsa.fsta_date_dw_id,
             fsa.fsta_student_dw_id,
             fsa.fsta_tenant_dw_id,
             fsa.fsta_school_dw_id,
             ds.windows_timezone,
             CONVERT(
                 DATE,
                 fsa.fsta_start_time
                     AT TIME ZONE 'UTC'
                     AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
             )

         UNION

         SELECT DISTINCT
                ful.ful_date_dw_id    AS login_date_dw_id,
                ful.ful_user_dw_id    AS student_dw_id,
                ful.ful_tenant_dw_id  AS tenant_dw_id,
                ful.ful_school_dw_id  AS school_dw_id,
                CONVERT(
                    DATE,
                    ful.ful_created_time
                        AT TIME ZONE 'UTC'
                        AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
                ) AS local_login_date,
                MIN(
                    ful.ful_created_time
                        AT TIME ZONE 'UTC'
                        AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
                ) AS local_login_time,
                ds.windows_timezone
         FROM ${rs_coredw}.fact_user_login AS ful
         JOIN ${rs_bi_coredw}.bi_active_schools_dim AS ds
           ON ful.ful_school_dw_id = ds.school_dw_id
         WHERE ful.ful_role_dw_id = 2
           AND ds.school_organisation = 'MHS'
           AND CONVERT(
                   TIME,
                   ful.ful_created_time
                       AT TIME ZONE 'UTC'
                       AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
               ) BETWEEN '07:00:00' AND '15:00:00'
         GROUP BY
             ful.ful_date_dw_id,
             ful.ful_user_dw_id,
             ful.ful_tenant_dw_id,
             ful.ful_school_dw_id,
             ds.windows_timezone,
             CONVERT(
                 DATE,
                 ful.ful_created_time
                     AT TIME ZONE 'UTC'
                     AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
             )

         UNION

         SELECT DISTINCT
                hbt.fuhha_date_dw_id   AS login_date_dw_id,
                hbt.fuhha_user_dw_id   AS student_dw_id,
                hbt.fuhha_tenant_dw_id AS tenant_dw_id,
                hbt.fuhha_school_dw_id AS school_dw_id,
                CONVERT(
                    DATE,
                    hbt.fuhha_created_time
                        AT TIME ZONE 'UTC'
                        AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
                ) AS local_login_date,
                MIN(
                    hbt.fuhha_created_time
                        AT TIME ZONE 'UTC'
                        AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
                ) AS local_login_time,
                ds.windows_timezone
         FROM ${rs_coredw}.fact_user_heartbeat_hourly_aggregated AS hbt
         JOIN ${rs_bi_coredw}.bi_active_schools_dim AS ds
           ON hbt.fuhha_school_dw_id = ds.school_dw_id
         WHERE hbt.fuhha_role_dw_id = 2
           AND ds.school_organisation = 'MHS'
           AND CONVERT(
                   TIME,
                   hbt.fuhha_created_time
                       AT TIME ZONE 'UTC'
                       AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
               ) BETWEEN '07:00:00' AND '15:00:00'
         GROUP BY
             hbt.fuhha_date_dw_id,
             hbt.fuhha_user_dw_id,
             hbt.fuhha_tenant_dw_id,
             hbt.fuhha_school_dw_id,
             ds.windows_timezone,
             CONVERT(
                 DATE,
                 hbt.fuhha_created_time
                     AT TIME ZONE 'UTC'
                     AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC') 
             )
     ) AS cd

GROUP BY
    cd.login_date_dw_id,
    cd.student_dw_id,
    cd.tenant_dw_id,
    cd.school_dw_id,
    cd.local_login_date,
    cd.windows_timezone;
