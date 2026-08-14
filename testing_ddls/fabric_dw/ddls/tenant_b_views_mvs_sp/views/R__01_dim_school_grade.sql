CREATE OR ALTER VIEW ${OS_EAGLES_COREDW}.dim_school_grade AS
SELECT DISTINCT
    s.school_id,
    UPPER(LTRIM(RTRIM(s.school_name))) AS school_name,
    g.grade_name,
    (CONVERT(varchar(200), g.school_id) + CONVERT(varchar(200), g.grade_name)) AS school_grade
FROM ${RS_COREDW}.dim_school s
JOIN ${RS_COREDW}.dim_grade g
    ON s.school_id = g.school_id;
