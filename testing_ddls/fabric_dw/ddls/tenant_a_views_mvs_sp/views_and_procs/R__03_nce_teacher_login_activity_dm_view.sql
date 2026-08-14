CREATE OR ALTER VIEW ${os_bi_coredw}.nce_teacher_login_activity_dm_view AS
WITH date_range AS (
    SELECT DISTINCT full_date
    FROM ${rs_coredw}.dim_date dt
    WHERE dt.full_date BETWEEN CONVERT(DATE, DATEADD(DAY, -365, GETDATE()))
                           AND CONVERT(DATE, GETDATE())
),

total_teachers AS (
    SELECT DISTINCT
        ds.*,
        dr.full_date                          AS local_date,
        t.teacher_dw_id                       AS available_teacher_dw_id,
        t.teacher_id,
        UPPER(ISNULL(dc.class_gen_subject,'NA')) AS class_gen_subject,
        UPPER(ISNULL(dc.class_title,'NA')) AS class,
        UPPER(ISNULL(dg.grade_k12grade,0)) AS grade_k12grade,
        FIRST_VALUE(CONVERT(DATE, t.teacher_created_time)) OVER (
            PARTITION BY t.teacher_dw_id
            ORDER BY t.teacher_created_time
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS teacher_first_created_date,
        FIRST_VALUE(t.teacher_status) OVER (
            PARTITION BY t.teacher_dw_id
            ORDER BY t.teacher_created_time DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS teacher_current_status
    FROM ${rs_bi_coredw}.bi_active_schools_dim ds
    CROSS JOIN date_range dr

    INNER JOIN ${rs_coredw}.dim_teacher t
        ON t.teacher_school_dw_id = ds.school_dw_id
       AND (
            (
                t.teacher_status = 2
                AND dr.full_date >= CONVERT(
                        DATE,
                        t.teacher_created_time
                            AT TIME ZONE 'UTC'
                            AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
                    )
                AND dr.full_date < CONVERT(
                        DATE,
                        t.teacher_active_until
                            AT TIME ZONE 'UTC'
                            AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
                    )
            )
            OR
            (
                t.teacher_status = 1
                AND dr.full_date >= CONVERT(
                        DATE,
                        t.teacher_created_time
                            AT TIME ZONE 'UTC'
                            AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
                    )
            )
       )
    LEFT JOIN ${rs_coredw}.dim_class_user dcu
        ON dcu.class_user_user_dw_id = t.teacher_dw_id
       AND dcu.class_user_role_dw_id = 1
       AND dcu.class_user_status = 1
       AND dcu.class_user_attach_status = 1
    LEFT JOIN ${rs_coredw}.dim_class dc
        ON dc.class_dw_id = dcu.class_user_class_dw_id
       AND dc.class_status = 1
       AND dc.class_course_status = 'ACTIVE'
    LEFT JOIN ${rs_coredw}.dim_grade dg
        ON dg.grade_id = dc.class_grade_id
    WHERE NOT EXISTS (SELECT 1 FROM ${rs_bi_coredw}.exclude_teacher_id excl WHERE excl.teacher_id = t.teacher_id)  -- OPT-8
      AND dr.full_date BETWEEN ds.academic_year_start_date
                           AND ds.academic_year_end_date
      AND ds.organisation_dw_id = 17   -- NCE content repository code
),

active_teachers AS (
    SELECT DISTINCT
        CONVERT(DATE, tl.login_local_date_time) AS login_date,
        tl.school_dw_id,
        tl.teacher_dw_id AS active_teacher_dw_id
    FROM ${rs_bi_coredw}.teacher_login tl
    INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim ds
        ON tl.school_dw_id = ds.school_dw_id

    INNER JOIN ${rs_coredw}.dim_teacher t
        ON t.teacher_school_dw_id = tl.school_dw_id
       AND t.teacher_dw_id = tl.teacher_dw_id
       AND (
            (
                t.teacher_status = 2
                AND CONVERT(DATE, tl.login_local_date_time) >= CONVERT(
                        DATE,
                        t.teacher_created_time
                            AT TIME ZONE 'UTC'
                            AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
                    )
                AND CONVERT(DATE, tl.login_local_date_time) < CONVERT(
                        DATE,
                        t.teacher_active_until
                            AT TIME ZONE 'UTC'
                            AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
                    )
            )
            OR 
            (
                t.teacher_status = 1
                AND tl.login_local_date_time >= CONVERT(
                        DATE,
                        t.teacher_created_time
                            AT TIME ZONE 'UTC'
                            AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
                    )
            )
       )
    WHERE CONVERT(DATE, tl.login_local_date_time)
          BETWEEN CONVERT(DATE, DATEADD(DAY, -365, GETDATE()))
              AND CONVERT(DATE, GETDATE())
      AND NOT EXISTS (SELECT 1 FROM ${rs_bi_coredw}.exclude_teacher_id excl WHERE excl.teacher_id = t.teacher_id)  -- OPT-8
      AND ds.organisation_dw_id = 17   -- NCE content repository code
),

holidays_dimension AS (
    SELECT DISTINCT
        CONVERT(DATE, holiday_date) AS holiday_date,
        holiday_organisation_dw_id
    FROM ${rs_coredw}.dim_holiday
)
SELECT DISTINCT
    tt.local_date,
    tt.tenant_name,
    tt.school_dw_id,
    tt.school_name,
    tt.school_created_time,
    tt.school_alias                                            AS adek_id,
    tt.school_city_name,
    tt.school_organisation,
    tt.school_country_name,
    tt.school_composition,
    tt.school_id,
    tt.school_label,
    tt.available_teacher_dw_id,
    at.active_teacher_dw_id,
    tt.teacher_id,
    tt.class_gen_subject,
    tt.class,
    tt.grade_k12grade,

    tt.teacher_first_created_date,
    tt.teacher_current_status,

    CONVERT(VARCHAR(4), DATEPART(YEAR, tt.academic_year_start_date))
        + '-' +
    CONVERT(VARCHAR(4), DATEPART(YEAR, tt.academic_year_end_date)) AS academic_year,

    tt.academic_year_start_date,
    tt.academic_year_end_date,

    CONVERT(
        BIT,
        CASE 
            WHEN dh.holiday_date IS NULL THEN 0 
            ELSE 1 
        END
) AS holiday_flag,

    tt.school_cx_cluster
FROM total_teachers tt
LEFT JOIN active_teachers at
    ON tt.school_dw_id           = at.school_dw_id
   AND tt.local_date             = at.login_date
   AND tt.available_teacher_dw_id = at.active_teacher_dw_id
LEFT JOIN holidays_dimension dh
    ON dh.holiday_date = tt.local_date
   AND dh.holiday_organisation_dw_id = tt.organisation_dw_id;
