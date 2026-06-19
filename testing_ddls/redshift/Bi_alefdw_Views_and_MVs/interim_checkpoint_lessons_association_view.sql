CREATE OR REPLACE VIEW bi_alefdw_dev.interim_checkpoint_lessons_association_view AS
SELECT icla.ic_lesson_ic_dw_id,
       icla.ic_lesson_lo_dw_id,
       lo.lo_title
FROM alefdw.dim_ic_lesson_association icla
INNER JOIN alefdw.dim_learning_objective lo
    ON lo.lo_dw_id = icla.ic_lesson_lo_dw_id
WHERE icla.ic_lesson_status = 1
    AND icla.ic_lesson_attach_status =1
    AND lo.lo_status = 1
WITH NO SCHEMA BINDING;