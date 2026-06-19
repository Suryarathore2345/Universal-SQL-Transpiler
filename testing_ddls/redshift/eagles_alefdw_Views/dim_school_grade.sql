CREATE OR REPLACE VIEW alefdatalake.eagles_alefdw_dev.dim_school_grade
AS
SELECT DISTINCT s.school_id,
                trim(upper(s.school_name)) AS school_name,
                g.grade_name,
                concat(g.school_id,
                       g.grade_name)       AS school_grade
FROM alefdw.dim_school s
         JOIN alefdw.dim_grade g ON md5(s.school_id) = md5(g.school_id)
WITH NO SCHEMA BINDING;

alter table eagles_alefdw_dev.dim_school_grade
    owner to marko;

grant delete, insert, references, select, trigger, update on eagles_alefdw_dev.fact_lessons_perf to group business_intelligence;

grant delete, insert, references, select, trigger, update on eagles_alefdw_dev.fact_lessons_perf to group datascience;

grant delete, insert, references, select, trigger, update on eagles_alefdw_dev.fact_lessons_perf to group tdc;

grant select on eagles_alefdw_dev.dim_school_grade to group ro_users;


