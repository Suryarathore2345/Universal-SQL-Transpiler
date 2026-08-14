CREATE OR REPLACE MATERIALIZED LAKE VIEW ${OS_EAGLES_COREDW}.student_absentees_noholiday_weekly_mv
AS 
WITH total_students AS -- Section Level
(
    SELECT DISTINCT
        full_date                                                                        AS local_date,
        date_trunc('week', full_date)                                                    AS week_start_date,
        dayofweek(full_date) - 1                                                         AS weekend,  -- Spark: 1=Sun..7=Sat minus 1 → 0=Sun..6=Sat matches Redshift DOW
        tenant_name,
        dsc.school_dw_id,
        dsc.school_id,
        school_name,
        school_city_name,
        school_organisation,
        school_country_name,
        school_composition,
        school_alias                                                                     AS adek_id,
        school_created_time,
        concat(
            year(dsc.academic_year_start_date), '-',
            year(dsc.academic_year_end_date)
        )                                                                                AS academic_year,
        dsc.academic_year_start_date,
        dsc.academic_year_end_date,
        grade_k12grade                                                                   AS grade,
        section_dw_id,
        section_name                                                                     AS section,
        student_tags,
        student_special_needs                                                            AS special_needs,
        ds.student_dw_id                                                                 AS available_student_dw_id,
        ds.student_id,
        student_username,
        student_first_created_date,
        FIRST_VALUE(student_status) OVER (
            PARTITION BY student_dw_id
            ORDER BY student_created_time DESC , student_status ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        )                                                                                AS student_current_status,
        school_label
    FROM (
        SELECT full_date, section_name, section_dw_id, grade_id, school_id, tenant_id, section_id
        FROM ${RS_COREDW}.dim_section
        CROSS JOIN (
            SELECT DISTINCT full_date
            FROM ${RS_COREDW}.dim_date dt
            WHERE dt.full_date BETWEEN date_add(current_date(), -365) AND date_add(current_date(), -1)
        )
        WHERE school_id IS NOT NULL
    ) dse
    INNER JOIN ${RS_BI_COREDW}.bi_active_schools_dim dsc
        ON dsc.school_id = dse.school_id
        AND (full_date >= dsc.academic_year_start_date AND full_date <= dsc.academic_year_end_date)
    INNER JOIN ${RS_BI_COREDW}.bi_student_dim ds
        ON ds.student_section_dw_id = dse.section_dw_id
        AND (
            (
                student_status = 2
                AND full_date >= to_date(from_utc_timestamp(student_created_time, dsc.tenant_timezone))
                AND full_date <  to_date(from_utc_timestamp(student_active_until, dsc.tenant_timezone))
            )
            OR (
                student_status = 1
                AND full_date >= to_date(from_utc_timestamp(student_created_time, dsc.tenant_timezone))
            )
        )
    INNER JOIN ${RS_COREDW}.dim_grade dg
        ON dse.grade_id = dg.grade_id
        AND dg.grade_dw_id = ds.student_grade_dw_id
        AND dsc.academic_year_id = dg.academic_year_id
    LEFT JOIN (
        SELECT DISTINCT
            cast(holiday_date AS date) AS holiday_date,
            holiday_organisation_dw_id
        FROM ${RS_COREDW}.dim_holiday
    ) dh
        ON dh.holiday_date = dse.full_date
        AND dh.holiday_organisation_dw_id = dsc.organisation_dw_id
    WHERE dsc.academic_year_end_date >= date_trunc('day', current_timestamp())
      AND holiday_date IS NULL
      AND (dayofweek(full_date) - 1) BETWEEN 1 AND 5
),

active_students AS ( -- Section Level
    SELECT DISTINCT
        to_date(sl.login_local_date_time)  AS login_date,
        student_section_dw_id,
        sl.student_dw_id                   AS active_student_dw_id
    FROM ${RS_BI_COREDW}.student_login sl
    INNER JOIN ${RS_BI_COREDW}.bi_active_schools_dim dsc
        ON dsc.school_dw_id = sl.school_dw_id
    INNER JOIN ${RS_BI_COREDW}.bi_student_dim ds
        ON ds.student_dw_id = sl.student_dw_id
        AND (
            (
                student_status = 2
                AND to_date(login_local_date_time) >= to_date(from_utc_timestamp(student_created_time, dsc.tenant_timezone))
                AND to_date(login_local_date_time) <  to_date(from_utc_timestamp(student_active_until, dsc.tenant_timezone))
            )
            OR (
                student_status = 1
                AND to_date(login_local_date_time) >= to_date(from_utc_timestamp(student_created_time, dsc.tenant_timezone))
            )
        )
    WHERE to_date(login_local_date_time) >= date_add(to_date(from_utc_timestamp(current_timestamp(), dsc.tenant_timezone)), -365)
      AND to_date(login_local_date_time) <= to_date(from_utc_timestamp(current_timestamp(), dsc.tenant_timezone))
)

SELECT
    ts.week_start_date,
    NULLIF(array_join(
        array_sort(
            collect_list(
                CASE WHEN ast.active_student_dw_id IS NULL THEN cast(local_date AS string) END
            )
        ), '|'
    ),'')                                                               AS absent_days,
    COUNT(CASE WHEN ast.active_student_dw_id IS NULL THEN local_date END) AS total_absent_days,
    ts.academic_year,
    ts.tenant_name,
    ts.school_dw_id,
    ts.school_id,
    ts.school_name,
    ts.adek_id,
    ts.grade,
    UPPER(ts.section)                                             AS section,
    ts.student_tags,
    ts.special_needs,
    ts.available_student_dw_id,
    ts.student_id,
    ts.student_username,
    ts.student_first_created_date,
    ts.student_current_status,
    ts.academic_year_start_date,
    ts.academic_year_end_date,
    ts.section_dw_id
FROM total_students ts
LEFT JOIN active_students ast
    ON ts.section_dw_id = ast.student_section_dw_id
    AND ts.local_date = ast.login_date
    AND ts.available_student_dw_id = ast.active_student_dw_id
GROUP BY
    ts.week_start_date,
    ts.academic_year,
    ts.tenant_name,
    ts.school_dw_id,
    ts.school_id,
    ts.school_name,
    ts.adek_id,
    ts.grade,
    UPPER(ts.section),
    ts.student_tags,
    ts.special_needs,
    ts.available_student_dw_id,
    ts.student_id,
    ts.student_username,
    ts.student_first_created_date,
    ts.student_current_status,
    ts.academic_year_start_date,
    ts.academic_year_end_date,
    ts.section_dw_id;
