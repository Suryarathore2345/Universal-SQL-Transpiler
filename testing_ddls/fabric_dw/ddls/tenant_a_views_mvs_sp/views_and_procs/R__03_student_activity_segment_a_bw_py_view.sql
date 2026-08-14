CREATE OR ALTER VIEW ${os_bi_coredw}.student_activity_military_bw_py_view AS

/* Description
   This view is replicated from student_activity_bw_py_view.sql. 
   It is created separately to handle the logic for Military Schools Absentee report as mentioned in following ticket
   https://coreeducation.atlassian.net/browse/CORE-37501
*/

SELECT DISTINCT 
       login_date_dw_id,
       student_dw_id,
       school_dw_id,
       conjugated_Data.tenant_dw_id,
        CONVERT(
            DATETIMEOFFSET,
            MIN(local_login_time)
        ) AT TIME ZONE 'UTC' AS login_local_date_time,
        MIN(local_login_time) AT TIME ZONE 'UTC' AS login_date_time

FROM (
    /* ----------------------------------------------------
       From fact_student_activities
    ---------------------------------------------------- */
    SELECT DISTINCT 
           fsa.fsta_date_dw_id    AS login_date_dw_id,
           fsa.fsta_student_dw_id AS student_dw_id,
           fsa.fsta_tenant_dw_id  AS tenant_dw_id,
           fsa.fsta_school_dw_id  AS school_dw_id,

           CONVERT(
               DATE,
               MIN(
                   fsa.fsta_start_time
                       AT TIME ZONE 'UTC'
                       AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
               )
           ) AS local_login_date,

           CONVERT(
               DATETIME2,
               MIN(
                   fsa.fsta_start_time
                       AT TIME ZONE 'UTC'
                       AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
               )
           ) AS local_login_time

    FROM ${rs_coredw}.fact_student_activities fsa
    JOIN ${rs_bi_coredw}.bi_active_schools_dim ds
        ON fsa.fsta_school_dw_id = ds.school_dw_id

    WHERE ds.school_organisation = 'MHS'
      AND FORMAT(
              fsa.fsta_start_time
                  AT TIME ZONE 'UTC'
                  AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC'),
              'HH:mm:ss'
          ) BETWEEN '07:00:00' AND '15:00:00'
      AND fsa.fsta_dw_created_time >= CONVERT(DATETIME2, DATEADD(DAY, -15, CONVERT(DATE, GETDATE())))
      AND fsa.fsta_dw_created_time <  DATEADD(DAY, 1, CONVERT(DATETIME2, CONVERT(DATE, GETDATE())))

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

    /* ----------------------------------------------------
       From fact_user_login
    ---------------------------------------------------- */
    SELECT DISTINCT 
           ful.ful_date_dw_id    AS login_date_dw_id,
           ful.ful_user_dw_id    AS student_dw_id,
           ful.ful_tenant_dw_id  AS tenant_dw_id,
           ful.ful_school_dw_id  AS school_dw_id,

           CONVERT(
               DATE,
               MIN(
                   ful.ful_created_time
                       AT TIME ZONE 'UTC'
                       AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
               )
           ) AS local_login_date,

           CONVERT(
               DATETIME2,
               MIN(
                   ful.ful_created_time
                       AT TIME ZONE 'UTC'
                       AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
               )
           ) AS local_login_time

    FROM ${rs_coredw}.fact_user_login ful
    JOIN ${rs_bi_coredw}.bi_active_schools_dim ds
        ON ful.ful_school_dw_id = ds.school_dw_id

    WHERE ful.ful_role_dw_id = 2
      AND ds.school_organisation = 'MHS'
      AND FORMAT(
              ful.ful_created_time
                  AT TIME ZONE 'UTC'
                  AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC'),
              'HH:mm:ss'
          ) BETWEEN '07:00:00' AND '15:00:00'
      AND CONVERT(DATE, ful.ful_dw_created_time)
          BETWEEN DATEADD(DAY, -15, CONVERT(DATE, GETDATE()))
              AND CONVERT(DATE, GETDATE())
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

    /* ----------------------------------------------------
       From fact_user_heartbeat_hourly_aggregated
    ---------------------------------------------------- */
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

           CONVERT(
               DATETIME2,
               MIN(
                   hbt.fuhha_created_time
                       AT TIME ZONE 'UTC'
                       AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
               )
           ) AS local_login_time

    FROM ${rs_coredw}.fact_user_heartbeat_hourly_aggregated hbt
    JOIN ${rs_bi_coredw}.bi_active_schools_dim ds
        ON hbt.fuhha_school_dw_id = ds.school_dw_id

    WHERE fuhha_role_dw_id = 2
      AND ds.school_organisation = 'MHS'
      AND FORMAT(
              hbt.fuhha_created_time
                  AT TIME ZONE 'UTC'
                  AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC'),
              'HH:mm:ss'
          ) BETWEEN '07:00:00' AND '15:00:00'
      AND CONVERT(DATE, hbt.fuhha_created_time)
          BETWEEN DATEADD(DAY, -15, CONVERT(DATE, GETDATE()))
              AND CONVERT(DATE, GETDATE())
    GROUP BY
        hbt.fuhha_date_dw_id,
        hbt.fuhha_user_dw_id,
        hbt.fuhha_tenant_dw_id,
        hbt.fuhha_school_dw_id,
        CONVERT(
            DATE,
            hbt.fuhha_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
        )

) conjugated_Data
JOIN ${rs_coredw}.dim_tenant dt
    ON conjugated_Data.tenant_dw_id = dt.tenant_dw_id

GROUP BY
    login_date_dw_id,
    student_dw_id,
    conjugated_Data.tenant_dw_id,
    school_dw_id,
    local_login_date,
    dt.windows_timezone;
