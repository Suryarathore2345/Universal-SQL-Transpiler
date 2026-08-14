CREATE OR REPLACE MATERIALIZED LAKE VIEW {{os_bi_coredw}}.nce_student_login_activity_dm_mv
AS
WITH total_students AS -- Section Level
(
    SELECT DISTINCT
        full_date                                                                    AS local_date,
        tenant_name,
        dsc.school_dw_id,
        school_name,
        school_city_name,
        school_organisation,
        school_longitude,
        school_latitude,
        organisation_dw_id,
        concat(
            year(dsc.academic_year_start_date), '-',
            year(dsc.academic_year_end_date)
        )                                                                            AS academic_year,
        dsc.academic_year_start_date,
        dsc.academic_year_end_date,
        grade_k12grade                                                               AS grade,
        dc.class_title                                                               AS class,
        section_dw_id,
        section_name                                                                 AS section,
        student_tags,
        student_special_needs                                                        AS special_needs,
        ds.student_dw_id                                                             AS available_student_dw_id,
        ds.student_id,
        dc.class_dw_id,
        dc.class_gen_subject,
        first_value(student_status) OVER (
            PARTITION BY student_dw_id
            ORDER BY student_created_time DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        )                                                                            AS student_current_status,
        school_label
    FROM (
        SELECT full_date, section_name, section_dw_id, grade_id, school_id, tenant_id, section_id
        FROM {{rs_coredw}}.dim_section
        CROSS JOIN (
            SELECT DISTINCT full_date
            FROM {{rs_coredw}}.dim_date dt
            WHERE dt.full_date BETWEEN date_add(current_date(), -365) AND current_date()
        )
        WHERE school_id IS NOT NULL
    ) dse
    INNER JOIN {{rs_bi_coredw}}.bi_active_schools_dim dsc
        ON dsc.school_id = dse.school_id
        AND (full_date >= dsc.academic_year_start_date AND full_date <= dsc.academic_year_end_date)
    INNER JOIN {{rs_bi_coredw}}.bi_student_dim ds
        ON ds.student_section_dw_id = dse.section_dw_id
        AND (
            (
                student_status = 2
                AND full_date >= to_date(from_utc_timestamp(student_created_time, dsc.tenant_timezone))
                AND full_date < to_date(from_utc_timestamp(student_active_until, dsc.tenant_timezone))
            )
            OR (
                student_status = 1
                AND full_date >= to_date(from_utc_timestamp(student_created_time, dsc.tenant_timezone))
            )
        )
    INNER JOIN {{rs_coredw}}   .dim_class_user dcu
        ON dcu.class_user_user_dw_id = ds.student_dw_id
    INNER JOIN {{rs_coredw}}.dim_class dc
        ON dcu.class_user_class_dw_id = dc.class_dw_id
        AND class_user_status = 1
        AND class_user_attach_status = 1
    INNER JOIN {{rs_coredw}}.dim_grade dg
        ON dse.grade_id = dg.grade_id
        AND dg.grade_dw_id = ds.student_grade_dw_id
        AND dsc.academic_year_id = dg.academic_year_id
    WHERE organisation_dw_id = 17 -- NCE organization dw id code
),

active_students AS -- Section Level
(
    SELECT DISTINCT
        login_date,
        student_section_dw_id,
        student_tags,
        special_needs,
        active_student_dw_id
    FROM (
        SELECT DISTINCT
            to_date(login_local_date_time)       AS login_date,
            student_section_dw_id,
            student_tags,
            student_special_needs                AS special_needs,
            sl.student_dw_id                     AS active_student_dw_id
        FROM {{rs_bi_coredw}}.student_login sl
        INNER JOIN {{rs_bi_coredw}}.bi_active_schools_dim dsc
            ON dsc.school_dw_id = sl.school_dw_id
        INNER JOIN {{rs_bi_coredw}}.bi_student_dim ds
            ON ds.student_dw_id = sl.student_dw_id
            AND (
                (
                    student_status = 2
                    AND to_date(login_local_date_time) >= to_date(from_utc_timestamp(student_created_time, dsc.tenant_timezone))
                    AND to_date(login_local_date_time) < to_date(from_utc_timestamp(student_active_until, dsc.tenant_timezone))
                )
                OR (
                    student_status = 1
                    AND to_date(login_local_date_time) >= to_date(from_utc_timestamp(student_created_time, dsc.tenant_timezone))
                )
            )
        WHERE to_date(login_local_date_time) >= date_add(to_date(from_utc_timestamp(current_timestamp(), dsc.tenant_timezone)), -365)
          AND to_date(login_local_date_time) <= to_date(from_utc_timestamp(current_timestamp(), dsc.tenant_timezone))
          AND organisation_dw_id = 17 -- NCE organization code TBD
    )
),

holidays_dimension AS
(
    SELECT DISTINCT
        cast(holiday_date AS date)      AS holiday_date,
        holiday_organisation_dw_id
    FROM {{rs_coredw}}.dim_holiday
)

SELECT DISTINCT
    local_date,
    ts.academic_year,
    ts.tenant_name,
    ts.school_dw_id,
    ts.school_name,
    ts.school_city_name,
    ts.school_organisation,
    ts.school_latitude,
    ts.school_longitude,
    ts.school_label,
    ts.grade,
    UPPER(ts.class)                                           AS class,
    UPPER(ts.section)                                         AS section,
    ts.student_tags,
    ts.special_needs,
    ts.available_student_dw_id,
    active_student_dw_id,
    student_id,
    student_current_status,
    ts.academic_year_start_date,
    ts.academic_year_end_date,
    ts.section_dw_id,
    CASE WHEN holiday_date IS NULL THEN FALSE ELSE TRUE END      AS holiday_flag,
    ts.class_gen_subject,
    ts.class_dw_id
FROM total_students ts
LEFT JOIN active_students ast
    ON ts.section_dw_id = ast.student_section_dw_id
    AND ts.local_date = ast.login_date
    AND ts.student_tags = ast.student_tags
    AND ts.special_needs = ast.special_needs
    AND ts.available_student_dw_id = ast.active_student_dw_id
LEFT JOIN holidays_dimension dh
    ON dh.holiday_date = ts.local_date
    AND dh.holiday_organisation_dw_id = ts.organisation_dw_id
    AND ts.organisation_dw_id = 17; 