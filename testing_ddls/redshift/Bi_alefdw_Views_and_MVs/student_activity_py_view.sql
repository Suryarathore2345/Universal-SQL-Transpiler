create or replace view bi_alefdw_dev.student_activity_py_view as
select distinct login_date_dw_id,
                student_dw_id,
                conjugated_Data.tenant_dw_id,
                school_dw_id,
                TRUE                                                               as outside_school_flag,
                min(local_login_time)                                              as login_local_date_time,
                convert_timezone(dt.tenant_timezone, 'UTC', min(local_login_time)) as login_date_time
from (
         select distinct fsa.fsta_date_dw_id                                                        as login_date_dw_id,
                         fsa.fsta_student_dw_id                                                     as student_dw_id,
                         fsa.fsta_tenant_dw_id                                                      as tenant_dw_id,
                         fsa.fsta_school_dw_id                                                      as school_dw_id,
                         trunc(min(
                                 convert_timezone('UTC', dt.tenant_timezone, fsa.fsta_start_time))) as local_login_date,
                         min(convert_timezone('UTC', dt.tenant_timezone, fsa.fsta_start_time))      as local_login_time
         from alefdw.fact_student_activities fsa
                  join alefdw.dim_school ds
                       on fsa.fsta_school_dw_id = ds.school_dw_id
                  join alefdw.dim_tenant dt
                       on fsa.fsta_tenant_dw_id = dt.tenant_dw_id
         group by fsa.fsta_date_dw_id,
                  fsa.fsta_student_dw_id,
                  fsa.fsta_tenant_dw_id,
                  fsa.fsta_school_dw_id,
                  ds.school_timezone,
                  dt.tenant_timezone,
                  trunc(convert_timezone('UTC', dt.tenant_timezone, fsa.fsta_start_time))
         union
         select distinct ful.ful_date_dw_id                                                          as login_date_dw_id,
                         ful.ful_user_dw_id                                                          as student_dw_id,
                         ful.ful_tenant_dw_id                                                        as tenant_dw_id,
                         ful.ful_school_dw_id                                                        as school_dw_id,
                         trunc(min(
                                 convert_timezone('UTC', dt.tenant_timezone, ful.ful_created_time))) as local_login_date,
                         min(convert_timezone('UTC', dt.tenant_timezone, ful.ful_created_time))      as local_login_time
         from alefdw.fact_user_login ful
                  join alefdw.dim_school ds
                       on ful.ful_school_dw_id = ds.school_dw_id
                  join alefdw.dim_tenant dt
                       on ds.school_tenant_id = dt.tenant_id
         where ful.ful_role_dw_id = 2
         group by ful.ful_date_dw_id,
                  ful.ful_user_dw_id,
                  ful.ful_tenant_dw_id,
                  ful.ful_school_dw_id,
                  ds.school_timezone,
                  dt.tenant_timezone,
                  trunc(convert_timezone('UTC', dt.tenant_timezone, ful.ful_created_time))
         union
         select distinct hbt.fuhha_date_dw_id                                                        as login_date_dw_id,
                         hbt.fuhha_user_dw_id                                                        as teacher_dw_id,
                         hbt.fuhha_tenant_dw_id                                                      as tenant_dw_id,
                         hbt.fuhha_school_dw_id                                                      as school_dw_id,
                         trunc(
                                 convert_timezone('UTC', dt.tenant_timezone, hbt.fuhha_created_time)) as local_login_date,
                         min(convert_timezone('UTC', dt.tenant_timezone, hbt.fuhha_created_time))      as local_login_time
         from alefdw.fact_user_heartbeat_hourly_aggregated hbt
                  join alefdw.dim_school ds
                       on hbt.fuhha_school_dw_id = ds.school_dw_id
                  join alefdw.dim_tenant dt
                       on ds.school_tenant_id = dt.tenant_id
         where fuhha_role_dw_id = 2
         group by 1,2,3,4,5
     ) conjugated_Data
         join alefdw.dim_tenant dt
              on conjugated_Data.tenant_dw_id = dt.tenant_dw_id
group by login_date_dw_id,
         student_dw_id,
         conjugated_Data.tenant_dw_id,
         school_dw_id,
         outside_school_flag,
         local_login_date,
         dt.tenant_timezone
with no schema binding;