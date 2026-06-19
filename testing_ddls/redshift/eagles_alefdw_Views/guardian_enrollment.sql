create or replace view eagles_alefdw.guardian_enrollment_p as
select distinct ts.school_dw_id,
                ts.school_id,
                ts.school_name,
                ts.school_city_name,
                ts.school_country_name,
                ts.school_composition,
                ts.school_organisation,
                ts.tenant_name,
                ts.school_label,
                ts.grade,
                ts.section,
                ts.total_students,
                gre.guardian_dw_id,
                gre.guardian_student_dw_id,
                gre.student_special_needs,
                gre.student_tags,
                CAST(gre.guardian_registered_date as date),
                CAST(gre.guardian_association_date as date)
from (select tst.local_date,
             tst.school_dw_id,
             tst.school_id,
             tst.school_name,
             tst.tenant_name,
             tst.school_city_name,
             tst.school_country_name,
             tst.school_composition,
             tst.school_organisation,
             tst.school_label,
             tst.grade,
             tst.section,
             tst.section_dw_id,
             sum(tst.total_students) as total_students
      from bi_alefdw.total_students tst
      where local_date = trunc(sysdate - 1)
        and academic_year != ''
      group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13) ts
         left join (
    select distinct dg.guardian_dw_id,
                    dg.guardian_student_dw_id,
                    dsc.school_dw_id,
                    dsc.school_id,
                    dsc.school_name,
                    dsc.school_city_name,
                    dsc.school_country_name,
                    dsc.school_composition,
                    dsc.school_organisation,
                    dsc.tenant_name,
                    ds.student_special_needs,
                    ds.student_tags,
                    ds.student_grade_dw_id,
                    dsc.school_label,
                    ds.student_grade_dw_id,
                    ds.student_section_dw_id,
                    dgu.guardian_association_date,
                    first_value(guardian_created_time)
                    over (partition by dg.guardian_dw_id
                        order by guardian_created_time ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) guardian_registered_date
    from alefdw.dim_guardian dg
             inner join (select distinct st.student_dw_id,
                                         st.student_school_dw_id,
                                         st.student_special_needs,
                                         st.student_grade_dw_id,
                                         st.student_tags,
                                         st.student_section_dw_id
                         from bi_alefdw.bi_student_dim_mv st
                         where st.student_status = 1
                           and st.student_school_dw_id NOT IN
                               (1283, 1287, 84, 88, 360, 369, 160, 152, 352, 354, 132, 11, 1809, 3542)) ds
                        on ds.student_dw_id = dg.guardian_student_dw_id
             inner join bi_alefdw.bi_active_schools_dim_mv dsc on dsc.school_dw_id = ds.student_school_dw_id
             left join (select distinct guardian_dw_id,
                                        guardian_student_dw_id,
                                        first_value(guardian_created_time)
                                        over (partition by guardian_dw_id, guardian_student_dw_id
                                            order by guardian_created_time ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING ) as guardian_association_date
                        from alefdw.dim_guardian
                        where guardian_invitation_status = 2
                          and guardian_status = 1
                          and guardian_student_dw_id is not null) dgu
                       on dgu.guardian_dw_id = dg.guardian_dw_id and
                          dgu.guardian_student_dw_id = dg.guardian_student_dw_id
    where guardian_status = 1
      and ds.student_school_dw_id NOT IN (1283, 1287, 84, 88, 360, 369, 160, 152, 352, 354, 132, 11, 1809, 3542)
) gre
                   ON ts.school_dw_id = gre.school_dw_id
                       AND ts.section_dw_id = gre.student_section_dw_id
WITH NO SCHEMA BINDING;

grant delete, insert, references, select, trigger, update on eagles_alefdw.guardian_enrollment_p to group business_intelligence;

grant delete, insert, references, select, trigger, update on eagles_alefdw.guardian_enrollment_p to group datascience;

grant delete, insert, references, select, trigger, update on eagles_alefdw.guardian_enrollment_p to group tdc;

grant select on eagles_alefdw.guardian_enrollment_p to group ro_users;