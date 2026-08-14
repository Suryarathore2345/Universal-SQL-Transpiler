CREATE OR ALTER VIEW ${os_bi_coredw}.bi_core_class_teacher_dm_view AS
WITH class_teacher AS (SELECT DISTINCT dc.class_dw_id AS teacher_class_dw_id,
                                       dt.teacher_id,
                                       dsc.tenant_name
                       FROM ${rs_coredw}.dim_class dc
                                JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
                                     ON dc.class_school_id = dsc.school_id
                                JOIN ${rs_coredw}.dim_class_user dcu
                                     ON dcu.class_user_class_dw_id = dc.class_dw_id
                                LEFT JOIN ${rs_coredw}.dim_teacher dt
                                          ON dcu.class_user_user_dw_id = dt.teacher_dw_id
                                              AND dt.teacher_status = 1
                                              AND NOT EXISTS (SELECT 1
                                                              FROM ${rs_bi_coredw}.exclude_teacher_id eti
                                                              WHERE eti.teacher_id = dt.teacher_id)
                       WHERE dc.class_status = 1
                         AND dcu.class_user_status = 1
                         AND dcu.class_user_attach_status = 1
                         AND dcu.class_user_role_dw_id = 1
                         AND dc.class_course_status = 'ACTIVE'
                         AND dc.class_material_type <> 'PATHWAY'),

     --classes IN which students are active
     active_student_class AS (SELECT DISTINCT dc.class_dw_id AS student_class_dw_id,
                                              tenant_name
                              FROM ${rs_coredw}.dim_class dc
                                       JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
                                            ON dc.class_school_id = dsc.school_id
                                       JOIN ${rs_coredw}.dim_class_user dcu
                                            ON dcu.class_user_class_dw_id = dc.class_dw_id
                              WHERE dc.class_status = 1
                                AND dcu.class_user_status = 1
                                AND dcu.class_user_attach_status = 1
                                AND dcu.class_user_role_dw_id = 2
                                AND dc.class_course_status = 'ACTIVE'
                                AND dc.class_material_type <> 'PATHWAY')

SELECT teacher_class_dw_id,
       teacher_id,
       tenant_name
FROM class_teacher
UNION ALL
SELECT ast. student_class_dw_id AS teacher_class_dw_id,
       NULL AS teacher_id,
       ast.tenant_name AS tenant_name
FROM active_student_class ast
WHERE NOT EXISTS (SELECT 1
                  FROM class_teacher ct
                  WHERE ct.teacher_class_dw_id = ast.student_class_dw_id);
