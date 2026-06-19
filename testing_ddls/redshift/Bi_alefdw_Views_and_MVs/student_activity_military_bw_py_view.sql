create or replace view bi_alefdw_dev.student_activity_military_bw_py_view as

/* Description
   This view is replicated from student_activity_bw_py_view.sql. 
   It is created separately to handle the logic for Military Schools Absentee report as mentioned in following ticket
   https://alefeducation.atlassian.net/browse/ALEF-37501
*/

select distinct login_date_dw_id,
                student_dw_id,
                school_dw_id,
                conjugated_Data.tenant_dw_id,
                min(local_login_time)                                              as login_local_date_time,
                convert_timezone(dt.tenant_timezone, 'UTC', min(local_login_time)) as login_date_time
from (
         select distinct fsa.fsta_date_dw_id                                                        as login_date_dw_id,
                         fsa.fsta_student_dw_id                                                     as student_dw_id,
                         fsa.fsta_tenant_dw_id                                                      as tenant_dw_id,
                         fsa.fsta_school_dw_id                                                      as school_dw_id,
                         trunc(min(
                                 convert_timezone('UTC', ds.tenant_timezone, fsa.fsta_start_time))) as local_login_date,
                         min(convert_timezone('UTC', ds.tenant_timezone, fsa.fsta_start_time))      as local_login_time
         from alefdw.fact_student_activities fsa
                  join bi_alefdw.bi_active_schools_dim_mv ds
                       on fsa.fsta_school_dw_id = ds.school_dw_id
         where ds.school_organisation = 'MHS'
            and TO_CHAR( convert_timezone('UTC', ds.tenant_timezone, fsa.fsta_start_time), 'HH24:MI:SS') between '07:00:00' and '15:00:00'
            and trunc(fsta_dw_created_time) BETWEEN TRUNC(SYSDATE) - 15 AND TRUNC(SYSDATE)
         group by fsa.fsta_date_dw_id,
                  fsa.fsta_student_dw_id,
                  fsa.fsta_tenant_dw_id,
                  fsa.fsta_school_dw_id,
                  ds.tenant_timezone,
                  trunc(convert_timezone('UTC', ds.tenant_timezone, fsa.fsta_start_time))
         union
         select distinct ful.ful_date_dw_id                                                          as login_date_dw_id,
                         ful.ful_user_dw_id                                                          as student_dw_id,
                         ful.ful_tenant_dw_id                                                        as tenant_dw_id,
                         ful.ful_school_dw_id                                                        as school_dw_id,
                         trunc(min(
                                 convert_timezone('UTC', ds.tenant_timezone, ful.ful_created_time))) as local_login_date,
                         min(convert_timezone('UTC', ds.tenant_timezone, ful.ful_created_time))      as local_login_time
         from alefdw.fact_user_login ful
                  join bi_alefdw.bi_active_schools_dim_mv ds
                       on ful.ful_school_dw_id = ds.school_dw_id
         where ful.ful_role_dw_id = 2
            and ds.school_organisation = 'MHS'
            and TO_CHAR( convert_timezone('UTC', ds.tenant_timezone, ful.ful_created_time), 'HH24:MI:SS') between '07:00:00' and '15:00:00'
            and trunc(ful_dw_created_time) BETWEEN TRUNC(SYSDATE) - 15 AND TRUNC(SYSDATE)
         group by ful.ful_date_dw_id,
                  ful.ful_user_dw_id,
                  ful.ful_tenant_dw_id,
                  ful.ful_school_dw_id,
                  ds.tenant_timezone,
                  trunc(convert_timezone('UTC', ds.tenant_timezone, ful.ful_created_time))
         union
         select distinct hbt.fuhha_date_dw_id                                                        as login_date_dw_id,
                         hbt.fuhha_user_dw_id                                                        as teacher_dw_id,
                         hbt.fuhha_tenant_dw_id                                                      as tenant_dw_id,
                         hbt.fuhha_school_dw_id                                                      as school_dw_id,
                         trunc(
                                 convert_timezone('UTC', ds.tenant_timezone, hbt.fuhha_created_time)) as local_login_date,
                         min(convert_timezone('UTC', ds.tenant_timezone, hbt.fuhha_created_time))      as local_login_time
         from alefdw.fact_user_heartbeat_hourly_aggregated hbt
                  join bi_alefdw.bi_active_schools_dim_mv ds
                       on hbt.fuhha_school_dw_id = ds.school_dw_id
         where fuhha_role_dw_id = 2
                     and ds.school_organisation = 'MHS'
            and TO_CHAR( convert_timezone('UTC', ds.tenant_timezone, hbt.fuhha_created_time), 'HH24:MI:SS') between '07:00:00' and '15:00:00'
            and trunc(hbt.fuhha_created_time) BETWEEN TRUNC(SYSDATE) - 15 AND TRUNC(SYSDATE)
         group by 1,2,3,4,5
     ) conjugated_Data
         join alefdw.dim_tenant dt
              on conjugated_Data.tenant_dw_id = dt.tenant_dw_id
group by login_date_dw_id,
         student_dw_id,
         conjugated_Data.tenant_dw_id,
         school_dw_id,
         local_login_date,
         dt.tenant_timezone
with no schema binding;