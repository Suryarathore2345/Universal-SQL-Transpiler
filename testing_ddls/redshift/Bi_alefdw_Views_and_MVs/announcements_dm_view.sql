CREATE OR REPLACE VIEW bi_alefdw_dev.announcements_dm_view AS
SELECT trunc(fa_created_time)                                     AS announcement_date,
       fa_role_dw_id,
       role_name,
       CASE fa_type
           WHEN 1 THEN 'STUDENTS'
           WHEN 2 THEN 'GUARDIANS'
           WHEN 3 THEN 'BOTH'
           ELSE 'N/A'
           END                                                    AS announcement_type,
       sch.school_dw_id,
       sch.school_name,
       sch.tenant_name,
       sch.school_organisation,
       count(*)                                                   AS announcements,
       nvl(sum(CASE WHEN fa_has_attachment = true THEN 1 END), 0) AS announcements_with_attachment
FROM alefdw.fact_announcement a
         INNER JOIN alefdw.dim_role r ON r.role_dw_id = a.fa_role_dw_id
         INNER JOIN alefdw.dim_staff_user dp ON dp.staff_user_dw_id = a.fa_admin_dw_id
         INNER JOIN alefdw.dim_staff_user_school_role_association dsusra
                    on dsusra.susra_staff_dw_id = dp.staff_user_dw_id
         INNER JOIN bi_alefdw.bi_active_schools_dim_mv sch ON sch.school_dw_id = dsusra.susra_school_dw_id
WHERE a.fa_role_dw_id != 1 --- principals have their school association in dim_admin table
  AND staff_user_status = 1
  AND staff_user_enabled = true
  AND dsusra.susra_status=1
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8

UNION ALL

SELECT trunc(fa_created_time)                                     AS announcement_date,
       fa_role_dw_id,
       role_name,
       CASE fa_type
           WHEN 1 THEN 'STUDENTS'
           WHEN 2 THEN 'GUARDIANS'
           WHEN 3 THEN 'BOTH'
           ELSE 'N/A'
           END                                                    AS announcement_type,
       sch.school_dw_id,
       sch.school_name,
       sch.tenant_name,
       sch.school_organisation,
       count(*)                                                   AS announcements,
       nvl(sum(CASE WHEN fa_has_attachment = true THEN 1 END), 0) AS announcements_with_attachment
FROM alefdw.fact_announcement a
         INNER JOIN alefdw.dim_role r ON r.role_dw_id = a.fa_role_dw_id
         INNER JOIN (SELECT DISTINCT teacher_dw_id,
                                     teacher_school_dw_id
                     FROM alefdw.dim_teacher
                     WHERE teacher_status = 1) tch ON tch.teacher_dw_id = a.fa_admin_dw_id
         INNER JOIN bi_alefdw.bi_active_schools_dim_mv sch ON sch.school_dw_id = tch.teacher_school_dw_id
WHERE fa_role_dw_id = 1 -- teachers have their school association in dim_teacher table
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
WITH NO SCHEMA BINDING;