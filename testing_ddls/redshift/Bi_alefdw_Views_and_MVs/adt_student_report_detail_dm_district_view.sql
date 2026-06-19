CREATE OR REPLACE VIEW bi_alefdw_dev.adt_student_report_detail_dm_district_view AS
select adt.*, sdm.*
from bi_alefdw_dev.adt_student_report_detail_dm_view adt
         full outer join bi_alefdw_dev.school_district_mapping sdm
                         on sdm."school dw id" = adt.school_dw_id
WITH NO SCHEMA BINDING;