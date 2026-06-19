create or replace view bi_alefdw_dev.guardian_login_activity_dm_view as
WITH guardian_info AS
         (select distinct dg.guardian_dw_id,
                          dg.guardian_student_dw_id,
                          dsc.school_dw_id,
                          dsc.school_id,
                          dsc.school_name,
                          dsc.school_city_name,
                          dsc.school_country_name,
                          dsc.school_composition,
                          dsc.school_organisation,
                          dsc.organisation_dw_id,
                          dsc.tenant_name,
                          ds.student_special_needs,
                          ds.student_tags,
                          dsc.school_label,
                          ts.total_students,
                          dgu.guardian_association_date,
                          first_value(guardian_created_time)
                                      over (partition by dg.guardian_dw_id
                                          order by guardian_created_time ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) guardian_registered_date
          from alefdw.dim_guardian dg
                   inner join
               (select distinct student_dw_id,
                                student_school_dw_id,
                                student_special_needs,
                                student_tags
                from bi_alefdw.bi_student_dim_mv
                where student_status = 1) ds on ds.student_dw_id = dg.guardian_student_dw_id
                   inner join bi_alefdw.bi_active_schools_dim_mv dsc
                              on dsc.school_dw_id = ds.student_school_dw_id
                   inner join
               (select school_dw_id, sum(total_students) as total_students
                from bi_alefdw.total_students
                where local_date = trunc(sysdate - 1)
                group by school_dw_id) ts on ds.student_school_dw_id = ts.school_dw_id
                   inner join
               (select distinct guardian_dw_id,
                                guardian_student_dw_id,
                                first_value(guardian_created_time)
                                            over (partition by guardian_dw_id, guardian_student_dw_id
                                                order by guardian_created_time ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as guardian_association_date
                from alefdw.dim_guardian
                where guardian_invitation_status = 2
                  and guardian_student_dw_id is not null) dgu on dgu.guardian_dw_id = dg.guardian_dw_id
                   and dgu.guardian_student_dw_id = dg.guardian_student_dw_id
          where guardian_status = 1)

select distinct gi.guardian_dw_id,
                gi.guardian_student_dw_id,
                gi.school_dw_id,
                gi.school_id,
                gi.school_name,
                gi.school_city_name,
                gi.school_country_name,
                gi.school_composition,
                gi.school_organisation,
                gi.organisation_dw_id,
                gi.tenant_name,
                gi.student_special_needs,
                gi.student_tags,
                gi.school_label,
                gi.total_students,
                gi.guardian_registered_date,
                gi.guardian_association_date,
                ga.activity_date,
                LAG(ga.activity_date, 1)
                    OVER ( PARTITION BY gi.school_dw_id,gi.guardian_dw_id,gi.guardian_association_date ORDER BY ga.activity_date asc, gi.guardian_association_date asc ) as previous_activity_date,
                ga.academic_year,
                ga.academic_year_start_date,
                ga.academic_year_end_date
from guardian_info gi
         left join (select distinct fgaa_guardian_dw_id,
                                    fgaa_school_dw_id,
                                    fgaa_student_dw_id,
                                    dt.academic_year_start_date,
                                    dt.academic_year_end_date,
                                    date_part(year, dt.academic_year_start_date) || '-' ||
                                    date_part(year, dt.academic_year_end_date)                               AS academic_year,
                                    trunc(convert_timezone('UTC', dt.tenant_timezone, fgaa_created_time)) as activity_date
                    from alefdw.fact_guardian_app_activities fgaa
                             inner join bi_alefdw.bi_active_schools_dim_mv dt
                                        on dt.school_dw_id = fgaa.fgaa_school_dw_id
                    WHERE activity_date >= dt.academic_year_start_date
                      AND activity_date <= dt.academic_year_end_date) ga
                   on gi.guardian_dw_id = ga.fgaa_guardian_dw_id
                       and gi.school_dw_id = ga.fgaa_school_dw_id
                       and gi.guardian_student_dw_id = ga.fgaa_student_dw_id
with no schema binding;