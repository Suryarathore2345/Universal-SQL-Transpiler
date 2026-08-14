CREATE OR ALTER VIEW ${os_bi_coredw}.product_level_kpis_monthly_view AS
WITH date_dimension AS (
    SELECT DISTINCT
        calendar_month_start_date AS month_start_date
    FROM ${rs_coredw}.dim_date AS dt
    WHERE dt.full_date >= DATEADD(DAY, -365, CONVERT(date, SYSDATETIME()))
      AND dt.full_date <= CONVERT(date, SYSDATETIME())
),
total_students_in_curriculum AS (
    SELECT
        dd.month_start_date,
        sc.tenant_name,
        sc.school_organisation,
        sc.school_dw_id,
        sc.school_name,
        CASE
            WHEN csa.cs_subject_dw_id = 129
                 OR dc.class_curriculum_subject_id = 963534 THEN 'ARABITS'
            WHEN csa.cs_subject_dw_id IS NULL
                 AND dc.class_material_type = 'CORE'
                 OR (dc.class_material_type = 'INSTRUCTIONAL_PLAN'
                     AND dc.class_curriculum_subject_id <> 963534) THEN 'CORE'
            WHEN csa.cs_subject_dw_id IS NULL
                 AND dc.class_material_type = 'PATHWAY' THEN 'PATHWAY'
            ELSE ''
        END AS product_category,
        COUNT(DISTINCT ds.student_dw_id) AS class_total_students
    FROM ${rs_coredw}.dim_class AS dc
    JOIN ${rs_coredw}.dim_class_user AS dcu
        ON dcu.class_user_class_dw_id = dc.class_dw_id
    LEFT JOIN ${rs_coredw}.dim_course_subject_association AS csa
        ON csa.cs_course_id = dc.class_material_id
       AND csa.cs_status = 1
       AND csa.cs_subject_dw_id = 129   -- Arabits subject
    JOIN ${rs_bi_coredw}.bi_active_schools_dim AS sc
        ON dc.class_school_id = sc.school_id
       AND CONVERT(VARCHAR(50), dc.class_academic_year_id)
         = CONVERT(VARCHAR(50), sc.academic_year_id)
    LEFT JOIN ${rs_bi_coredw}.bi_student_dim AS ds
        ON CONVERT(VARCHAR(50), dcu.class_user_user_dw_id)
         = CONVERT(VARCHAR(50), ds.student_dw_id)
       AND sc.school_dw_id = ds.student_school_dw_id
    CROSS JOIN date_dimension AS dd
    WHERE
        (
            (
                ds.student_status = 2
                AND dd.month_start_date >= DATETRUNC(month, ds.student_created_time)
                AND dd.month_start_date < DATETRUNC(month, ds.student_active_until)
            )
            OR (
                ds.student_status = 1
                AND dd.month_start_date >= DATETRUNC(month, ds.student_created_time)
            )
        )
        AND (
            (
                dcu.class_user_status = 2
                AND dd.month_start_date >= DATETRUNC(month, dcu.class_user_created_time)
                AND dd.month_start_date < DATETRUNC(month, dcu.class_user_active_until)
            )
            OR (
                dcu.class_user_status = 1
                AND dd.month_start_date >= DATETRUNC(month, dcu.class_user_created_time)
            )
        )
        AND dcu.class_user_role_dw_id = 2
        AND dcu.class_user_attach_status = 1
        AND dc.class_status = 1
        AND dc.class_course_status = 'ACTIVE'
    GROUP BY
        dd.month_start_date,
        sc.tenant_name,
        sc.school_organisation,
        sc.school_dw_id,
        sc.school_name,
        CASE
            WHEN csa.cs_subject_dw_id = 129
                 OR dc.class_curriculum_subject_id = 963534 THEN 'ARABITS'
            WHEN csa.cs_subject_dw_id IS NULL
                 AND dc.class_material_type = 'CORE'
                 OR (dc.class_material_type = 'INSTRUCTIONAL_PLAN'
                     AND dc.class_curriculum_subject_id <> 963534) THEN 'CORE'
            WHEN csa.cs_subject_dw_id IS NULL
                 AND dc.class_material_type = 'PATHWAY' THEN 'PATHWAY'
            ELSE ''
        END
),
total_teacher_in_curriculum AS (
    SELECT
        dd.month_start_date,
        sc.tenant_name,
        sc.school_organisation,
        sc.school_dw_id,
        sc.school_name,
        CASE
            WHEN csa.cs_subject_dw_id = 129
                 OR dc.class_curriculum_subject_id = 963534 THEN 'ARABITS'
            WHEN csa.cs_subject_dw_id IS NULL
                 AND dc.class_material_type = 'CORE'
                 OR (dc.class_material_type = 'INSTRUCTIONAL_PLAN'
                     AND dc.class_curriculum_subject_id <> 963534) THEN 'CORE'
            WHEN csa.cs_subject_dw_id IS NULL
                 AND dc.class_material_type = 'PATHWAY' THEN 'PATHWAY'
            ELSE ''
        END AS product_category,
        COUNT(DISTINCT t.teacher_id) AS class_total_teachers
    FROM ${rs_coredw}.dim_class AS dc
    JOIN ${rs_coredw}.dim_class_user AS dcu
        ON dcu.class_user_class_dw_id = dc.class_dw_id
    LEFT JOIN ${rs_coredw}.dim_course_subject_association AS csa
        ON csa.cs_course_id = dc.class_material_id
       AND csa.cs_status = 1
       AND csa.cs_subject_dw_id = 129   -- Arabits subject
    JOIN ${rs_bi_coredw}.bi_active_schools_dim AS sc
        ON dc.class_school_id = sc.school_id
       AND CONVERT(VARCHAR(50), dc.class_academic_year_id)
         = CONVERT(VARCHAR(50), sc.academic_year_id)
    LEFT JOIN ${rs_coredw}.dim_teacher AS t
        ON dcu.class_user_user_dw_id = t.teacher_dw_id
       AND sc.school_dw_id           = t.teacher_school_dw_id
    CROSS JOIN date_dimension AS dd
    WHERE
        (
            (
                t.teacher_status = 2
                AND dd.month_start_date >= DATETRUNC(month, t.teacher_created_time)
                AND dd.month_start_date < DATETRUNC(month, t.teacher_active_until)
            )
            OR (
                t.teacher_status = 1
                AND dd.month_start_date >= DATETRUNC(month, t.teacher_created_time)
            )
        )
        AND (
            (
                dcu.class_user_status = 2
                AND dd.month_start_date >= DATETRUNC(month, dcu.class_user_created_time)
                AND dd.month_start_date < DATETRUNC(month, dcu.class_user_active_until)
            )
            OR (
                dcu.class_user_status = 1
                AND dd.month_start_date >= DATETRUNC(month, dcu.class_user_created_time)
            )
        )
        AND dcu.class_user_role_dw_id = 1
        AND dcu.class_user_attach_status = 1
        AND dc.class_status = 1
        AND dc.class_course_status = 'ACTIVE'
    GROUP BY
        dd.month_start_date,
        sc.tenant_name,
        sc.school_organisation,
        sc.school_dw_id,
        sc.school_name,
        CASE
            WHEN csa.cs_subject_dw_id = 129
                 OR dc.class_curriculum_subject_id = 963534 THEN 'ARABITS'
            WHEN csa.cs_subject_dw_id IS NULL
                 AND dc.class_material_type = 'CORE'
                 OR (dc.class_material_type = 'INSTRUCTIONAL_PLAN'
                     AND dc.class_curriculum_subject_id <> 963534) THEN 'CORE'
            WHEN csa.cs_subject_dw_id IS NULL
                 AND dc.class_material_type = 'PATHWAY' THEN 'PATHWAY'
            ELSE ''
        END
)
SELECT
    ISNULL(st.month_start_date, tc.month_start_date)       AS month_start_date,
    ISNULL(st.school_name, tc.school_name)                 AS school_name,
    ISNULL(st.school_dw_id, tc.school_dw_id)               AS school_dw_id,
    ISNULL(st.school_organisation, tc.school_organisation) AS school_organisation,
    ISNULL(st.tenant_name, tc.tenant_name)                 AS tenant_name,
    ISNULL(st.product_category, tc.product_category)       AS product_category,
    ISNULL(st.class_total_students, 0)                     AS class_total_students,
    ISNULL(tc.class_total_teachers, 0)                     AS class_total_teachers
FROM total_students_in_curriculum AS st
FULL OUTER JOIN total_teacher_in_curriculum AS tc
    ON tc.month_start_date   = st.month_start_date
   AND tc.school_dw_id       = st.school_dw_id
   AND tc.product_category   = st.product_category;
