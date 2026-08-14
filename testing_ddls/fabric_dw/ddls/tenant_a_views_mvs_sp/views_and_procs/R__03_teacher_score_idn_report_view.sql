CREATE OR ALTER VIEW ${os_bi_coredw}.teacher_score_idn_report_view
AS
WITH holidays_dimension AS (
    SELECT DISTINCT
        CONVERT(DATE, holiday_date) AS holiday_date,
        holiday_organisation_dw_id
    FROM ${rs_coredw}.dim_holiday
),

class_teachers AS (
    SELECT
        subq.class_dw_id,
        subq.class_user_user_dw_id AS teacher_dw_id,
        STRING_AGG(CONVERT(VARCHAR(MAX), subq.teacher_id), ',') WITHIN GROUP (ORDER BY subq.class_user_created_time) AS teacher_ids
    FROM (
        SELECT DISTINCT
            dc.class_dw_id,
            dcu.class_user_user_dw_id,
            dt.teacher_id,
            dcu.class_user_created_time
        FROM ${rs_coredw}.dim_class dc
        JOIN ${rs_coredw}.dim_class_user dcu
            ON dcu.class_user_class_dw_id = dc.class_dw_id
        LEFT JOIN ${rs_coredw}.dim_teacher dt
            ON dcu.class_user_user_dw_id = dt.teacher_dw_id
           AND dt.teacher_status = 1
        WHERE dc.class_status = 1
          AND dcu.class_user_role_dw_id = 1
          AND dc.class_course_status = 'ACTIVE'
          AND dcu.class_user_status = 1
    ) subq
    GROUP BY subq.class_dw_id, subq.class_user_user_dw_id
),

active_teachers AS (
    SELECT
        temp_tab.login_date,
        temp_tab.teacher_id,
        temp_tab.teacher_status,
        temp_tab.active_teacher_dw_id,
        temp_tab.available_teacher_dw_id,
        temp_tab.organisation_dw_id,
        temp_tab.school_organisation,
        temp_tab.school_city_name,
        temp_tab.school_name,
        temp_tab.school_country_name,
        temp_tab.school_id,
        temp_tab.school_dw_id,
        temp_tab.school_label,
        temp_tab.tenant_name,
        temp_tab.academic_year_start_date,
        temp_tab.academic_year_end_date,
        temp_tab.start_ay_flag,
        temp_tab.end_ay_flag,
        temp_tab.academic_year,
        CONVERT(DATE, DATEADD(DAY, 1 - DAY(login_date), login_date)) AS login_start_month,
        CASE
            WHEN start_ay_flag = 1
                THEN DATEDIFF(DAY, academic_year_start_date, EOMONTH(academic_year_start_date)) + 1
            WHEN end_ay_flag = 1
                THEN DATEDIFF(DAY, DATEADD(DAY, 1 - DAY(academic_year_end_date), academic_year_end_date), EOMONTH(academic_year_end_date)) + 1
            ELSE DAY(EOMONTH(login_date))
        END AS total_days_in_month,
            CONVERT(
                BIGINT,
                CASE
                    WHEN start_ay_flag = 1 THEN
                        (DATEDIFF(DAY, academic_year_start_date, EOMONTH(academic_year_start_date))) + 1
                        - (DATEDIFF(WEEK, academic_year_start_date, EOMONTH(academic_year_start_date)) * 2)
                        - (CASE WHEN DATEPART(WEEKDAY, academic_year_start_date) = 1 THEN 1 ELSE 0 END)
                        - (CASE WHEN DATEPART(WEEKDAY, EOMONTH(academic_year_start_date)) = 7 THEN 1 ELSE 0 END)

                    WHEN end_ay_flag = 1 THEN
                        (DATEDIFF(DAY,
                            DATEADD(DAY, 1 - DAY(academic_year_end_date), academic_year_end_date),
                            academic_year_end_date
                        )) + 1
                        - (DATEDIFF(WEEK,
                            DATEADD(DAY, 1 - DAY(academic_year_end_date), academic_year_end_date),
                            academic_year_end_date
                        ) * 2)
                        - (CASE WHEN DATEPART(WEEKDAY, academic_year_end_date) = 1 THEN 1 ELSE 0 END)
                        - (CASE WHEN DATEPART(WEEKDAY, EOMONTH(academic_year_end_date)) = 7 THEN 1 ELSE 0 END)

                    ELSE
                        (DATEDIFF(DAY,
                            DATEADD(DAY, 1 - DAY(login_date), login_date),
                            EOMONTH(login_date)
                        )) + 1
                        - (DATEDIFF(WEEK,
                            DATEADD(DAY, 1 - DAY(login_date), login_date),
                            EOMONTH(login_date)
                        ) * 2)
                        - (CASE WHEN DATEPART(WEEKDAY, login_date) = 1 THEN 1 ELSE 0 END)
                        - (CASE WHEN DATEPART(WEEKDAY, login_date) = 7 THEN 1 ELSE 0 END)
                END
            ) AS business_days
    FROM (
        SELECT DISTINCT
            CONVERT(DATE, tl.login_local_date_time) AS login_date,
            dt.teacher_id,
            dt.teacher_status,
            tl.teacher_dw_id AS active_teacher_dw_id,
            dt.teacher_dw_id AS available_teacher_dw_id,
            dsc.organisation_dw_id,
            dsc.school_organisation,
            dsc.school_city_name,
            dsc.school_name,
            dsc.school_country_name,
            dsc.school_id,
            dsc.school_dw_id,
            dsc.school_label,
            dsc.tenant_name,
            dsc.academic_year_start_date,
            dsc.academic_year_end_date,
            CASE
                WHEN CONVERT(DATE, DATEADD(DAY, 1 - DAY(dsc.academic_year_start_date), dsc.academic_year_start_date)) =
                     CONVERT(DATE, DATEADD(DAY, 1 - DAY(tl.login_local_date_time), CONVERT(DATE, tl.login_local_date_time)))
                    THEN 1
                ELSE 0
            END AS start_ay_flag,
            CASE
                WHEN CONVERT(DATE, DATEADD(DAY, 1 - DAY(dsc.academic_year_end_date), dsc.academic_year_end_date)) =
                     CONVERT(DATE, DATEADD(DAY, 1 - DAY(tl.login_local_date_time), CONVERT(DATE, tl.login_local_date_time)))
                    THEN 1
                ELSE 0
            END AS end_ay_flag,
            CONVERT(VARCHAR, DATEPART(YEAR, dsc.academic_year_start_date)) + '-' +
            CONVERT(VARCHAR, DATEPART(YEAR, dsc.academic_year_end_date)) AS academic_year
        FROM ${rs_bi_coredw}.teacher_login tl
        INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
            ON dsc.school_dw_id = tl.school_dw_id
        INNER JOIN ${rs_coredw}.dim_teacher dt
            ON dt.teacher_dw_id = tl.teacher_dw_id

        LEFT JOIN holidays_dimension dh
            -- FIX #1: no timezone conversion on login_local_date_time
            ON dh.holiday_date = CONVERT(DATE, tl.login_local_date_time)
               AND holiday_organisation_dw_id = dsc.organisation_dw_id
        -- FIX #1: no timezone conversion on login_local_date_time throughout WHERE
        WHERE CONVERT(DATE, tl.login_local_date_time)
                  BETWEEN dsc.academic_year_start_date AND dsc.academic_year_end_date
          AND dsc.tenant_name = 'idn'
          AND (
              (
                  dt.teacher_status = 2
                  -- FIX #5: CAST AS DATETIME2 before AT TIME ZONE for teacher columns
                  AND CONVERT(DATE, tl.login_local_date_time) >=
                      CONVERT(
                          DATE,
                          CONVERT(DATETIME2, dt.teacher_created_time)
                              AT TIME ZONE 'UTC'
                              AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
)
                  AND CONVERT(DATE, tl.login_local_date_time) <
                      CONVERT(
                          DATE,
                          CONVERT(DATETIME2, dt.teacher_active_until)
                              AT TIME ZONE 'UTC'
                              AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
)
              )
              OR
              (
                  dt.teacher_status = 1
                  AND CONVERT(DATE, tl.login_local_date_time) >=
                      CONVERT(
                          DATE,
                          CONVERT(DATETIME2, dt.teacher_created_time)
                              AT TIME ZONE 'UTC'
                              AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
)
              )
          )
          AND dh.holiday_date IS NULL
          AND DATEPART(WEEKDAY, tl.login_local_date_time) NOT IN (1, 7)
          AND NOT EXISTS (SELECT 1 FROM ${rs_bi_coredw}.exclude_teacher_id excl WHERE excl.teacher_id = dt.teacher_id)  -- OPT-8
    ) temp_tab
),

date_dimension AS (
    SELECT DISTINCT
        calendar_month_start_date AS month_start_date
    FROM ${rs_coredw}.dim_date dt
    WHERE dt.full_date >= CONVERT(DATE, DATEADD(DAY, -365, GETDATE()))
      AND dt.full_date <= CONVERT(DATE, GETDATE())
),

min_max_date AS (
    SELECT
        MIN(month_start_date) AS start_date,
        MAX(month_start_date) AS end_date
    FROM date_dimension
),

active_students AS (
    SELECT DISTINCT
        CONVERT(
            DATE,DATEADD(DAY, 1 - DAY(
            CONVERT(
                DATE,
                fsta.fsta_start_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
)
        ),
            CONVERT(
                DATE,
                fsta.fsta_start_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
)
        )
) AS month_start_date,
        fsta_school_dw_id,
        fsta_grade_dw_id,
        dcu.class_user_class_dw_id AS class_dw_id,
        fsta_section_dw_id,
        COUNT(DISTINCT fsta_student_dw_id) AS monthly_active
    FROM ${rs_coredw}.fact_student_activities fsta
    JOIN ${rs_coredw}.dim_tenant dt
        ON fsta.fsta_tenant_dw_id = dt.tenant_dw_id

    LEFT JOIN ${rs_coredw}.dim_class_user dcu
        ON dcu.class_user_user_dw_id = fsta.fsta_student_dw_id
    LEFT JOIN ${rs_coredw}.dim_class dc
        ON dcu.class_user_class_dw_id = dc.class_dw_id
    CROSS APPLY (
        SELECT value
        FROM STRING_SPLIT(fsta.fsta_object_id, '/', 1)
        WHERE ordinal = 5
    ) parts
    WHERE parts.value IN (
        SELECT DISTINCT lo_id
        FROM ${rs_coredw}.dim_learning_objective
    )
      AND dt.tenant_name = 'idn'
      AND dcu.class_user_role_dw_id = 2
      AND dc.class_status = 1
      AND dc.class_course_status = 'ACTIVE'
      AND CONVERT(
              DATE,DATEADD(DAY, 1 - DAY(
              CONVERT(
                  DATE,
                  fsta.fsta_start_time
                      AT TIME ZONE 'UTC'
                      AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
)
          ),
              CONVERT(
                  DATE,
                  fsta.fsta_start_time
                      AT TIME ZONE 'UTC'
                      AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
)
          )
)
          BETWEEN (SELECT start_date FROM min_max_date) AND (SELECT end_date FROM min_max_date)
      AND CONVERT(
              DATE,DATEADD(DAY, 1 - DAY(
              CONVERT(
                  DATE,
                  fsta.fsta_start_time
                      AT TIME ZONE 'UTC'
                      AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
)
          ),
              CONVERT(
                  DATE,
                  fsta.fsta_start_time
                      AT TIME ZONE 'UTC'
                      AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
)
          )
) >= dcu.class_user_created_time
    GROUP BY
        CONVERT(
            DATE,DATEADD(DAY, 1 - DAY(
            CONVERT(
                DATE,
                fsta.fsta_start_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
)
        ),
            CONVERT(
                DATE,
                fsta.fsta_start_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
)
        )
),
        fsta_school_dw_id,
        fsta_grade_dw_id,
        dcu.class_user_class_dw_id,
        fsta_section_dw_id
),

total_in_curriculum AS (
    SELECT
        dd.month_start_date,
        sc.tenant_name,
        sc.school_organisation,
        sc.school_dw_id,
        sc.school_name,
        dg.grade_dw_id,
        dg.grade_name,
        dc.class_dw_id,
        CONVERT(VARCHAR, DATEPART(YEAR, sc.academic_year_start_date)) + '-' +
        CONVERT(VARCHAR, DATEPART(YEAR, sc.academic_year_end_date)) AS academic_year,
        ISNULL(dse.section_dw_id, '10001') AS section_dw_id,
        -- FIX #4: Use UPPER() per established pattern
        UPPER(ISNULL(dse.section_name, 'NA')) AS section_name,
        COUNT(DISTINCT ds.student_dw_id) AS class_total_students
    FROM ${rs_coredw}.dim_class dc
    JOIN ${rs_coredw}.dim_class_user dcu
        ON dcu.class_user_class_dw_id = dc.class_dw_id
    JOIN ${rs_bi_coredw}.bi_active_schools_dim sc
        ON dc.class_school_id = sc.school_id
       AND dc.class_academic_year_id = sc.academic_year_id
    LEFT JOIN ${rs_bi_coredw}.bi_student_dim ds
        ON dcu.class_user_user_dw_id = ds.student_dw_id
       AND sc.school_dw_id = ds.student_school_dw_id
    JOIN ${rs_coredw}.dim_grade dg
        ON dg.grade_dw_id = ds.student_grade_dw_id
    LEFT JOIN ${rs_coredw}.dim_section dse
        ON dse.section_dw_id = ds.student_section_dw_id
    CROSS JOIN date_dimension dd
    WHERE (
        (
            (ds.student_status = 2
                AND dd.month_start_date >= CONVERT(DATE, DATEADD(DAY, 1 - DAY(ds.student_created_time), ds.student_created_time))
                AND dd.month_start_date < CONVERT(DATE, DATEADD(DAY, 1 - DAY(ds.student_active_until), ds.student_active_until)))
            OR (ds.student_status = 1
                AND dd.month_start_date >= CONVERT(DATE, DATEADD(DAY, 1 - DAY(ds.student_created_time), ds.student_created_time)))
        )
        AND (
            (dcu.class_user_attach_status = 2
                AND dd.month_start_date >= CONVERT(DATE, DATEADD(DAY, 1 - DAY(dcu.class_user_created_time), dcu.class_user_created_time))
                AND dd.month_start_date < CONVERT(DATE, DATEADD(DAY, 1 - DAY(dcu.class_user_active_until), dcu.class_user_active_until)))
            OR (dcu.class_user_attach_status = 1
                AND dd.month_start_date >= CONVERT(DATE, DATEADD(DAY, 1 - DAY(dcu.class_user_created_time), dcu.class_user_created_time)))
            OR (dcu.class_user_attach_status = 2
                AND CONVERT(DATE, DATEADD(DAY, 1 - DAY(dcu.class_user_active_until), dcu.class_user_active_until)) IS NULL)
        )
    )
      AND dcu.class_user_role_dw_id = 2
      AND dc.class_status = 1
      AND dc.class_course_status = 'ACTIVE'
      AND sc.tenant_name = 'idn'
    GROUP BY
        dd.month_start_date,
        sc.tenant_name,
        sc.school_organisation,
        sc.school_dw_id,
        sc.school_name,
        dg.grade_dw_id,
        dg.grade_name,
        dc.class_dw_id,
        CONVERT(VARCHAR, DATEPART(YEAR, sc.academic_year_start_date)) + '-' + CONVERT(VARCHAR, DATEPART(YEAR, sc.academic_year_end_date)),
        ISNULL(dse.section_dw_id, '10001'),
        UPPER(ISNULL(dse.section_name, 'NA'))
),

monthly_students_data AS (
    SELECT DISTINCT
        tc.month_start_date,
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
    LEFT JOIN class_teachers ct
        ON ct.class_dw_id = tc.class_dw_id
),

teacher_login_stats AS (
    SELECT
        login_start_month,
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
        COUNT(active_teacher_dw_id) AS teacher_logins,
        MAX(business_days) AS business_days_total,
        CONVERT(
                NUMERIC(26,2),
                ROUND(
                    100.0 * COUNT(active_teacher_dw_id)
                    / NULLIF(MAX(ISNULL(business_days, 0)), 0),
                    2
                )
        ) AS login_percentage_per_teacher
    FROM active_teachers
    GROUP BY
        login_start_month,
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
        academic_year
)

SELECT
    temp.login_start_month,
    temp.teacher_id,
    temp.active_teacher_dw_id,
    temp.available_teacher_dw_id,
    temp.teacher_status,
    temp.organisation_dw_id,
    temp.school_organisation,
    temp.school_city_name,
    temp.school_name,
    temp.school_country_name,
    temp.school_id,
    temp.school_dw_id,
    temp.school_label,
    temp.tenant_name,
    temp.login_percentage_per_teacher,
    temp.teacher_logins,
    temp.business_days,
    temp.total_active_students,
    temp.total_students,
    temp.total_classes,
    temp.total_sections,
    temp.total_grades
FROM (
    SELECT
        act.login_start_month,
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
        act.login_percentage_per_teacher,
        act.teacher_logins,
        act.business_days_total AS business_days,
        SUM(mst.monthly_active) AS total_active_students,
        SUM(mst.class_total_students) AS total_students,
        COUNT(DISTINCT mst.class_dw_id) AS total_classes,
        COUNT(DISTINCT mst.section_name) AS total_sections,
        COUNT(DISTINCT mst.grade_name) AS total_grades
    FROM teacher_login_stats act
    LEFT JOIN monthly_students_data mst
        ON act.login_start_month = mst.month_start_date
       AND act.teacher_id = mst.teacher_ids
       AND act.school_dw_id = mst.school_dw_id
       AND act.academic_year = mst.academic_year
    GROUP BY
        act.login_start_month,
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
        act.login_percentage_per_teacher,
        act.teacher_logins,
        act.business_days_total
) temp
WHERE login_start_month <> DATEADD(DAY, 1 - DAY(GETDATE()), CONVERT(DATE, GETDATE()));
