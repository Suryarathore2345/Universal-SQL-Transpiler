CREATE OR ALTER VIEW ${os_bi_coredw}.announcements_dm_view AS
SELECT
    CONVERT(DATE, a.fa_created_time) AS announcement_date,
    a.fa_role_dw_id,
    r.role_name,
    CASE a.fa_type
        WHEN 1 THEN 'STUDENTS'
        WHEN 2 THEN 'GUARDIANS'
        WHEN 3 THEN 'BOTH'
        ELSE 'N/A'
    END AS announcement_type,
    sch.school_dw_id,
    sch.school_name,
    sch.tenant_name,
    sch.school_organisation,
    COUNT(*) AS announcements,
    ISNULL(SUM(CASE WHEN a.fa_has_attachment = 1 THEN 1 ELSE 0 END), 0) AS announcements_with_attachment
FROM ${rs_coredw}.fact_announcement a
INNER JOIN ${rs_coredw}.dim_role r
    ON r.role_dw_id = a.fa_role_dw_id
INNER JOIN ${rs_coredw}.dim_staff_user dp
    ON dp.staff_user_dw_id = a.fa_admin_dw_id
INNER JOIN ${rs_coredw}.dim_staff_user_school_role_association dsusra
    ON dsusra.susra_staff_dw_id = dp.staff_user_dw_id
INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim sch
    ON sch.school_dw_id = dsusra.susra_school_dw_id
WHERE a.fa_role_dw_id != 1 -- principals have their school association in dim_admin table
  AND dp.staff_user_status = 1
  AND dp.staff_user_enabled = 1
  AND dsusra.susra_status = 1
GROUP BY
    CONVERT(DATE, a.fa_created_time),
    a.fa_role_dw_id,
    r.role_name,
    CASE a.fa_type
        WHEN 1 THEN 'STUDENTS'
        WHEN 2 THEN 'GUARDIANS'
        WHEN 3 THEN 'BOTH'
        ELSE 'N/A'
    END,
    sch.school_dw_id,
    sch.school_name,
    sch.tenant_name,
    sch.school_organisation

UNION ALL

SELECT
    CONVERT(DATE, a.fa_created_time) AS announcement_date,
    a.fa_role_dw_id,
    r.role_name,
    CASE a.fa_type
        WHEN 1 THEN 'STUDENTS'
        WHEN 2 THEN 'GUARDIANS'
        WHEN 3 THEN 'BOTH'
        ELSE 'N/A'
    END AS announcement_type,
    sch.school_dw_id,
    sch.school_name,
    sch.tenant_name,
    sch.school_organisation,
    COUNT(*) AS announcements,
    ISNULL(SUM(CASE WHEN a.fa_has_attachment = 1 THEN 1 ELSE 0 END), 0) AS announcements_with_attachment
FROM ${rs_coredw}.fact_announcement a
INNER JOIN ${rs_coredw}.dim_role r
    ON r.role_dw_id = a.fa_role_dw_id
INNER JOIN (
    SELECT DISTINCT teacher_dw_id, teacher_school_dw_id
    FROM ${rs_coredw}.dim_teacher
    WHERE teacher_status = 1
) tch
    ON tch.teacher_dw_id = a.fa_admin_dw_id
INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim sch
    ON sch.school_dw_id = tch.teacher_school_dw_id
WHERE a.fa_role_dw_id = 1 -- teachers have their school association in dim_teacher table
GROUP BY
    CONVERT(DATE, a.fa_created_time),
    a.fa_role_dw_id,
    r.role_name,
    CASE a.fa_type
        WHEN 1 THEN 'STUDENTS'
        WHEN 2 THEN 'GUARDIANS'
        WHEN 3 THEN 'BOTH'
        ELSE 'N/A'
    END,
    sch.school_dw_id,
    sch.school_name,
    sch.tenant_name,
    sch.school_organisation;
