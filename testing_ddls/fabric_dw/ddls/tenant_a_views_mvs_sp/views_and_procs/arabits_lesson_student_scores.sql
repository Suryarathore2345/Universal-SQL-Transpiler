CREATE OR ALTER VIEW ${os_bi_coredw}.arabits_lesson_student_scores AS
SELECT 
    CONVERT(DATE, fle.fle_created_time) AS datestamp,
    fle.fle_lo_dw_id,
    lo.lo_title,
    fle.fle_student_dw_id,
    st.student_id,
    dc.class_title,
    MAX(CASE WHEN fle_lesson_type = 'PT' THEN fle_score END) AS PT_score,
    MAX(CASE WHEN fle_lesson_type = 'FT' THEN fle_score END) AS FT_score
FROM (
    SELECT
        fle_lo_dw_id,
        fle_student_dw_id,
        fle_school_dw_id,
        fle_class_dw_id,
        fle_lesson_type,
        fle_score,
        fle_created_time
    FROM (
        SELECT
            fle_lo_dw_id,
            fle_student_dw_id,
            fle_school_dw_id,
            fle_class_dw_id,
            fle_lesson_type,
            fle_score,
            fle_created_time,
               ROW_NUMBER() OVER (
                   PARTITION BY fle_lo_dw_id, fle_student_dw_id, fle_lesson_type
                   ORDER BY fle_score DESC, fle_created_time DESC
               ) AS rank
        FROM ${rs_coredw}.fact_learning_experience
        WHERE fle_lesson_type IN ('PT', 'FT')
    ) sub
    WHERE sub.rank = 1
) fle
JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
    ON fle.fle_school_dw_id = dsc.school_dw_id
   AND fle.fle_created_time >= CONVERT(DATETIME2, dsc.academic_year_start_date)  -- OPT-7: SARGable rewrite
   AND fle.fle_created_time < DATEADD(DAY, 1, CONVERT(DATETIME2, dsc.academic_year_end_date))  -- OPT-7: SARGable rewrite
JOIN ${rs_coredw}.dim_learning_objective lo
    ON lo.lo_dw_id = fle.fle_lo_dw_id
JOIN ${rs_bi_coredw}.bi_student_dim st
    ON st.student_dw_id = fle.fle_student_dw_id
JOIN ${rs_coredw}.dim_class dc
    ON dc.class_dw_id = fle.fle_class_dw_id
   AND dc.class_status = 1
   AND dc.class_course_status = 'ACTIVE'
WHERE fle.fle_school_dw_id = 4225   -- requirement: only this school
GROUP BY 
    CONVERT(DATE, fle.fle_created_time),
    fle.fle_lo_dw_id,
    lo.lo_title,
    fle.fle_student_dw_id,
    st.student_id,
    dc.class_title;
