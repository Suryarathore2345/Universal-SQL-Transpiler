CREATE OR ALTER VIEW ${OS_EAGLES_COREDW}.adt_class_teacher AS
SELECT DISTINCT
    dc.class_dw_id,
    dt.teacher_id
FROM ${RS_COREDW}.dim_class dc
JOIN ${RS_COREDW}.dim_class_user dcu
    ON dcu.class_user_class_dw_id = dc.class_dw_id
LEFT JOIN ${RS_COREDW}.dim_teacher dt
    ON dcu.class_user_user_dw_id = dt.teacher_dw_id
   AND dt.teacher_status = 1
   AND dt.teacher_id NOT IN (SELECT DISTINCT teacher_id FROM ${RS_BI_COREDW}.exclude_teacher_id)
INNER JOIN ${RS_COREDW}.dim_course_ability_test_association cata
    ON cata.cata_course_id = dc.class_material_id
WHERE dc.class_status = 1
  AND dc.class_course_status = 'ACTIVE'
  AND dcu.class_user_status = 1
  AND dcu.class_user_attach_status = 1
  AND dcu.class_user_role_dw_id = 1
  AND cata.cata_status = 1;