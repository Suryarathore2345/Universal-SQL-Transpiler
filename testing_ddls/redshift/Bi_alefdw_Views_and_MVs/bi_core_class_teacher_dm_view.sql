CREATE OR REPLACE VIEW bi_alefdw_dev.bi_core_class_teacher_dm_view AS
WITH class_teacher AS (SELECT DISTINCT dc.class_dw_id AS teacher_class_dw_id,
                                       dt.teacher_id,
                                       dsc.tenant_name
                       FROM alefdw.dim_class dc
                                JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                                     ON dc.class_school_id = dsc.school_id
                                JOIN alefdw.dim_class_user dcu
                                     ON dcu.class_user_class_dw_id = dc.class_dw_id
                                LEFT JOIN alefdw.dim_teacher dt
                                          ON dcu.class_user_user_dw_id = dt.teacher_dw_id
                                              AND dt.teacher_status = 1
                                              AND dt.teacher_id NOT IN
                                                  (SELECT DISTINCT teacher_id FROM bi_alefdw.exclude_teacher_id)
                       WHERE dc.class_status = 1
                         AND dcu.class_user_status = 1
                         AND dcu.class_user_attach_status = 1
                         AND dcu.class_user_role_dw_id = 1
                         AND dc.class_course_status = 'ACTIVE'
                         AND dc.class_material_type <> 'PATHWAY'),

     --classes in which students are active
     active_student_class AS (SELECT DISTINCT dc.class_dw_id AS student_class_dw_id,
                                              tenant_name
                              FROM alefdw.dim_class dc
                                       JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                                            ON dc.class_school_id = dsc.school_id
                                       JOIN alefdw.dim_class_user dcu
                                            ON dcu.class_user_class_dw_id = dc.class_dw_id
                              WHERE dc.class_status = 1
                                AND dcu.class_user_status = 1
                                AND dcu.class_user_attach_status = 1
                                AND dcu.class_user_role_dw_id = 2
                                AND dc.class_course_status = 'ACTIVE'
                                AND dc.class_material_type <> 'PATHWAY'),

     --classes in which students are active with no teacher assigned - VALID BUSINESS SCENARIO
     classes_without_teacher AS (SELECT student_class_dw_id AS missing_class_dw_id,
                                        tenant_name
                                 from active_student_class
                                 where student_class_dw_id not in
                                       (select teacher_class_dw_id from class_teacher))

SELECT teacher_class_dw_id,
       teacher_id,
       tenant_name
FROM class_teacher
UNION ALL
SELECT missing_class_dw_id,
       NULL as teacher_id,
       tenant_name
FROM classes_without_teacher

WITH NO SCHEMA BINDING;
