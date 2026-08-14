CREATE OR ALTER VIEW ${os_bi_coredw}.student_login_activity_military_biweekly_view AS
WITH total_students AS (
    SELECT DISTINCT
        dsx.full_date                                                    AS local_date,
        dsc.tenant_name,
        dsc.school_dw_id,
        dsc.school_id,
        dsc.school_name,
        dsc.school_city_name,
        dsc.school_organisation,
        dsc.organisation_dw_id,
        dsc.school_country_name,
        dsc.school_composition,
        dsc.school_alias                                                 AS adek_id,
        dsc.school_created_time,
        CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_start_date)) 
            + '-' +
        CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_end_date)) AS academic_year,
        dsc.academic_year_start_date,
        dsc.academic_year_end_date,
        dg.grade_k12grade                                                AS grade,
        ''                                                               AS class,
        dsx.section_dw_id,
        dsx.section_alias                                                AS section,
        ds.student_tags,
        ds.student_special_needs                                         AS special_needs,
        ds.student_dw_id                                                 AS available_student_dw_id,
        ds.student_id,
        ds.student_username,
        ds.student_first_created_date,
        FIRST_VALUE(ds.student_status) OVER (
            PARTITION BY dsc.school_dw_id, dsx.section_dw_id, ds.student_dw_id
            ORDER BY ds.student_created_time DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        )                                                                AS student_current_status,
        dsc.school_label,
        dsc.school_cx_cluster
    FROM (
        SELECT
            s.full_date,
            sec.section_alias,
            sec.section_dw_id,
            sec.grade_id,
            sec.school_id,
            sec.tenant_id,
            sec.section_id
        FROM ${rs_coredw}.dim_section sec
        CROSS JOIN (
            SELECT DISTINCT full_date
            FROM ${rs_coredw}.dim_date dt
            WHERE dt.full_date BETWEEN DATEADD(DAY, -14, CONVERT(DATE, GETDATE()))
                                   AND CONVERT(DATE, GETDATE())
        ) s
        WHERE sec.school_id IS NOT NULL
    ) dsx
    INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
        ON CONVERT(VARBINARY(256), dsc.school_id) =
           CONVERT(VARBINARY(256), dsx.school_id)
       AND dsx.full_date BETWEEN dsc.academic_year_start_date
                             AND dsc.academic_year_end_date

    INNER JOIN ${rs_bi_coredw}.bi_student_dim ds
        ON ds.student_section_dw_id = dsx.section_dw_id
       AND (
            (
                ds.student_status = 2
                AND dsx.full_date >=
                    CONVERT(
                        DATE,
                        (
                            ds.student_created_time
                                AT TIME ZONE 'UTC'
                                AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
                        )
                    )
                AND dsx.full_date <
                    CONVERT(
                        DATE,
                        (
                            ds.student_active_until
                                AT TIME ZONE 'UTC'
                                AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
                        )
                    )
            )
            OR (
                ds.student_status = 1
                AND dsx.full_date >=
                    CONVERT(
                        DATE,
                        (
                            ds.student_created_time
                                AT TIME ZONE 'UTC'
                                AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
                        )
                    )
            )
       )
    INNER JOIN ${rs_coredw}.dim_grade dg
        ON dsx.grade_id   = dg.grade_id
       AND dg.grade_dw_id = ds.student_grade_dw_id
       AND CONVERT(VARBINARY(256), dsc.academic_year_id) =
           CONVERT(VARBINARY(256), dg.academic_year_id)
),

active_students AS (
    SELECT DISTINCT
        CONVERT(DATE, sl.login_local_date_time) AS login_date,
        ds.student_section_dw_id,
        ds.student_tags,
        ds.student_special_needs               AS special_needs,
        sl.student_dw_id                       AS active_student_dw_id
    FROM ${rs_bi_coredw}.student_login_military sl
    INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
        ON dsc.school_dw_id = sl.school_dw_id

    INNER JOIN ${rs_bi_coredw}.bi_student_dim ds
        ON ds.student_dw_id = sl.student_dw_id
       AND (
            (
                ds.student_status = 2
                AND CONVERT(DATE, sl.login_local_date_time) >=
                    CONVERT(
                        DATE,
                        (
                            ds.student_created_time
                                AT TIME ZONE 'UTC'
                                AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
                        )
                    )
                AND CONVERT(DATE, sl.login_local_date_time) <
                    CONVERT(
                        DATE,
                        (
                            ds.student_active_until
                                AT TIME ZONE 'UTC'
                                AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
                        )
                    )
            )
            OR (
                ds.student_status = 1
                AND CONVERT(DATE, sl.login_local_date_time) >=
                    CONVERT(
                        DATE,
                        (
                            ds.student_created_time
                                AT TIME ZONE 'UTC'
                                AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
                        )
                    )
            )
       )
    WHERE CONVERT(DATE, sl.login_local_date_time)
          BETWEEN DATEADD(DAY, -14,
              CONVERT(DATE, GETDATE() AT TIME ZONE 'UTC' AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC'))
          )
          AND CONVERT(DATE, GETDATE() AT TIME ZONE 'UTC' AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC'))
),

student_onboarding AS (
    SELECT DISTINCT
        sl.student_dw_id,
        sl.school_dw_id,
        FIRST_VALUE(sl.login_local_date_time) OVER (
            PARTITION BY sl.student_dw_id, sl.school_dw_id
            ORDER BY sl.login_local_date_time ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS student_first_login_date,
        FIRST_VALUE(sl.login_local_date_time) OVER (
            PARTITION BY sl.student_dw_id, sl.school_dw_id
            ORDER BY sl.login_local_date_time DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS student_last_login_date
    FROM ${rs_bi_coredw}.student_login_military sl
    INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
        ON dsc.school_dw_id = sl.school_dw_id
       AND CONVERT(DATE, sl.login_local_date_time) >= dsc.academic_year_start_date
),

school_prveviousay AS (
    SELECT
        school_dw_id,
        MAX(academic_year_start_date) AS previous_academic_year_start_date,
        MAX(academic_year_end_date)   AS previous_academic_year_end_date
    FROM ${rs_bi_coredw}.bi_all_schools_dim
    WHERE academic_year_is_roll_over_completed = 1
    GROUP BY school_dw_id
),

student_onboarding_pay AS (
    SELECT DISTINCT sl.student_dw_id
    FROM ${rs_bi_coredw}.student_login_military sl
    INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
        ON dsc.school_dw_id = sl.school_dw_id
    INNER JOIN school_prveviousay spay
        ON dsc.school_dw_id = spay.school_dw_id
       AND CONVERT(DATE, sl.login_local_date_time)
           BETWEEN spay.previous_academic_year_start_date
               AND spay.previous_academic_year_end_date
),

lessons_started AS (
    SELECT DISTINCT
        fle.fle_student_dw_id,
        MIN(CONVERT(DATE, fle.fle_created_time)) AS student_lesson_start_date
    FROM ${rs_coredw}.fact_learning_experience fle
    INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
        ON dsc.school_dw_id = fle.fle_school_dw_id
       AND fle.fle_created_time >= CONVERT(DATETIME2, dsc.academic_year_start_date)  -- OPT-7: SARGable rewrite
    WHERE fle.fle_activity_type <> 'INTERIM_CHECKPOINT'
    GROUP BY fle.fle_student_dw_id
),

holidays_dimension AS (
    SELECT DISTINCT
        CONVERT(DATE, holiday_date) AS holiday_date,
        holiday_organisation_dw_id
    FROM ${rs_coredw}.dim_holiday
)

SELECT DISTINCT
    ts.local_date,
    ts.academic_year,
    ts.tenant_name,
    ts.school_dw_id,
    ts.school_id,
    ts.school_name,
    ts.school_created_time,
    ts.adek_id,
    ts.school_city_name,
    ts.school_organisation,
    ts.school_country_name,
    ts.school_composition,
    ts.school_label,
    ts.grade,
    UPPER(ts.class)   AS class,
    UPPER(ts.section) AS section,
    ts.student_tags,
    ts.special_needs,
    ts.available_student_dw_id,
    CASE WHEN pay_st.student_dw_id IS NULL THEN 0 ELSE 1 END AS repeat_student_previous_ay,
    ast.active_student_dw_id,
    ts.student_id,
    ts.student_username,
    ts.student_first_created_date,
    ts.student_current_status,
    so.student_first_login_date,
    so.student_last_login_date,
    ls.student_lesson_start_date,
    ts.academic_year_start_date,
    ts.academic_year_end_date,
    ts.section_dw_id,
    CONVERT(
        BIT,
        CASE WHEN dh.holiday_date IS NULL THEN 0 ELSE 1 END
) AS holiday_flag,
    ts.school_cx_cluster
FROM total_students ts
LEFT JOIN active_students ast
    ON ts.section_dw_id = ast.student_section_dw_id
   AND ts.local_date    = ast.login_date
   AND CONVERT(VARBINARY(256), ts.student_tags) =
       CONVERT(VARBINARY(256), ast.student_tags)
   AND CONVERT(VARBINARY(256), ts.special_needs) =
       CONVERT(VARBINARY(256), ast.special_needs)
   AND ts.available_student_dw_id = ast.active_student_dw_id
LEFT JOIN student_onboarding so
    ON ts.available_student_dw_id = so.student_dw_id
   AND ts.school_dw_id           = so.school_dw_id
LEFT JOIN student_onboarding_pay pay_st
    ON ts.available_student_dw_id = pay_st.student_dw_id
LEFT JOIN lessons_started ls
    ON ts.available_student_dw_id = ls.fle_student_dw_id
LEFT JOIN holidays_dimension dh
    ON dh.holiday_date = ts.local_date
   AND CONVERT(VARBINARY(256), dh.holiday_organisation_dw_id) =
       CONVERT(VARBINARY(256), ts.organisation_dw_id)
WHERE CONVERT(VARBINARY(256), ts.school_organisation) =
      CONVERT(VARBINARY(256), 'MHS');
