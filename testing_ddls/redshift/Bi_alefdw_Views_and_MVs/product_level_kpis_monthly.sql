CREATE OR REPLACE VIEW bi_alefdw_dev.product_level_kpis_monthly_view AS
WITH date_dimension as
         (SELECT DISTINCT calendar_month_start_date as month_start_date
          FROM alefdw.dim_date dt
          WHERE dt.full_date >= Trunc(sysdate) - 365
            AND dt.full_date <= Trunc(sysdate)),
     total_students_in_curriculum AS
         (SELECT month_start_date,
                 sc.tenant_name,
                 sc.school_organisation,
                 sc.school_dw_id,
                 sc.school_name,
                 CASE
                    WHEN csa.cs_subject_dw_id = 129 OR dc.class_curriculum_subject_id = 963534 THEN 'ARABITS'
                    WHEN csa.cs_subject_dw_id is null AND dc.class_material_type = 'CORE'
                        OR (dc.class_material_type = 'INSTRUCTIONAL_PLAN' AND dc.class_curriculum_subject_id != 963534) THEN 'ALEF'
                    WHEN csa.cs_subject_dw_id is null AND dc.class_material_type = 'PATHWAY' THEN 'PATHWAY'
                    ELSE ''
                 END                          AS product_category,
                 count(DISTINCT ds.student_dw_id) AS class_total_students
          FROM alefdw.dim_class dc
                   JOIN alefdw.dim_class_user dcu
                        on dcu.class_user_class_dw_id = dc.class_dw_id
                   LEFT JOIN alefdw.dim_course_subject_association csa
                       ON csa.cs_course_id = dc.class_material_id
                       AND csa.cs_status = 1
                       AND csa.cs_subject_dw_id = 129 -- Arabits subject
                   JOIN bi_alefdw.bi_active_schools_dim_mv sc
                        ON md5(dc.class_school_id) = md5(sc.school_id)
                            AND dc.class_academic_year_id=sc.academic_year_id
                   LEFT JOIN bi_alefdw.bi_student_dim_mv ds
                             ON dcu.class_user_user_dw_id = ds.student_dw_id
                                 AND sc.school_dw_id = ds.student_school_dw_id
                   CROSS JOIN date_dimension dd
          WHERE (
              ((ds.student_status = 2
                  AND dd.month_start_date >= date_trunc('month', ds.student_created_time)
                  AND dd.month_start_date < date_trunc('month', ds.student_active_until))
                  OR (ds.student_status = 1 AND dd.month_start_date >=
                                                date_trunc('month', ds.student_created_time))) --if the student is active i.e status = 1 then count him active till date else count him active till his active until date
                  AND ((dcu.class_user_status =
                        2 -- is the user is unenrolled count him till his active untill date else count him till date
                  AND dd.month_start_date >= date_trunc('month', class_user_created_time)
                  AND dd.month_start_date < date_trunc('month', class_user_active_until))
                  OR (dcu.class_user_status = 1 AND
                      dd.month_start_date >= date_trunc('month', class_user_created_time)))
              )
            AND class_user_role_dw_id = 2
            AND class_user_attach_status = 1
            AND dc.class_status = 1
            AND dc.class_course_status = 'ACTIVE'
          GROUP BY 1, 2, 3, 4, 5, 6),
     total_teacher_in_curriculum AS
         (SELECT month_start_date,
                 sc.tenant_name,
                 sc.school_organisation,
                 sc.school_dw_id,
                 sc.school_name,
                  CASE
                    WHEN csa.cs_subject_dw_id = 129 OR dc.class_curriculum_subject_id = 963534 THEN 'ARABITS'
                    WHEN csa.cs_subject_dw_id is null AND dc.class_material_type = 'CORE'
                        OR (dc.class_material_type = 'INSTRUCTIONAL_PLAN' AND dc.class_curriculum_subject_id != 963534) THEN 'ALEF'
                    WHEN csa.cs_subject_dw_id is null AND dc.class_material_type = 'PATHWAY' THEN 'PATHWAY'
                    ELSE ''
                 END                          AS product_category,
                 count(DISTINCT t.teacher_id) AS class_total_teachers
          FROM alefdw.dim_class dc
                   JOIN alefdw.dim_class_user dcu
                        on dcu.class_user_class_dw_id = dc.class_dw_id
                   LEFT JOIN alefdw.dim_course_subject_association csa
                       ON csa.cs_course_id = dc.class_material_id
                       AND csa.cs_status = 1
                       AND csa.cs_subject_dw_id = 129 -- Arabits subject
                   JOIN bi_alefdw.bi_active_schools_dim_mv sc
                        ON md5(dc.class_school_id) = md5(sc.school_id)
                            AND dc.class_academic_year_id=sc.academic_year_id
                   LEFT JOIN alefdw.dim_teacher t
                             ON dcu.class_user_user_dw_id = t.teacher_dw_id
                                 AND sc.school_dw_id = t.teacher_school_dw_id
                   CROSS JOIN date_dimension dd
          WHERE ((t.teacher_status = 2
              AND dd.month_start_date >= date_trunc('month', t.teacher_created_time)
              AND dd.month_start_date < date_trunc('month', t.teacher_active_until))
              OR (t.teacher_status = 1 AND dd.month_start_date >= date_trunc('month', t.teacher_created_time)))
            AND ((dcu.class_user_status = 2 -- is the user is unenrolled count him till his active untill date else count him till date
              AND dd.month_start_date >= date_trunc('month', class_user_created_time)
              AND dd.month_start_date < date_trunc('month', class_user_active_until))
              OR (dcu.class_user_status = 1 AND
                  dd.month_start_date >= date_trunc('month', class_user_created_time))
              )
            AND class_user_role_dw_id = 1
            AND class_user_attach_status = 1
            AND dc.class_status = 1
            AND dc.class_course_status = 'ACTIVE'
          GROUP BY 1, 2, 3, 4, 5, 6)
select coalesce(st.month_start_date, tc.month_start_date)       as month_start_date,
       coalesce(st.school_name, tc.school_name)                 as school_name,
       coalesce(st.school_dw_id, tc.school_dw_id)               as school_dw_id,
       coalesce(st.school_organisation, tc.school_organisation) as school_organisation,
       coalesce(st.tenant_name, tc.tenant_name)                 as tenant_name,
       coalesce(st.product_category, tc.product_category)       as product_category,
       coalesce(st.class_total_students, 0)                     as class_total_students,
       coalesce(tc.class_total_teachers, 0)                     as class_total_teachers
from total_students_in_curriculum st
         full outer join total_teacher_in_curriculum tc
                         on tc.month_start_date = st.month_start_date
                             and tc.school_dw_id = st.school_dw_id
                             and tc.product_category = st.product_category
WITH NO SCHEMA BINDING;
