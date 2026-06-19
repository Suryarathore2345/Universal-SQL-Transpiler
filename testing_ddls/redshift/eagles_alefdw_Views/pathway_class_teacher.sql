CREATE OR REPLACE VIEW eagles_alefdw_dev.pathway_class_teacher AS
SELECT DISTINCT dc.class_dw_id,
                dt.teacher_id
FROM alefdw.dim_class dc
         JOIN alefdw.dim_class_user dcu
              ON dcu.class_user_class_dw_id = dc.class_dw_id
         JOIN alefdw.dim_teacher dt
              ON dcu.class_user_user_dw_id = dt.teacher_dw_id
                  AND dt.teacher_status = 1
                  AND dt.teacher_id NOT IN (SELECT DISTINCT teacher_id FROM bi_alefdw.exclude_teacher_id)
WHERE dc.class_status = 1
  AND dc.class_course_status = 'ACTIVE'
  AND dcu.class_user_status = 1
  AND dcu.class_user_attach_status = 1
  AND dcu.class_user_role_dw_id = 1
  AND dc.class_material_type = 'PATHWAY'
WITH NO SCHEMA BINDING;