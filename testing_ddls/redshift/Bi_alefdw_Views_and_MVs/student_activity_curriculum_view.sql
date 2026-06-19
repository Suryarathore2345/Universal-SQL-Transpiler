CREATE OR REPLACE VIEW bi_alefdw_dev.student_activity_curriculum_view AS
WITH date_dimension as
         (SELECT DISTINCT full_date            as local_date,
                          uae_week_number      as uae_week_num,
                          uae_year_week_number as uae_wy_num,
                          calendar_year_month_number as year_month
    FROM alefdw.dim_date dt
    WHERE dt.full_date >= Trunc(sysdate) - 365
    AND dt.full_date <= Trunc(sysdate)
),
    active_in_curriculum as
    (select distinct trunc(convert_timezone('UTC', dt.tenant_timezone, fle.fle_created_time)) as local_date,
    date_trunc('week', convert_timezone('UTC', dt.tenant_timezone, fle.fle_created_time)) as week_local_date,
    date_trunc('month', convert_timezone('UTC', dt.tenant_timezone, fle.fle_created_time)) as month_local_date,
    fle.fle_school_dw_id,
    fle.fle_grade_dw_id,
    fle.fle_class_dw_id,
    DENSE_RANK () OVER (PARTITION BY local_date, fle_class_dw_id ORDER BY fle_student_dw_id ASC) +
        DENSE_RANK () OVER (PARTITION BY local_date, fle_class_dw_id ORDER BY fle_student_dw_id DESC) - 1 as active_in_curriculum,
    DENSE_RANK () OVER (PARTITION BY week_local_date, fle_class_dw_id ORDER BY fle_student_dw_id ASC) +
        DENSE_RANK () OVER (PARTITION BY week_local_date, fle_class_dw_id ORDER BY fle_student_dw_id DESC) - 1 AS weekly_active_in_curriculum,
    DENSE_RANK () OVER (PARTITION BY month_local_date, fle_class_dw_id ORDER BY fle_student_dw_id ASC) +
        DENSE_RANK () OVER (PARTITION BY month_local_date, fle_class_dw_id ORDER BY fle_student_dw_id DESC) - 1 AS monthly_active_in_curriculum,
    DENSE_RANK () OVER (PARTITION BY fle_class_dw_id ORDER BY fle_student_dw_id ASC) +
        DENSE_RANK () OVER (PARTITION BY fle_class_dw_id ORDER BY fle_student_dw_id DESC) - 1 AS alltime_active_in_curriculum
    from alefdw.fact_learning_experience fle
    join bi_alefdw.bi_active_schools_dim_mv sch
        on sch.school_dw_id = fle.fle_school_dw_id
        and trunc(fle.fle_created_time) >= sch.academic_year_start_date
        and trunc(fle.fle_created_time) <= sch.academic_year_end_date
    join alefdw.dim_tenant dt
    on fle.fle_tenant_dw_id = dt.tenant_dw_id
    where fle_curr_subject_dw_id = 129 -- filter for only Arabits events
),
    total_in_curriculum as
    (select distinct local_date,
    dsc.school_dw_id,
    dsc.school_name,
    dg.grade_name,
    dg.grade_dw_id,
    dc.class_dw_id,
    dc.class_academic_year_id                   AS content_academic_year_id,
    date_part(year, dsc.academic_year_end_date) AS content_academic_year_name,
    date_part(year, dsc.academic_year_start_date) || '-' || date_part(year, dsc.academic_year_end_date) AS academic_year,
    dsc.tenant_name,
    count (distinct ds.student_dw_id) as class_total_students_curriculum
    FROM alefdw.dim_class dc
    JOIN alefdw.dim_class_user dcu
        ON dcu.class_user_class_dw_id = dc.class_dw_id
    JOIN bi_alefdw.bi_active_schools_dim_mv dsc
        ON md5(dc.class_school_id) = md5(dsc.school_id)
        AND md5(dsc.academic_year_id) = md5(dc.class_academic_year_id)
    JOIN bi_alefdw.bi_student_dim_mv ds
        ON dcu.class_user_user_dw_id = ds.student_dw_id
        AND dsc.school_dw_id = ds.student_school_dw_id
    JOIN alefdw.dim_grade dg
        ON dg.grade_id = dc.class_grade_id
    LEFT JOIN alefdw.dim_course_subject_association csa
        ON csa.cs_course_id = dc.class_material_id
        AND csa.cs_status = 1
    CROSS JOIN date_dimension dd
    WHERE ((ds.student_status = 2
        AND dd.local_date >= trunc(ds.student_created_time)
        AND dd.local_date < trunc(ds.student_active_until))
        OR (ds.student_status = 1 AND dd.local_date >= trunc(ds.student_created_time)))
    AND dcu.class_user_role_dw_id = 2
    AND dcu.class_user_attach_status = 1
    AND ((dcu.class_user_status = 2
        AND dd.local_date >= trunc(class_user_created_time)
        AND dd.local_date < trunc(class_user_active_until))
        OR (dcu.class_user_status = 1 AND dd.local_date >= trunc(class_user_created_time)))
    AND dc.class_status = 1
    AND dc.class_course_status = 'ACTIVE'
    AND (csa.cs_subject_dw_id = 129 OR dc.class_curriculum_subject_id = 963534) -- Arabits subject_dw_id , courses can have multiple subjects - with this condition we keep the unique value
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
)
select distinct tc.local_date,
                dd.uae_week_num,
                dd.uae_wy_num,
                dd.year_month,
                tc.academic_year,
                tc.tenant_name,
                tc.school_name,
                tc.school_dw_id,
                tc.grade_name,
                tc.class_dw_id,
                tc.content_academic_year_id,
                tc.content_academic_year_name,
                ac.active_in_curriculum,
                ac.weekly_active_in_curriculum,
                ac.monthly_active_in_curriculum,
                ac.alltime_active_in_curriculum,
                tc.class_total_students_curriculum
from total_in_curriculum tc
         inner join date_dimension dd
                    on tc.local_date = dd.local_date
         left join active_in_curriculum ac
                   ON tc.school_dw_id = ac.fle_school_dw_id
                       AND tc.class_dw_id = ac.fle_class_dw_id
                       AND tc.local_date = ac.local_date
    WITH NO SCHEMA BINDING;