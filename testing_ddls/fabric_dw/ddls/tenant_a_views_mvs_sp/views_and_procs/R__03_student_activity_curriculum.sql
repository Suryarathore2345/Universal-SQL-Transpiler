CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_student_activity_curriculum
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.student_activity_curriculum_staging;

        -- --------------------------------------------------------
        -- Step 2: CTAS - Build staging table with full transformation
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.student_activity_curriculum_staging
        WITH (CLUSTER BY (school_dw_id, class_dw_id))
        AS
        WITH date_dimension AS
        (
            SELECT DISTINCT
                full_date                  AS local_date,
                uae_week_number            AS uae_week_num,
                uae_year_week_number       AS uae_wy_num,
                calendar_year_month_number AS year_month
            FROM ${rs_coredw}.dim_date dt
            WHERE dt.full_date >= CONVERT(DATE, DATEADD(DAY, -365, GETDATE()))
              AND dt.full_date <= CONVERT(DATE, GETDATE())
        ),

        active_in_curriculum AS
        (
            SELECT DISTINCT
                CONVERT(
                    DATE,
                    (
                        fle.fle_created_time
                            AT TIME ZONE 'UTC'
                            AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
                    )
                ) AS local_date,

                DATETRUNC(
                    iso_week,
                    fle.fle_created_time
                        AT TIME ZONE 'UTC'
                        AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
                ) AS week_local_date,

                DATETRUNC(
                    MONTH,
                    fle.fle_created_time
                        AT TIME ZONE 'UTC'
                        AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
                ) AS month_local_date,

                fle.fle_school_dw_id,
                fle.fle_grade_dw_id,
                fle.fle_class_dw_id,

                DENSE_RANK() OVER (
                    PARTITION BY
                        CONVERT(
                            DATE,
                            (
                                fle.fle_created_time
                                    AT TIME ZONE 'UTC'
                                    AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
                            )
                        ),
                        fle_class_dw_id
                    ORDER BY fle_student_dw_id ASC
                )
                +
                DENSE_RANK() OVER (
                    PARTITION BY
                        CONVERT(
                            DATE,
                            (
                                fle.fle_created_time
                                    AT TIME ZONE 'UTC'
                                    AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
                            )
                        ),
                        fle_class_dw_id
                    ORDER BY fle_student_dw_id DESC
                ) - 1 AS active_in_curriculum,

                DENSE_RANK() OVER (
                    PARTITION BY
                        DATETRUNC(
                            iso_week,
                            fle.fle_created_time
                                AT TIME ZONE 'UTC'
                                AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
                        ),
                        fle_class_dw_id
                    ORDER BY fle_student_dw_id ASC
                )
                +
                DENSE_RANK() OVER (
                    PARTITION BY
                        DATETRUNC(
                            iso_week,
                            fle.fle_created_time
                                AT TIME ZONE 'UTC'
                                AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
                        ),
                        fle_class_dw_id
                    ORDER BY fle_student_dw_id DESC
                ) - 1 AS weekly_active_in_curriculum,

                DENSE_RANK() OVER (
                    PARTITION BY
                        DATETRUNC(
                            MONTH,
                            fle.fle_created_time
                                AT TIME ZONE 'UTC'
                                AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
                        ),
                        fle_class_dw_id
                    ORDER BY fle_student_dw_id ASC
                )
                +
                DENSE_RANK() OVER (
                    PARTITION BY
                        DATETRUNC(
                            MONTH,
                            fle.fle_created_time
                                AT TIME ZONE 'UTC'
                                AT TIME ZONE ISNULL(dt.windows_timezone, 'UTC')
                        ),
                        fle_class_dw_id
                    ORDER BY fle_student_dw_id DESC
                ) - 1 AS monthly_active_in_curriculum,

                DENSE_RANK() OVER (
                    PARTITION BY fle_class_dw_id
                    ORDER BY fle_student_dw_id ASC
                )
                +
                DENSE_RANK() OVER (
                    PARTITION BY fle_class_dw_id
                    ORDER BY fle_student_dw_id DESC
                ) - 1 AS alltime_active_in_curriculum

            FROM ${rs_coredw}.fact_learning_experience fle
            JOIN ${rs_bi_coredw}.bi_active_schools_dim sch
                ON sch.school_dw_id = fle.fle_school_dw_id
               AND fle.fle_created_time >= CONVERT(DATETIME2, sch.academic_year_start_date)
               AND fle.fle_created_time <  DATEADD(DAY, 1, CONVERT(DATETIME2, sch.academic_year_end_date))
            JOIN ${rs_coredw}.dim_tenant dt
                ON fle.fle_tenant_dw_id = dt.tenant_dw_id
            WHERE fle_curr_subject_dw_id = 129
        ),

        total_in_curriculum AS
        (
            SELECT DISTINCT
                dd.local_date,
                dsc.school_dw_id,
                dsc.school_name,
                dg.grade_name,
                dg.grade_dw_id,
                dc.class_dw_id,
                dc.class_academic_year_id AS content_academic_year_id,
                CONVERT(FLOAT(53), DATEPART(YEAR, dsc.academic_year_end_date))   AS content_academic_year_name,
                CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_start_date))
                    + '-' +
                CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_end_date))  AS academic_year,
                dsc.tenant_name,
                COUNT(DISTINCT ds.student_dw_id) AS class_total_students_curriculum
            FROM ${rs_coredw}.dim_class dc
            JOIN ${rs_coredw}.dim_class_user dcu
                ON dcu.class_user_class_dw_id = dc.class_dw_id
            JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
                ON dc.class_school_id = dsc.school_id
               AND dsc.academic_year_id = dc.class_academic_year_id
            JOIN ${rs_bi_coredw}.bi_student_dim ds
                ON dcu.class_user_user_dw_id = ds.student_dw_id
               AND dsc.school_dw_id = ds.student_school_dw_id
            JOIN ${rs_coredw}.dim_grade dg
                ON dg.grade_id = dc.class_grade_id
            LEFT JOIN ${rs_coredw}.dim_course_subject_association csa
                ON csa.cs_course_id = dc.class_material_id
               AND csa.cs_status = 1
            CROSS JOIN date_dimension dd
            WHERE (
                    (
                        ds.student_status = 2
                        AND dd.local_date >= CONVERT(DATE, ds.student_created_time)
                        AND dd.local_date <  CONVERT(DATE, ds.student_active_until)
                    )
                    OR (
                        ds.student_status = 1
                        AND dd.local_date >= CONVERT(DATE, ds.student_created_time)
                    )
                  )
              AND dcu.class_user_role_dw_id = 2
              AND dcu.class_user_attach_status = 1
              AND (
                    (dcu.class_user_status = 2
                     AND dd.local_date >= CONVERT(DATE, dcu.class_user_created_time)
                     AND dd.local_date <  CONVERT(DATE, dcu.class_user_active_until))
                    OR
                    (dcu.class_user_status = 1
                     AND dd.local_date >= CONVERT(DATE, dcu.class_user_created_time))
                  )
              AND dc.class_status = 1
              AND dc.class_course_status = 'ACTIVE'
              AND (csa.cs_subject_dw_id = 129 OR dc.class_curriculum_subject_id = 963534)
            GROUP BY
                dd.local_date,
                dsc.school_dw_id,
                dsc.school_name,
                dg.grade_name,
                dg.grade_dw_id,
                dc.class_dw_id,
                dc.class_academic_year_id,
                CONVERT(FLOAT(53), DATEPART(YEAR, dsc.academic_year_end_date)),
                CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_start_date))
                    + '-' +
                CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_end_date)),
                dsc.tenant_name
        )

        SELECT DISTINCT
            tc.local_date,
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
        FROM total_in_curriculum tc
        INNER JOIN date_dimension dd
            ON tc.local_date = dd.local_date
        LEFT JOIN active_in_curriculum ac
            ON tc.school_dw_id = ac.fle_school_dw_id
           AND tc.class_dw_id  = ac.fle_class_dw_id
           AND tc.local_date   = ac.local_date;

        -- --------------------------------------------------------
        -- Step 3: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.student_activity_curriculum;

        -- --------------------------------------------------------
        -- Step 4: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.student_activity_curriculum_staging', 'student_activity_curriculum';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;