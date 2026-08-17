CREATE TABLE devcoredw.dim_tdc (
    rel_tdc_dw_id bigint identity(1,1) ENCODE lzo,
    tdc_created_time timestamp without time zone ENCODE lzo,
    tdc_updated_time timestamp without time zone ENCODE lzo,
    tdc_deleted_time timestamp without time zone ENCODE lzo,
    tdc_dw_created_time timestamp without time zone ENCODE lzo,
    tdc_dw_updated_time timestamp without time zone ENCODE lzo,
    tdc_active_until timestamp without time zone ENCODE lzo,
    tdc_status integer ENCODE lzo,
    tdc_id character varying(36) ENCODE lzo,
    tdc_dw_id bigint ENCODE raw,
    tdc_onboarded boolean ENCODE raw,
    tdc_school_dw_id character varying(36) ENCODE lzo distkey,
    tdc_expirable boolean ENCODE raw
) 
DISTSTYLE KEY
SORTKEY ( tdc_dw_id );
CREATE TABLE devcoredw.fact_guardian_joint_activity (
    fgja_dw_id bigint identity(1,1) ENCODE az64 distkey,
    fgja_created_time timestamp without time zone ENCODE raw,
    fgja_dw_created_time timestamp without time zone ENCODE az64,
    fgja_date_dw_id bigint ENCODE az64,
    fgja_tenant_dw_id bigint ENCODE az64,
    fgja_school_dw_id bigint ENCODE az64,
    fgja_k12_grade integer ENCODE az64,
    fgja_class_dw_id bigint ENCODE az64,
    fgja_student_dw_id bigint ENCODE az64,
    fgja_guardian_dw_id bigint ENCODE az64,
    fgja_pathway_dw_id bigint ENCODE az64,
    fgja_pathway_level_dw_id bigint ENCODE az64,
    fgja_attempt smallint ENCODE az64,
    fgja_rating smallint ENCODE az64,
    fgja_state smallint ENCODE az64,
    fgja_course_activity_container_dw_id bigint ENCODE az64,
    fgja_course_dw_id bigint ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( fgja_created_time );
CREATE TABLE devcoredw.fact_assessment_answer_submitted (
    dw_id bigint ENCODE az64,
    _trace_id character varying(36) ENCODE lzo,
    event_type character varying(100) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    date_dw_id bigint ENCODE az64,
    assessment_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    tenant_dw_id bigint ENCODE az64,
    academic_year_tag character varying(10) ENCODE lzo,
    attempt_number integer ENCODE az64,
    candidate_id character varying(36) ENCODE lzo,
    candidate_dw_id bigint ENCODE az64,
    class_id character varying(36) ENCODE lzo,
    class_dw_id bigint ENCODE az64,
    grade integer ENCODE az64,
    grade_id character varying(36) ENCODE lzo,
    grade_dw_id bigint ENCODE az64,
    time_spent integer ENCODE az64,
    subject character varying(10) ENCODE lzo,
    school_id character varying(36) ENCODE lzo,
    school_dw_id bigint ENCODE az64,
    language character varying(10) ENCODE lzo,
    question_id character varying(36) ENCODE lzo,
    question_code character varying(50) ENCODE lzo,
    question_version integer ENCODE az64,
    test_level_session_id character varying(36) ENCODE lzo,
    test_level_version bigint ENCODE az64,
    test_level_id character varying(36) ENCODE lzo,
    test_level_dw_id bigint ENCODE az64,
    test_level_section_id character varying(36) ENCODE lzo distkey,
    test_level_section_dw_id bigint ENCODE az64,
    reference_code character varying(50) ENCODE lzo,
    test_level character varying(20) ENCODE lzo,
    skill character varying(20) ENCODE lzo,
    material_type character varying(20) ENCODE lzo,
    _ingestion_type character varying(10) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_content_slide (
    dw_id bigint NOT NULL ENCODE az64,
    event_type character varying(100) ENCODE lzo,
    _trace_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    tenant_dw_id bigint ENCODE az64,
    id character varying(36) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    status smallint ENCODE az64,
    active_until character varying(36) ENCODE lzo,
    section_dw_id bigint ENCODE az64 distkey,
    section_id character varying(36) ENCODE lzo,
    source_id character varying(36) ENCODE lzo,
    sequence smallint ENCODE az64,
    show_progressbar boolean ENCODE raw,
    disable_primary_button boolean ENCODE raw,
    is_default_disabled boolean ENCODE raw,
    is_last_slide boolean ENCODE raw,
    widget_id character varying(50) ENCODE lzo,
    widget_type character varying(50) ENCODE raw,
    widget_sub_type character varying(50) ENCODE lzo,
    widget_version character varying(5) ENCODE lzo,
    widget_title character varying(750) ENCODE lzo,
    widget_subtitle character varying(1200) ENCODE lzo,
    widget_has_passage boolean ENCODE raw,
    widget_video boolean ENCODE raw,
    widget_audio boolean ENCODE raw,
    widget_need_help boolean ENCODE raw,
    widget_submit_limit integer ENCODE az64,
    widget_shuffled boolean ENCODE raw,
    widget_feedback boolean ENCODE raw,
    widget_multiple_answer boolean ENCODE raw,
    _ingestion_type character varying(10) ENCODE lzo,
    PRIMARY KEY (dw_id),
    FOREIGN KEY (tenant_dw_id) REFERENCES devcoredw.dim_tenant(tenant_dw_id)
)
DISTSTYLE KEY
SORTKEY ( widget_type, is_last_slide );
CREATE TABLE devcoredw.dim_date (
    date_id integer NOT NULL ENCODE raw,
    full_date date NOT NULL ENCODE raw,
    weekday_name_short character varying(5) NOT NULL ENCODE lzo,
    weekday_name_long character varying(20) NOT NULL ENCODE lzo,
    day_of_week integer NOT NULL ENCODE lzo,
    is_weekend boolean NOT NULL ENCODE raw,
    calendar_week_of date NOT NULL ENCODE lzo,
    calendar_week_number integer NOT NULL ENCODE lzo,
    calendar_month_name_short character varying(20) NOT NULL ENCODE lzo,
    calendar_month_name_long character varying(20) NOT NULL ENCODE lzo,
    calendar_month_number integer NOT NULL ENCODE lzo,
    calendar_month_start_date date NOT NULL ENCODE lzo,
    calendar_month_end_date date NOT NULL ENCODE lzo,
    calendar_quarter_name character varying(20) NOT NULL ENCODE lzo,
    calendar_quarter_number integer NOT NULL ENCODE lzo,
    calendar_quarter_start_date date NOT NULL ENCODE lzo,
    calendar_quarter_end_date date NOT NULL ENCODE lzo,
    calendar_year_week_name character varying(20) NOT NULL ENCODE lzo,
    calendar_year_week_number integer NOT NULL ENCODE lzo,
    calendar_year_month_name character varying(20) NOT NULL ENCODE lzo,
    calendar_year_month_number integer NOT NULL ENCODE lzo,
    calendar_year_quarter_name character varying(20) NOT NULL ENCODE lzo,
    calendar_year_quarter_number integer NOT NULL ENCODE lzo,
    calendar_year_number integer NOT NULL ENCODE lzo,
    calendar_year_name character varying(20) NOT NULL ENCODE lzo,
    calendar_year_start_date date NOT NULL ENCODE lzo,
    calendar_year_end_date date NOT NULL ENCODE lzo,
    broadcast_week_number integer NOT NULL ENCODE lzo,
    broadcast_week_start_date date NOT NULL ENCODE lzo,
    broadcast_week_end_date date NOT NULL ENCODE lzo,
    broadcast_year_week_name character varying(20) NOT NULL ENCODE lzo,
    broadcast_year_week_number integer NOT NULL ENCODE lzo,
    broadcast_month_start_date date NOT NULL ENCODE lzo,
    broadcast_month_end_date date NOT NULL ENCODE lzo,
    broadcast_month_number character varying(20) NOT NULL ENCODE lzo,
    broadcast_month_name_long character varying(20) NOT NULL ENCODE lzo,
    broadcast_month_name_short character varying(20) NOT NULL ENCODE lzo,
    broadcast_year_month_name character varying(20) NOT NULL ENCODE lzo,
    broadcast_year_month_number integer NOT NULL ENCODE lzo,
    broadcast_quarter_start_date date NOT NULL ENCODE lzo,
    broadcast_quarter_end_date date NOT NULL ENCODE lzo,
    broadcast_quarter_number integer NOT NULL ENCODE lzo,
    broadcast_quarter_name character varying(20) NOT NULL ENCODE lzo,
    broadcast_year_quarter_name character varying(20) NOT NULL ENCODE lzo,
    broadcast_year_quarter_number integer NOT NULL ENCODE lzo,
    broadcast_year_start_date date NOT NULL ENCODE lzo,
    broadcast_year_end_date date NOT NULL ENCODE lzo,
    broadcast_year_number integer NOT NULL ENCODE lzo,
    uae_week_number numeric(18,0) ENCODE az64,
    uae_year_week_number numeric(18,0) ENCODE az64,
    PRIMARY KEY (date_id)
)
DISTSTYLE ALL
SORTKEY ( date_id, full_date );
CREATE TABLE devcoredw.dim_learning_objective (
    lo_dw_id bigint identity(1,1) ENCODE raw,
    lo_created_time timestamp without time zone ENCODE raw,
    lo_updated_time timestamp without time zone ENCODE raw,
    lo_deleted_time timestamp without time zone ENCODE raw,
    lo_dw_created_time timestamp without time zone ENCODE raw,
    lo_dw_updated_time timestamp without time zone ENCODE raw,
    lo_status integer ENCODE raw,
    lo_id character varying(36) ENCODE raw,
    lo_title character varying(750) ENCODE raw,
    lo_framework_code character varying(50) ENCODE raw,
    lo_curriculum_id character varying(36) ENCODE lzo,
    lo_curriculum_subject_id character varying(36) ENCODE lzo,
    lo_curriculum_grade_id character varying(36) ENCODE lzo,
    lo_content_academic_year character varying(250) ENCODE lzo,
    lo_code character varying(750) ENCODE lzo,
    lo_ccl_id bigint ENCODE az64,
    lo_action_status integer ENCODE az64,
    lo_skillable boolean ENCODE raw,
    lo_framework_id integer ENCODE az64,
    lo_user_id integer ENCODE az64,
    lo_template_id integer ENCODE az64,
    lo_content_academic_year_id integer ENCODE az64,
    lo_assessment_tool character varying(50) ENCODE lzo,
    lo_type character varying(100) ENCODE lzo,
    lo_publisher_id integer ENCODE az64,
    lo_published_date date ENCODE az64,
    lo_max_stars integer ENCODE az64,
    lo_duration integer ENCODE az64,
    lo_language character varying(50) ENCODE lzo,
    lo_organisation character varying(50) ENCODE lzo,
    lo_template_uuid character varying(36) ENCODE lzo,
    lo_theme_id bigint ENCODE az64,
    UNIQUE (lo_dw_id)
)
DISTSTYLE ALL
SORTKEY ( lo_dw_id );
CREATE TABLE devcoredw.dim_theme (
    theme_id bigint ENCODE az64,
    theme_name character varying(256) ENCODE lzo,
    theme_curriculum_id bigint ENCODE az64,
    theme_curriculum_grade_id bigint ENCODE az64,
    theme_curriculum_subject_id bigint ENCODE az64,
    theme_created_at timestamp without time zone ENCODE az64,
    theme_updated_at timestamp without time zone ENCODE az64,
    theme_status integer NOT NULL ENCODE az64,
    theme_created_time timestamp without time zone ENCODE az64,
    theme_dw_created_time timestamp without time zone ENCODE az64,
    theme_updated_time timestamp without time zone ENCODE az64,
    theme_deleted_time timestamp without time zone ENCODE az64,
    theme_dw_updated_time timestamp without time zone ENCODE az64
)
DISTSTYLE EVEN;
CREATE TABLE devcoredw.fact_badge_awarded (
    fba_dw_id bigint identity(1,1) ENCODE az64 distkey,
    fba_id character varying(36) ENCODE lzo,
    fba_created_time timestamp without time zone ENCODE az64,
    fba_badge_dw_id bigint ENCODE az64,
    fba_student_dw_id bigint ENCODE az64,
    fba_school_dw_id bigint ENCODE az64,
    fba_grade_dw_id bigint ENCODE az64,
    fba_section_dw_id bigint ENCODE az64,
    fba_tenant_dw_id bigint ENCODE az64,
    fba_academic_year_dw_id bigint ENCODE az64,
    fba_content_repository_dw_id bigint ENCODE az64,
    fba_organization_dw_id bigint ENCODE az64,
    fba_date_dw_id bigint ENCODE az64,
    fba_dw_created_time timestamp without time zone DEFAULT ('now'::text)::timestamp with time zone ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( fba_created_time );
CREATE TABLE devcoredw.fact_tutor_conversation (
    ftc_dw_id bigint identity(1,1) ENCODE az64 distkey,
    ftc_created_time timestamp without time zone ENCODE raw,
    ftc_dw_created_time timestamp without time zone ENCODE az64,
    ftc_date_dw_id bigint ENCODE az64,
    ftc_tenant_dw_id bigint ENCODE az64,
    ftc_school_dw_id bigint ENCODE az64,
    ftc_user_dw_id bigint ENCODE az64,
    ftc_role character varying(20) ENCODE lzo,
    ftc_grade integer ENCODE az64,
    ftc_grade_dw_id bigint ENCODE az64,
    ftc_context_id character varying(36) ENCODE bytedict,
    ftc_session_id character varying(36) ENCODE bytedict,
    ftc_subject_dw_id bigint ENCODE az64,
    ftc_subject character varying(20) ENCODE bytedict,
    ftc_language character varying(20) ENCODE lzo,
    ftc_activity_dw_id bigint ENCODE az64,
    ftc_activity_status character varying(20) ENCODE bytedict,
    ftc_material_id character varying(36) ENCODE bytedict,
    ftc_material_type character varying(20) ENCODE lzo,
    ftc_level_dw_id bigint ENCODE az64,
    ftc_outcome_dw_id bigint ENCODE az64,
    ftc_conversation_max_tokens integer ENCODE az64,
    ftc_conversation_token_count integer ENCODE az64,
    ftc_system_prompt_tokens integer ENCODE az64,
    ftc_message_language character varying(30) ENCODE lzo,
    ftc_user_message_source character varying(30) ENCODE lzo,
    ftc_user_message_tokens integer ENCODE az64,
    ftc_user_message_timestamp timestamp without time zone ENCODE az64,
    ftc_bot_message_source character varying(30) ENCODE lzo,
    ftc_bot_message_tokens integer ENCODE az64,
    ftc_bot_message_timestamp timestamp without time zone ENCODE az64,
    ftc_bot_message_confidence double precision ENCODE raw,
    ftc_bot_message_response_time double precision ENCODE raw,
    ftc_session_state integer ENCODE az64,
    ftc_session_status character varying(20) ENCODE lzo,
    ftc_message_id character varying(36) ENCODE bytedict,
    ftc_conversation_id character varying(36) ENCODE bytedict,
    ftc_suggestions_prompt_tokens character varying(256) ENCODE bytedict,
    ftc_message_tokens character varying(256) ENCODE bytedict,
    ftc_activity_page_context_id character varying(256) ENCODE lzo,
    ftc_student_location character varying(256) ENCODE bytedict,
    ftc_suggestion_clicked boolean ENCODE raw,
    ftc_clicked_suggestion_id character varying(36) ENCODE bytedict,
    ftc_message_feedback character varying(10) ENCODE bytedict,
    ftc_course_activity_container_dw_id bigint ENCODE az64,
    ftc_activity_id character varying(36) ENCODE lzo
)
DISTSTYLE KEY
SORTKEY ( ftc_created_time );
CREATE TABLE devcoredw.dim_course_subject_association (
    cs_dw_id bigint ENCODE az64,
    cs_course_dw_id bigint ENCODE az64,
    cs_course_id character varying(36) ENCODE lzo,
    cs_subject_dw_id bigint ENCODE az64 distkey,
    cs_subject_id integer ENCODE az64,
    cs_status integer ENCODE az64,
    cs_created_time timestamp without time zone ENCODE az64,
    cs_dw_created_time timestamp without time zone ENCODE az64,
    cs_updated_time timestamp without time zone ENCODE az64,
    cs_dw_updated_time timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_content_section (
    dw_id bigint NOT NULL ENCODE raw distkey,
    event_type character varying(100) ENCODE lzo,
    _trace_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    id character varying(36) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    updated_time timestamp without time zone ENCODE az64,
    dw_updated_time timestamp without time zone ENCODE az64,
    deleted_time timestamp without time zone ENCODE az64,
    status smallint ENCODE az64,
    content_id bigint ENCODE az64,
    color_set_id smallint ENCODE az64,
    app_status character varying(50) ENCODE lzo,
    title character varying(256) ENCODE lzo,
    type character varying(50) ENCODE lzo,
    number_of_stars smallint ENCODE az64,
    theme character varying(50) ENCODE lzo,
    source_id character varying(36) ENCODE lzo,
    _ingestion_type character varying(10) ENCODE lzo,
    PRIMARY KEY (dw_id),
    UNIQUE (id)
)
DISTSTYLE AUTO
SORTKEY ( dw_id );
CREATE TABLE devcoredw.fact_item_purchase (
    fip_dw_id bigint ENCODE az64,
    fip_created_time timestamp without time zone ENCODE raw,
    fip_dw_created_time timestamp without time zone ENCODE az64,
    fip_date_dw_id bigint ENCODE az64,
    fip_id character varying(36) ENCODE lzo,
    fip_item_id character varying(36) ENCODE lzo,
    fip_item_dw_id bigint ENCODE az64 distkey,
    fip_item_type character varying(50) ENCODE lzo,
    fip_item_title character varying(50) ENCODE lzo,
    fip_item_description character varying(50) ENCODE lzo,
    fip_transaction_id character varying(36) ENCODE lzo,
    fip_school_id character varying(36) ENCODE lzo,
    fip_school_dw_id bigint ENCODE az64,
    fip_grade_id character varying(36) ENCODE lzo,
    fip_grade_dw_id bigint ENCODE az64,
    fip_section_id character varying(36) ENCODE lzo,
    fip_section_dw_id bigint ENCODE az64,
    fip_academic_year_id character varying(36) ENCODE lzo,
    fip_academic_year_dw_id bigint ENCODE az64,
    fip_academic_year integer ENCODE az64,
    fip_student_id character varying(36) ENCODE lzo,
    fip_student_dw_id bigint ENCODE az64,
    fip_tenant_id character varying(36) ENCODE lzo,
    fip_tenant_dw_id bigint ENCODE az64,
    fip_redeemed_stars integer ENCODE az64
)
DISTSTYLE AUTO
SORTKEY ( fip_created_time );
CREATE TABLE devcoredw.fact_level_completed_testing_backfill (
    flc_dw_id bigint ENCODE az64,
    flc_created_time timestamp without time zone ENCODE az64,
    flc_dw_created_time timestamp without time zone ENCODE az64,
    flc_date_dw_id bigint ENCODE az64,
    flc_completed_on timestamp without time zone ENCODE az64,
    flc_tenant_dw_id bigint ENCODE az64,
    flc_student_dw_id bigint ENCODE az64,
    flc_class_dw_id bigint ENCODE az64,
    flc_pathway_dw_id bigint ENCODE az64,
    flc_level_dw_id bigint ENCODE az64,
    flc_total_stars integer ENCODE az64,
    flc_course_activity_container_dw_id bigint ENCODE az64,
    flc_course_dw_id bigint ENCODE az64,
    flc_academic_year character varying(50) ENCODE lzo,
    flc_score integer ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_content_repository (
    rel_content_repository_dw_id bigint identity(1,1) ENCODE raw,
    content_repository_created_time timestamp without time zone ENCODE az64,
    content_repository_dw_created_time timestamp without time zone ENCODE az64,
    content_repository_updated_time timestamp without time zone ENCODE az64,
    content_repository_dw_updated_time timestamp without time zone ENCODE az64,
    content_repository_dw_id bigint ENCODE az64,
    content_repository_id character varying(36) ENCODE lzo,
    content_repository_status integer ENCODE az64,
    content_repository_name character varying(50) ENCODE lzo,
    content_repository_organisation_owner character varying(50) ENCODE lzo,
    content_repository_updated_by_id character varying(36) ENCODE lzo,
    content_repository_created_by_id character varying(36) ENCODE lzo,
    content_repository_deleted_time timestamp without time zone ENCODE az64
)
DISTSTYLE ALL
SORTKEY ( rel_content_repository_dw_id );
CREATE TABLE devcoredw.dim_testpart_section_association (
    dw_id bigint ENCODE az64,
    _trace_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    event_type character varying(50) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    active_until timestamp without time zone ENCODE az64,
    status integer ENCODE az64,
    id character varying(36) ENCODE lzo,
    title character varying(768) ENCODE lzo,
    testpart_id character varying(36) ENCODE lzo,
    testpart_version_id character varying(36) ENCODE lzo,
    question_id character varying(36) ENCODE lzo,
    question_code character varying(100) ENCODE lzo,
    submission_mode character varying(50) ENCODE lzo,
    navigation_mode character varying(50) ENCODE lzo,
    time_limit_seconds integer ENCODE az64,
    shuffle_questions boolean ENCODE raw,
    type character varying(50) ENCODE lzo,
    _ingestion_type character varying(10) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_adt_attempt_threshold (
    aat_dw_id bigint ENCODE az64,
    aat_created_time timestamp without time zone ENCODE raw,
    aat_updated_time timestamp without time zone ENCODE az64,
    aat_dw_created_time timestamp without time zone ENCODE az64,
    aat_dw_updated_time timestamp without time zone ENCODE az64,
    aat_status integer ENCODE az64,
    aat_id character varying(36) ENCODE lzo,
    aat_tenant_dw_id bigint ENCODE az64,
    aat_tenant_id character varying(36) ENCODE lzo,
    aat_academic_year_dw_id bigint ENCODE az64,
    aat_academic_year_id character varying(36) ENCODE lzo,
    aat_school_dw_id bigint ENCODE az64,
    aat_school_id character varying(36) ENCODE lzo,
    aat_state character varying(50) ENCODE lzo,
    aat_attempt_title character varying(100) ENCODE lzo,
    aat_attempt_start_time timestamp without time zone ENCODE az64,
    aat_attempt_end_time timestamp without time zone ENCODE az64,
    aat_attempt_number integer ENCODE az64,
    aat_total_attempts integer ENCODE az64
)
DISTSTYLE AUTO
SORTKEY ( aat_created_time );
CREATE TABLE devcoredw.dim_course_activity_outcome_association (
    caoa_dw_id bigint ENCODE az64,
    caoa_created_time timestamp without time zone ENCODE az64,
    caoa_updated_time timestamp without time zone ENCODE az64,
    caoa_dw_created_time timestamp without time zone ENCODE az64,
    caoa_dw_updated_time timestamp without time zone ENCODE az64,
    caoa_status integer ENCODE az64,
    caoa_course_dw_id bigint ENCODE az64,
    caoa_course_id character varying(36) ENCODE lzo,
    caoa_activity_dw_id bigint ENCODE az64,
    caoa_activity_id character varying(36) ENCODE lzo,
    caoa_outcome_id character varying(36) ENCODE lzo,
    caoa_outcome_type character varying(50) ENCODE lzo,
    caoa_curr_id bigint ENCODE az64,
    caoa_curr_grade_id bigint ENCODE az64,
    caoa_curr_subject_id bigint ENCODE az64 distkey
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_pacing_guide (
    pacing_dw_id bigint ENCODE az64,
    pacing_id character varying(36) ENCODE lzo,
    pacing_course_id character varying(36) ENCODE bytedict,
    pacing_course_dw_id bigint ENCODE az64,
    pacing_class_id character varying(36) ENCODE lzo,
    pacing_class_dw_id bigint ENCODE az64,
    pacing_academic_calendar_id character varying(36) ENCODE bytedict,
    pacing_academic_year_id character varying(36) ENCODE lzo,
    pacing_activity_id character varying(36) ENCODE bytedict,
    pacing_activity_dw_id bigint ENCODE az64,
    pacing_tenant_id character varying(36) ENCODE lzo,
    pacing_tenant_dw_id bigint ENCODE az64,
    pacing_status integer ENCODE raw,
    pacing_activity_order integer ENCODE az64,
    pacing_ip_id character varying(36) ENCODE bytedict,
    pacing_period_start_date date ENCODE az64,
    pacing_period_label character varying(25) ENCODE lzo,
    pacing_period_id character varying(36) ENCODE lzo,
    pacing_period_end_date date ENCODE az64,
    pacing_interval_id character varying(36) ENCODE bytedict,
    pacing_interval_start_date date ENCODE az64,
    pacing_interval_label character varying(240) ENCODE lzo,
    pacing_interval_end_date date ENCODE az64,
    pacing_created_time timestamp without time zone ENCODE az64,
    pacing_dw_created_time timestamp without time zone ENCODE az64,
    pacing_updated_time timestamp without time zone ENCODE az64,
    pacing_dw_updated_time timestamp without time zone ENCODE az64,
    pacing_interval_type character varying(20) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( pacing_status );
CREATE TABLE devcoredw.fact_challenge_game_progress (
    fgc_dw_id bigint ENCODE az64,
    fgc_created_time timestamp without time zone ENCODE raw,
    fgc_dw_created_time timestamp without time zone ENCODE az64,
    fgc_date_dw_id bigint ENCODE az64,
    fgc_id character varying(36) ENCODE lzo,
    fgc_game_id character varying(36) ENCODE lzo,
    fgc_state character varying(20) ENCODE lzo,
    fgc_tenant_id character varying(36) ENCODE lzo,
    fgc_tenant_dw_id bigint ENCODE az64,
    fgc_student_id character varying(36) ENCODE lzo distkey,
    fgc_student_dw_id bigint ENCODE az64,
    fgc_academic_year_id character varying(36) ENCODE lzo,
    fgc_academic_year_dw_id bigint ENCODE az64,
    fgc_academic_year_tag character varying(10) ENCODE lzo,
    fgc_school_id character varying(36) ENCODE lzo,
    fgc_school_dw_id bigint ENCODE az64,
    fgc_grade integer ENCODE az64,
    fgc_organization character varying(100) ENCODE lzo,
    fgc_score integer ENCODE az64
)
DISTSTYLE AUTO
SORTKEY ( fgc_created_time );
CREATE TABLE devcoredw.dim_academic_calendar_teaching_period (
    actp_teaching_period_title character varying(50) ENCODE lzo,
    actp_academic_calendar_id character varying(36) ENCODE lzo,
    actp_dw_updated_time timestamp without time zone ENCODE az64,
    actp_teaching_period_is_current boolean ENCODE raw,
    actp_teaching_period_id character varying(36) ENCODE lzo,
    actp_teaching_period_start_date date ENCODE az64,
    actp_teaching_period_end_date date ENCODE az64,
    actp_dw_created_time timestamp without time zone ENCODE az64,
    actp_updated_time timestamp without time zone ENCODE az64,
    actp_created_time timestamp without time zone ENCODE az64,
    actp_dw_id bigint ENCODE az64,
    actp_teaching_period_created_by_id character varying(36) ENCODE lzo,
    actp_teaching_period_updated_by_id character varying(36) ENCODE lzo,
    actp_status integer ENCODE az64,
    actp_teaching_period_order integer ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_marketplace_config (
    dw_id bigint ENCODE az64,
    _trace_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    event_type character varying(50) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    updated_time timestamp without time zone ENCODE az64,
    deleted_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    dw_updated_time timestamp without time zone ENCODE az64,
    status integer ENCODE az64,
    id character varying(36) ENCODE lzo,
    impact_type character varying(50) ENCODE lzo,
    star_cost bigint ENCODE az64,
    quota bigint ENCODE az64,
    _ingestion_type character varying(10) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.fact_tutor_suggestions (
    fts_dw_id bigint ENCODE az64,
    fts_message_id character varying(36) ENCODE lzo,
    fts_suggestion_id character varying(36) ENCODE lzo,
    fts_created_time timestamp without time zone ENCODE az64,
    fts_dw_created_time timestamp without time zone ENCODE az64,
    fts_user_id character varying(36) ENCODE lzo,
    fts_user_dw_id bigint ENCODE az64 distkey,
    fts_session_id character varying(36) ENCODE lzo,
    fts_conversation_id character varying(36) ENCODE lzo,
    fts_response_time double precision ENCODE raw,
    fts_success_parser_tokens integer ENCODE az64,
    fts_failure_parser_tokens integer ENCODE az64,
    fts_suggestion_clicked boolean ENCODE raw,
    fts_date_dw_id bigint ENCODE az64,
    fts_tenant_dw_id bigint ENCODE az64,
    fts_tenant_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_outcome_association (
    outcome_association_dw_id bigint identity(1,1) ENCODE raw,
    outcome_association_created_time timestamp without time zone ENCODE az64,
    outcome_association_updated_time timestamp without time zone ENCODE az64,
    outcome_association_dw_created_time timestamp without time zone ENCODE az64,
    outcome_association_dw_updated_time timestamp without time zone ENCODE az64,
    outcome_association_status integer ENCODE az64,
    outcome_association_outcome_id character varying(36) ENCODE lzo,
    outcome_association_id character varying(36) ENCODE lzo,
    outcome_association_type integer ENCODE az64,
    outcome_association_attach_status integer ENCODE az64
)
DISTSTYLE ALL
SORTKEY ( outcome_association_dw_id );
CREATE TABLE devcoredw.dim_school_content_repository_association (
    scra_dw_id bigint ENCODE az64,
    scra_school_id character varying(36) ENCODE lzo,
    scra_school_dw_id bigint ENCODE az64,
    scra_content_repository_id character varying(36) ENCODE lzo,
    scra_content_repository_dw_id bigint ENCODE az64,
    scra_status integer ENCODE az64,
    scra_active_until timestamp without time zone ENCODE az64,
    scra_created_time timestamp without time zone ENCODE az64,
    scra_dw_created_time timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.schema_evolution_testing_table (
    first_name character varying(256) ENCODE lzo,
    id integer NOT NULL ENCODE az64,
    last_name character varying(256) ENCODE lzo,
    temp2 integer NOT NULL ENCODE az64,
    temp integer NOT NULL ENCODE az64,
    temp3 integer NOT NULL ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.second_ever_table (
    id integer ENCODE az64,
    name character varying(256) ENCODE lzo,
    age integer ENCODE az64,
    email character varying(256) ENCODE lzo,
    country character varying(256) ENCODE lzo,
    _commit_version bigint ENCODE az64,
    _change_type character varying(256) ENCODE lzo,
    _commit_timestamp timestamp without time zone ENCODE az64
)
DISTSTYLE EVEN;
CREATE TABLE devcoredw.fact_pathway_teacher_activity (
    fpta_dw_id bigint ENCODE az64,
    fpta_created_time timestamp without time zone ENCODE az64,
    fpta_dw_created_time timestamp without time zone ENCODE az64,
    fpta_date_dw_id bigint ENCODE az64,
    fpta_student_id character varying(36) ENCODE lzo distkey,
    fpta_level_id character varying(36) ENCODE lzo,
    fpta_pathway_id character varying(36) ENCODE lzo,
    fpta_tenant_id character varying(36) ENCODE lzo,
    fpta_action_name character varying(255) ENCODE lzo,
    fpta_class_id character varying(36) ENCODE lzo,
    fpta_teacher_id character varying(36) ENCODE lzo,
    fpta_activity_id character varying(36) ENCODE lzo,
    fpta_action_time timestamp without time zone ENCODE az64,
    fpta_tenant_dw_id bigint ENCODE az64,
    fpta_student_dw_id bigint ENCODE az64,
    fpta_level_dw_id bigint ENCODE az64,
    fpta_pathway_dw_id bigint ENCODE az64,
    fpta_class_dw_id bigint ENCODE az64,
    fpta_teacher_dw_id bigint ENCODE az64,
    fpta_activity_dw_id bigint ENCODE az64,
    fpta_activity_type integer ENCODE az64,
    fpta_start_date date ENCODE az64,
    fpta_end_date date ENCODE az64,
    fpta_course_dw_id bigint ENCODE az64,
    fpta_course_activity_container_dw_id bigint ENCODE az64,
    fpta_activity_progress_status character varying(30) ENCODE lzo,
    fpta_activity_type_value character varying(50) ENCODE lzo,
    fpta_is_added_as_resource boolean DEFAULT false ENCODE raw
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_cx_user (
    cx_user_dw_id bigint ENCODE az64,
    cx_user_cx_id bigint ENCODE az64,
    cx_user_id character varying(36) ENCODE lzo,
    cx_user_cx_status integer ENCODE az64,
    cx_user_status integer ENCODE az64,
    cx_user_subject character varying(25) ENCODE lzo,
    cx_user_role_dw_id bigint ENCODE az64,
    cx_user_created_time timestamp without time zone ENCODE az64,
    cx_user_dw_created_time timestamp without time zone ENCODE az64,
    cx_user_updated_time timestamp without time zone ENCODE az64,
    cx_user_dw_updated_time timestamp without time zone ENCODE az64,
    cx_user_deleted_time timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_cx_role (
    role_dw_id bigint identity(1,1) ENCODE raw,
    role_id integer ENCODE az64,
    role_title character varying(20) ENCODE lzo,
    role_status integer ENCODE az64,
    role_created_time timestamp without time zone ENCODE az64,
    role_dw_created_time timestamp without time zone ENCODE az64,
    role_updated_time timestamp without time zone ENCODE az64,
    role_dw_updated_time timestamp without time zone ENCODE az64,
    role_deleted_time timestamp without time zone ENCODE az64
)
DISTSTYLE ALL
SORTKEY ( role_dw_id );
CREATE TABLE devcoredw.fact_user_avatar1 (
    fua_dw_id bigint ENCODE az64,
    fua_created_time timestamp without time zone ENCODE az64,
    fua_dw_created_time timestamp without time zone ENCODE az64,
    fua_date_dw_id bigint ENCODE az64,
    fua_school_dw_id bigint ENCODE az64,
    fua_grade_id character varying(36) ENCODE lzo,
    fua_grade_dw_id bigint ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_badge (
    bdg_dw_id bigint NOT NULL generated by default as identity(1,1) ENCODE raw distkey,
    bdg_id character varying(36) ENCODE lzo,
    bdg_tier character varying(36) ENCODE lzo,
    bdg_grade character varying(36) ENCODE lzo,
    bdg_type character varying(36) ENCODE lzo,
    bdg_tenant_dw_id bigint ENCODE az64,
    bdg_title character varying(36) ENCODE lzo,
    bdg_category character varying(36) ENCODE lzo,
    bdg_threshold integer ENCODE az64,
    bdg_status integer ENCODE az64,
    bdg_created_time timestamp without time zone ENCODE az64,
    bdg_deleted_time timestamp without time zone ENCODE az64,
    bdg_dw_created_time timestamp without time zone DEFAULT ('now'::text)::timestamp with time zone ENCODE az64,
    bdg_active_until timestamp without time zone DEFAULT ('now'::text)::timestamp with time zone ENCODE az64,
    PRIMARY KEY (bdg_dw_id)
)
DISTSTYLE KEY
SORTKEY ( bdg_dw_id );
CREATE TABLE devcoredw.test_table (
    id bigint ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_class_user (
    class_user_created_time timestamp without time zone ENCODE az64,
    class_user_updated_time timestamp without time zone ENCODE az64,
    class_user_deleted_time timestamp without time zone ENCODE az64,
    class_user_dw_created_time timestamp without time zone ENCODE az64,
    class_user_dw_updated_time timestamp without time zone ENCODE az64,
    class_user_active_until timestamp without time zone ENCODE az64,
    class_user_status integer ENCODE az64,
    class_user_class_dw_id bigint ENCODE raw,
    class_user_user_dw_id bigint ENCODE raw,
    class_user_role_dw_id bigint ENCODE az64,
    class_user_attach_status integer ENCODE az64,
    rel_class_user_dw_id bigint ENCODE raw
)
DISTSTYLE ALL
SORTKEY ( rel_class_user_dw_id );
CREATE TABLE devcoredw.fact_ktg (
    ktg_dw_id bigint identity(1,1) ENCODE raw,
    ktg_id character varying(256) ENCODE lzo,
    ktg_created_time timestamp without time zone ENCODE lzo,
    ktg_dw_created_time timestamp without time zone ENCODE lzo,
    ktg_date_dw_id bigint ENCODE lzo,
    ktg_tenant_dw_id bigint ENCODE lzo,
    ktg_student_dw_id bigint ENCODE raw,
    ktg_subject_dw_id bigint ENCODE raw,
    ktg_school_dw_id bigint ENCODE raw,
    ktg_grade_dw_id bigint ENCODE raw,
    ktg_section_dw_id bigint ENCODE raw,
    ktg_lo_dw_id bigint ENCODE raw,
    ktg_academic_year_dw_id bigint ENCODE raw,
    ktg_num_key_terms smallint ENCODE lzo,
    ktg_kt_collection_id bigint ENCODE lzo,
    ktg_trimester_id character varying(256) ENCODE lzo,
    ktg_trimester_order smallint ENCODE lzo,
    ktg_type character varying(200) ENCODE lzo,
    ktg_question_type character varying(200) ENCODE lzo,
    ktg_min_question smallint ENCODE lzo,
    ktg_max_question smallint ENCODE lzo,
    ktg_question_time_allotted integer ENCODE lzo,
    ktg_instructional_plan_id character varying(36) ENCODE lzo,
    ktg_learning_path_id character varying(36) ENCODE lzo,
    ktg_class_dw_id bigint ENCODE az64,
    ktg_material_id character varying(36) ENCODE lzo,
    ktg_material_type character varying(20) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( ktg_dw_id, ktg_student_dw_id, ktg_subject_dw_id, ktg_school_dw_id, ktg_grade_dw_id, ktg_section_dw_id, ktg_lo_dw_id, ktg_academic_year_dw_id );
CREATE TABLE devcoredw.fact_pathway_leaderboard (
    fpl_dw_id bigint identity(1,1) ENCODE az64 distkey,
    fpl_created_time timestamp without time zone ENCODE raw,
    fpl_dw_created_time timestamp without time zone ENCODE az64,
    fpl_date_dw_id bigint ENCODE az64,
    fpl_id character varying(36) ENCODE lzo,
    fpl_student_dw_id bigint ENCODE az64,
    fpl_pathway_dw_id bigint ENCODE az64,
    fpl_class_dw_id bigint ENCODE az64,
    fpl_grade_dw_id bigint ENCODE az64,
    fpl_academic_year_dw_id bigint ENCODE az64,
    fpl_start_date date ENCODE az64,
    fpl_end_date date ENCODE az64,
    fpl_order smallint ENCODE az64,
    fpl_level_competed_count smallint ENCODE az64,
    fpl_average_score double precision ENCODE raw,
    fpl_total_stars smallint ENCODE az64,
    fpl_tenant_dw_id bigint ENCODE az64,
    fpl_course_dw_id bigint ENCODE az64,
    fpl_average_proficiency_score double precision DEFAULT -1 ENCODE raw
)
DISTSTYLE KEY
SORTKEY ( fpl_created_time );
CREATE TABLE devcoredw.fact_guardian_app_activities (
    fgaa_dw_id bigint identity(1,1) ENCODE lzo,
    fgaa_created_time timestamp without time zone ENCODE lzo,
    fgaa_actor_object_type character varying(100) ENCODE lzo,
    fgaa_actor_account_homepage character varying(100) ENCODE lzo,
    fgaa_verb_display character varying(100) ENCODE lzo,
    fgaa_verb_id character varying(100) ENCODE lzo,
    fgaa_object_id character varying(2000) ENCODE lzo,
    fgaa_object_type character varying(100) ENCODE lzo,
    fgaa_object_account_homepage character varying(100) ENCODE lzo,
    fgaa_dw_created_time timestamp without time zone ENCODE lzo,
    fgaa_event_type character varying(100) ENCODE lzo,
    fgaa_date_dw_id bigint ENCODE lzo,
    fgaa_device character varying(100) ENCODE lzo,
    fgaa_tenant_dw_id bigint ENCODE lzo,
    fgaa_guardian_dw_id bigint ENCODE raw,
    fgaa_student_dw_id bigint ENCODE lzo,
    fgaa_school_dw_id bigint ENCODE lzo,
    fgaa_timestamp_local character varying(100) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( fgaa_guardian_dw_id );
CREATE TABLE devcoredw.dim_course_resource_activity_grade_association (
    craga_dw_id bigint ENCODE az64,
    craga_created_time timestamp without time zone ENCODE raw,
    craga_updated_time timestamp without time zone ENCODE az64,
    craga_deleted_time timestamp without time zone ENCODE az64,
    craga_dw_created_time timestamp without time zone ENCODE az64,
    craga_dw_updated_time timestamp without time zone ENCODE az64,
    craga_dw_deleted_time timestamp without time zone ENCODE az64,
    craga_status integer ENCODE az64,
    craga_course_dw_id bigint ENCODE az64,
    craga_course_id character varying(36) ENCODE lzo,
    craga_activity_dw_id bigint ENCODE az64,
    craga_activity_id character varying(36) ENCODE lzo,
    craga_grade_id character varying(5) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( craga_created_time );
CREATE TABLE devcoredw.be_fact_returns (
    row_id integer ENCODE az64,
    order_id character varying(256) ENCODE lzo,
    returned character varying(256) ENCODE lzo,
    is_returned character varying(256) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_test_testpart_association (
    dw_id bigint ENCODE az64,
    _trace_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    event_type character varying(50) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    active_until timestamp without time zone ENCODE az64,
    status integer ENCODE az64,
    id character varying(36) ENCODE lzo,
    version_id character varying(36) ENCODE lzo,
    version bigint ENCODE az64,
    title character varying(768) ENCODE lzo,
    testpart_id character varying(36) ENCODE lzo,
    testpart_version_id character varying(36) ENCODE lzo,
    app_status character varying(36) ENCODE lzo,
    user_type character varying(36) ENCODE lzo,
    active boolean ENCODE raw,
    _ingestion_type character varying(10) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_course (
    rel_course_dw_id bigint ENCODE az64,
    course_dw_id bigint ENCODE az64,
    course_id character varying(36) ENCODE lzo,
    course_type character varying(25) ENCODE lzo,
    course_status integer ENCODE az64,
    course_name character varying(255) ENCODE lzo,
    course_code character varying(50) ENCODE lzo,
    course_subject_id integer ENCODE az64,
    course_organization_dw_id bigint ENCODE az64,
    course_created_time timestamp without time zone ENCODE az64,
    course_deleted_time timestamp without time zone ENCODE az64,
    course_updated_time timestamp without time zone ENCODE az64,
    course_dw_created_time timestamp without time zone ENCODE az64,
    course_dw_updated_time timestamp without time zone ENCODE az64,
    course_dw_deleted_time timestamp without time zone ENCODE az64,
    course_lang_code character varying(10) ENCODE lzo,
    course_program_enabled boolean ENCODE raw,
    course_resources_enabled boolean ENCODE raw,
    course_placement_type character varying(50) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_tag (
    tag_created_time timestamp without time zone ENCODE az64,
    tag_updated_time timestamp without time zone ENCODE az64,
    tag_dw_created_time timestamp without time zone ENCODE az64,
    tag_dw_updated_time timestamp without time zone ENCODE az64,
    tag_id character varying(36) ENCODE lzo,
    tag_name character varying(1024) ENCODE lzo,
    tag_status integer ENCODE az64,
    tag_type character varying(36) ENCODE lzo,
    tag_association_id character varying(36) ENCODE lzo,
    tag_association_dw_id bigint ENCODE az64,
    tag_association_type integer ENCODE az64,
    tag_association_attach_status integer ENCODE az64,
    tag_dw_id bigint ENCODE raw
)
DISTSTYLE ALL
SORTKEY ( tag_dw_id );
CREATE TABLE devcoredw.dim_substandard (
    substandard_dw_id bigint identity(1,1) ENCODE raw,
    substandard_created_time timestamp without time zone ENCODE lzo,
    substandard_updated_time timestamp without time zone ENCODE lzo,
    substandard_deleted_time timestamp without time zone ENCODE lzo,
    substandard_dw_created_time timestamp without time zone ENCODE lzo,
    substandard_dw_updated_time timestamp without time zone ENCODE lzo,
    substandard_status integer ENCODE lzo,
    substandard_id character varying(36) ENCODE lzo,
    substandard_name character varying(500) ENCODE lzo,
    substandard_description character varying(500) ENCODE lzo,
    substandard_standard_id bigint ENCODE lzo
)
DISTSTYLE ALL
SORTKEY ( substandard_dw_id );
CREATE TABLE devcoredw.fact_adaptive_practice_progress (
    dw_id bigint ENCODE az64,
    event_type character varying(100) ENCODE lzo,
    _trace_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    tenant_dw_id bigint ENCODE az64,
    date_dw_id bigint ENCODE az64,
    uuid character varying(36) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    student_id character varying(36) ENCODE lzo distkey,
    student_dw_id bigint ENCODE az64,
    class_id character varying(36) ENCODE lzo,
    class_dw_id bigint ENCODE az64,
    school_id character varying(36) ENCODE lzo,
    school_dw_id bigint ENCODE az64,
    pathway_id character varying(36) ENCODE lzo,
    pathway_dw_id bigint ENCODE az64,
    level_id character varying(36) ENCODE lzo,
    level_dw_id bigint ENCODE az64,
    academic_year_tag character varying(40) ENCODE lzo,
    session_id character varying(36) ENCODE lzo,
    ml_session_id character varying(36) ENCODE lzo,
    level_proficiency_tier character varying(50) ENCODE lzo,
    assessment_id character varying(36) ENCODE lzo,
    session_attempt integer ENCODE az64,
    stars integer ENCODE az64,
    time_spent integer ENCODE az64,
    question_id character varying(36) ENCODE lzo,
    question_skill_id character varying(36) ENCODE lzo,
    question_skill_dw_id bigint ENCODE az64,
    question_difficulty_label character varying(30) ENCODE lzo,
    skill_proficiency_tier character varying(40) ENCODE lzo,
    time_spent_on_question integer ENCODE az64,
    hint_used boolean ENCODE raw,
    is_answer_correct boolean ENCODE raw,
    next_question_id character varying(36) ENCODE lzo,
    attempt_number integer ENCODE az64,
    next_question_skill_id character varying(36) ENCODE lzo,
    next_question_skill_dw_id bigint ENCODE az64,
    next_question_difficulty_label character varying(30) ENCODE lzo,
    skill_proficiency_score double precision ENCODE raw,
    level_proficiency_score double precision ENCODE raw,
    answer_score double precision ENCODE raw,
    _ingestion_type character varying(10) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_interim_checkpoint_rules (
    ic_rule_dw_id bigint identity(1,1) ENCODE raw,
    ic_rule_created_time timestamp without time zone ENCODE az64,
    ic_rule_dw_created_time timestamp without time zone ENCODE az64,
    ic_rule_updated_time timestamp without time zone ENCODE az64,
    ic_rule_dw_updated_time timestamp without time zone ENCODE az64,
    ic_rule_status smallint ENCODE az64,
    ic_rule_attach_status smallint ENCODE az64,
    ic_rule_type smallint ENCODE az64,
    ic_rule_resource_type character varying(50) ENCODE lzo,
    ic_rule_ic_dw_id bigint ENCODE az64,
    ic_rule_outcome_dw_id bigint ENCODE az64,
    ic_rule_no_questions integer ENCODE az64
)
DISTSTYLE ALL
SORTKEY ( ic_rule_dw_id );
CREATE TABLE devcoredw.dim_learning_path (
    learning_path_dw_id bigint identity(1,1) ENCODE raw,
    learning_path_created_time timestamp without time zone ENCODE raw,
    learning_path_updated_time timestamp without time zone ENCODE raw,
    learning_path_deleted_time timestamp without time zone ENCODE raw,
    learning_path_dw_created_time timestamp without time zone ENCODE raw,
    learning_path_dw_updated_time timestamp without time zone ENCODE raw,
    learning_path_status integer ENCODE raw,
    learning_path_id character varying(108) ENCODE raw,
    learning_path_uuid character varying(36) ENCODE raw,
    learning_path_name character varying(255) ENCODE raw,
    learning_path_lp_status character varying(50) ENCODE raw,
    learning_path_language_type_script character varying(50) ENCODE raw,
    learning_path_experiential_learning boolean ENCODE raw,
    learning_path_tutor_dhabi_enabled boolean ENCODE raw,
    learning_path_default boolean ENCODE raw,
    learning_path_school_id character varying(36) ENCODE raw,
    learning_path_subject_id character varying(36) ENCODE raw,
    learning_path_curriculum_id character varying(50) ENCODE raw,
    learning_path_curriculum_grade_id character varying(50) ENCODE raw,
    learning_path_curriculum_subject_id character varying(50) ENCODE raw,
    learning_path_academic_year_id character varying(36) ENCODE lzo,
    learning_path_content_academic_year integer ENCODE lzo,
    learning_path_class_id character varying(36) ENCODE lzo
)
DISTSTYLE ALL
SORTKEY ( learning_path_dw_id );
CREATE TABLE devcoredw.dim_core_activity_assign (
    cta_dw_id bigint ENCODE az64,
    cta_event_type character varying(100) ENCODE lzo,
    cta_id character varying(36) ENCODE raw,
    cta_created_time timestamp without time zone ENCODE az64,
    cta_dw_created_time timestamp without time zone ENCODE az64,
    cta_status smallint ENCODE az64,
    cta_active_until timestamp without time zone ENCODE az64,
    cta_action_time timestamp without time zone ENCODE az64,
    cta_start_date character varying(10) ENCODE lzo,
    cta_end_date character varying(10) ENCODE lzo,
    cta_ay_tag character varying(10) ENCODE lzo,
    cta_tenant_dw_id bigint ENCODE az64,
    cta_tenant_id character varying(36) ENCODE lzo,
    cta_student_dw_id bigint ENCODE az64,
    cta_student_id character varying(36) ENCODE lzo distkey,
    cta_course_dw_id bigint ENCODE az64,
    cta_course_id character varying(36) ENCODE lzo,
    cta_class_dw_id bigint ENCODE az64,
    cta_class_id character varying(36) ENCODE lzo,
    cta_teacher_dw_id bigint ENCODE az64,
    cta_teacher_id character varying(36) ENCODE lzo,
    cta_activity_dw_id bigint ENCODE az64,
    cta_activity_id character varying(36) ENCODE lzo,
    cta_activity_type character varying(20) ENCODE lzo,
    cta_progress_status character varying(30) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( cta_id );
CREATE TABLE devcoredw.dim_course_activity_container_grade_association (
    cacga_dw_id bigint ENCODE az64,
    cacga_container_id character varying(36) ENCODE lzo,
    cacga_container_dw_id bigint ENCODE az64,
    cacga_course_id character varying(36) ENCODE lzo,
    cacga_grade character varying(10) ENCODE lzo,
    cacga_created_time timestamp without time zone ENCODE az64,
    cacga_dw_created_time timestamp without time zone ENCODE az64,
    cacga_updated_time timestamp without time zone ENCODE az64,
    cacga_dw_updated_time timestamp without time zone ENCODE az64,
    cacga_status integer ENCODE az64,
    cacga_course_dw_id bigint ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.fact_inc_game_session (
    inc_game_session_dw_id bigint identity(1,1) ENCODE lzo,
    inc_game_session_id character varying(36) ENCODE lzo,
    inc_game_session_start_time timestamp without time zone ENCODE lzo,
    inc_game_session_end_time timestamp without time zone ENCODE lzo,
    inc_game_session_dw_created_time timestamp without time zone ENCODE lzo,
    inc_game_session_date_dw_id bigint ENCODE lzo,
    inc_game_session_time_spent integer ENCODE lzo,
    inc_game_session_tenant_dw_id bigint ENCODE lzo,
    inc_game_session_game_id character varying(36) ENCODE lzo,
    inc_game_session_title character varying(256) ENCODE lzo,
    inc_game_session_num_players integer ENCODE lzo,
    inc_game_session_num_joined_players integer ENCODE lzo,
    inc_game_session_started_by_dw_id bigint ENCODE lzo,
    inc_game_session_status integer ENCODE lzo,
    inc_game_session_is_start boolean ENCODE raw,
    inc_game_session_is_assessment boolean DEFAULT false ENCODE raw
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_term (
    term_dw_id bigint identity(1,1) ENCODE raw,
    term_created_time timestamp without time zone ENCODE az64,
    term_updated_time timestamp without time zone ENCODE az64,
    term_deleted_time timestamp without time zone ENCODE az64,
    term_dw_created_time timestamp without time zone ENCODE az64,
    term_dw_updated_time timestamp without time zone ENCODE az64,
    term_status integer ENCODE az64,
    term_id character varying(36) ENCODE lzo,
    term_academic_period_order integer ENCODE az64,
    term_curriculum_id bigint ENCODE az64,
    term_content_academic_year_id bigint ENCODE az64,
    term_start_date date ENCODE az64,
    term_end_date date ENCODE az64,
    term_content_repository_dw_id bigint ENCODE az64,
    term_content_repository_id character varying(36) ENCODE lzo
)
DISTSTYLE ALL
SORTKEY ( term_dw_id );
CREATE TABLE devcoredw.dim_teacher_test (
    tt_dw_id bigint ENCODE az64,
    tt_test_id character varying(36) ENCODE lzo,
    tt_tenant_id character varying(36) ENCODE lzo,
    tt_test_class_id character varying(36) ENCODE lzo,
    tt_test_title character varying(255) ENCODE lzo,
    tt_test_domain_id character varying(36) ENCODE lzo,
    tt_test_status character varying(50) ENCODE lzo,
    tt_test_created_by_id character varying(36) ENCODE lzo,
    tt_status integer ENCODE az64,
    tt_test_updated_by_id character varying(36) ENCODE lzo,
    tt_test_published_by_id character varying(36) ENCODE lzo,
    tt_created_time timestamp without time zone ENCODE az64,
    tt_updated_time timestamp without time zone ENCODE az64,
    tt_deleted_time timestamp without time zone ENCODE az64,
    tt_dw_created_time timestamp without time zone ENCODE az64,
    tt_dw_updated_time timestamp without time zone ENCODE az64,
    tt_dw_deleted_time timestamp without time zone ENCODE az64,
    tt_test_blueprint_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_outcome (
    outcome_dw_id bigint identity(1,1) ENCODE raw,
    outcome_created_time timestamp without time zone ENCODE az64,
    outcome_updated_time timestamp without time zone ENCODE az64,
    outcome_deleted_time timestamp without time zone ENCODE az64,
    outcome_dw_created_time timestamp without time zone ENCODE az64,
    outcome_dw_updated_time timestamp without time zone ENCODE az64,
    outcome_status integer ENCODE az64,
    outcome_id character varying(36) ENCODE lzo,
    outcome_parent_id character varying(36) ENCODE lzo,
    outcome_type integer ENCODE az64,
    outcome_name character varying(500) ENCODE lzo,
    outcome_curriculum_id bigint ENCODE az64,
    outcome_curriculum_grade_id bigint ENCODE az64,
    outcome_curriculum_subject_id bigint ENCODE az64,
    outcome_description character varying(1500) ENCODE lzo
)
DISTSTYLE ALL
SORTKEY ( outcome_dw_id );
CREATE TABLE devcoredw.fact_cx_maturity_indicator (
    fcmi_dw_id bigint identity(1,1) ENCODE raw,
    fcmi_id bigint ENCODE az64,
    fcmi_maturity_dw_id bigint ENCODE az64,
    fcmi_indicator_id character varying(25) ENCODE lzo distkey,
    fcmi_indicator_value integer ENCODE az64,
    fcmi_created_time timestamp without time zone ENCODE az64,
    fcmi_dw_created_time timestamp without time zone ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( fcmi_dw_id );
CREATE TABLE devcoredw.dim_course_activity_grade_association (
    caga_dw_id bigint ENCODE az64,
    caga_created_time timestamp without time zone ENCODE az64,
    caga_updated_time timestamp without time zone ENCODE az64,
    caga_deleted_time timestamp without time zone ENCODE az64,
    caga_dw_created_time timestamp without time zone ENCODE az64,
    caga_dw_updated_time timestamp without time zone ENCODE az64,
    caga_dw_deleted_time timestamp without time zone ENCODE az64,
    caga_status integer ENCODE az64,
    caga_course_dw_id bigint ENCODE az64,
    caga_course_id character varying(36) ENCODE lzo,
    caga_activity_dw_id bigint ENCODE az64,
    caga_activity_id character varying(36) ENCODE lzo,
    caga_grade_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_cefr_level_mapping (
    grade integer ENCODE az64,
    range_scale_score character varying(10) ENCODE lzo,
    category character varying(50) ENCODE lzo,
    grade_offset integer ENCODE az64,
    cefr_level character varying(10) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_activity_template (
    at_dw_id bigint identity(1,1) ENCODE raw,
    at_uuid character varying(36) ENCODE lzo,
    at_name character varying(256) ENCODE lzo,
    at_description character varying(4096) ENCODE lzo,
    at_status integer ENCODE az64,
    at_activity_type character varying(50) ENCODE lzo,
    at_created_time timestamp without time zone ENCODE az64,
    at_updated_time timestamp without time zone ENCODE az64,
    at_dw_created_time timestamp without time zone ENCODE az64,
    at_dw_updated_time timestamp without time zone ENCODE az64,
    at_publisher_id bigint ENCODE az64,
    at_publisher_name character varying(255) ENCODE lzo,
    at_published_date timestamp without time zone ENCODE az64,
    at_component_uuid character varying(36) ENCODE lzo,
    at_order integer ENCODE az64,
    at_component_name character varying(256) ENCODE lzo,
    at_component_type integer ENCODE az64,
    at_abbreviation character varying(50) ENCODE lzo,
    at_icon character varying(256) ENCODE lzo,
    at_max_repeat integer ENCODE az64,
    at_exit_ticket boolean ENCODE raw,
    at_completion_node boolean ENCODE raw,
    at_always_enabled boolean ENCODE raw,
    at_passing_score integer ENCODE az64,
    at_assessments_attempts integer ENCODE az64,
    at_question_attempts_hints boolean ENCODE raw,
    at_question_attempts integer ENCODE az64,
    at_release_condition character varying(36) ENCODE lzo,
    at_section_type integer ENCODE az64,
    at_release_component character varying(36) ENCODE lzo,
    at_min integer ENCODE az64,
    at_max integer ENCODE az64
)
DISTSTYLE ALL
SORTKEY ( at_dw_id );
CREATE TABLE devcoredw.fact_practice (
    practice_dw_id bigint identity(1,1) ENCODE az64,
    practice_created_time timestamp without time zone ENCODE az64,
    practice_dw_created_time timestamp without time zone ENCODE az64,
    practice_date_dw_id integer ENCODE az64 distkey,
    practice_id character varying(36) ENCODE lzo,
    practice_lo_dw_id bigint ENCODE az64,
    practice_student_dw_id bigint ENCODE raw,
    practice_subject_dw_id bigint ENCODE az64,
    practice_grade_dw_id bigint ENCODE raw,
    practice_tenant_dw_id bigint ENCODE az64,
    practice_school_dw_id bigint ENCODE raw,
    practice_section_dw_id bigint ENCODE raw,
    practice_skill_dw_id bigint ENCODE az64,
    practice_sa_score bigint ENCODE az64,
    practice_item_lo_dw_id bigint ENCODE az64,
    practice_item_skill_dw_id bigint ENCODE az64,
    practice_item_content_title character varying(100) ENCODE lzo,
    practice_item_content_lesson_type character varying(50) ENCODE lzo,
    practice_item_content_location character varying(200) ENCODE lzo,
    practice_academic_year_dw_id bigint ENCODE az64,
    practice_instructional_plan_id character varying(36) ENCODE lzo,
    practice_learning_path_id character varying(36) ENCODE lzo,
    practice_class_dw_id bigint ENCODE az64,
    practice_item_step_id character varying(36) ENCODE lzo,
    practice_material_id character varying(36) ENCODE lzo,
    practice_material_type character varying(20) ENCODE lzo
)
DISTSTYLE KEY
SORTKEY ( practice_school_dw_id, practice_grade_dw_id, practice_section_dw_id, practice_student_dw_id );
CREATE TABLE devcoredw.dim_class_backup_20220118 (
    rel_class_dw_id bigint ENCODE az64,
    class_dw_id bigint ENCODE az64,
    class_created_time timestamp without time zone ENCODE az64,
    class_updated_time timestamp without time zone ENCODE az64,
    class_deleted_time timestamp without time zone ENCODE az64,
    class_dw_created_time timestamp without time zone ENCODE az64,
    class_dw_updated_time timestamp without time zone ENCODE az64,
    class_status integer ENCODE az64,
    class_id character varying(36) ENCODE lzo,
    class_title character varying(255) ENCODE lzo,
    class_school_id character varying(36) ENCODE lzo,
    class_grade_id character varying(36) ENCODE lzo,
    class_section_id character varying(36) ENCODE lzo,
    class_academic_year_id character varying(36) ENCODE lzo,
    class_gen_subject character varying(255) ENCODE lzo,
    class_curriculum_id bigint ENCODE az64,
    class_curriculum_grade_id bigint ENCODE az64,
    class_curriculum_subject_id bigint ENCODE az64,
    class_content_academic_year integer ENCODE az64,
    class_tutor_dhabi_enabled boolean ENCODE raw,
    class_language_direction character varying(25) ENCODE lzo,
    class_online boolean ENCODE raw,
    class_practice boolean ENCODE raw,
    class_course_status character varying(50) ENCODE lzo,
    class_source_id character varying(255) ENCODE lzo,
    class_curriculum_instructional_plan_id character varying(36) ENCODE lzo,
    class_category_id character varying(36) ENCODE lzo,
    class_active_until timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_skill (
    skill_dw_id bigint identity(1,1) ENCODE raw,
    skill_created_time timestamp without time zone ENCODE raw,
    skill_updated_time timestamp without time zone ENCODE raw,
    skill_deleted_time timestamp without time zone ENCODE raw,
    skill_dw_created_time timestamp without time zone ENCODE raw,
    skill_dw_updated_time timestamp without time zone ENCODE raw,
    skill_status integer ENCODE raw,
    skill_id character varying(36) ENCODE raw,
    skill_name character varying(255) ENCODE raw,
    skill_code character varying(50) ENCODE raw,
    skill_description character varying(500) ENCODE lzo
)
DISTSTYLE ALL
SORTKEY ( skill_dw_id );
CREATE TABLE devcoredw.be_dim_customers (
    row_id integer ENCODE az64,
    customer_id character varying(256) ENCODE lzo,
    customer_name character varying(256) ENCODE lzo,
    segment character varying(256) ENCODE lzo,
    country character varying(256) ENCODE lzo,
    city character varying(256) ENCODE lzo,
    state character varying(256) ENCODE lzo,
    postal_code character varying(256) ENCODE lzo,
    region character varying(256) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.fact_tutor_session (
    fts_dw_id bigint identity(1,1) ENCODE az64 distkey,
    fts_created_time timestamp without time zone ENCODE raw,
    fts_dw_created_time timestamp without time zone ENCODE az64,
    fts_date_dw_id bigint ENCODE az64,
    fts_session_id character varying(36) ENCODE bytedict,
    fts_tenant_dw_id bigint ENCODE az64,
    fts_school_dw_id bigint ENCODE az64,
    fts_user_dw_id bigint ENCODE az64,
    fts_grade_dw_id bigint ENCODE az64,
    fts_context_id character varying(36) ENCODE bytedict,
    fts_role character varying(20) ENCODE lzo,
    fts_grade integer ENCODE az64,
    fts_subject_dw_id bigint ENCODE az64,
    fts_subject character varying(20) ENCODE lzo,
    fts_language character varying(20) ENCODE lzo,
    fts_session_state character varying(20) ENCODE bytedict,
    fts_activity_dw_id bigint ENCODE az64,
    fts_activity_status character varying(20) ENCODE bytedict,
    fts_material_id character varying(36) ENCODE bytedict,
    fts_material_type character varying(20) ENCODE lzo,
    fts_level_dw_id bigint ENCODE az64,
    fts_outcome_dw_id bigint ENCODE az64,
    fts_session_message_limit_reached boolean ENCODE raw,
    fts_course_activity_container_dw_id bigint ENCODE az64,
    fts_learning_session_id character varying(36) ENCODE bytedict,
    fts_activity_id character varying(36) ENCODE lzo
)
DISTSTYLE KEY
SORTKEY ( fts_created_time );
CREATE TABLE devcoredw.fact_lesson_feedback (
    lesson_feedback_staging_id bigint identity(1,1) ENCODE lzo,
    lesson_feedback_id character varying(36) ENCODE lzo,
    lesson_feedback_created_time timestamp without time zone ENCODE lzo,
    lesson_feedback_dw_created_time timestamp without time zone ENCODE lzo,
    lesson_feedback_date_dw_id bigint ENCODE lzo,
    lesson_feedback_tenant_dw_id bigint ENCODE lzo,
    lesson_feedback_school_dw_id bigint ENCODE lzo,
    lesson_feedback_academic_year_dw_id bigint ENCODE lzo,
    lesson_feedback_grade_dw_id bigint ENCODE lzo,
    lesson_feedback_section_dw_id bigint ENCODE lzo,
    lesson_feedback_subject_dw_id bigint ENCODE lzo,
    lesson_feedback_student_dw_id bigint ENCODE lzo,
    lesson_feedback_lo_dw_id bigint ENCODE lzo,
    lesson_feedback_term_dw_id bigint ENCODE lzo,
    lesson_feedback_curr_grade_dw_id bigint ENCODE lzo,
    lesson_feedback_curr_subject_dw_id bigint ENCODE lzo,
    lesson_feedback_fle_ls_dw_id bigint ENCODE lzo,
    lesson_feedback_trimester_id character varying(36) ENCODE lzo,
    lesson_feedback_trimester_order integer ENCODE lzo,
    lesson_feedback_content_academic_year integer ENCODE lzo,
    lesson_feedback_rating character varying(50) ENCODE lzo,
    lesson_feedback_rating_text character varying(50) ENCODE lzo,
    lesson_feedback_has_comment boolean ENCODE raw,
    lesson_feedback_is_cancelled boolean ENCODE raw,
    lesson_feedback_instructional_plan_id character varying(36) ENCODE lzo,
    lesson_feedback_learning_path_id character varying(36) ENCODE lzo,
    lesson_feedback_class_dw_id bigint ENCODE az64,
    lesson_feedback_fle_ls_uuid character varying(36) ENCODE lzo,
    lesson_feedback_teaching_period_id character varying(36) ENCODE lzo,
    lesson_feedback_teaching_period_title character varying(50) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_student (
    rel_student_dw_id bigint identity(1,1) ENCODE lzo,
    student_created_time timestamp without time zone ENCODE lzo,
    student_updated_time timestamp without time zone ENCODE lzo,
    student_deleted_time timestamp without time zone ENCODE lzo,
    student_dw_created_time timestamp without time zone ENCODE lzo,
    student_dw_updated_time timestamp without time zone ENCODE lzo,
    student_active_until timestamp without time zone ENCODE lzo,
    student_status integer ENCODE lzo,
    student_id character varying(36) ENCODE lzo,
    student_username character varying(256) ENCODE lzo,
    student_dw_id bigint ENCODE lzo,
    student_school_dw_id bigint ENCODE raw distkey,
    student_grade_dw_id bigint ENCODE raw,
    student_section_dw_id bigint ENCODE raw,
    student_tags character varying(256) ENCODE lzo,
    student_special_needs character varying(2000) ENCODE lzo,
    UNIQUE (student_dw_id)
)
DISTSTYLE KEY
SORTKEY ( student_school_dw_id, student_grade_dw_id, student_section_dw_id );
CREATE TABLE devcoredw.be_fact_retail (
    row_id integer ENCODE az64,
    order_id character varying(256) ENCODE lzo,
    order_date date ENCODE az64,
    ship_date date ENCODE az64,
    ship_mode character varying(256) ENCODE bytedict,
    customer_id character varying(256) ENCODE lzo,
    product_id character varying(256) ENCODE lzo,
    sales double precision ENCODE raw,
    quantity double precision ENCODE raw,
    discount double precision ENCODE raw,
    profit double precision ENCODE raw
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_category (
    category_dw_id bigint identity(1,1) ENCODE raw,
    category_created_time timestamp without time zone ENCODE az64,
    category_updated_time timestamp without time zone ENCODE az64,
    category_deleted_time timestamp without time zone ENCODE az64,
    category_dw_created_time timestamp without time zone ENCODE az64,
    category_dw_updated_time timestamp without time zone ENCODE az64,
    category_status integer ENCODE az64,
    category_id character varying(36) ENCODE lzo,
    category_name character varying(500) ENCODE lzo,
    category_code character varying(150) ENCODE lzo,
    category_description character varying(500) ENCODE lzo
)
DISTSTYLE ALL
SORTKEY ( category_dw_id );
CREATE TABLE devcoredw.dim_academic_year (
    academic_year_dw_id bigint identity(1,1) ENCODE raw,
    academic_year_created_time timestamp without time zone ENCODE az64,
    academic_year_updated_time timestamp without time zone ENCODE az64,
    academic_year_deleted_time timestamp without time zone ENCODE az64,
    academic_year_dw_created_time timestamp without time zone ENCODE az64,
    academic_year_dw_updated_time timestamp without time zone ENCODE az64,
    academic_year_status smallint ENCODE az64,
    academic_year_id character varying(36) ENCODE lzo,
    academic_year_school_id character varying(36) ENCODE lzo,
    academic_year_start_date date ENCODE az64,
    academic_year_end_date date ENCODE az64,
    academic_year_delta_dw_id bigint ENCODE az64,
    academic_year_organization_code character varying(50) ENCODE lzo,
    academic_year_organization_dw_id bigint ENCODE az64,
    academic_year_school_dw_id bigint ENCODE az64,
    academic_year_created_by_dw_id bigint ENCODE az64,
    academic_year_updated_by_dw_id bigint ENCODE az64,
    academic_year_state character varying(50) ENCODE lzo,
    academic_year_created_by character varying(36) ENCODE lzo,
    academic_year_updated_by character varying(36) ENCODE lzo,
    academic_year_is_roll_over_completed boolean DEFAULT false ENCODE raw,
    academic_year_type character varying(36) ENCODE lzo
)
DISTSTYLE ALL
SORTKEY ( academic_year_dw_id );
CREATE TABLE devcoredw.dim_curriculum_subject (
    curr_subject_dw_id bigint identity(1,1) ENCODE raw,
    curr_subject_name character varying(255) ENCODE lzo,
    curr_subject_created_time timestamp without time zone ENCODE az64,
    curr_subject_updated_time timestamp without time zone ENCODE az64,
    curr_subject_deleted_time timestamp without time zone ENCODE az64,
    curr_subject_dw_created_time timestamp without time zone ENCODE az64,
    curr_subject_dw_updated_time timestamp without time zone ENCODE az64,
    curr_subject_status integer ENCODE az64,
    curr_subject_id bigint ENCODE az64,
    curr_subject_skillable boolean ENCODE raw
)
DISTSTYLE ALL
SORTKEY ( curr_subject_dw_id );
CREATE TABLE devcoredw.dim_cx_observation (
    cx_observation_dw_id bigint identity(1,1) ENCODE raw,
    cx_observation_observation_id bigint ENCODE az64 distkey,
    cx_observation_observed_dw_id bigint ENCODE az64,
    cx_observation_observer_dw_id bigint ENCODE az64,
    cx_observation_observation_timing character varying(25) ENCODE lzo,
    cx_observation_observed_grade integer ENCODE az64,
    cx_observation_observed_period integer ENCODE az64,
    cx_observation_observation_score integer ENCODE az64,
    cx_observation_joint_observer_dw_id bigint ENCODE az64,
    cx_observation_observation_submit_time timestamp without time zone ENCODE az64,
    cx_observation_observation_sent_time timestamp without time zone ENCODE az64,
    cx_observation_observation_type character varying(25) ENCODE lzo,
    cx_observation_coaching_closing_time timestamp without time zone ENCODE az64,
    cx_observation_coach_dw_id bigint ENCODE az64,
    cx_observation_observation_center_dw_id bigint ENCODE az64,
    cx_observation_observation_archived character varying(60) ENCODE lzo,
    cx_observation_status integer ENCODE az64,
    cx_observation_created_time timestamp without time zone ENCODE az64,
    cx_observation_dw_created_time timestamp without time zone ENCODE az64,
    cx_observation_updated_time timestamp without time zone ENCODE az64,
    cx_observation_dw_updated_time timestamp without time zone ENCODE az64,
    cx_observation_deleted_time timestamp without time zone ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( cx_observation_dw_id );
CREATE TABLE devcoredw.fact_assignment_submission (
    assignment_submission_dw_id bigint identity(1,1) ENCODE az64,
    assignment_submission_id character varying(36) ENCODE lzo,
    assignment_submission_assignment_id character varying(36) ENCODE lzo,
    assignment_submission_referrer_id character varying(36) ENCODE lzo,
    assignment_submission_type character varying(100) ENCODE lzo,
    assignment_submission_updated_on timestamp without time zone ENCODE az64,
    assignment_submission_returned_on timestamp without time zone ENCODE az64,
    assignment_submission_submitted_on timestamp without time zone ENCODE az64,
    assignment_submission_graded_on timestamp without time zone ENCODE az64,
    assignment_submission_evaluated_on timestamp without time zone ENCODE az64,
    assignment_submission_status character varying(20) ENCODE lzo,
    assignment_submission_student_attachment_file_name character varying(200) ENCODE lzo,
    assignment_submission_student_attachment_path character varying(200) ENCODE lzo,
    assignment_submission_teacher_attachment_path character varying(200) ENCODE lzo,
    assignment_submission_teacher_attachment_file_name character varying(200) ENCODE lzo,
    assignment_submission_teacher_score double precision ENCODE raw,
    assignment_submission_date_dw_id character varying(36) ENCODE lzo,
    assignment_submission_created_time timestamp without time zone ENCODE raw,
    assignment_submission_dw_created_time timestamp without time zone ENCODE az64,
    assignment_submission_has_teacher_comment boolean ENCODE raw,
    assignment_submission_has_student_comment boolean ENCODE raw,
    assignment_submission_assignment_instance_id character varying(36) ENCODE lzo distkey,
    assignment_submission_student_dw_id character varying(36) ENCODE raw,
    assignment_submission_teacher_dw_id character varying(36) ENCODE lzo,
    assignment_submission_tenant_dw_id character varying(36) ENCODE raw,
    eventdate date ENCODE az64,
    assignment_submission_resubmission_count integer ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( assignment_submission_tenant_dw_id, assignment_submission_student_dw_id, assignment_submission_created_time );
CREATE TABLE devcoredw.dim_academic_calendar (
    academic_calendar_dw_id bigint ENCODE az64,
    academic_calendar_created_time timestamp without time zone ENCODE az64,
    academic_calendar_updated_time timestamp without time zone ENCODE az64,
    academic_calendar_deleted_time timestamp without time zone ENCODE az64,
    academic_calendar_dw_created_time timestamp without time zone ENCODE az64,
    academic_calendar_dw_updated_time timestamp without time zone ENCODE az64,
    academic_calendar_status integer ENCODE az64,
    academic_calendar_title character varying(50) ENCODE lzo,
    academic_calendar_id character varying(36) ENCODE lzo,
    academic_calendar_tenant_id character varying(36) ENCODE lzo,
    academic_calendar_school_id character varying(36) ENCODE lzo,
    academic_calendar_school_dw_id bigint ENCODE az64,
    academic_calendar_is_default boolean ENCODE raw,
    academic_calendar_type character varying(30) ENCODE lzo,
    academic_calendar_academic_year_id character varying(36) ENCODE lzo,
    academic_calendar_academic_year_dw_id character varying(36) ENCODE lzo,
    academic_calendar_created_by_id character varying(36) ENCODE lzo,
    academic_calendar_updated_by_id character varying(36) ENCODE lzo,
    academic_calendar_organization character varying(50) ENCODE lzo,
    academic_calendar_organization_dw_id bigint ENCODE az64,
    academic_calendar_created_by_dw_id bigint ENCODE az64,
    academic_calendar_updated_by_dw_id bigint ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.fact_teacher_test_candidate_progress (
    fttcp_dw_id bigint ENCODE az64,
    fttcp_session_id character varying(36) ENCODE lzo,
    fttcp_candidate_id character varying(36) ENCODE lzo,
    fttcp_test_delivery_id character varying(36) ENCODE lzo,
    fttcp_assessment_id character varying(36) ENCODE lzo,
    fttcp_score double precision ENCODE raw,
    fttcp_stars_awarded integer ENCODE az64,
    fttcp_status character varying(50) ENCODE lzo,
    fttcp_updated_at timestamp without time zone ENCODE az64,
    fttcp_created_at timestamp without time zone ENCODE az64,
    fttcp_date_dw_id bigint ENCODE az64,
    fttcp_created_time timestamp without time zone ENCODE az64,
    fttcp_dw_created_time timestamp without time zone ENCODE az64,
    fttcp_test_delivery_dw_id bigint ENCODE az64,
    fttcp_candidate_dw_id bigint ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_week (
    week_dw_id bigint identity(1,1) ENCODE raw,
    week_created_time timestamp without time zone ENCODE az64,
    week_updated_time timestamp without time zone ENCODE az64,
    week_deleted_time timestamp without time zone ENCODE az64,
    week_dw_created_time timestamp without time zone ENCODE az64,
    week_dw_updated_time timestamp without time zone ENCODE az64,
    week_status integer ENCODE az64,
    week_id character varying(36) ENCODE lzo,
    week_number integer ENCODE az64,
    week_start_date date ENCODE az64,
    week_end_date date ENCODE az64,
    week_term_id character varying(36) ENCODE lzo
)
DISTSTYLE ALL
SORTKEY ( week_dw_id );
CREATE TABLE devcoredw.dim_course_curriculum_association (
    cc_dw_id bigint ENCODE az64,
    cc_course_dw_id bigint ENCODE az64,
    cc_course_id character varying(36) ENCODE lzo,
    cc_curr_id bigint ENCODE az64,
    cc_curr_grade_id bigint ENCODE az64,
    cc_curr_subject_id bigint ENCODE az64 distkey,
    cc_status integer ENCODE az64,
    cc_created_time timestamp without time zone ENCODE az64,
    cc_updated_time timestamp without time zone ENCODE az64,
    cc_deleted_time timestamp without time zone ENCODE az64,
    cc_dw_created_time timestamp without time zone ENCODE az64,
    cc_dw_updated_time timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.fact_inc_game (
    inc_game_dw_id bigint identity(1,1) ENCODE lzo,
    inc_game_id character varying(36) ENCODE lzo,
    inc_game_created_time timestamp without time zone ENCODE lzo,
    inc_game_dw_created_time timestamp without time zone ENCODE lzo,
    inc_game_date_dw_id bigint ENCODE lzo,
    inc_game_updated_time timestamp without time zone ENCODE lzo,
    inc_game_dw_updated_time timestamp without time zone ENCODE lzo,
    inc_game_tenant_dw_id bigint ENCODE lzo,
    inc_game_school_dw_id bigint ENCODE lzo,
    inc_game_section_dw_id bigint ENCODE lzo,
    inc_game_lo_dw_id bigint ENCODE lzo,
    inc_game_title character varying(256) ENCODE lzo,
    inc_game_teacher_dw_id bigint ENCODE lzo,
    inc_game_subject_dw_id bigint ENCODE lzo,
    inc_game_grade_dw_id bigint ENCODE lzo,
    inc_game_learning_path_dw_id bigint ENCODE lzo,
    inc_game_num_questions integer ENCODE lzo,
    inc_game_instructional_plan_id character varying(36) ENCODE lzo,
    inc_game_class_dw_id bigint ENCODE az64,
    inc_game_is_assessment boolean DEFAULT false ENCODE raw,
    inc_game_lesson_component_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_teacher_test_item_association (
    ttia_dw_id bigint ENCODE az64,
    ttia_test_id character varying(36) ENCODE raw,
    ttia_test_item_id character varying(36) ENCODE lzo,
    ttia_status integer ENCODE az64,
    ttia_dw_created_time timestamp without time zone ENCODE az64,
    ttia_created_time timestamp without time zone ENCODE az64,
    ttia_active_until timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO
SORTKEY ( ttia_test_id );
CREATE TABLE devcoredw.fact_content_session (
    fcs_dw_id bigint identity(1,1) ENCODE az64,
    fcs_created_time timestamp without time zone ENCODE az64,
    fcs_dw_created_time timestamp without time zone ENCODE az64,
    fcs_date_dw_id bigint ENCODE raw,
    fcs_id character varying(36) ENCODE lzo,
    fcs_event_type smallint ENCODE az64,
    fcs_is_start boolean ENCODE raw,
    fcs_ls_id character varying(36) ENCODE lzo,
    fcs_content_id character varying(36) ENCODE lzo,
    fcs_lo_dw_id bigint ENCODE az64,
    fcs_student_dw_id bigint ENCODE raw,
    fcs_class_dw_id bigint ENCODE raw,
    fcs_grade_dw_id bigint ENCODE raw,
    fcs_tenant_dw_id bigint ENCODE az64,
    fcs_school_dw_id bigint ENCODE raw,
    fcs_ay_dw_id bigint ENCODE az64,
    fcs_section_dw_id bigint ENCODE az64,
    fcs_lp_dw_id bigint ENCODE az64,
    fcs_ip_id character varying(36) ENCODE lzo,
    fcs_outside_of_school boolean ENCODE raw,
    fcs_content_academic_year character varying(4) ENCODE lzo,
    fcs_app_timespent double precision ENCODE raw,
    fcs_app_score double precision ENCODE raw
)
DISTSTYLE AUTO
SORTKEY ( fcs_school_dw_id, fcs_grade_dw_id, fcs_class_dw_id, fcs_student_dw_id, fcs_date_dw_id );
CREATE TABLE devcoredw.dim_question_pool_association (
    question_pool_association_dw_id bigint identity(1,1) ENCODE raw,
    question_pool_association_created_time timestamp without time zone ENCODE az64,
    question_pool_association_updated_time timestamp without time zone ENCODE az64,
    question_pool_association_dw_created_time timestamp without time zone ENCODE az64,
    question_pool_association_dw_updated_time timestamp without time zone ENCODE az64,
    question_pool_association_status integer ENCODE az64,
    question_pool_association_assign_status integer ENCODE az64,
    question_pool_association_question_code character varying(120) ENCODE lzo,
    question_pool_association_question_pool_dw_id bigint ENCODE az64,
    question_pool_association_triggered_by character varying(100) ENCODE lzo
)
DISTSTYLE ALL
SORTKEY ( question_pool_association_dw_id );
CREATE TABLE devcoredw.dim_class (
    class_dw_id bigint ENCODE az64,
    class_created_time timestamp without time zone ENCODE az64,
    class_updated_time timestamp without time zone ENCODE az64,
    class_deleted_time timestamp without time zone ENCODE az64,
    class_dw_created_time timestamp without time zone ENCODE az64,
    class_dw_updated_time timestamp without time zone ENCODE az64,
    class_status smallint ENCODE az64,
    class_id character varying(36) ENCODE lzo,
    class_title character varying(255) ENCODE lzo,
    class_school_id character varying(36) ENCODE lzo,
    class_grade_id character varying(36) ENCODE lzo,
    class_section_id character varying(36) ENCODE lzo,
    class_academic_year_id character varying(36) ENCODE lzo,
    class_gen_subject character varying(255) ENCODE lzo,
    class_curriculum_id bigint ENCODE az64,
    class_curriculum_grade_id bigint ENCODE az64,
    class_curriculum_subject_id bigint ENCODE az64,
    class_content_academic_year smallint ENCODE az64,
    class_tutor_dhabi_enabled boolean ENCODE raw,
    class_language_direction character varying(25) ENCODE lzo,
    class_online boolean ENCODE raw,
    class_practice boolean ENCODE raw,
    class_course_status character varying(50) ENCODE lzo,
    class_source_id character varying(255) ENCODE lzo,
    class_curriculum_instructional_plan_id character varying(36) ENCODE lzo,
    class_category_id character varying(36) ENCODE lzo,
    class_active_until timestamp without time zone ENCODE az64,
    class_material_id character varying(36) ENCODE lzo,
    class_material_type character varying(20) ENCODE lzo,
    rel_class_dw_id bigint ENCODE raw,
    class_academic_calendar_id character varying(36) ENCODE lzo,
    UNIQUE (class_dw_id)
)
DISTSTYLE AUTO
SORTKEY ( rel_class_dw_id );
CREATE TABLE devcoredw.fact_weekly_goal_activity (
    fwga_dw_id bigint identity(1,1) ENCODE az64,
    fwga_created_time timestamp without time zone ENCODE raw,
    fwga_dw_created_time timestamp without time zone ENCODE az64,
    fwga_weekly_goal_id character varying(36) ENCODE lzo,
    fwga_completed_activity_id character varying(36) ENCODE lzo,
    fwga_weekly_goal_status integer ENCODE az64,
    fwga_date_dw_id bigint ENCODE az64
)
DISTSTYLE AUTO
SORTKEY ( fwga_created_time );
CREATE TABLE devcoredw.dim_interim_checkpoint (
    ic_dw_id bigint identity(1,1) ENCODE raw,
    ic_created_time timestamp without time zone ENCODE az64,
    ic_dw_created_time timestamp without time zone ENCODE az64,
    ic_deleted_time timestamp without time zone ENCODE az64,
    ic_dw_deleted_time timestamp without time zone ENCODE az64,
    ic_updated_time timestamp without time zone ENCODE az64,
    ic_dw_updated_time timestamp without time zone ENCODE az64,
    ic_status smallint ENCODE az64,
    ic_id character varying(36) ENCODE lzo,
    ic_title character varying(250) ENCODE lzo,
    ic_language character varying(50) ENCODE lzo,
    ic_material_type character varying(20) ENCODE lzo
)
DISTSTYLE ALL
SORTKEY ( ic_dw_id );
CREATE TABLE devcoredw.dim_principal (
    rel_principal_dw_id bigint identity(1,1) ENCODE lzo,
    principal_created_time timestamp without time zone ENCODE lzo,
    principal_updated_time timestamp without time zone ENCODE lzo,
    principal_deleted_time timestamp without time zone ENCODE lzo,
    principal_dw_created_time timestamp without time zone ENCODE lzo,
    principal_dw_updated_time timestamp without time zone ENCODE lzo,
    principal_active_until timestamp without time zone ENCODE lzo,
    principal_status integer ENCODE lzo,
    principal_id character varying(36) ENCODE lzo,
    principal_dw_id bigint ENCODE raw,
    principal_onboarded boolean ENCODE raw,
    principal_school_dw_id character varying(36) ENCODE lzo distkey,
    principal_expirable boolean ENCODE raw
)
DISTSTYLE KEY
SORTKEY ( principal_dw_id );
CREATE TABLE devcoredw.dim_class_schedule (
    class_schedule_dw_id bigint identity(1,1) ENCODE raw,
    class_schedule_created_time timestamp without time zone ENCODE az64,
    class_schedule_updated_time timestamp without time zone ENCODE az64,
    class_schedule_dw_created_time timestamp without time zone ENCODE az64,
    class_schedule_dw_updated_time timestamp without time zone ENCODE az64,
    class_schedule_status integer ENCODE az64,
    class_schedule_class_id character varying(36) ENCODE lzo,
    class_schedule_day character varying(10) ENCODE lzo,
    class_schedule_start_time character varying(10) ENCODE lzo,
    class_schedule_end_time character varying(10) ENCODE lzo,
    class_schedule_attach_status integer ENCODE az64
)
DISTSTYLE ALL
SORTKEY ( class_schedule_dw_id );
CREATE TABLE devcoredw.fact_activity_setting (
    fas_activity_dw_id bigint ENCODE az64,
    fas_activity_id character varying(36) ENCODE lzo,
    fas_class_dw_id bigint ENCODE az64,
    fas_class_id character varying(36) ENCODE lzo,
    fas_created_time timestamp without time zone ENCODE az64,
    fas_dw_created_time timestamp without time zone ENCODE az64,
    fas_dw_id bigint ENCODE az64,
    fas_grade_dw_id bigint ENCODE az64,
    fas_grade_id character varying(36) ENCODE lzo,
    fas_k12_grade integer ENCODE az64,
    fas_open_path_enabled boolean ENCODE raw,
    fas_school_dw_id bigint ENCODE az64,
    fas_school_id character varying(36) ENCODE lzo,
    fas_class_gen_subject_name character varying(50) ENCODE lzo,
    fas_teacher_dw_id bigint ENCODE az64,
    fas_teacher_id character varying(36) ENCODE lzo distkey,
    fas_tenant_dw_id bigint ENCODE az64,
    fas_tenant_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_content_student_association (
    content_student_association_dw_id bigint identity(1,1) ENCODE raw,
    content_student_association_created_time timestamp without time zone ENCODE az64,
    content_student_association_updated_time timestamp without time zone ENCODE az64,
    content_student_association_dw_created_time timestamp without time zone ENCODE az64,
    content_student_association_dw_updated_time timestamp without time zone ENCODE az64,
    content_student_association_status integer ENCODE az64,
    content_student_association_student_id character varying(36) ENCODE lzo,
    content_student_association_assign_status integer ENCODE az64,
    content_student_association_assigned_by character varying(36) ENCODE lzo,
    content_student_association_type smallint ENCODE az64,
    content_student_association_lo_id character varying(36) ENCODE lzo,
    content_student_association_class_id character varying(36) ENCODE lzo,
    content_student_association_step_id character varying(36) ENCODE lzo,
    content_student_association_content_type character varying(50) ENCODE lzo
)
DISTSTYLE ALL
SORTKEY ( content_student_association_dw_id );
CREATE TABLE devcoredw.rel_activity_section_association (
    dw_id bigint ENCODE az64,
    event_type character varying(100) ENCODE lzo,
    _trace_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    id character varying(36) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    status smallint ENCODE az64,
    active_until timestamp without time zone ENCODE az64,
    section_id character varying(36) ENCODE lzo,
    activity_id character varying(36) ENCODE lzo,
    template_uuid character varying(36) ENCODE lzo,
    content_id bigint ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_staff_user (
    rel_staff_user_dw_id bigint ENCODE az64,
    staff_user_event_type character varying(50) ENCODE lzo distkey,
    staff_user_created_time timestamp without time zone ENCODE az64,
    staff_user_dw_created_time timestamp without time zone ENCODE az64,
    staff_user_active_until timestamp without time zone ENCODE az64,
    staff_user_status integer ENCODE az64,
    staff_user_id character varying(36) ENCODE lzo,
    staff_user_dw_id bigint ENCODE az64,
    staff_user_onboarded boolean ENCODE raw,
    staff_user_expirable boolean DEFAULT false ENCODE raw,
    staff_user_exclude_from_report boolean DEFAULT false ENCODE raw,
    staff_user_avatar character varying(100) ENCODE lzo,
    staff_user_enabled boolean ENCODE raw
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.fact_adt_student_report1 (
    fasr_dw_id bigint ENCODE az64 distkey,
    fasr_created_time timestamp without time zone ENCODE az64,
    fasr_dw_created_time timestamp without time zone ENCODE az64,
    fasr_date_dw_id bigint ENCODE az64,
    fasr_tenant_dw_id bigint ENCODE az64,
    fasr_student_dw_id bigint ENCODE az64,
    fasr_question_pool_id character varying(36) ENCODE lzo,
    fasr_fle_ls_dw_id bigint ENCODE az64,
    fasr_id character varying(36) ENCODE lzo,
    fasr_scaler_version character varying(20) ENCODE lzo,
    fasr_final_see double precision ENCODE raw,
    fasr_final_score double precision ENCODE raw,
    fasr_final_proficiency double precision ENCODE raw,
    fasr_final_cefr character varying(20) ENCODE lzo,
    fasr_total_time_spent double precision ENCODE raw
)
DISTSTYLE KEY;
CREATE TABLE devcoredw.fact_item_transaction (
    fit_dw_id bigint ENCODE az64,
    fit_created_time timestamp without time zone ENCODE raw,
    fit_dw_created_time timestamp without time zone ENCODE az64,
    fit_date_dw_id bigint ENCODE az64,
    fit_id character varying(36) ENCODE lzo,
    fit_available_stars integer ENCODE az64,
    fit_item_cost integer ENCODE az64,
    fit_star_balance integer ENCODE az64,
    fit_item_id character varying(36) ENCODE lzo,
    fit_item_dw_id bigint ENCODE az64 distkey,
    fit_item_type character varying(50) ENCODE lzo,
    fit_student_id character varying(36) ENCODE lzo,
    fit_student_dw_id bigint ENCODE az64,
    fit_tenant_id character varying(36) ENCODE lzo,
    fit_tenant_dw_id bigint ENCODE az64,
    fit_school_id character varying(36) ENCODE lzo,
    fit_school_dw_id bigint ENCODE az64,
    fit_grade_id character varying(36) ENCODE lzo,
    fit_grade_dw_id bigint ENCODE az64,
    fit_section_id character varying(36) ENCODE lzo,
    fit_section_dw_id bigint ENCODE az64,
    fit_academic_year_id character varying(36) ENCODE lzo,
    fit_academic_year_dw_id bigint ENCODE az64,
    fit_academic_year integer ENCODE az64
)
DISTSTYLE AUTO
SORTKEY ( fit_created_time );
CREATE TABLE devcoredw.fact_learning_experience (
    fle_dw_id bigint identity(1,1) ENCODE lzo,
    fle_created_time timestamp without time zone ENCODE lzo,
    fle_dw_created_time timestamp without time zone ENCODE lzo,
    fle_date_dw_id bigint ENCODE raw,
    fle_exp_id character varying(36) ENCODE lzo,
    fle_ls_id character varying(36) ENCODE raw,
    fle_lo_dw_id bigint ENCODE lzo,
    fle_student_dw_id bigint ENCODE raw,
    fle_subject_dw_id bigint ENCODE lzo,
    fle_grade_dw_id bigint ENCODE raw,
    fle_curr_subject_dw_id bigint ENCODE lzo,
    fle_curr_grade_dw_id bigint ENCODE lzo,
    fle_term_dw_id bigint ENCODE lzo,
    fle_tenant_dw_id bigint ENCODE lzo,
    fle_school_dw_id bigint ENCODE raw,
    fle_section_dw_id bigint ENCODE raw,
    fle_lp_dw_id bigint ENCODE lzo,
    fle_start_time timestamp without time zone ENCODE lzo,
    fle_end_time timestamp without time zone ENCODE lzo,
    fle_total_time double precision ENCODE raw,
    fle_score integer ENCODE lzo,
    fle_star_earned integer ENCODE lzo,
    fle_lesson_type character varying(50) ENCODE lzo,
    fle_is_retry boolean ENCODE raw,
    fle_outside_of_school boolean ENCODE raw,
    fle_attempt integer ENCODE lzo,
    fle_exp_ls_flag boolean ENCODE raw,
    fle_academic_period_order character varying(20) ENCODE lzo,
    fle_academic_year_dw_id bigint ENCODE lzo,
    fle_content_academic_year character varying(20) ENCODE lzo,
    fle_time_spent_app integer ENCODE lzo,
    fle_instructional_plan_id character varying(36) ENCODE lzo,
    fle_class_dw_id bigint ENCODE az64,
    fle_lesson_category character varying(40) ENCODE lzo,
    fle_adt_level character varying(20) ENCODE lzo,
    fle_step_id character varying(36) ENCODE lzo,
    fle_abbreviation character varying(100) ENCODE lzo,
    fle_activity_template_id character varying(100) ENCODE lzo,
    fle_activity_type character varying(100) ENCODE lzo,
    fle_activity_component_type character varying(100) ENCODE lzo,
    fle_exit_ticket boolean ENCODE raw,
    fle_main_component boolean ENCODE raw,
    fle_completion_node boolean ENCODE raw,
    fle_total_score numeric(10,4) ENCODE az64,
    fle_is_activity_completed boolean ENCODE raw,
    fle_material_id character varying(36) ENCODE lzo,
    fle_material_type character varying(20) ENCODE lzo,
    fle_state smallint ENCODE az64,
    fle_total_stars smallint ENCODE az64,
    fle_open_path_enabled boolean DEFAULT false ENCODE raw,
    fle_source character varying(10) ENCODE lzo,
    fle_teaching_period_id character varying(36) ENCODE lzo,
    fle_academic_year character varying(10) ENCODE lzo,
    fle_assessment_id character varying(36) ENCODE lzo,
    fle_is_gamified boolean DEFAULT false ENCODE raw,
    fle_is_additional_resource boolean DEFAULT false ENCODE raw,
    fle_bonus_stars integer DEFAULT -1 ENCODE az64,
    fle_bonus_stars_scheme character varying(40) DEFAULT 'NA'::character varying ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( fle_school_dw_id, fle_grade_dw_id, fle_section_dw_id, fle_student_dw_id, fle_ls_id, fle_date_dw_id );
CREATE TABLE devcoredw.fact_learning_score_breakdown (
    fle_scbd_dw_id bigint identity(1,1) ENCODE raw,
    fle_scbd_created_time timestamp without time zone ENCODE az64,
    fle_scbd_dw_created_time timestamp without time zone ENCODE az64,
    fle_scbd_date_dw_id bigint ENCODE az64,
    fle_scbd_fle_dw_id bigint ENCODE az64,
    fle_scbd_fle_exp_id character varying(36) ENCODE lzo,
    fle_scbd_fle_ls_id character varying(36) ENCODE lzo,
    fle_scbd_question_dw_id bigint ENCODE az64,
    fle_scbd_code character varying(50) ENCODE lzo,
    fle_scbd_time_spent double precision ENCODE raw,
    fle_scbd_hints_used boolean ENCODE raw,
    fle_scbd_max_score double precision ENCODE raw,
    fle_scbd_score double precision ENCODE raw,
    fle_scbd_lo_dw_id bigint ENCODE az64,
    fle_scbd_type character varying(250) ENCODE lzo,
    fle_scbd_version integer ENCODE az64,
    fle_scbd_is_attended boolean ENCODE raw
)
DISTSTYLE AUTO
SORTKEY ( fle_scbd_dw_id );
CREATE TABLE devcoredw.fact_announcement (
    fa_dw_id bigint identity(1,1) ENCODE az64,
    fa_created_time timestamp without time zone ENCODE az64,
    fa_dw_created_time timestamp without time zone ENCODE az64,
    fa_status integer ENCODE az64,
    fa_tenant_dw_id integer ENCODE az64,
    fa_id character varying(36) ENCODE lzo,
    fa_admin_dw_id integer ENCODE az64,
    fa_role_dw_id integer ENCODE az64,
    fa_recipient_type integer ENCODE az64,
    fa_recipient_type_description character varying(50) ENCODE lzo,
    fa_recipient_dw_id integer ENCODE az64,
    fa_has_attachment boolean ENCODE raw,
    fa_type integer ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_section_schedule (
    rel_section_schedule_dw_id bigint identity(1,1) ENCODE lzo,
    section_id character varying(36) ENCODE lzo,
    section_schedule_day_of_week character varying(10) ENCODE lzo,
    section_schedule_start_time character varying(20) ENCODE lzo,
    section_schedule_end_time character varying(20) ENCODE lzo,
    section_schedule_created_time timestamp without time zone ENCODE lzo,
    section_schedule_updated_time timestamp without time zone ENCODE lzo,
    section_schedule_deleted_time timestamp without time zone ENCODE lzo,
    section_schedule_dw_created_time timestamp without time zone ENCODE lzo,
    section_schedule_dw_updated_time timestamp without time zone ENCODE lzo,
    section_schedule_active_until timestamp without time zone ENCODE lzo,
    section_schedule_status integer ENCODE lzo,
    section_schedule_section_dw_id bigint ENCODE lzo,
    section_schedule_tenant_dw_id bigint ENCODE lzo,
    section_schedule_subject_dw_id bigint ENCODE lzo,
    section_schedule_teacher_dw_id bigint ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_curriculum_grade (
    curr_grade_dw_id bigint identity(1,1) ENCODE raw,
    curr_grade_name character varying(255) ENCODE lzo,
    curr_grade_created_time timestamp without time zone ENCODE az64,
    curr_grade_updated_time timestamp without time zone ENCODE az64,
    curr_grade_deleted_time timestamp without time zone ENCODE az64,
    curr_grade_dw_created_time timestamp without time zone ENCODE az64,
    curr_grade_dw_updated_time timestamp without time zone ENCODE az64,
    curr_grade_status integer ENCODE az64,
    curr_grade_id bigint ENCODE az64
)
DISTSTYLE ALL
SORTKEY ( curr_grade_dw_id );
CREATE TABLE devcoredw.dim_strand (
    strand_dw_id bigint identity(1,1) ENCODE raw,
    strand_created_time timestamp without time zone ENCODE lzo,
    strand_updated_time timestamp without time zone ENCODE lzo,
    strand_deleted_time timestamp without time zone ENCODE lzo,
    strand_dw_created_time timestamp without time zone ENCODE lzo,
    strand_dw_updated_time timestamp without time zone ENCODE lzo,
    strand_status integer ENCODE lzo,
    strand_id character varying(36) ENCODE lzo,
    strand_name character varying(500) ENCODE lzo,
    strand_description character varying(500) ENCODE lzo,
    strand_curriculum_id bigint ENCODE lzo,
    strand_grade_id bigint ENCODE lzo,
    strand_subject_id bigint ENCODE lzo
)
DISTSTYLE ALL
SORTKEY ( strand_dw_id );
CREATE TABLE devcoredw.fact_teacher_task_center (
    dw_id bigint ENCODE az64,
    created_time timestamp without time zone ENCODE raw,
    dw_created_time timestamp without time zone ENCODE az64,
    date_dw_id bigint ENCODE az64,
    _trace_id character varying(36) ENCODE lzo,
    event_type character varying(36) ENCODE lzo,
    event_id character varying(36) ENCODE lzo,
    task_id character varying(36) ENCODE lzo,
    task_type character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    tenant_dw_id bigint ENCODE az64,
    school_id character varying(36) ENCODE lzo,
    school_dw_id bigint ENCODE az64,
    class_id character varying(36) ENCODE lzo,
    class_dw_id bigint ENCODE az64,
    teacher_id character varying(36) ENCODE lzo distkey,
    teacher_dw_id bigint ENCODE az64,
    _ingestion_type character varying(10) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( created_time );
CREATE TABLE devcoredw.dim_school (
    school_dw_id bigint identity(1,1) ENCODE raw,
    school_created_time timestamp without time zone ENCODE az64,
    school_updated_time timestamp without time zone ENCODE az64,
    school_deleted_time timestamp without time zone ENCODE az64,
    school_dw_created_time timestamp without time zone ENCODE az64,
    school_dw_updated_time timestamp without time zone ENCODE az64,
    school_status integer ENCODE az64,
    school_id character varying(36) ENCODE lzo,
    school_name character varying(256) ENCODE lzo,
    school_address_line character varying(255) ENCODE lzo,
    school_post_box character varying(10) ENCODE lzo,
    school_city_name character varying(100) ENCODE lzo,
    school_country_name character varying(100) ENCODE lzo,
    school_latitude numeric(10,6) ENCODE az64,
    school_longitude numeric(10,6) ENCODE az64,
    school_first_day character varying(30) ENCODE lzo,
    school_timezone character varying(64) ENCODE lzo,
    school_composition character varying(64) ENCODE lzo,
    school_tenant_id character varying(36) ENCODE lzo,
    school_alias character varying(256) ENCODE lzo,
    school_source_id character varying(256) ENCODE lzo,
    school_cx_name_ar character varying(200) ENCODE lzo,
    school_cx_zone character varying(50) ENCODE lzo,
    school_cx_cluster character varying(50) ENCODE lzo,
    school_cx_batch integer ENCODE az64,
    school_cx_status integer ENCODE az64,
    school_cx_report integer ENCODE az64,
    school_cx_last_updated timestamp without time zone ENCODE az64,
    school_cx_id bigint ENCODE az64,
    school_content_repository_dw_id bigint ENCODE az64,
    school_organization_dw_id bigint ENCODE az64,
    school_content_repository_id character varying(36) ENCODE lzo,
    school_organization_code character varying(50) ENCODE lzo,
    _is_complete boolean DEFAULT false ENCODE raw,
    UNIQUE (school_dw_id)
)
DISTSTYLE ALL
SORTKEY ( school_dw_id );
CREATE TABLE devcoredw.dim_content_association (
    content_association_dw_id bigint identity(1,1) ENCODE raw,
    content_association_content_id bigint ENCODE az64,
    content_association_created_time timestamp without time zone ENCODE az64,
    content_association_updated_time timestamp without time zone ENCODE az64,
    content_association_dw_created_time timestamp without time zone ENCODE az64,
    content_association_dw_updated_time timestamp without time zone ENCODE az64,
    content_association_status integer ENCODE az64,
    content_association_id character varying(36) ENCODE lzo,
    content_association_type integer ENCODE az64,
    content_association_attach_status integer ENCODE az64
)
DISTSTYLE ALL
SORTKEY ( content_association_dw_id );
CREATE TABLE devcoredw.dim_assignment_instance (
    assignment_instance_dw_id bigint identity(1,1) ENCODE az64,
    assignment_instance_id character varying(36) ENCODE lzo,
    assignment_instance_created_time timestamp without time zone ENCODE az64,
    assignment_instance_updated_time timestamp without time zone ENCODE az64,
    assignment_instance_deleted_time timestamp without time zone ENCODE az64,
    assignment_instance_dw_created_time timestamp without time zone ENCODE az64,
    assignment_instance_dw_updated_time timestamp without time zone ENCODE az64,
    assignment_instance_instructional_plan_id character varying(36) ENCODE lzo,
    assignment_instance_assignment_dw_id bigint ENCODE az64,
    assignment_instance_due_on timestamp without time zone ENCODE az64,
    assignment_instance_allow_late_submission boolean ENCODE raw,
    assignment_instance_teacher_dw_id bigint ENCODE az64,
    assignment_instance_type character varying(10) ENCODE lzo,
    assignment_instance_grade_dw_id bigint ENCODE raw,
    assignment_instance_subject_dw_id bigint ENCODE az64,
    assignment_instance_class_dw_id bigint ENCODE raw,
    assignment_instance_learning_path_dw_id bigint ENCODE az64,
    assignment_instance_lo_dw_id bigint ENCODE az64,
    assignment_instance_section_dw_id bigint ENCODE az64,
    assignment_instance_start_on timestamp without time zone ENCODE az64,
    assignment_instance_status integer ENCODE az64,
    assignment_instance_tenant_dw_id bigint ENCODE az64,
    assignment_instance_trimester_id character varying(36) ENCODE lzo,
    assignment_instance_active_until timestamp without time zone ENCODE az64,
    assignment_instance_teaching_period_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( assignment_instance_grade_dw_id, assignment_instance_class_dw_id );
CREATE TABLE devcoredw.dim_question_pool (
    question_pool_dw_id bigint identity(1,1) ENCODE raw distkey,
    question_pool_id character varying(36) ENCODE lzo,
    question_pool_name character varying(256) ENCODE lzo,
    question_pool_app_status character varying(24) ENCODE lzo,
    question_pool_triggered_by character varying(108) ENCODE lzo,
    question_pool_question_code_prefix character varying(48) ENCODE lzo,
    question_pool_status integer ENCODE az64,
    question_pool_created_time timestamp without time zone ENCODE az64,
    question_pool_dw_created_time timestamp without time zone ENCODE az64,
    question_pool_updated_time timestamp without time zone ENCODE az64,
    question_pool_deleted_time timestamp without time zone ENCODE az64,
    question_pool_dw_updated_time timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO
SORTKEY ( question_pool_dw_id );
CREATE TABLE devcoredw.dim_pathway_target (
    pt_dw_id bigint ENCODE az64,
    pt_id character varying(36) ENCODE lzo,
    pt_created_time timestamp without time zone ENCODE az64,
    pt_dw_created_time timestamp without time zone ENCODE az64,
    pt_status integer ENCODE az64,
    pt_active_until timestamp without time zone ENCODE az64,
    pt_target_id character varying(36) ENCODE lzo,
    pt_target_dw_id bigint ENCODE az64,
    pt_target_state character varying(20) ENCODE lzo,
    pt_start_date character varying(10) ENCODE lzo,
    pt_end_date character varying(10) ENCODE lzo,
    pt_tenant_id character varying(36) ENCODE lzo,
    pt_tenant_dw_id bigint ENCODE az64,
    pt_school_id character varying(36) ENCODE lzo,
    pt_school_dw_id bigint ENCODE az64,
    pt_grade_id character varying(36) ENCODE lzo,
    pt_grade_dw_id bigint ENCODE az64,
    pt_class_id character varying(36) ENCODE lzo,
    pt_class_dw_id bigint ENCODE az64,
    pt_teacher_id character varying(36) ENCODE lzo distkey,
    pt_teacher_dw_id bigint ENCODE az64,
    pt_pathway_id character varying(36) ENCODE lzo,
    pt_pathway_dw_id bigint ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.fact_tutor_translation (
    ftt_dw_id bigint ENCODE az64,
    ftt_created_time timestamp without time zone ENCODE az64,
    ftt_dw_created_time timestamp without time zone ENCODE az64,
    ftt_date_dw_id bigint ENCODE az64,
    ftt_user_id character varying(36) ENCODE lzo,
    ftt_user_dw_id bigint ENCODE az64,
    ftt_tenant_id character varying(36) ENCODE lzo,
    ftt_message_id character varying(36) ENCODE lzo,
    ftt_session_id character varying(36) ENCODE lzo,
    ftt_conversation_id character varying(36) ENCODE lzo,
    ftt_translation_language character varying(50) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_teacher (
    rel_teacher_dw_id bigint identity(1,1) ENCODE lzo,
    teacher_created_time timestamp without time zone ENCODE lzo,
    teacher_updated_time timestamp without time zone ENCODE lzo,
    teacher_deleted_time timestamp without time zone ENCODE lzo,
    teacher_dw_created_time timestamp without time zone ENCODE lzo,
    teacher_dw_updated_time timestamp without time zone ENCODE lzo,
    teacher_active_until timestamp without time zone ENCODE lzo,
    teacher_status integer ENCODE lzo,
    teacher_id character varying(36) ENCODE lzo,
    teacher_dw_id bigint ENCODE raw distkey,
    teacher_subject_dw_id bigint ENCODE lzo,
    teacher_school_dw_id bigint ENCODE lzo
)
DISTSTYLE KEY
SORTKEY ( teacher_dw_id );
CREATE TABLE devcoredw.dim_staff_user_school_role_association (
    susra_dw_id bigint ENCODE az64,
    susra_event_type character varying(50) ENCODE lzo,
    susra_staff_id character varying(36) ENCODE lzo,
    susra_staff_dw_id bigint ENCODE az64,
    susra_school_id character varying(36) ENCODE lzo,
    susra_school_dw_id bigint ENCODE az64,
    susra_role_name character varying(50) ENCODE lzo,
    susra_role_uuid character varying(36) ENCODE lzo,
    susra_role_dw_id bigint ENCODE az64,
    susra_organization character varying(50) ENCODE lzo,
    susra_status integer ENCODE az64,
    susra_created_time timestamp without time zone ENCODE az64,
    susra_dw_created_time timestamp without time zone ENCODE az64,
    susra_active_until timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.mainbackupfle (
    cnt bigint ENCODE az64,
    fle_ls_id character varying(36) ENCODE lzo,
    fle_exp_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.fact_teacher_task_center_clone (
    dw_id bigint ENCODE az64,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    date_dw_id bigint ENCODE az64,
    trace_id character varying(36) ENCODE lzo,
    event_type character varying(36) ENCODE lzo,
    id character varying(36) ENCODE lzo,
    task_id character varying(36) ENCODE lzo,
    task_type character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    tenant_dw_id bigint ENCODE az64,
    school_id character varying(36) ENCODE lzo,
    school_dw_id bigint ENCODE az64,
    class_id character varying(36) ENCODE lzo,
    class_dw_id bigint ENCODE az64,
    teacher_id character varying(36) ENCODE lzo,
    teacher_dw_id bigint ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.fact_experience_submitted (
    fes_dw_id bigint identity(1,1) ENCODE az64,
    fes_created_time timestamp without time zone ENCODE az64,
    fes_dw_created_time timestamp without time zone ENCODE az64,
    fes_date_dw_id bigint ENCODE raw,
    fes_id character varying(36) ENCODE lzo,
    fes_exp_dw_id bigint ENCODE az64 distkey,
    fes_ls_dw_id bigint ENCODE az64,
    fes_content_id character varying(36) ENCODE lzo,
    fes_lo_dw_id bigint ENCODE az64,
    fes_student_dw_id bigint ENCODE raw,
    fes_section_dw_id bigint ENCODE az64,
    fes_class_dw_id bigint ENCODE raw,
    fes_subject_dw_id bigint ENCODE az64,
    fes_grade_dw_id bigint ENCODE raw,
    fes_tenant_dw_id bigint ENCODE az64,
    fes_school_dw_id bigint ENCODE raw,
    fes_lp_dw_id bigint ENCODE az64,
    fes_instructional_plan_id character varying(36) ENCODE lzo,
    fes_content_package_id character varying(36) ENCODE lzo,
    fes_content_title character varying(100) ENCODE lzo,
    fes_content_type character varying(100) ENCODE lzo,
    fes_start_time timestamp without time zone ENCODE az64,
    fes_lesson_type character varying(50) ENCODE lzo,
    fes_is_retry boolean ENCODE raw,
    fes_outside_of_school boolean ENCODE raw,
    fes_attempt integer ENCODE az64,
    fes_academic_period_order integer ENCODE az64,
    fes_academic_year_dw_id bigint ENCODE az64,
    fes_content_academic_year integer ENCODE az64,
    fes_lesson_category character varying(100) ENCODE lzo,
    fes_suid character varying(36) ENCODE lzo,
    fes_abbreviation character varying(100) ENCODE lzo,
    fes_activity_type character varying(100) ENCODE lzo,
    fes_activity_component_type character varying(100) ENCODE lzo,
    fes_completion_node boolean ENCODE raw,
    fes_main_component boolean ENCODE raw,
    fes_exit_ticket boolean ENCODE raw,
    fes_ls_id character varying(36) ENCODE lzo,
    exp_uuid character varying(36) ENCODE lzo,
    fes_material_id character varying(36) ENCODE lzo,
    fes_material_type character varying(20) ENCODE lzo
)
DISTSTYLE KEY
SORTKEY ( fes_date_dw_id, fes_school_dw_id, fes_grade_dw_id, fes_class_dw_id, fes_student_dw_id );
CREATE TABLE devcoredw.fact_student_slide_progress (
    dw_id bigint ENCODE az64,
    event_type character varying(100) ENCODE lzo,
    created_time timestamp without time zone ENCODE raw,
    dw_created_time timestamp without time zone ENCODE az64,
    _trace_id character varying(36) ENCODE lzo,
    date_dw_id bigint ENCODE az64,
    tenant_id character varying(36) ENCODE lzo,
    tenant_dw_id bigint ENCODE az64,
    experience_id character varying(36) ENCODE lzo,
    learning_session_id character varying(36) ENCODE lzo,
    content_section_id character varying(36) ENCODE lzo,
    content_section_dw_id bigint ENCODE az64,
    slide_id character varying(36) ENCODE lzo,
    slide_dw_id_sk bigint ENCODE az64,
    widget_id character varying(50) ENCODE lzo,
    status character varying(20) ENCODE lzo,
    active_time integer ENCODE az64,
    idle_time integer ENCODE az64,
    total_time_spent integer ENCODE az64,
    result character varying(20) ENCODE lzo,
    attempt integer ENCODE az64,
    student_id character varying(36) ENCODE lzo,
    student_dw_id bigint ENCODE raw distkey,
    school_id character varying(36) ENCODE lzo,
    school_dw_id bigint ENCODE az64,
    grade_id character varying(36) ENCODE lzo,
    grade_dw_id bigint ENCODE az64,
    student_section_id character varying(36) ENCODE lzo,
    student_section_dw_id bigint ENCODE az64,
    class_id character varying(36) ENCODE lzo,
    class_dw_id bigint ENCODE az64,
    activity_id character varying(36) ENCODE lzo,
    activity_dw_id bigint ENCODE az64,
    academic_year_tag character varying(20) ENCODE lzo,
    material_id character varying(36) ENCODE lzo,
    material_dw_id bigint ENCODE az64,
    material_type character varying(20) ENCODE lzo,
    ccl_content_id bigint ENCODE az64,
    channel character varying(50) ENCODE lzo,
    _ingestion_type character varying(10) ENCODE lzo,
    FOREIGN KEY (content_section_dw_id) REFERENCES devcoredw.dim_content_section(dw_id),
    FOREIGN KEY (slide_dw_id_sk) REFERENCES devcoredw.dim_content_slide(dw_id),
    FOREIGN KEY (student_dw_id) REFERENCES devcoredw.dim_student(student_dw_id),
    FOREIGN KEY (school_dw_id) REFERENCES devcoredw.dim_school(school_dw_id),
    FOREIGN KEY (grade_dw_id) REFERENCES devcoredw.dim_grade(grade_dw_id),
    FOREIGN KEY (student_section_dw_id) REFERENCES devcoredw.dim_section(section_dw_id),
    FOREIGN KEY (class_dw_id) REFERENCES devcoredw.dim_class(class_dw_id),
    FOREIGN KEY (activity_dw_id) REFERENCES devcoredw.dim_learning_objective(lo_dw_id),
    FOREIGN KEY (ccl_content_id) REFERENCES devcoredw.dim_content(content_id)
)
DISTSTYLE KEY
SORTKEY ( created_time, student_dw_id );
CREATE TABLE devcoredw.dim_course_ability_test_association (
    cata_dw_id bigint ENCODE az64,
    cata_created_time timestamp without time zone ENCODE az64,
    cata_updated_time timestamp without time zone ENCODE az64,
    cata_dw_created_time timestamp without time zone ENCODE az64,
    cata_dw_updated_time timestamp without time zone ENCODE az64,
    cata_course_id character varying(36) ENCODE lzo,
    cata_ability_test_activity_uuid character varying(36) ENCODE lzo,
    cata_ability_test_activity_id integer ENCODE az64,
    cata_ability_test_id character varying(36) ENCODE lzo,
    cata_max_attempts integer ENCODE az64,
    cata_ability_test_pacing character varying(16) ENCODE lzo,
    cata_ability_test_index integer ENCODE az64,
    cata_course_version character varying(10) ENCODE lzo,
    cata_ability_test_type integer ENCODE az64,
    cata_status integer ENCODE az64,
    cata_attach_status integer ENCODE az64,
    cata_ability_test_activity_type character varying(50) ENCODE lzo,
    cata_is_placement_test boolean ENCODE raw
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_tenant (
    tenant_dw_id bigint identity(1,1) ENCODE raw,
    tenant_id character varying(36) ENCODE lzo,
    tenant_name character varying(765) ENCODE lzo,
    tenant_timezone character varying(100) ENCODE lzo,
    UNIQUE (tenant_dw_id)
)
DISTSTYLE ALL
SORTKEY ( tenant_dw_id );
CREATE TABLE devcoredw.dim_team_student_association (
    rel_team_student_association_dw_id bigint identity(1,1) ENCODE raw,
    team_student_association_created_time timestamp without time zone ENCODE az64,
    team_student_association_updated_time timestamp without time zone ENCODE az64,
    team_student_association_dw_created_time timestamp without time zone ENCODE az64,
    team_student_association_dw_updated_time timestamp without time zone ENCODE az64,
    team_student_association_status smallint ENCODE az64,
    team_student_association_active_until timestamp without time zone ENCODE az64,
    team_student_association_team_dw_id bigint ENCODE az64,
    team_student_association_student_dw_id bigint ENCODE az64
)
DISTSTYLE ALL
SORTKEY ( rel_team_student_association_dw_id );
CREATE TABLE devcoredw.dim_avatar_customization (
    ac_dw_id bigint NOT NULL ENCODE az64,
    ac_created_time timestamp without time zone ENCODE az64,
    ac_updated_time timestamp without time zone ENCODE az64,
    ac_deleted_time timestamp without time zone ENCODE az64,
    ac_dw_created_time timestamp without time zone ENCODE az64,
    ac_dw_updated_time timestamp without time zone ENCODE az64,
    ac_status integer ENCODE az64,
    ac_student_id character varying(36) ENCODE lzo,
    ac_student_dw_id integer ENCODE az64,
    ac_avatar_id character varying(36) ENCODE lzo,
    ac_avatar_dw_id integer ENCODE az64,
    ac_type character varying(30) ENCODE lzo,
    ac_item_id character varying(36) ENCODE lzo,
    ac_item_type character varying(30) ENCODE lzo,
    ac_item_value character varying(60) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.fact_adt_lock_status (
    dw_id bigint ENCODE az64,
    _trace_id character varying(36) ENCODE lzo,
    event_type character varying(36) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    date_dw_id bigint ENCODE az64,
    id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    tenant_dw_id bigint ENCODE az64,
    academic_year_tag character varying(10) ENCODE lzo,
    attempt_number bigint ENCODE az64,
    teacher_id character varying(36) ENCODE lzo,
    teacher_dw_id bigint ENCODE az64,
    student_id character varying(36) ENCODE lzo distkey,
    student_dw_id bigint ENCODE az64,
    school_id character varying(36) ENCODE lzo,
    school_dw_id bigint ENCODE az64,
    class_id character varying(36) ENCODE lzo,
    class_dw_id bigint ENCODE az64,
    adt_id character varying(36) ENCODE lzo,
    should_send_notification boolean ENCODE raw,
    _ingestion_type character varying(10) ENCODE lzo,
    source character varying(10) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.rel_content_slide (
    dw_id bigint NOT NULL ENCODE az64,
    event_type character varying(100) ENCODE lzo,
    _trace_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    id character varying(36) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    status smallint ENCODE az64,
    active_until character varying(36) ENCODE lzo,
    section_id bigint ENCODE az64,
    source_id character varying(36) ENCODE lzo,
    sequence smallint ENCODE az64,
    show_progressbar boolean ENCODE raw,
    disable_primary_button boolean ENCODE raw,
    is_default_disabled boolean ENCODE raw,
    is_last_slide boolean ENCODE raw,
    widget_id character varying(50) ENCODE lzo,
    widget_type character varying(50) ENCODE lzo,
    widget_sub_type character varying(50) ENCODE lzo,
    widget_version character varying(5) ENCODE lzo,
    widget_title character varying(256) ENCODE lzo,
    widget_subtitle character varying(400) ENCODE lzo,
    widget_has_passage boolean ENCODE raw,
    widget_video boolean ENCODE raw,
    widget_audio boolean ENCODE raw,
    widget_need_help boolean ENCODE raw,
    widget_submit_limit integer ENCODE az64,
    widget_shuffled boolean ENCODE raw,
    widget_feedback boolean ENCODE raw,
    widget_multiple_answer boolean ENCODE raw,
    PRIMARY KEY (dw_id)
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_standard (
    standard_dw_id bigint identity(1,1) ENCODE raw,
    standard_created_time timestamp without time zone ENCODE lzo,
    standard_updated_time timestamp without time zone ENCODE lzo,
    standard_deleted_time timestamp without time zone ENCODE lzo,
    standard_dw_created_time timestamp without time zone ENCODE lzo,
    standard_dw_updated_time timestamp without time zone ENCODE lzo,
    standard_status integer ENCODE lzo,
    standard_id character varying(36) ENCODE lzo,
    standard_name character varying(500) ENCODE lzo,
    standard_description character varying(500) ENCODE lzo,
    standard_strand_id bigint ENCODE lzo
)
DISTSTYLE ALL
SORTKEY ( standard_dw_id );
CREATE TABLE devcoredw.dim_teacher_test_delivery_settings (
    ttds_dw_id bigint ENCODE az64,
    ttds_test_id character varying(36) ENCODE lzo,
    ttds_tenant_id character varying(36) ENCODE lzo,
    ttds_test_delivery_id character varying(36) ENCODE lzo,
    ttds_test_start_time timestamp without time zone ENCODE az64,
    ttds_test_end_time timestamp without time zone ENCODE az64,
    ttds_allow_late_submission boolean ENCODE raw,
    ttds_title character varying(255) ENCODE lzo,
    ttds_stars integer ENCODE az64,
    ttds_randomized boolean ENCODE raw,
    ttds_delivery_status character varying(40) ENCODE lzo,
    ttds_status integer ENCODE az64,
    ttds_created_time timestamp without time zone ENCODE az64,
    ttds_updated_time timestamp without time zone ENCODE az64,
    ttds_deleted_time timestamp without time zone ENCODE az64,
    ttds_dw_created_time timestamp without time zone ENCODE az64,
    ttds_dw_updated_time timestamp without time zone ENCODE az64,
    ttds_dw_deleted_time timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_assignment_instance_student (
    ais_dw_id bigint identity(1,1) ENCODE az64,
    ais_created_time timestamp without time zone ENCODE az64,
    ais_dw_created_time timestamp without time zone ENCODE az64,
    ais_updated_time timestamp without time zone ENCODE az64,
    ais_dw_updated_time timestamp without time zone ENCODE az64,
    ais_deleted_time timestamp without time zone ENCODE az64,
    ais_status integer ENCODE az64,
    ais_instance_dw_id bigint ENCODE raw,
    ais_student_dw_id bigint ENCODE raw
)
DISTSTYLE AUTO
SORTKEY ( ais_instance_dw_id, ais_student_dw_id );
CREATE TABLE devcoredw.dim_avatar_layer (
    avatar_layer_dw_id bigint NOT NULL ENCODE az64,
    avatar_layer_created_time timestamp without time zone ENCODE raw,
    avatar_layer_dw_created_time timestamp without time zone ENCODE az64,
    avatar_layer_updated_time timestamp without time zone ENCODE az64,
    avatar_layer_dw_updated_time timestamp without time zone ENCODE az64,
    avatar_layer_deleted_time timestamp without time zone ENCODE az64,
    avatar_layer_id character varying(36) NOT NULL ENCODE lzo distkey,
    avatar_layer_status integer ENCODE az64,
    avatar_layer_config_type character varying(20) ENCODE lzo,
    avatar_layer_type character varying(20) ENCODE lzo,
    avatar_layer_key character varying(50) ENCODE lzo,
    avatar_layer_value character varying(50) ENCODE lzo,
    avatar_layer_genders character varying(36) ENCODE lzo,
    avatar_layer_cost integer ENCODE az64,
    avatar_layer_is_enabled boolean ENCODE raw,
    avatar_layer_is_deleted boolean ENCODE raw,
    avatar_layer_valid_from timestamp without time zone ENCODE az64,
    avatar_layer_valid_till timestamp without time zone ENCODE az64,
    avatar_layer_order integer ENCODE az64
)
DISTSTYLE AUTO
SORTKEY ( avatar_layer_created_time );
CREATE TABLE devcoredw.dim_instructional_plan (
    instructional_plan_dw_id bigint identity(1,1) ENCODE raw,
    instructional_plan_created_time timestamp without time zone ENCODE az64,
    instructional_plan_updated_time timestamp without time zone ENCODE az64,
    instructional_plan_deleted_time timestamp without time zone ENCODE az64,
    instructional_plan_dw_created_time timestamp without time zone ENCODE az64,
    instructional_plan_dw_updated_time timestamp without time zone ENCODE az64,
    instructional_plan_status integer ENCODE az64,
    instructional_plan_id character varying(36) ENCODE lzo,
    instructional_plan_curriculum_id bigint ENCODE az64,
    instructional_plan_curriculum_subject_id bigint ENCODE az64,
    instructional_plan_curriculum_grade_id bigint ENCODE az64,
    instructional_plan_content_academic_year_id integer ENCODE az64,
    instructional_plan_item_order integer ENCODE az64,
    instructional_plan_item_ccl_lo_id bigint ENCODE az64,
    instructional_plan_item_optional boolean ENCODE raw,
    instructional_plan_item_lo_dw_id bigint ENCODE az64,
    instructional_plan_item_week_dw_id bigint ENCODE az64,
    instructional_plan_item_instructor_led boolean ENCODE raw,
    instructional_plan_item_default_locked boolean ENCODE raw,
    instructional_plan_item_type character varying(36) ENCODE lzo,
    instructional_plan_item_ic_dw_id bigint ENCODE az64,
    instructional_plan_content_repository_id character varying(36) ENCODE lzo,
    instructional_plan_content_repository_dw_id bigint ENCODE az64,
    instructional_plan_name character varying(100) ENCODE lzo
)
DISTSTYLE ALL
SORTKEY ( instructional_plan_dw_id );
CREATE TABLE devcoredw.dim_skill_association (
    skill_association_dw_id bigint identity(1,1) ENCODE raw,
    skill_association_created_time timestamp without time zone ENCODE az64,
    skill_association_updated_time timestamp without time zone ENCODE az64,
    skill_association_dw_created_time timestamp without time zone ENCODE az64,
    skill_association_dw_updated_time timestamp without time zone ENCODE az64,
    skill_association_status integer ENCODE az64,
    skill_association_skill_id character varying(36) ENCODE lzo,
    skill_association_skill_code character varying(50) ENCODE lzo,
    skill_association_id character varying(36) ENCODE lzo,
    skill_association_code character varying(50) ENCODE lzo,
    skill_association_type integer ENCODE az64,
    skill_association_attach_status integer ENCODE az64,
    skill_association_is_previous boolean ENCODE raw
)
DISTSTYLE ALL
SORTKEY ( skill_association_dw_id );
CREATE TABLE devcoredw.fact_skill_content_unavailable (
    scu_dw_id bigint identity(1,1) ENCODE lzo,
    scu_created_time timestamp without time zone ENCODE lzo,
    scu_dw_created_time timestamp without time zone ENCODE lzo,
    scu_date_dw_id bigint ENCODE lzo,
    scu_tenant_dw_id bigint ENCODE lzo,
    scu_lo_dw_id bigint ENCODE lzo,
    scu_skill_dw_id bigint ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.fact_tutor_onboarding (
    fto_dw_id bigint ENCODE az64,
    fto_created_time timestamp without time zone ENCODE az64,
    fto_dw_created_time timestamp without time zone ENCODE az64,
    fto_date_dw_id bigint ENCODE az64,
    fto_user_id character varying(36) ENCODE lzo,
    fto_user_dw_id bigint ENCODE az64,
    fto_tenant_id character varying(36) ENCODE lzo,
    fto_question_id character varying(36) ENCODE lzo,
    fto_question_category character varying(50) ENCODE lzo,
    fto_user_free_text_response boolean ENCODE raw,
    fto_onboarding_complete boolean ENCODE raw,
    fto_onboarding_skipped boolean ENCODE raw
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.fact_levels_recommended (
    flr_dw_id bigint identity(1,1) ENCODE raw,
    flr_created_time timestamp without time zone ENCODE az64,
    flr_dw_created_time timestamp without time zone ENCODE az64,
    flr_date_dw_id bigint ENCODE az64,
    flr_recommended_on timestamp without time zone ENCODE az64,
    flr_tenant_dw_id bigint ENCODE az64,
    flr_student_dw_id bigint ENCODE az64,
    flr_class_dw_id bigint ENCODE az64,
    flr_pathway_dw_id bigint ENCODE az64,
    flr_completed_level_dw_id bigint ENCODE az64,
    flr_level_dw_id bigint ENCODE az64,
    flr_status integer ENCODE az64,
    flr_recommendation_type integer ENCODE az64,
    flr_course_activity_container_dw_id bigint ENCODE az64,
    flr_completed_course_activity_container_dw_id bigint ENCODE az64,
    flr_course_dw_id bigint ENCODE az64,
    flr_academic_year character varying(50) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( flr_dw_id );
CREATE TABLE devcoredw.flyway_schema_history_nextgen (
    installed_rank integer NOT NULL ENCODE raw,
    version character varying(50) ENCODE lzo,
    description character varying(200) NOT NULL ENCODE lzo,
    type character varying(20) NOT NULL ENCODE lzo,
    script character varying(1000) NOT NULL ENCODE lzo,
    checksum integer ENCODE az64,
    installed_by character varying(100) NOT NULL ENCODE lzo,
    installed_on timestamp without time zone NOT NULL DEFAULT getdate() ENCODE az64,
    execution_time integer NOT NULL ENCODE az64,
    success boolean NOT NULL ENCODE raw,
    PRIMARY KEY (installed_rank)
)
DISTSTYLE AUTO
SORTKEY ( installed_rank );
CREATE TABLE devcoredw.dim_teacher_feedback_thread (
    tft_dw_id bigint identity(1,1) ENCODE az64,
    tft_status smallint ENCODE az64,
    tft_created_time timestamp without time zone ENCODE az64,
    tft_dw_created_time timestamp without time zone ENCODE az64,
    tft_deleted_time timestamp without time zone ENCODE az64,
    tft_updated_time timestamp without time zone ENCODE az64,
    tft_dw_updated_time timestamp without time zone ENCODE az64,
    tft_thread_id character varying(36) ENCODE lzo,
    tft_actor_type smallint ENCODE az64,
    tft_guardian_dw_id bigint ENCODE raw,
    tft_message_id character varying(36) ENCODE lzo,
    tft_response_enabled boolean ENCODE raw,
    tft_feedback_type smallint ENCODE az64,
    tft_teacher_dw_id bigint ENCODE raw,
    tft_student_dw_id bigint ENCODE raw,
    tft_class_dw_id bigint ENCODE raw,
    tft_is_read boolean ENCODE raw,
    tft_event_subject smallint ENCODE az64,
    tft_is_first_of_thread boolean ENCODE raw
)
DISTSTYLE AUTO
SORTKEY ( tft_teacher_dw_id, tft_class_dw_id, tft_guardian_dw_id, tft_student_dw_id );
CREATE TABLE devcoredw.schema_evolution_testing_first_table (
    id integer NOT NULL ENCODE az64,
    first_name character varying(256) ENCODE lzo,
    last_name character varying(256) ENCODE lzo,
    temp2 integer NOT NULL ENCODE az64,
    temp integer NOT NULL ENCODE az64,
    temp3 integer NOT NULL ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_holiday (
    holiday_dw_id bigint identity(1,1) ENCODE raw,
    holiday_date date ENCODE az64,
    holiday_name character varying(100) ENCODE lzo,
    holiday_country character varying(50) ENCODE lzo,
    holiday_organisation_dw_id integer ENCODE az64,
    content_repository_dw_id bigint ENCODE az64
)
DISTSTYLE ALL
SORTKEY ( holiday_dw_id );
CREATE TABLE devcoredw.fact_tutor_challenge_question_answer (
    ftcqa_bot_question_timestamp timestamp without time zone ENCODE raw,
    ftcqa_bot_question_source character varying(10) ENCODE lzo,
    ftcqa_bot_question_id character varying(36) ENCODE lzo,
    ftcqa_bot_question_tokens integer ENCODE az64,
    ftcqa_conversation_id character varying(36) ENCODE lzo,
    ftcqa_session_id character varying(36) ENCODE lzo,
    ftcqa_message_id character varying(36) ENCODE lzo,
    ftcqa_user_id character varying(36) ENCODE lzo,
    ftcqa_user_dw_id bigint ENCODE az64 distkey,
    ftcqa_tenant_id character varying(36) ENCODE lzo,
    ftcqa_date_dw_id bigint ENCODE az64,
    ftcqa_created_time timestamp without time zone ENCODE az64,
    ftcqa_dw_created_time timestamp without time zone ENCODE az64,
    ftcqa_is_answer_evaluated boolean ENCODE raw,
    ftcqa_dw_id bigint ENCODE az64,
    ftcqa_user_attempt_tokens integer ENCODE az64,
    ftcqa_user_attempt_number integer ENCODE az64,
    ftcqa_user_remaining_attempts integer ENCODE az64,
    ftcqa_user_attempt_timestamp timestamp without time zone ENCODE az64,
    ftcqa_user_attempt_is_correct boolean ENCODE raw,
    ftcqa_user_attempt_source character varying(20) ENCODE lzo,
    ftcqa_user_attempt_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( ftcqa_bot_question_timestamp );
CREATE TABLE devcoredw.fact_tutor_user_context (
    ftc_dw_id bigint identity(1,1) ENCODE az64 distkey,
    ftc_created_time timestamp without time zone ENCODE raw,
    ftc_dw_created_time timestamp without time zone ENCODE az64,
    ftc_date_dw_id bigint ENCODE az64,
    ftc_tenant_dw_id bigint ENCODE az64,
    ftc_user_dw_id bigint ENCODE az64,
    ftc_role character varying(20) ENCODE lzo,
    ftc_context_id character varying(36) ENCODE lzo,
    ftc_school_dw_id bigint ENCODE az64,
    ftc_grade_dw_id bigint ENCODE az64,
    ftc_grade bigint ENCODE az64,
    ftc_subject_dw_id bigint ENCODE az64,
    ftc_subject character varying(20) ENCODE lzo,
    ftc_language character varying(20) ENCODE lzo,
    ftc_tutor_locked boolean ENCODE raw
)
DISTSTYLE KEY
SORTKEY ( ftc_created_time );
CREATE TABLE devcoredw.dim_teacher_test_candidate_association (
    ttca_dw_id bigint ENCODE az64,
    ttca_test_delivery_id character varying(36) ENCODE lzo,
    ttca_test_id character varying(36) ENCODE lzo,
    ttca_test_candidate_id character varying(36) ENCODE lzo,
    ttca_status integer ENCODE az64,
    ttca_active_until timestamp without time zone ENCODE az64,
    ttca_created_time timestamp without time zone ENCODE az64,
    ttca_dw_created_time timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_class_category (
    class_category_dw_id bigint identity(1,1) ENCODE raw,
    class_category_id character varying(36) ENCODE lzo,
    class_category_name character varying(50) ENCODE lzo,
    class_category_created_time timestamp without time zone ENCODE az64,
    class_category_dw_created_time timestamp without time zone ENCODE az64,
    class_category_updated_time timestamp without time zone ENCODE az64,
    class_category_dw_updated_time timestamp without time zone ENCODE az64,
    class_category_status integer ENCODE az64,
    class_category_organization_code character varying(20) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( class_category_dw_id );
CREATE TABLE devcoredw.dim_curriculum (
    curr_dw_id bigint identity(1,1) ENCODE raw,
    curr_name character varying(255) ENCODE lzo,
    curr_created_time timestamp without time zone ENCODE az64,
    curr_updated_time timestamp without time zone ENCODE az64,
    curr_deleted_time timestamp without time zone ENCODE az64,
    curr_dw_created_time timestamp without time zone ENCODE az64,
    curr_dw_updated_time timestamp without time zone ENCODE az64,
    curr_status integer ENCODE az64,
    curr_id bigint ENCODE az64,
    curr_organisation character varying(50) ENCODE lzo
)
DISTSTYLE ALL
SORTKEY ( curr_dw_id );
CREATE TABLE devcoredw.fact_ktgskipped (
    ktgskipped_dw_id bigint identity(1,1) ENCODE raw,
    ktgskipped_created_time timestamp without time zone ENCODE lzo,
    ktgskipped_dw_created_time timestamp without time zone ENCODE lzo,
    ktgskipped_date_dw_id bigint ENCODE lzo,
    ktgskipped_tenant_dw_id bigint ENCODE lzo,
    ktgskipped_student_dw_id bigint ENCODE raw,
    ktgskipped_subject_dw_id bigint ENCODE raw,
    ktgskipped_school_dw_id bigint ENCODE raw,
    ktgskipped_grade_dw_id bigint ENCODE raw,
    ktgskipped_section_dw_id bigint ENCODE raw,
    ktgskipped_lo_dw_id bigint ENCODE raw,
    ktgskipped_academic_year_dw_id bigint ENCODE raw,
    ktgskipped_num_key_terms smallint ENCODE lzo,
    ktgskipped_kt_collection_id bigint ENCODE lzo,
    ktgskipped_trimester_id character varying(256) ENCODE lzo,
    ktgskipped_trimester_order smallint ENCODE lzo,
    ktgskipped_min_question smallint ENCODE lzo,
    ktgskipped_max_question smallint ENCODE lzo,
    ktgskipped_type character varying(200) ENCODE lzo,
    ktgskipped_question_type character varying(1000) ENCODE lzo,
    ktgskipped_question_time_allotted integer ENCODE lzo,
    ktgskipped_instructional_plan_id character varying(36) ENCODE lzo,
    ktgskipped_learning_path_id character varying(36) ENCODE lzo,
    ktgskipped_class_dw_id bigint ENCODE az64,
    ktgskipped_material_type character varying(20) ENCODE lzo,
    ktgskipped_material_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( ktgskipped_dw_id, ktgskipped_student_dw_id, ktgskipped_subject_dw_id, ktgskipped_school_dw_id, ktgskipped_grade_dw_id, ktgskipped_section_dw_id, ktgskipped_lo_dw_id, ktgskipped_academic_year_dw_id );
CREATE TABLE devcoredw.dim_content (
    content_dw_id bigint identity(1,1) ENCODE raw,
    content_created_time timestamp without time zone ENCODE az64,
    content_updated_time timestamp without time zone ENCODE az64,
    content_deleted_time timestamp without time zone ENCODE az64,
    content_dw_created_time timestamp without time zone ENCODE az64,
    content_dw_updated_time timestamp without time zone ENCODE az64,
    content_status integer ENCODE az64,
    content_id character varying(36) ENCODE lzo,
    content_title character varying(255) ENCODE lzo,
    content_tags character varying(255) ENCODE lzo,
    content_file_content_type character varying(50) ENCODE lzo,
    content_file_size bigint ENCODE az64,
    content_file_updated_at timestamp without time zone ENCODE az64,
    content_condition_of_use character varying(100) ENCODE lzo,
    content_knowledge_dimension character varying(50) ENCODE lzo,
    content_difficulty_level character varying(50) ENCODE lzo,
    content_language character varying(50) ENCODE lzo,
    content_lexical_level character varying(36) ENCODE lzo,
    content_media_type character varying(50) ENCODE lzo,
    content_action_status integer ENCODE az64,
    content_location character varying(100) ENCODE lzo,
    content_authored_date date ENCODE az64,
    content_created_at timestamp without time zone ENCODE az64,
    content_created_by bigint ENCODE az64,
    content_published_date date ENCODE az64,
    content_publisher_id bigint ENCODE az64,
    content_organisation character varying(50) ENCODE lzo,
    content_learning_resource_types character varying(200) ENCODE lzo,
    content_cognitive_dimensions character varying(200) ENCODE lzo,
    content_file_name character varying(256) ENCODE lzo,
    UNIQUE (content_dw_id),
    UNIQUE (content_id)
)
DISTSTYLE ALL
SORTKEY ( content_dw_id );
CREATE TABLE devcoredw.dim_learning_objective_association (
    lo_association_dw_id bigint identity(1,1) ENCODE raw,
    lo_association_lo_id character varying(36) ENCODE lzo,
    lo_association_created_time timestamp without time zone ENCODE az64,
    lo_association_updated_time timestamp without time zone ENCODE az64,
    lo_association_dw_created_time timestamp without time zone ENCODE az64,
    lo_association_dw_updated_time timestamp without time zone ENCODE az64,
    lo_association_status integer ENCODE az64,
    lo_association_lo_ccl_id bigint ENCODE az64,
    lo_association_id character varying(36) ENCODE lzo,
    lo_association_attach_status integer ENCODE az64,
    lo_association_type integer ENCODE az64,
    lo_association_derived boolean ENCODE raw
)
DISTSTYLE ALL
SORTKEY ( lo_association_dw_id );
CREATE TABLE devcoredw.dim_school_academic_year_association (
    saya_dw_id bigint ENCODE az64,
    saya_school_id character varying(36) ENCODE lzo,
    saya_academic_year_id character varying(36) ENCODE lzo,
    saya_status integer ENCODE az64,
    saya_created_time timestamp without time zone ENCODE az64,
    saya_updated_time timestamp without time zone ENCODE az64,
    saya_dw_created_time timestamp without time zone ENCODE az64,
    saya_dw_updated_time timestamp without time zone ENCODE az64,
    saya_previous_academic_year_id character varying(36) ENCODE lzo,
    saya_type character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_course_activity_container (
    course_activity_container_is_accelerated boolean ENCODE raw,
    course_activity_container_pacing character varying(50) ENCODE lzo,
    course_activity_container_grade character varying(10) ENCODE lzo,
    course_activity_container_sequence integer ENCODE az64,
    course_activity_container_course_version character varying(10) ENCODE lzo,
    course_activity_container_attach_status integer ENCODE az64,
    course_activity_container_id character varying(36) ENCODE lzo,
    course_activity_container_dw_id bigint ENCODE az64,
    course_activity_container_longname character varying(255) ENCODE lzo,
    course_activity_container_updated_time timestamp without time zone ENCODE az64,
    course_activity_container_dw_created_time timestamp without time zone ENCODE az64,
    course_activity_container_title character varying(50) ENCODE lzo,
    course_activity_container_created_time timestamp without time zone ENCODE az64,
    course_activity_container_course_id character varying(36) ENCODE lzo,
    course_activity_container_domain character varying(50) ENCODE lzo,
    course_activity_container_status integer ENCODE az64,
    course_activity_container_dw_updated_time timestamp without time zone ENCODE az64,
    course_activity_container_index integer ENCODE az64,
    rel_course_activity_container_dw_id bigint ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_weekly_goal_type (
    weekly_goal_type_dw_id bigint identity(1,1) ENCODE az64,
    weekly_goal_type_created_time timestamp without time zone ENCODE az64,
    weekly_goal_type_dw_created_time timestamp without time zone ENCODE az64,
    weekly_goal_type_id character varying(36) ENCODE lzo,
    weekly_goal_type_tenant_id character varying(36) ENCODE lzo,
    weekly_goal_type_total_activity_count integer ENCODE az64,
    weekly_goal_type_stars_to_award integer ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_grade (
    grade_dw_id bigint identity(1,1) ENCODE raw,
    grade_created_time timestamp without time zone ENCODE raw,
    grade_updated_time timestamp without time zone ENCODE raw,
    grade_deleted_time timestamp without time zone ENCODE raw,
    grade_dw_created_time timestamp without time zone ENCODE raw,
    grade_dw_updated_time timestamp without time zone ENCODE raw,
    grade_status integer ENCODE raw,
    grade_id character varying(36) ENCODE raw,
    grade_name character varying(250) ENCODE raw,
    grade_k12grade integer ENCODE raw,
    academic_year_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    school_id character varying(36) ENCODE lzo,
    UNIQUE (grade_dw_id)
)
DISTSTYLE ALL
SORTKEY ( grade_dw_id );
CREATE TABLE devcoredw.fact_level_completed (
    flc_dw_id bigint identity(1,1) ENCODE raw,
    flc_created_time timestamp without time zone ENCODE az64,
    flc_dw_created_time timestamp without time zone ENCODE az64,
    flc_date_dw_id bigint ENCODE az64,
    flc_completed_on timestamp without time zone ENCODE az64,
    flc_tenant_dw_id bigint ENCODE az64,
    flc_student_dw_id bigint ENCODE az64,
    flc_class_dw_id bigint ENCODE az64,
    flc_pathway_dw_id bigint ENCODE az64,
    flc_level_dw_id bigint ENCODE az64,
    flc_total_stars integer ENCODE az64,
    flc_course_activity_container_dw_id bigint ENCODE az64,
    flc_course_dw_id bigint ENCODE az64,
    flc_academic_year character varying(50) ENCODE lzo,
    flc_score integer ENCODE az64
)
DISTSTYLE AUTO
SORTKEY ( flc_dw_id );
CREATE TABLE devcoredw.dim_testpart (
    dw_id bigint ENCODE az64,
    _trace_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    event_type character varying(50) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    active_until timestamp without time zone ENCODE az64,
    status integer ENCODE az64,
    published_on timestamp without time zone ENCODE az64,
    id character varying(36) ENCODE lzo,
    version_id character varying(36) ENCODE lzo,
    version bigint ENCODE az64,
    title character varying(768) ENCODE lzo,
    reference_code character varying(50) ENCODE lzo,
    app_status character varying(36) ENCODE lzo,
    user_id character varying(36) ENCODE lzo distkey,
    user_type character varying(36) ENCODE lzo,
    active boolean ENCODE raw,
    type character varying(50) ENCODE lzo,
    subject character varying(36) ENCODE lzo,
    language character varying(50) ENCODE lzo,
    selection_mode character varying(20) ENCODE lzo,
    skill character varying(20) ENCODE lzo,
    framework character varying(30) ENCODE lzo,
    _ingestion_type character varying(10) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_course_resource_activity_outcome_association (
    craoa_dw_id bigint ENCODE az64,
    craoa_created_time timestamp without time zone ENCODE raw,
    craoa_updated_time timestamp without time zone ENCODE az64,
    craoa_dw_created_time timestamp without time zone ENCODE az64,
    craoa_dw_updated_time timestamp without time zone ENCODE az64,
    craoa_status integer ENCODE az64,
    craoa_course_dw_id bigint ENCODE az64,
    craoa_course_id character varying(36) ENCODE lzo,
    craoa_activity_dw_id bigint ENCODE az64,
    craoa_activity_id character varying(36) ENCODE lzo,
    craoa_outcome_id character varying(36) ENCODE lzo,
    craoa_outcome_type character varying(50) ENCODE lzo,
    craoa_curr_id bigint ENCODE az64,
    craoa_curr_grade_id bigint ENCODE az64,
    craoa_curr_subject_id bigint ENCODE az64 distkey
)
DISTSTYLE AUTO
SORTKEY ( craoa_created_time );
CREATE TABLE devcoredw.dim_course_additional_resource_activity_association (
    caraa_dw_id bigint ENCODE az64,
    caraa_course_id character varying(36) ENCODE lzo,
    caraa_resource_activity_id character varying(36) ENCODE lzo,
    caraa_resource_activity_legacy_id character varying(36) ENCODE lzo,
    caraa_resource_activity_type character varying(20) ENCODE lzo,
    caraa_resource_activity_title character varying(100) ENCODE lzo,
    caraa_resource_activity_file_name character varying(100) ENCODE lzo,
    caraa_resource_activity_file_id character varying(50) ENCODE lzo,
    caraa_created_time timestamp without time zone ENCODE az64,
    caraa_updated_time timestamp without time zone ENCODE az64,
    caraa_dw_created_time timestamp without time zone ENCODE az64,
    caraa_dw_updated_time timestamp without time zone ENCODE az64,
    caraa_status integer ENCODE az64,
    caraa_attach_status integer ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_student_learning_path (
    rel_slu_dwid bigint identity(1,1) ENCODE lzo,
    student_dw_id bigint ENCODE lzo,
    lp_uuid character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.fact_pathway_activity_completed (
    fpac_dw_id bigint identity(1,1) ENCODE raw,
    fpac_created_time timestamp without time zone ENCODE az64,
    fpac_dw_created_time timestamp without time zone ENCODE az64,
    fpac_date_dw_id bigint ENCODE az64,
    fpac_tenant_dw_id bigint ENCODE az64,
    fpac_student_dw_id bigint ENCODE az64,
    fpac_class_dw_id bigint ENCODE az64,
    fpac_pathway_dw_id bigint ENCODE az64,
    fpac_level_dw_id bigint ENCODE az64,
    fpac_activity_dw_id bigint ENCODE az64,
    fpac_activity_type integer ENCODE az64,
    fpac_score double precision ENCODE raw,
    fpac_learning_session_id character varying(36) ENCODE lzo,
    fpac_attempt integer ENCODE az64,
    fpac_course_activity_container_dw_id bigint ENCODE az64,
    fpac_course_dw_id bigint ENCODE az64,
    fpac_time_spent integer ENCODE az64,
    fpac_academic_year character varying(50) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( fpac_dw_id );
CREATE TABLE devcoredw.test_table_1 (
    id integer ENCODE az64,
    name character varying(256) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_sublevel (
    sublevel_dw_id bigint identity(1,1) ENCODE raw,
    sublevel_created_time timestamp without time zone ENCODE lzo,
    sublevel_updated_time timestamp without time zone ENCODE lzo,
    sublevel_deleted_time timestamp without time zone ENCODE lzo,
    sublevel_dw_created_time timestamp without time zone ENCODE lzo,
    sublevel_dw_updated_time timestamp without time zone ENCODE lzo,
    sublevel_status integer ENCODE lzo,
    sublevel_id character varying(36) ENCODE lzo,
    sublevel_name character varying(500) ENCODE lzo,
    sublevel_description character varying(500) ENCODE lzo,
    sublevel_substandard_dw_id bigint ENCODE lzo
)
DISTSTYLE ALL
SORTKEY ( sublevel_dw_id );
CREATE TABLE devcoredw.fact_adt_next_question (
    fanq_dw_id bigint identity(1,1) ENCODE az64,
    fanq_created_time timestamp without time zone ENCODE az64,
    fanq_dw_created_time timestamp without time zone ENCODE az64,
    fanq_date_dw_id bigint ENCODE raw,
    fanq_id character varying(36) ENCODE lzo,
    fanq_fle_ls_dw_id character varying(36) ENCODE lzo distkey,
    fanq_student_dw_id character varying(36) ENCODE raw,
    fanq_question_pool_id character varying(36) ENCODE lzo,
    fanq_tenant_dw_id character varying(36) ENCODE lzo,
    fanq_response boolean ENCODE raw,
    fanq_proficiency double precision ENCODE raw,
    fanq_next_question_id character varying(36) ENCODE lzo,
    fanq_time_spent double precision ENCODE raw,
    fanq_current_question_id character varying(36) ENCODE lzo,
    fanq_intest_progress double precision ENCODE raw,
    fanq_status integer ENCODE az64,
    fanq_curriculum_subject_id integer ENCODE az64,
    fanq_curriculum_subject_name character varying(36) ENCODE lzo,
    fanq_fle_ls_uuid character varying(36) ENCODE lzo,
    fanq_language character varying(50) ENCODE lzo,
    fanq_standard_error double precision ENCODE raw,
    fanq_attempt integer ENCODE az64,
    fanq_grade integer ENCODE az64,
    fanq_grade_id character varying(36) ENCODE lzo,
    fanq_grade_dw_id bigint ENCODE az64,
    fanq_academic_year integer ENCODE az64,
    fanq_academic_year_id character varying(36) ENCODE lzo,
    fanq_academic_year_dw_id bigint ENCODE az64,
    fanq_academic_term smallint ENCODE az64,
    fanq_class_subject_name character varying(64) ENCODE lzo,
    fanq_skill character varying(20) ENCODE lzo
)
DISTSTYLE KEY
SORTKEY ( fanq_date_dw_id, fanq_student_dw_id );
CREATE TABLE devcoredw.curio_teacher (
    student_id character varying(36) ENCODE lzo,
    teacher_id character varying(36) ENCODE lzo,
    topic character varying(800) ENCODE lzo,
    created_at timestamp without time zone ENCODE lzo,
    updated_at timestamp without time zone ENCODE lzo,
    date_dw_id bigint ENCODE lzo,
    loadtime timestamp without time zone ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.fact_ebook_progress (
    fep_dw_id bigint ENCODE az64,
    fep_id character varying(36) ENCODE lzo,
    fep_created_time timestamp without time zone ENCODE az64,
    fep_dw_created_time timestamp without time zone ENCODE az64,
    fep_date_dw_id bigint ENCODE az64,
    fep_session_id character varying(36) ENCODE lzo,
    fep_exp_id character varying(36) ENCODE lzo,
    fep_tenant_id character varying(36) ENCODE lzo,
    fep_tenant_dw_id bigint ENCODE az64,
    fep_student_id character varying(36) ENCODE lzo,
    fep_student_dw_id bigint ENCODE az64,
    feb_ay_tag character varying(10) ENCODE lzo,
    fep_school_id character varying(36) ENCODE lzo,
    fep_school_dw_id bigint ENCODE az64,
    fep_grade_id character varying(36) ENCODE lzo,
    fep_grade_dw_id bigint ENCODE az64,
    fep_class_id character varying(36) ENCODE lzo,
    fep_class_dw_id bigint ENCODE az64,
    fep_lo_id character varying(36) ENCODE lzo,
    fep_lo_dw_id bigint ENCODE az64,
    fep_step_instance_step_id character varying(36) ENCODE lzo,
    fep_content_hash character varying(256) ENCODE lzo,
    fep_material_type character varying(20) ENCODE lzo,
    fep_title character varying(512) ENCODE lzo,
    fep_total_pages integer ENCODE az64,
    fep_has_audio boolean ENCODE raw,
    fep_action character varying(50) ENCODE lzo,
    fep_is_last_page boolean ENCODE raw,
    fep_location character varying(100) ENCODE lzo,
    fep_state character varying(50) ENCODE lzo,
    fep_time_spent numeric(18,0) ENCODE az64,
    fep_bookmark_location character varying(255) ENCODE lzo,
    fep_highlight_location character varying(255) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_announcement (
    rel_announcement_dw_id bigint identity(1,1) ENCODE az64,
    announcement_created_time timestamp without time zone ENCODE az64,
    announcement_deleted_time timestamp without time zone ENCODE az64,
    announcement_updated_time timestamp without time zone ENCODE az64,
    announcement_dw_created_time timestamp without time zone ENCODE az64,
    announcement_dw_updated_time timestamp without time zone ENCODE az64,
    announcement_status integer ENCODE az64,
    announcement_tenant_dw_id integer ENCODE az64,
    announcement_id character varying(36) ENCODE lzo,
    announcement_dw_id integer ENCODE az64,
    announcement_admin_dw_id integer ENCODE az64,
    announcement_role_dw_id integer ENCODE az64,
    announcement_recipient_type integer ENCODE az64,
    announcement_recipient_dw_id integer ENCODE az64,
    announcement_has_attachment boolean ENCODE raw
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.fact_inc_game_outcome (
    inc_game_outcome_dw_id bigint identity(1,1) ENCODE lzo,
    inc_game_outcome_id character varying(36) ENCODE lzo,
    inc_game_outcome_created_time timestamp without time zone ENCODE lzo,
    inc_game_outcome_dw_created_time timestamp without time zone ENCODE lzo,
    inc_game_outcome_date_dw_id bigint ENCODE lzo,
    inc_game_outcome_tenant_dw_id bigint ENCODE lzo,
    inc_game_outcome_session_id character varying(36) ENCODE lzo,
    inc_game_outcome_game_id character varying(36) ENCODE lzo,
    inc_game_outcome_player_dw_id bigint ENCODE lzo,
    inc_game_outcome_lo_dw_id bigint ENCODE lzo,
    inc_game_outcome_score double precision ENCODE raw,
    inc_game_outcome_status integer ENCODE lzo,
    inc_game_outcome_is_assessment boolean DEFAULT false ENCODE raw
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.fact_jira_issue (
    fji_dw_id bigint identity(1,1) ENCODE az64,
    fji_resolution character varying(100) ENCODE lzo,
    fji_issue_type character varying(100) ENCODE lzo,
    fji_assignee character varying(50) ENCODE lzo,
    fji_reporter character varying(50) ENCODE lzo,
    fji_priority character varying(20) ENCODE lzo,
    fji_status character varying(100) ENCODE lzo,
    fji_original_estimate bigint ENCODE az64,
    fji_percent_of_spent_time character varying(30) ENCODE lzo,
    fji_labels character varying(255) ENCODE lzo,
    fji_summary character varying(255) ENCODE lzo,
    fji_key character varying(50) ENCODE lzo,
    fji_due_date timestamp without time zone ENCODE az64,
    fji_date_dw_id bigint ENCODE az64,
    fji_created_time timestamp without time zone ENCODE az64,
    fji_dw_created_time timestamp without time zone ENCODE az64,
    fji_issue_created_on timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.fact_assessment_lock_action (
    dw_id bigint ENCODE az64,
    _trace_id character varying(36) ENCODE lzo,
    event_type character varying(36) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    date_dw_id bigint ENCODE az64,
    id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    tenant_dw_id bigint ENCODE az64,
    academic_year_tag character varying(10) ENCODE lzo,
    attempt bigint ENCODE az64,
    teacher_id character varying(36) ENCODE lzo distkey,
    teacher_dw_id bigint ENCODE az64,
    candidate_id character varying(36) ENCODE lzo,
    candidate_dw_id bigint ENCODE az64,
    school_id character varying(36) ENCODE lzo,
    school_dw_id bigint ENCODE az64,
    class_id character varying(36) ENCODE lzo,
    class_dw_id bigint ENCODE az64,
    test_part_session_id character varying(36) ENCODE lzo,
    test_level_name character varying(20) ENCODE lzo,
    test_level_dw_id bigint ENCODE az64,
    test_level_id character varying(36) ENCODE lzo,
    test_level_version bigint ENCODE az64,
    skill character varying(50) ENCODE lzo,
    subject character varying(50) ENCODE lzo,
    _ingestion_type character varying(10) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.fact_target_recommender (
    student_id character varying(256) ENCODE lzo,
    avg_number_of_completions double precision ENCODE raw,
    datetime timestamp without time zone ENCODE az64,
    execution_date timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_ic_lesson_association (
    ic_lesson_dw_id bigint identity(1,1) ENCODE raw,
    ic_lesson_created_time timestamp without time zone ENCODE az64,
    ic_lesson_dw_created_time timestamp without time zone ENCODE az64,
    ic_lesson_updated_time timestamp without time zone ENCODE az64,
    ic_lesson_dw_updated_time timestamp without time zone ENCODE az64,
    ic_lesson_status smallint ENCODE az64,
    ic_lesson_attach_status smallint ENCODE az64,
    ic_lesson_type smallint ENCODE az64,
    ic_lesson_ic_dw_id bigint ENCODE az64,
    ic_lesson_lo_dw_id bigint ENCODE az64
)
DISTSTYLE ALL
SORTKEY ( ic_lesson_dw_id );
CREATE TABLE devcoredw.fact_pathway_placement (
    fpp_dw_id bigint identity(1,1) ENCODE az64 distkey,
    fpp_created_time timestamp without time zone ENCODE raw,
    fpp_dw_created_time timestamp without time zone ENCODE az64,
    fpp_date_dw_id bigint ENCODE az64,
    fpp_previous_pathway_domain character varying(100) ENCODE lzo,
    fpp_pathway_id character varying(36) ENCODE lzo,
    fpp_pathway_dw_id bigint ENCODE az64,
    fpp_new_pathway_domain character varying(100) ENCODE lzo,
    fpp_new_pathway_grade integer ENCODE az64,
    fpp_class_id character varying(36) ENCODE lzo,
    fpp_class_dw_id bigint ENCODE az64,
    fpp_student_id character varying(36) ENCODE lzo,
    fpp_student_dw_id bigint ENCODE az64,
    fpp_previous_pathway_grade integer ENCODE az64,
    fpp_tenant_id character varying(36) ENCODE lzo,
    fpp_tenant_dw_id bigint ENCODE az64,
    fpp_placement_type integer ENCODE az64,
    fpp_overall_grade integer ENCODE az64,
    fpp_created_by character varying(36) ENCODE lzo,
    fpp_created_by_dw_id bigint ENCODE az64,
    fpp_course_dw_id bigint ENCODE az64,
    fpp_is_initial boolean DEFAULT true ENCODE raw,
    fpp_has_accelerated_domains boolean ENCODE raw,
    fpp_academic_year_tag character varying(40) ENCODE lzo
)
DISTSTYLE KEY
SORTKEY ( fpp_created_time );
CREATE TABLE devcoredw.fact_pathway_skill_learning_progress (
    dw_id bigint ENCODE az64,
    event_type character varying(100) ENCODE lzo,
    uuid character varying(36) ENCODE lzo,
    _trace_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    tenant_dw_id bigint ENCODE az64,
    date_dw_id bigint ENCODE az64,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    skill_session_id character varying(36) ENCODE lzo,
    experience_id character varying(36) ENCODE lzo,
    time_spent_on_activity integer ENCODE az64,
    time_spent_this_time_on_activity integer ENCODE az64,
    component_id character varying(36) ENCODE lzo,
    class_id character varying(36) ENCODE lzo,
    class_dw_id bigint ENCODE az64,
    school_id character varying(36) ENCODE lzo,
    school_dw_id bigint ENCODE az64,
    student_id character varying(36) ENCODE lzo distkey,
    student_dw_id bigint ENCODE az64,
    skill_id character varying(36) ENCODE lzo,
    skill_dw_id bigint ENCODE az64,
    material_id character varying(36) ENCODE lzo,
    material_dw_id bigint ENCODE az64,
    academic_year character varying(40) ENCODE lzo,
    skill_completion_percentage double precision ENCODE raw,
    is_activity_completed boolean ENCODE raw,
    _ingestion_type character varying(10) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.fact_tutor_simplification (
    fts_dw_id bigint ENCODE az64,
    fts_created_time timestamp without time zone ENCODE az64,
    fts_dw_created_time timestamp without time zone ENCODE az64,
    fts_date_dw_id bigint ENCODE az64,
    fts_user_id character varying(36) ENCODE lzo,
    fts_user_dw_id bigint ENCODE az64,
    fts_tenant_id character varying(36) ENCODE lzo,
    fts_message_id character varying(36) ENCODE lzo,
    fts_session_id character varying(36) ENCODE lzo,
    fts_conversation_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_school_2023_12_07_backup (
    school_dw_id bigint ENCODE az64,
    school_created_time timestamp without time zone ENCODE az64,
    school_updated_time timestamp without time zone ENCODE az64,
    school_deleted_time timestamp without time zone ENCODE az64,
    school_dw_created_time timestamp without time zone ENCODE az64,
    school_dw_updated_time timestamp without time zone ENCODE az64,
    school_status integer ENCODE az64,
    school_id character varying(36) ENCODE lzo,
    school_name character varying(256) ENCODE lzo,
    school_address_line character varying(255) ENCODE lzo,
    school_post_box character varying(10) ENCODE lzo,
    school_city_name character varying(100) ENCODE lzo,
    school_country_name character varying(100) ENCODE lzo,
    school_latitude numeric(10,6) ENCODE az64,
    school_longitude numeric(10,6) ENCODE az64,
    school_first_day character varying(30) ENCODE lzo,
    school_timezone character varying(64) ENCODE lzo,
    school_composition character varying(64) ENCODE lzo,
    school_tenant_id character varying(36) ENCODE lzo,
    school_alias character varying(256) ENCODE lzo,
    school_source_id character varying(256) ENCODE lzo,
    school_cx_id bigint ENCODE az64,
    school_cx_name_ar character varying(100) ENCODE lzo,
    school_cx_zone character varying(50) ENCODE lzo,
    school_cx_cluster character varying(50) ENCODE lzo,
    school_cx_batch integer ENCODE az64,
    school_cx_status integer ENCODE az64,
    school_cx_report integer ENCODE az64,
    school_cx_last_updated timestamp without time zone ENCODE az64,
    school_content_repository_dw_id bigint ENCODE az64,
    school_organization_dw_id bigint ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_lesson_assignment (
    lesson_assignment_dw_id bigint identity(1,1) ENCODE raw,
    lesson_assignment_created_time timestamp without time zone ENCODE az64,
    lesson_assignment_updated_time timestamp without time zone ENCODE az64,
    lesson_assignment_dw_created_time timestamp without time zone ENCODE az64,
    lesson_assignment_dw_updated_time timestamp without time zone ENCODE az64,
    lesson_assignment_status integer ENCODE az64,
    lesson_assignment_student_dw_id bigint ENCODE az64,
    lesson_assignment_lo_dw_id bigint ENCODE az64,
    lesson_assignment_class_dw_id bigint ENCODE az64,
    lesson_assignment_teacher_dw_id integer ENCODE az64,
    lesson_assignment_assign_status integer ENCODE az64,
    lesson_assignment_type integer ENCODE az64
)
DISTSTYLE AUTO
SORTKEY ( lesson_assignment_dw_id );
CREATE TABLE devcoredw.fact_candidate_assessment_progress (
    dw_id bigint ENCODE az64,
    _trace_id character varying(36) ENCODE lzo,
    event_type character varying(50) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    date_dw_id bigint ENCODE az64,
    tenant_id character varying(36) ENCODE lzo,
    tenant_dw_id bigint ENCODE az64,
    academic_year_tag character varying(9) ENCODE lzo,
    assessment_id character varying(36) ENCODE lzo,
    school_id character varying(36) ENCODE lzo,
    school_dw_id bigint ENCODE az64,
    grade_id character varying(36) ENCODE lzo,
    grade_dw_id bigint ENCODE az64,
    candidate_id character varying(36) ENCODE lzo,
    candidate_dw_id bigint ENCODE az64,
    class_id character varying(36) ENCODE lzo,
    class_dw_id bigint ENCODE az64,
    grade integer ENCODE az64,
    material_type character varying(50) ENCODE lzo,
    attempt_number integer ENCODE az64,
    skill character varying(20) ENCODE lzo,
    subject character varying(50) ENCODE lzo,
    language character varying(20) ENCODE lzo,
    status character varying(20) ENCODE lzo,
    test_level_session_id character varying(36) ENCODE lzo,
    test_level character varying(20) ENCODE lzo,
    test_id character varying(36) ENCODE lzo,
    test_version bigint ENCODE az64,
    test_level_id character varying(36) ENCODE lzo,
    test_level_version bigint ENCODE az64,
    test_level_version_dw_id bigint ENCODE az64,
    test_level_section_id character varying(36) ENCODE lzo distkey,
    report_id character varying(36) ENCODE lzo,
    total_timespent bigint ENCODE az64,
    final_score bigint ENCODE az64,
    final_grade bigint ENCODE az64,
    final_category character varying(20) ENCODE lzo,
    final_uncertainty double precision ENCODE raw,
    time_to_return bigint ENCODE az64,
    framework character varying(20) ENCODE lzo,
    _ingestion_type character varying(10) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_course_grade_association (
    cg_dw_id bigint ENCODE az64,
    cg_course_dw_id bigint ENCODE az64,
    cg_course_id character varying(36) ENCODE lzo,
    cg_grade_id integer ENCODE az64,
    cg_status integer ENCODE az64,
    cg_grade_dw_id bigint ENCODE az64,
    cg_created_time timestamp without time zone ENCODE az64,
    cg_dw_created_time timestamp without time zone ENCODE az64,
    cg_updated_time timestamp without time zone ENCODE az64,
    cg_dw_updated_time timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_question (
    rel_question_dw_id bigint identity(1,1) ENCODE raw,
    question_dw_id bigint ENCODE az64,
    question_created_time timestamp without time zone ENCODE az64,
    question_updated_time timestamp without time zone ENCODE az64,
    question_deleted_time timestamp without time zone ENCODE az64,
    question_dw_created_time timestamp without time zone ENCODE az64,
    question_dw_updated_time timestamp without time zone ENCODE az64,
    question_status integer ENCODE az64,
    question_id character varying(36) ENCODE lzo,
    question_code character varying(50) ENCODE lzo,
    question_triggered_by character varying(50) ENCODE lzo,
    question_language character varying(50) ENCODE lzo,
    question_type character varying(50) ENCODE lzo,
    question_max_score double precision ENCODE raw,
    question_version integer ENCODE az64,
    question_stage character varying(50) ENCODE lzo,
    question_variant character varying(5) ENCODE lzo,
    question_active_until timestamp without time zone ENCODE az64,
    question_format_type character varying(30) ENCODE lzo,
    question_resource_type character varying(10) ENCODE lzo,
    question_summative_assessment boolean ENCODE raw,
    question_difficulty_level character varying(50) ENCODE lzo,
    question_lexile_level character varying(36) ENCODE lzo,
    question_author character varying(70) ENCODE lzo,
    question_authored_date timestamp without time zone ENCODE az64,
    question_skill_id character varying(36) ENCODE lzo,
    question_cefr_level character varying(50) ENCODE lzo,
    question_proficiency character varying(50) ENCODE lzo,
    question_knowledge_dimensions character varying(128) ENCODE lzo
)
DISTSTYLE ALL
SORTKEY ( rel_question_dw_id );
CREATE TABLE devcoredw.dim_samvel_test (
    id integer NOT NULL ENCODE az64,
    number integer NOT NULL ENCODE az64,
    word character varying(256) ENCODE lzo
)
DISTSTYLE EVEN;
CREATE TABLE devcoredw.dim_subject (
    subject_dw_id bigint identity(1,1) ENCODE raw,
    subject_created_time timestamp without time zone ENCODE raw,
    subject_updated_time timestamp without time zone ENCODE raw,
    subject_deleted_time timestamp without time zone ENCODE raw,
    subject_dw_created_time timestamp without time zone ENCODE raw,
    subject_dw_updated_time timestamp without time zone ENCODE raw,
    subject_status integer ENCODE raw,
    subject_id character varying(36) ENCODE raw,
    subject_name character varying(255) ENCODE raw,
    subject_online boolean ENCODE raw,
    subject_gen_subject character varying(255) ENCODE raw,
    grade_id character varying(36) ENCODE lzo
)
DISTSTYLE ALL
SORTKEY ( subject_dw_id );
CREATE TABLE devcoredw.fact_service_desk_request (
    fsdr_dw_id bigint identity(1,1) ENCODE az64 distkey,
    fsdr_dw_created_time timestamp without time zone ENCODE az64,
    fsdr_created_time timestamp without time zone ENCODE raw,
    fsdr_completed_time timestamp without time zone ENCODE az64,
    fsdr_category_name character varying(50) ENCODE lzo,
    fsdr_sub_category character varying(600) ENCODE lzo,
    fsdr_subject character varying(800) ENCODE lzo,
    fsdr_request_status character varying(30) ENCODE lzo,
    fsdr_request_type character varying(30) ENCODE lzo,
    fsdr_request_id bigint ENCODE az64,
    fsdr_item_name character varying(300) ENCODE lzo,
    fsdr_site_name character varying(100) ENCODE lzo,
    fsdr_group_name character varying(50) ENCODE lzo,
    fsdr_technician_name character varying(50) ENCODE lzo,
    fsdr_template_name character varying(100) ENCODE lzo,
    fsdr_closure_code_name character varying(500) ENCODE lzo,
    fsdr_impact_name character varying(50) ENCODE lzo,
    fsdr_resolved_time timestamp without time zone ENCODE az64,
    fsdr_assigned_time timestamp without time zone ENCODE az64,
    fsdr_sla_name character varying(500) ENCODE lzo,
    fsdr_impact_details_name character varying(50) ENCODE lzo,
    fsdr_linked_request_id bigint ENCODE az64,
    fsdr_organization_name character varying(30) ENCODE lzo,
    fsdr_is_escalated boolean ENCODE raw,
    fsdr_priority_name character varying(50) ENCODE lzo,
    fsdr_request_display_id bigint ENCODE az64,
    fsdr_request_mode_name character varying(50) ENCODE lzo,
    fsdr_requester_job_title character varying(200) ENCODE lzo,
    fsdr_date_dw_id bigint ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( fsdr_created_time );
CREATE TABLE devcoredw.dim_award_category (
    award_category_dw_id bigint identity(1,1) ENCODE raw,
    award_category_id character varying(20) ENCODE lzo,
    award_category_level_ar character varying(100) ENCODE lzo,
    award_category_level_en character varying(100) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( award_category_dw_id );
CREATE TABLE devcoredw.backup_dim_class (
    class_dw_id bigint ENCODE az64,
    class_created_time timestamp without time zone ENCODE az64,
    class_updated_time timestamp without time zone ENCODE az64,
    class_deleted_time timestamp without time zone ENCODE az64,
    class_dw_created_time timestamp without time zone ENCODE az64,
    class_dw_updated_time timestamp without time zone ENCODE az64,
    class_status integer ENCODE az64,
    class_id character varying(36) ENCODE lzo,
    class_title character varying(255) ENCODE lzo,
    class_school_id character varying(36) ENCODE lzo,
    class_grade_id character varying(36) ENCODE lzo,
    class_section_id character varying(36) ENCODE lzo,
    class_academic_year_id character varying(36) ENCODE lzo,
    class_gen_subject character varying(255) ENCODE lzo,
    class_curriculum_id bigint ENCODE az64,
    class_curriculum_grade_id bigint ENCODE az64,
    class_curriculum_subject_id bigint ENCODE az64,
    class_content_academic_year integer ENCODE az64,
    class_tutor_dhabi_enabled boolean ENCODE raw,
    class_language_direction character varying(25) ENCODE lzo,
    class_online boolean ENCODE raw,
    class_practice boolean ENCODE raw,
    class_course_status character varying(50) ENCODE lzo,
    class_source_id character varying(255) ENCODE lzo,
    class_curriculum_instructional_plan_id character varying(36) ENCODE lzo,
    class_category_id character varying(36) ENCODE lzo,
    class_active_until timestamp without time zone ENCODE az64
)
DISTSTYLE EVEN;
CREATE TABLE devcoredw.fact_student_activities (
    fsta_dw_id bigint identity(1,1) ENCODE lzo,
    fsta_created_time timestamp without time zone ENCODE lzo,
    fsta_dw_created_time timestamp without time zone ENCODE lzo,
    fsta_actor_object_type character varying(100) ENCODE lzo,
    fsta_actor_account_homepage character varying(100) ENCODE lzo,
    fsta_verb_display character varying(100) ENCODE lzo,
    fsta_verb_id character varying(100) ENCODE lzo,
    fsta_object_id character varying(2000) ENCODE lzo,
    fsta_object_type character varying(100) ENCODE lzo,
    fsta_object_definition_type character varying(100) ENCODE lzo,
    fsta_object_definition_name character varying(2000) ENCODE lzo,
    fsta_from_time numeric(5,0) ENCODE lzo,
    fsta_to_time numeric(5,0) ENCODE lzo,
    fsta_outside_of_school boolean ENCODE raw,
    fsta_event_type character varying(100) ENCODE lzo,
    fsta_prev_event_type character varying(100) ENCODE lzo,
    fsta_next_event_type character varying(100) ENCODE lzo,
    fsta_date_dw_id bigint ENCODE lzo,
    fsta_attempt smallint ENCODE lzo,
    fsta_score_scaled numeric(6,2) ENCODE lzo,
    fsta_score_max numeric(6,2) ENCODE lzo,
    fsta_score_min numeric(6,2) ENCODE lzo,
    fsta_lesson_position smallint ENCODE lzo,
    fsta_exp_id character varying(36) ENCODE lzo,
    fsta_ls_id character varying(36) ENCODE lzo,
    fsta_tenant_dw_id bigint ENCODE raw,
    fsta_school_dw_id bigint ENCODE raw,
    fsta_grade_dw_id bigint ENCODE raw,
    fsta_section_dw_id bigint ENCODE raw,
    fsta_subject_dw_id bigint ENCODE lzo,
    fsta_student_dw_id bigint ENCODE raw,
    fsta_academic_year_dw_id bigint ENCODE raw,
    fsta_timestamp_local character varying(100) ENCODE lzo,
    fsta_start_time timestamp without time zone ENCODE lzo,
    fsta_end_time timestamp without time zone ENCODE lzo,
    fsta_time_spent double precision ENCODE raw,
    fsta_score_raw numeric(7,2) ENCODE az64,
    fsta_is_completion_node boolean ENCODE raw,
    fsta_is_flexible_lesson boolean ENCODE raw,
    fsta_academic_calendar_id character varying(36) ENCODE lzo,
    fsta_teaching_period_id character varying(36) ENCODE lzo,
    fsta_teaching_period_title character varying(50) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( fsta_tenant_dw_id, fsta_school_dw_id, fsta_grade_dw_id, fsta_section_dw_id, fsta_student_dw_id, fsta_academic_year_dw_id );
CREATE TABLE devcoredw.flyway_schema_history (
    installed_rank integer NOT NULL ENCODE raw,
    version character varying(50) ENCODE lzo,
    description character varying(200) NOT NULL ENCODE lzo,
    type character varying(20) NOT NULL ENCODE lzo,
    script character varying(1000) NOT NULL ENCODE lzo,
    checksum integer ENCODE az64,
    installed_by character varying(100) NOT NULL ENCODE lzo,
    installed_on timestamp without time zone NOT NULL DEFAULT getdate() ENCODE az64,
    execution_time integer NOT NULL ENCODE az64,
    success boolean NOT NULL ENCODE raw,
    PRIMARY KEY (installed_rank)
)
DISTSTYLE AUTO
SORTKEY ( installed_rank );
CREATE TABLE devcoredw.dim_step_instance (
    step_instance_dw_id bigint identity(1,1) ENCODE raw,
    step_instance_lo_id character varying(36) ENCODE lzo,
    step_instance_created_time timestamp without time zone ENCODE az64,
    step_instance_updated_time timestamp without time zone ENCODE az64,
    step_instance_dw_created_time timestamp without time zone ENCODE az64,
    step_instance_dw_updated_time timestamp without time zone ENCODE az64,
    step_instance_status integer ENCODE az64,
    step_instance_step_id integer ENCODE az64,
    step_instance_step_uuid character varying(36) ENCODE lzo,
    step_instance_lo_ccl_id bigint ENCODE az64,
    step_instance_id character varying(36) ENCODE lzo,
    step_instance_attach_status integer ENCODE az64,
    step_instance_type integer ENCODE az64,
    step_instance_pool_name character varying(255) ENCODE lzo,
    step_instance_difficulty_level character varying(50) ENCODE lzo,
    step_instance_resource_type character varying(50) ENCODE lzo,
    step_instance_questions integer ENCODE az64,
    step_instance_pool_id character varying(36) ENCODE lzo,
    step_instance_template_uuid character varying(36) ENCODE lzo,
    step_instance_title character varying(255) ENCODE lzo,
    step_instance_media_type character varying(50) ENCODE lzo
)
DISTSTYLE ALL
SORTKEY ( step_instance_dw_id );
CREATE TABLE devcoredw.dim_template (
    template_dw_id bigint identity(1,1) ENCODE raw,
    template_status smallint ENCODE az64,
    template_created_time timestamp without time zone ENCODE az64,
    template_updated_time timestamp without time zone ENCODE az64,
    template_deleted_time timestamp without time zone ENCODE az64,
    template_dw_created_time timestamp without time zone ENCODE az64,
    template_dw_updated_time timestamp without time zone ENCODE az64,
    template_id bigint ENCODE az64,
    template_framework_id bigint ENCODE az64,
    template_title character varying(750) ENCODE lzo,
    template_step_id bigint ENCODE az64,
    template_step_display_name character varying(90) ENCODE lzo,
    template_organisation character varying(50) ENCODE lzo
)
DISTSTYLE ALL
SORTKEY ( template_dw_id );
CREATE TABLE devcoredw.fact_pathway_skill_gap_tracker (
    dw_id bigint ENCODE az64,
    event_type character varying(100) ENCODE lzo,
    _trace_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    tenant_dw_id bigint ENCODE az64,
    date_dw_id bigint ENCODE az64,
    uuid character varying(36) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    student_id character varying(36) ENCODE lzo distkey,
    student_dw_id bigint ENCODE az64,
    class_id character varying(36) ENCODE lzo,
    class_dw_id bigint ENCODE az64,
    school_id character varying(36) ENCODE lzo,
    school_dw_id bigint ENCODE az64,
    pathway_id character varying(36) ENCODE lzo,
    pathway_dw_id bigint ENCODE az64,
    level_id character varying(36) ENCODE lzo,
    level_dw_id bigint ENCODE az64,
    academic_year_tag character varying(40) ENCODE lzo,
    session_id character varying(36) ENCODE lzo,
    ml_session_id character varying(36) ENCODE lzo,
    level_proficiency_score double precision ENCODE raw,
    level_proficiency_tier character varying(50) ENCODE lzo,
    assessment_id character varying(36) ENCODE lzo,
    session_attempt integer ENCODE az64,
    stars integer ENCODE az64,
    time_spent integer ENCODE az64,
    skill_proficiency_tier character varying(40) ENCODE lzo,
    skill_proficiency_score double precision ENCODE raw,
    skill_id character varying(36) ENCODE lzo,
    skill_dw_id bigint ENCODE az64,
    status character varying(50) ENCODE lzo,
    _ingestion_type character varying(10) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_team (
    team_dw_id bigint identity(1,1) ENCODE raw,
    team_created_time timestamp without time zone ENCODE az64,
    team_updated_time timestamp without time zone ENCODE az64,
    team_deleted_time timestamp without time zone ENCODE az64,
    team_dw_created_time timestamp without time zone ENCODE az64,
    team_dw_updated_time timestamp without time zone ENCODE az64,
    team_status integer ENCODE az64,
    team_id character varying(36) ENCODE lzo,
    team_name character varying(36) ENCODE lzo,
    team_class_id character varying(36) ENCODE lzo,
    team_teacher_id character varying(36) ENCODE lzo
)
DISTSTYLE ALL
SORTKEY ( team_dw_id );
CREATE TABLE devcoredw.dim_avatar (
    avatar_dw_id bigint NOT NULL ENCODE az64,
    avatar_id character varying(36) NOT NULL ENCODE lzo distkey,
    avatar_file_id character varying(36) NOT NULL ENCODE lzo,
    avatar_created_time timestamp without time zone ENCODE az64,
    avatar_deleted_time timestamp without time zone ENCODE az64,
    avatar_dw_created_time timestamp without time zone ENCODE az64,
    avatar_updated_time timestamp without time zone ENCODE az64,
    avatar_dw_updated_time timestamp without time zone ENCODE az64,
    avatar_app_status character varying(20) ENCODE lzo,
    avatar_status integer ENCODE az64,
    avatar_type character varying(36) ENCODE lzo,
    avatar_name character varying(256) ENCODE lzo,
    avatar_description character varying(36) ENCODE lzo,
    avatar_valid_from timestamp without time zone ENCODE az64,
    avatar_valid_till timestamp without time zone ENCODE az64,
    avatar_category character varying(20) ENCODE lzo,
    avatar_star_cost integer ENCODE az64,
    avatar_is_enabled_for_all_orgs boolean ENCODE raw
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.be_dim_products (
    row_id integer ENCODE az64,
    product_id character varying(256) ENCODE lzo,
    category character varying(256) ENCODE lzo,
    sub_category character varying(256) ENCODE lzo,
    product_name character varying(256) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.fact_weekly_goal (
    fwg_dw_id bigint identity(1,1) ENCODE az64,
    fwg_created_time timestamp without time zone ENCODE az64,
    fwg_dw_created_time timestamp without time zone ENCODE az64,
    fwg_id character varying(36) ENCODE lzo,
    fwg_action_status integer ENCODE az64,
    fwg_type_dw_id bigint ENCODE az64,
    fwg_student_dw_id bigint ENCODE az64,
    fwg_tenant_dw_id bigint ENCODE az64,
    fwg_class_dw_id bigint ENCODE az64,
    fwg_star_earned integer ENCODE az64,
    fwg_date_dw_id bigint ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_activity_section_association (
    dw_id bigint ENCODE az64,
    event_type character varying(100) ENCODE lzo,
    _trace_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    tenant_dw_id bigint ENCODE az64,
    id character varying(36) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    status smallint ENCODE az64,
    active_until timestamp without time zone ENCODE az64,
    section_id character varying(36) ENCODE lzo,
    section_dw_id bigint ENCODE az64,
    activity_id character varying(36) ENCODE lzo,
    activity_dw_id bigint ENCODE az64 distkey,
    template_component_uuid character varying(36) ENCODE lzo,
    content_id bigint ENCODE az64,
    _ingestion_type character varying(10) ENCODE lzo,
    FOREIGN KEY (tenant_dw_id) REFERENCES devcoredw.dim_tenant(tenant_dw_id),
    FOREIGN KEY (section_dw_id) REFERENCES devcoredw.dim_content_section(dw_id),
    FOREIGN KEY (activity_dw_id) REFERENCES devcoredw.dim_learning_objective(lo_dw_id),
    FOREIGN KEY (content_id) REFERENCES devcoredw.dim_content(content_dw_id)
)
DISTSTYLE KEY;
CREATE TABLE devcoredw.fact_practice_session (
    practice_session_dw_id bigint identity(1,1) ENCODE az64,
    practice_session_start_time timestamp without time zone ENCODE az64,
    practice_session_end_time timestamp without time zone ENCODE az64,
    practice_session_dw_created_time timestamp without time zone ENCODE az64,
    practice_session_date_dw_id integer ENCODE az64 distkey,
    practice_session_id character varying(36) ENCODE lzo,
    practice_session_lo_dw_id bigint ENCODE az64,
    practice_session_student_dw_id bigint ENCODE raw,
    practice_session_subject_dw_id bigint ENCODE az64,
    practice_session_grade_dw_id bigint ENCODE raw,
    practice_session_tenant_dw_id bigint ENCODE az64,
    practice_session_school_dw_id bigint ENCODE raw,
    practice_session_section_dw_id bigint ENCODE az64,
    practice_session_sa_score numeric(10,4) ENCODE az64,
    practice_session_item_lo_dw_id bigint ENCODE az64,
    practice_session_item_content_uuid character varying(36) ENCODE lzo,
    practice_session_item_content_title character varying(100) ENCODE lzo,
    practice_session_item_content_lesson_type character varying(50) ENCODE lzo,
    practice_session_item_content_location character varying(200) ENCODE lzo,
    practice_session_time_spent bigint ENCODE az64,
    practice_session_score numeric(10,4) ENCODE az64,
    practice_session_event_type integer ENCODE az64,
    practice_session_is_start boolean ENCODE raw,
    practice_session_outside_of_school boolean ENCODE raw,
    practice_session_stars integer ENCODE az64,
    practice_academic_year_dw_id bigint ENCODE az64,
    practice_session_instructional_plan_id character varying(36) ENCODE lzo,
    practice_session_learning_path_id character varying(36) ENCODE lzo,
    practice_session_class_dw_id bigint ENCODE raw,
    practice_session_item_step_id character varying(36) ENCODE lzo,
    practice_session_material_id character varying(36) ENCODE lzo,
    practice_session_material_type character varying(20) ENCODE lzo
)
DISTSTYLE KEY
SORTKEY ( practice_session_school_dw_id, practice_session_grade_dw_id, practice_session_class_dw_id, practice_session_student_dw_id );
CREATE TABLE devcoredw.dim_assignment (
    assignment_dw_id bigint identity(1,1) ENCODE az64,
    assignment_created_time timestamp without time zone ENCODE az64,
    assignment_updated_time timestamp without time zone ENCODE az64,
    assignment_deleted_time timestamp without time zone ENCODE az64,
    assignment_dw_created_time timestamp without time zone ENCODE az64,
    assignment_dw_updated_time timestamp without time zone ENCODE az64,
    assignment_id character varying(36) ENCODE lzo,
    assignment_title character varying(100) ENCODE lzo,
    assignment_description character varying(250) ENCODE lzo,
    assignment_max_score numeric(10,4) ENCODE az64,
    assignment_attachment_file_id character varying(100) ENCODE lzo,
    assignment_attachment_file_name character varying(100) ENCODE lzo,
    assignment_attachment_path character varying(200) ENCODE lzo,
    assignment_allow_submission boolean ENCODE raw,
    assignment_language character varying(36) ENCODE lzo,
    assignment_status integer ENCODE az64,
    assignment_is_gradeable boolean ENCODE raw,
    assignment_assignment_status character varying(36) ENCODE lzo,
    assignment_created_by character varying(36) ENCODE lzo,
    assignment_updated_by character varying(36) ENCODE lzo,
    assignment_published_on timestamp without time zone ENCODE az64,
    assignment_attachment_required boolean ENCODE raw,
    assignment_comment_required boolean ENCODE raw,
    assignment_type character varying(36) ENCODE lzo,
    assignment_metadata_author character varying(36) ENCODE lzo,
    assignment_metadata_is_sa boolean ENCODE raw,
    assignment_metadata_authored_date character varying(36) ENCODE lzo,
    assignment_metadata_language character varying(36) ENCODE lzo,
    assignment_metadata_format_type character varying(36) ENCODE lzo,
    assignment_metadata_lexile_level character varying(36) ENCODE lzo,
    assignment_metadata_difficulty_level character varying(36) ENCODE lzo,
    assignment_metadata_resource_type character varying(36) ENCODE lzo,
    assignment_metadata_knowledge_dimensions character varying(36) ENCODE lzo,
    assignment_school_dw_id bigint ENCODE az64,
    assignment_tenant_dw_id bigint ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_course_activity_ip_association (
    dw_id bigint ENCODE az64,
    event_type character varying(100) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    active_until timestamp without time zone ENCODE az64,
    status integer ENCODE az64,
    ip_id character varying(36) ENCODE lzo,
    course_id character varying(36) ENCODE lzo,
    course_dw_id bigint ENCODE az64,
    course_type character varying(255) ENCODE lzo,
    course_version character varying(255) ENCODE lzo,
    course_status character varying(255) ENCODE lzo,
    frame_id character varying(36) ENCODE lzo,
    frame_is_hidden boolean ENCODE raw,
    parent_container_id character varying(36) ENCODE lzo,
    parent_container_title character varying(255) ENCODE lzo,
    activity_id character varying(36) ENCODE lzo,
    activity_dw_id bigint ENCODE az64,
    activity_is_joint_parent_activity boolean ENCODE raw,
    activity_type character varying(255) ENCODE lzo,
    activity_is_hidden boolean ENCODE raw
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_content_academic_year (
    content_academic_year_id integer ENCODE raw,
    content_academic_year_name character varying(20) ENCODE lzo
)
DISTSTYLE ALL
SORTKEY ( content_academic_year_id );
CREATE TABLE devcoredw.dim_event_type (
    event_type_dw_id bigint identity(1,1) ENCODE lzo,
    event_type character varying(100) ENCODE lzo,
    event_type_tag character varying(50) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_teacher_test_blueprint_lesson_association (
    ttbla_dw_id bigint ENCODE az64,
    ttbla_test_blueprint_id character varying(36) ENCODE lzo,
    ttbla_lesson_id character varying(36) ENCODE lzo,
    ttbla_status integer ENCODE az64,
    ttbla_dw_created_time timestamp without time zone ENCODE az64,
    ttbla_created_time timestamp without time zone ENCODE az64,
    ttbla_active_until timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_course_activity_container_domain (
    cacd_dw_id bigint ENCODE az64,
    cacd_container_id character varying(36) ENCODE lzo,
    cacd_container_dw_id bigint ENCODE az64,
    cacd_course_id character varying(36) ENCODE lzo,
    cacd_course_dw_id bigint ENCODE az64,
    cacd_domain character varying(50) ENCODE lzo,
    cacd_sequence integer ENCODE az64,
    cacd_created_time timestamp without time zone ENCODE az64,
    cacd_dw_created_time timestamp without time zone ENCODE az64,
    cacd_updated_time timestamp without time zone ENCODE az64,
    cacd_dw_updated_time timestamp without time zone ENCODE az64,
    cacd_status integer ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_role (
    role_dw_id bigint identity(1,1) ENCODE raw,
    role_id character varying(50) ENCODE lzo,
    role_name character varying(50) ENCODE lzo,
    role_uuid character varying(36) ENCODE lzo,
    role_created_time timestamp without time zone ENCODE az64,
    role_updated_time timestamp without time zone ENCODE az64,
    role_dw_created_time timestamp without time zone ENCODE az64,
    role_dw_updated_time timestamp without time zone ENCODE az64,
    role_organization_name character varying(50) ENCODE lzo,
    role_organization_code character varying(50) ENCODE lzo,
    role_type character varying(50) ENCODE lzo,
    role_category_id character varying(36) ENCODE lzo,
    role_is_ccl boolean ENCODE raw,
    role_status integer ENCODE az64,
    role_description character varying(1536) ENCODE lzo,
    role_predefined boolean ENCODE raw
)
DISTSTYLE ALL
SORTKEY ( role_dw_id );
CREATE TABLE devcoredw.fact_conversation_occurred (
    fco_dw_id bigint identity(1,1) ENCODE lzo,
    fco_created_time timestamp without time zone ENCODE lzo,
    fco_dw_created_time timestamp without time zone ENCODE lzo,
    fco_date_dw_id bigint ENCODE raw,
    fco_id character varying(36) ENCODE lzo,
    fco_student_dw_id bigint ENCODE lzo,
    fco_school_dw_id bigint ENCODE raw,
    fco_tenant_dw_id bigint ENCODE lzo,
    fco_grade_dw_id bigint ENCODE lzo,
    fco_subject_dw_id bigint ENCODE lzo,
    fco_section_dw_id bigint ENCODE lzo,
    fco_lo_dw_id bigint ENCODE lzo,
    fco_answer_id character varying(36) ENCODE lzo,
    fco_source character varying(256) ENCODE lzo,
    fco_question character varying(6138) ENCODE lzo,
    fco_suggestions character varying(15000) ENCODE lzo,
    fco_answer character varying(3000) ENCODE lzo,
    fco_arabic_answer character varying(3000) ENCODE lzo,
    fco_learning_session_id character varying(36) ENCODE lzo,
    fco_subject_category character varying(256) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( fco_school_dw_id, fco_date_dw_id );
CREATE TABLE devcoredw.fact_user_login (
    ful_dw_id bigint identity(1,1) ENCODE lzo,
    ful_created_time timestamp without time zone ENCODE lzo,
    ful_dw_created_time timestamp without time zone ENCODE lzo,
    ful_date_dw_id bigint ENCODE raw,
    ful_id character varying(36) ENCODE lzo,
    ful_user_dw_id bigint ENCODE lzo,
    ful_role_dw_id bigint ENCODE lzo,
    ful_tenant_dw_id bigint ENCODE lzo,
    ful_school_dw_id bigint ENCODE raw,
    ful_outside_of_school boolean ENCODE raw,
    ful_login_time timestamp without time zone ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( ful_school_dw_id, ful_date_dw_id );
CREATE TABLE devcoredw.curio_student (
    student_dw_id bigint ENCODE lzo,
    adek_id character varying(36) ENCODE lzo,
    time_stamp timestamp without time zone ENCODE lzo,
    status character varying(20) ENCODE lzo,
    interaction_type character varying(50) ENCODE lzo,
    topic_name character varying(800) ENCODE lzo,
    subject_id character varying(200) ENCODE lzo,
    role character varying(20) ENCODE lzo,
    date_dw_id bigint ENCODE lzo,
    loadtime timestamp without time zone ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_section (
    section_dw_id bigint identity(1,1) ENCODE raw,
    section_created_time timestamp without time zone ENCODE raw,
    section_updated_time timestamp without time zone ENCODE raw,
    section_deleted_time timestamp without time zone ENCODE raw,
    section_dw_created_time timestamp without time zone ENCODE raw,
    section_dw_updated_time timestamp without time zone ENCODE raw,
    section_status integer ENCODE raw,
    section_id character varying(36) ENCODE raw,
    section_alias character varying(256) ENCODE raw,
    section_name character varying(256) ENCODE raw,
    section_enabled boolean ENCODE raw,
    tenant_id character varying(36) ENCODE lzo,
    grade_id character varying(36) ENCODE lzo,
    school_id character varying(36) ENCODE lzo,
    section_source_id character varying(256) ENCODE lzo,
    UNIQUE (section_dw_id)
)
DISTSTYLE ALL
SORTKEY ( section_dw_id );
CREATE TABLE devcoredw.dim_cx_maturity (
    cx_maturity_dw_id bigint identity(1,1) ENCODE raw,
    cx_maturity_id bigint ENCODE az64,
    cx_maturity_evaluation_id character varying(15) ENCODE lzo,
    cx_maturity_tdc_dw_id bigint ENCODE az64,
    cx_maturity_sch_dw_id bigint ENCODE az64,
    cx_maturity_acc_year_dw_id bigint ENCODE az64 distkey,
    cx_maturity_trimester integer ENCODE az64,
    cx_maturity_submit character varying(5) ENCODE lzo,
    cx_maturity_approved character varying(5) ENCODE lzo,
    cx_maturity_submit_date timestamp without time zone ENCODE az64,
    cx_maturity_principal_factor double precision ENCODE raw,
    cx_maturity_teacher_factor double precision ENCODE raw,
    cx_maturity_student_factor double precision ENCODE raw,
    cx_maturity_parent_factor double precision ENCODE raw,
    cx_maturity_total_avg double precision ENCODE raw,
    cx_maturity_status integer ENCODE az64,
    cx_maturity_created_time timestamp without time zone ENCODE az64,
    cx_maturity_dw_created_time timestamp without time zone ENCODE az64,
    cx_maturity_updated_time timestamp without time zone ENCODE az64,
    cx_maturity_dw_updated_time timestamp without time zone ENCODE az64,
    cx_maturity_deleted_time timestamp without time zone ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( cx_maturity_dw_id );
CREATE TABLE devcoredw.staging_adt_next_question (
    question_pool_uuid character varying(256) ENCODE lzo,
    fanq_time_spent double precision ENCODE raw,
    fanq_proficiency double precision ENCODE raw,
    fanq_response character varying(256) ENCODE lzo,
    fanq_id character varying(256) ENCODE lzo,
    fle_ls_uuid character varying(256) ENCODE lzo,
    fanq_next_question_id character varying(256) ENCODE lzo,
    tenant_uuid character varying(256) ENCODE lzo,
    fanq_see real ENCODE raw,
    student_uuid character varying(256) ENCODE lzo,
    eventdate character varying(256) ENCODE lzo,
    fanq_date_dw_id character varying(256) ENCODE lzo,
    fanq_created_time timestamp without time zone ENCODE az64,
    fanq_dw_created_time timestamp without time zone ENCODE az64
)
DISTSTYLE EVEN;
CREATE TABLE devcoredw.dim_cx_plc_info (
    cx_plc_info_dw_id bigint identity(1,1) ENCODE raw,
    cx_plc_info_id bigint ENCODE az64,
    cx_plc_info_code character varying(10) ENCODE lzo,
    cx_plc_info_term integer ENCODE az64,
    cx_plc_info_acc_year character varying(9) ENCODE lzo,
    cx_plc_info_creation_date timestamp without time zone ENCODE az64,
    cx_plc_info_title character varying(500) ENCODE lzo,
    cx_plc_info_audience integer ENCODE az64,
    cx_plc_info_status integer ENCODE az64,
    cx_plc_info_cx_status integer ENCODE az64,
    cx_plc_info_created_time timestamp without time zone ENCODE az64,
    cx_plc_info_dw_created_time timestamp without time zone ENCODE az64,
    cx_plc_info_updated_time timestamp without time zone ENCODE az64,
    cx_plc_info_dw_updated_time timestamp without time zone ENCODE az64,
    cx_plc_info_deleted_time timestamp without time zone ENCODE az64
)
DISTSTYLE ALL
SORTKEY ( cx_plc_info_dw_id );
CREATE TABLE devcoredw.dim_avatar_layer_customization (
    ala_dw_id bigint NOT NULL ENCODE az64,
    ala_created_time timestamp without time zone NOT NULL ENCODE az64,
    ala_dw_created_time timestamp without time zone NOT NULL ENCODE az64,
    ala_deleted_time timestamp without time zone ENCODE az64,
    ala_updated_time timestamp without time zone ENCODE az64,
    ala_dw_updated_time timestamp without time zone ENCODE az64,
    ala_status integer NOT NULL ENCODE az64,
    ala_avatar_id character varying(36) NOT NULL ENCODE lzo distkey,
    ala_layer_id character varying(36) NOT NULL ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_course_activity_association (
    caa_dw_id bigint ENCODE az64,
    caa_created_time timestamp without time zone ENCODE az64,
    caa_updated_time timestamp without time zone ENCODE az64,
    caa_deleted_time timestamp without time zone ENCODE az64,
    caa_dw_created_time timestamp without time zone ENCODE az64,
    caa_dw_updated_time timestamp without time zone ENCODE az64,
    caa_dw_deleted_time timestamp without time zone ENCODE az64,
    caa_status integer ENCODE az64,
    caa_attach_status integer ENCODE az64,
    caa_course_id character varying(36) ENCODE lzo,
    caa_course_dw_id bigint ENCODE az64,
    caa_container_id character varying(36) ENCODE lzo,
    caa_container_dw_id bigint ENCODE az64,
    caa_activity_id character varying(36) ENCODE lzo,
    caa_activity_dw_id bigint ENCODE az64,
    caa_activity_type integer ENCODE az64,
    caa_activity_pacing character varying(50) ENCODE lzo,
    caa_activity_index integer ENCODE az64,
    caa_course_version character varying(10) ENCODE lzo,
    caa_is_parent_deleted boolean ENCODE raw,
    caa_grade character varying(10) ENCODE lzo,
    caa_activity_is_optional boolean ENCODE raw,
    caa_is_joint_parent_activity boolean ENCODE raw
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.fact_star_awarded (
    fsa_dw_id bigint identity(1,1) ENCODE lzo,
    fsa_created_time timestamp without time zone ENCODE lzo,
    fsa_dw_created_time timestamp without time zone ENCODE lzo,
    fsa_date_dw_id bigint ENCODE raw,
    fsa_id character varying(36) ENCODE lzo,
    fsa_award_category_dw_id bigint ENCODE lzo,
    fsa_student_dw_id bigint ENCODE lzo,
    fsa_tenant_dw_id bigint ENCODE lzo,
    fsa_school_dw_id bigint ENCODE raw,
    fsa_subject_dw_id bigint ENCODE raw,
    fsa_teacher_dw_id bigint ENCODE lzo,
    fsa_grade_dw_id bigint ENCODE lzo,
    fsa_award_comments boolean ENCODE raw,
    fsa_academic_year_dw_id bigint ENCODE lzo,
    fsa_class_dw_id bigint ENCODE az64,
    fsa_stars integer ENCODE az64
)
DISTSTYLE AUTO
SORTKEY ( fsa_school_dw_id, fsa_subject_dw_id, fsa_date_dw_id );
CREATE TABLE devcoredw.fact_ktg_session (
    ktg_session_dw_id bigint identity(1,1) ENCODE raw,
    ktg_session_id character varying(256) ENCODE lzo,
    ktg_session_start_time timestamp without time zone ENCODE lzo,
    ktg_session_end_time timestamp without time zone ENCODE lzo,
    ktg_session_dw_created_time timestamp without time zone ENCODE lzo,
    ktg_session_date_dw_id bigint ENCODE lzo,
    ktg_session_question_id character varying(256) ENCODE lzo,
    ktg_session_kt_id character varying(256) ENCODE lzo,
    ktg_session_tenant_dw_id bigint ENCODE lzo,
    ktg_session_student_dw_id bigint ENCODE raw,
    ktg_session_subject_dw_id bigint ENCODE raw,
    ktg_session_school_dw_id bigint ENCODE raw,
    ktg_session_grade_dw_id bigint ENCODE raw,
    ktg_session_section_dw_id bigint ENCODE raw,
    ktg_session_lo_dw_id bigint ENCODE raw,
    ktg_session_academic_year_dw_id bigint ENCODE raw,
    ktg_session_outside_of_school boolean ENCODE raw,
    ktg_session_trimester_id character varying(256) ENCODE lzo,
    ktg_session_trimester_order smallint ENCODE lzo,
    ktg_session_type character varying(200) ENCODE lzo,
    ktg_session_question_time_allotted integer ENCODE lzo,
    ktg_session_time_spent integer ENCODE lzo,
    ktg_session_answer character varying(5000) ENCODE lzo,
    ktg_session_num_attempts smallint ENCODE lzo,
    ktg_session_score double precision ENCODE raw,
    ktg_session_max_score double precision ENCODE raw,
    ktg_session_stars integer ENCODE lzo,
    ktg_session_is_attended boolean ENCODE raw,
    ktg_session_event_type integer ENCODE lzo,
    ktg_session_is_start boolean ENCODE raw,
    ktg_session_instructional_plan_id character varying(36) ENCODE lzo,
    ktg_session_learning_path_id character varying(36) ENCODE lzo,
    ktg_session_class_dw_id bigint ENCODE az64,
    ktg_session_material_id character varying(36) ENCODE lzo,
    ktg_session_material_type character varying(20) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( ktg_session_dw_id, ktg_session_student_dw_id, ktg_session_subject_dw_id, ktg_session_school_dw_id, ktg_session_grade_dw_id, ktg_session_section_dw_id, ktg_session_lo_dw_id, ktg_session_academic_year_dw_id );
CREATE TABLE devcoredw.fact_user_avatar (
    fua_dw_id bigint ENCODE az64,
    fua_created_time timestamp without time zone ENCODE az64,
    fua_dw_created_time timestamp without time zone ENCODE az64,
    fua_date_dw_id bigint ENCODE az64,
    fua_id character varying(255) ENCODE lzo,
    fua_user_id character varying(36) ENCODE lzo,
    fua_user_dw_id bigint ENCODE az64,
    fua_tenant_id character varying(36) ENCODE lzo,
    fua_tenant_dw_id bigint ENCODE az64,
    fua_school_id character varying(36) ENCODE lzo,
    fua_school_dw_id bigint ENCODE az64,
    fua_grade_id character varying(36) ENCODE lzo,
    fua_grade_dw_id bigint ENCODE az64,
    fua_avatar_type character varying(36) ENCODE lzo,
    fua_avatar_file_id character varying(36) ENCODE lzo,
    fua_avatar_dw_id bigint ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.fact_pathway_target_progress (
    fptp_dw_id bigint ENCODE az64,
    fptp_id character varying(36) ENCODE lzo,
    fptp_created_time timestamp without time zone ENCODE az64,
    fptp_dw_created_time timestamp without time zone ENCODE az64,
    fptp_date_dw_id bigint ENCODE az64,
    fptp_student_target_id character varying(36) ENCODE lzo,
    fptp_target_id character varying(36) ENCODE lzo,
    fptp_target_dw_id bigint ENCODE az64,
    fptp_student_id character varying(36) ENCODE lzo distkey,
    fptp_student_dw_id bigint ENCODE az64,
    fptp_tenant_id character varying(36) ENCODE lzo,
    fptp_tenant_dw_id bigint ENCODE az64,
    fptp_school_id character varying(36) ENCODE lzo,
    fptp_school_dw_id bigint ENCODE az64,
    fptp_grade_id character varying(36) ENCODE lzo,
    fptp_grade_dw_id bigint ENCODE az64,
    fptp_class_id character varying(36) ENCODE lzo,
    fptp_class_dw_id bigint ENCODE az64,
    fptp_teacher_id character varying(36) ENCODE lzo,
    fptp_teacher_dw_id bigint ENCODE az64,
    fptp_pathway_id character varying(36) ENCODE lzo,
    fptp_pathway_dw_id bigint ENCODE az64,
    fptp_target_state character varying(20) ENCODE lzo,
    fptp_recommended_target_level integer ENCODE az64,
    fptp_finalized_target_level integer ENCODE az64,
    fptp_levels_completed integer ENCODE az64,
    fptp_earned_stars integer ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_course_content_repository_association (
    ccr_dw_id bigint ENCODE az64,
    ccr_course_dw_id bigint ENCODE az64,
    ccr_course_id character varying(36) ENCODE lzo,
    ccr_repository_dw_id bigint ENCODE az64,
    ccr_repository_id character varying(36) ENCODE lzo,
    ccr_status integer ENCODE az64,
    ccr_created_time timestamp without time zone ENCODE az64,
    ccr_updated_time timestamp without time zone ENCODE az64,
    ccr_deleted_time timestamp without time zone ENCODE az64,
    ccr_dw_created_time timestamp without time zone ENCODE az64,
    ccr_dw_updated_time timestamp without time zone ENCODE az64,
    ccr_course_type character varying(50) ENCODE lzo,
    ccr_attach_status integer ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_learning_path_detail (
    lpd_dwid bigint identity(1,1) ENCODE lzo,
    lpd_id character varying(36) ENCODE lzo,
    lo_dwid bigint ENCODE lzo,
    lo_order integer ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.fact_tutor_analogous (
    fta_dw_id bigint ENCODE az64,
    fta_created_time timestamp without time zone ENCODE az64,
    fta_dw_created_time timestamp without time zone ENCODE az64,
    fta_date_dw_id bigint ENCODE az64,
    fta_user_id character varying(36) ENCODE lzo,
    fta_user_dw_id bigint ENCODE az64,
    fta_tenant_id character varying(36) ENCODE lzo,
    fta_message_id character varying(36) ENCODE lzo,
    fta_session_id character varying(36) ENCODE lzo,
    fta_conversation_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.fact_cx_observation_indicator (
    fcoi_dw_id bigint identity(1,1) ENCODE raw,
    fcoi_id bigint ENCODE az64,
    fcoi_observation_dw_id bigint ENCODE az64,
    fcoi_indicator_id bigint ENCODE az64 distkey,
    fcoi_indicator_value double precision ENCODE raw,
    fcoi_coaching_time timestamp without time zone ENCODE az64,
    fcoi_created_time timestamp without time zone ENCODE az64,
    fcoi_dw_created_time timestamp without time zone ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( fcoi_dw_id );
CREATE TABLE devcoredw.dim_ccl_skill (
    ccl_skill_dw_id bigint identity(1,1) ENCODE raw,
    ccl_skill_created_time timestamp without time zone ENCODE az64,
    ccl_skill_updated_time timestamp without time zone ENCODE az64,
    ccl_skill_deleted_time timestamp without time zone ENCODE az64,
    ccl_skill_dw_created_time timestamp without time zone ENCODE az64,
    ccl_skill_dw_updated_time timestamp without time zone ENCODE az64,
    ccl_skill_status integer ENCODE az64,
    ccl_skill_id character varying(36) ENCODE lzo,
    ccl_skill_name character varying(750) ENCODE lzo,
    ccl_skill_code character varying(150) ENCODE lzo,
    ccl_skill_description character varying(750) ENCODE lzo,
    ccl_skill_subject_id bigint ENCODE az64
)
DISTSTYLE ALL
SORTKEY ( ccl_skill_dw_id );
CREATE TABLE devcoredw.ic_id_mapping (
    ic_id_in_table integer ENCODE az64,
    ic_to_update integer ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.fact_adt_student_report (
    fasr_dw_id bigint identity(1,1) ENCODE az64 distkey,
    fasr_created_time timestamp without time zone ENCODE az64,
    fasr_dw_created_time timestamp without time zone ENCODE az64,
    fasr_date_dw_id bigint ENCODE raw,
    fasr_tenant_dw_id bigint ENCODE raw,
    fasr_student_dw_id bigint ENCODE raw,
    fasr_question_pool_id character varying(256) ENCODE lzo,
    fasr_fle_ls_dw_id bigint ENCODE az64,
    fasr_id character varying(36) ENCODE lzo,
    fasr_final_score double precision ENCODE raw,
    fasr_final_proficiency double precision ENCODE raw,
    fasr_final_result character varying(20) ENCODE lzo,
    fasr_total_time_spent double precision ENCODE raw,
    fasr_academic_year integer ENCODE az64,
    fasr_academic_term integer ENCODE az64,
    fasr_test_id character varying(36) ENCODE lzo,
    fasr_curriculum_subject_id bigint ENCODE az64,
    fasr_curriculum_subject_name character varying(255) ENCODE lzo,
    fasr_status integer ENCODE az64,
    fasr_final_uncertainty double precision ENCODE raw,
    fasr_framework character varying(36) ENCODE lzo,
    fasr_fle_ls_uuid character varying(36) ENCODE lzo,
    fasr_final_standard_error double precision ENCODE raw,
    fasr_language character varying(50) ENCODE lzo,
    fasr_school_dw_id bigint ENCODE az64,
    fasr_attempt integer ENCODE az64,
    fasr_final_grade integer ENCODE az64,
    fasr_forecast_score double precision ENCODE raw,
    fasr_final_category character varying(50) ENCODE lzo,
    fasr_grade integer ENCODE az64,
    fasr_grade_id character varying(36) ENCODE lzo,
    fasr_grade_dw_id bigint ENCODE az64,
    fasr_academic_year_id character varying(36) ENCODE lzo,
    fasr_academic_year_dw_id bigint ENCODE az64,
    fasr_secondary_result character varying(50) ENCODE lzo,
    fasr_class_subject_name character varying(64) ENCODE lzo,
    fasr_skill character varying(20) ENCODE lzo
)
DISTSTYLE KEY
SORTKEY ( fasr_date_dw_id, fasr_tenant_dw_id, fasr_student_dw_id );
CREATE TABLE devcoredw.dim_guardian (
    rel_guardian_dw_id bigint ENCODE az64,
    guardian_created_time timestamp without time zone ENCODE az64,
    guardian_updated_time timestamp without time zone ENCODE az64,
    guardian_deleted_time timestamp without time zone ENCODE az64,
    guardian_dw_created_time timestamp without time zone ENCODE az64,
    guardian_dw_updated_time timestamp without time zone ENCODE az64,
    guardian_active_until timestamp without time zone ENCODE az64,
    guardian_status integer ENCODE az64,
    guardian_id character varying(36) ENCODE lzo,
    guardian_dw_id bigint ENCODE az64,
    guardian_student_dw_id bigint ENCODE raw distkey,
    guardian_invitation_status integer ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( guardian_student_dw_id );
CREATE TABLE devcoredw.staging_student_slide_progress (
    dw_id bigint ENCODE az64,
    event_type character varying(100) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    _trace_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    experience_id character varying(36) ENCODE lzo,
    learning_session_id character varying(36) ENCODE lzo,
    content_section_id character varying(36) ENCODE lzo,
    slide_id character varying(36) ENCODE lzo,
    widget_id character varying(50) ENCODE lzo,
    status character varying(20) ENCODE lzo,
    active_time integer ENCODE az64,
    idle_time integer ENCODE az64,
    total_time_spent integer ENCODE az64,
    result character varying(20) ENCODE lzo,
    attempt integer ENCODE az64,
    student_id character varying(36) ENCODE lzo,
    school_id character varying(36) ENCODE lzo,
    grade_id character varying(36) ENCODE lzo,
    student_section_id character varying(36) ENCODE lzo,
    class_id character varying(36) ENCODE lzo,
    activity_id character varying(36) ENCODE lzo,
    academic_year_tag character varying(20) ENCODE lzo,
    material_id character varying(36) ENCODE lzo,
    material_type character varying(20) ENCODE lzo,
    ccl_content_id bigint ENCODE az64,
    channel character varying(50) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.test_table_2 (
    id integer ENCODE az64,
    name character varying(256) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.fact_teacher_activities (
    fta_dw_id bigint identity(1,1) ENCODE lzo,
    fta_created_time timestamp without time zone ENCODE lzo,
    fta_dw_created_time timestamp without time zone ENCODE lzo,
    fta_actor_object_type character varying(100) ENCODE lzo,
    fta_actor_account_homepage character varying(100) ENCODE lzo,
    fta_verb_id character varying(100) ENCODE lzo,
    fta_verb_display character varying(100) ENCODE lzo,
    fta_object_id character varying(2000) ENCODE lzo,
    fta_object_type character varying(100) ENCODE lzo,
    fta_object_definition_type character varying(100) ENCODE lzo,
    fta_object_definition_name character varying(2000) ENCODE lzo,
    fta_context_category character varying(100) ENCODE lzo,
    fta_outside_of_school boolean ENCODE raw,
    fta_event_type character varying(100) ENCODE lzo,
    fta_prev_event_type character varying(100) ENCODE lzo,
    fta_next_event_type character varying(100) ENCODE lzo,
    fta_date_dw_id bigint ENCODE lzo,
    fta_tenant_dw_id bigint ENCODE raw,
    fta_school_dw_id bigint ENCODE raw,
    fta_grade_dw_id bigint ENCODE raw,
    fta_section_dw_id bigint ENCODE raw,
    fta_subject_dw_id bigint ENCODE lzo,
    fta_teacher_dw_id bigint ENCODE raw,
    fta_start_time timestamp without time zone ENCODE lzo,
    fta_end_time timestamp without time zone ENCODE lzo,
    fta_timestamp_local character varying(100) ENCODE lzo,
    fta_time_spent double precision ENCODE raw
)
DISTSTYLE AUTO
SORTKEY ( fta_tenant_dw_id, fta_school_dw_id, fta_grade_dw_id, fta_section_dw_id, fta_teacher_dw_id );
CREATE TABLE devcoredw.fact_student_certificate_awarded (
    fsca_dw_id bigint identity(1,1) ENCODE az64 distkey,
    fsca_created_time timestamp without time zone ENCODE raw,
    fsca_dw_created_time timestamp without time zone ENCODE az64,
    fsca_date_dw_id bigint ENCODE az64,
    fsca_certificate_id character varying(36) ENCODE lzo,
    fsca_student_dw_id bigint ENCODE az64,
    fsca_award_category character varying(50) ENCODE lzo,
    fsca_award_purpose character varying(100) ENCODE lzo,
    fsca_academic_year_dw_id bigint ENCODE az64,
    fsca_class_dw_id bigint ENCODE az64,
    fsca_grade_dw_id bigint ENCODE az64,
    fsca_teacher_dw_id bigint ENCODE az64,
    fsca_language character varying(36) ENCODE lzo,
    fsca_tenant_dw_id bigint ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( fsca_created_time );
CREATE TABLE devcoredw.fact_student_queries (
    dw_id bigint ENCODE az64,
    created_time timestamp without time zone ENCODE raw,
    dw_created_time timestamp without time zone ENCODE az64,
    date_dw_id bigint ENCODE az64,
    _trace_id character varying(36) ENCODE lzo,
    event_type character varying(36) ENCODE lzo,
    message_id character varying(36) ENCODE lzo,
    query_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    tenant_dw_id bigint ENCODE az64,
    school_id character varying(36) ENCODE lzo,
    school_dw_id bigint ENCODE az64,
    grade_id character varying(36) ENCODE lzo,
    grade_dw_id bigint ENCODE az64,
    class_id character varying(36) ENCODE lzo,
    class_dw_id bigint ENCODE az64,
    section_id character varying(36) ENCODE lzo,
    section_dw_id bigint ENCODE az64,
    teacher_id character varying(36) ENCODE lzo,
    teacher_dw_id bigint ENCODE az64,
    academic_year_id character varying(36) ENCODE lzo,
    academic_year_dw_id bigint ENCODE az64,
    student_id character varying(36) ENCODE lzo distkey,
    student_dw_id bigint ENCODE az64,
    activity_id character varying(36) ENCODE lzo,
    activity_dw_id bigint ENCODE az64,
    activity_type character varying(100) ENCODE lzo,
    can_student_reply boolean ENCODE raw,
    with_audio boolean ENCODE raw,
    with_text boolean ENCODE raw,
    material_type character varying(100) ENCODE lzo,
    gen_subject character varying(100) ENCODE lzo,
    lang_code character varying(100) ENCODE lzo,
    is_follow_up boolean ENCODE raw,
    has_screenshot boolean ENCODE raw,
    _ingestion_type character varying(10) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( created_time );
CREATE TABLE devcoredw.dim_content_repository_new (
    content_repository_dw_id bigint ENCODE az64,
    content_repository_id character varying(36) ENCODE lzo,
    content_repository_name character varying(50) ENCODE lzo,
    content_repository_organisation_owner character varying(30) ENCODE lzo,
    content_repository_created_by_id character varying(36) ENCODE lzo,
    content_repository_updated_by_id character varying(36) ENCODE lzo,
    content_repository_status integer ENCODE az64,
    content_repository_created_time timestamp without time zone ENCODE az64,
    content_repository_dw_created_time timestamp without time zone ENCODE az64,
    content_repository_updated_time timestamp without time zone ENCODE az64,
    content_repository_dw_updated_time timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_teacher_test_blueprint (
    ttb_dw_id bigint ENCODE az64,
    ttb_created_time timestamp without time zone ENCODE raw,
    ttb_updated_time timestamp without time zone ENCODE az64,
    ttb_deleted_time timestamp without time zone ENCODE az64,
    ttb_dw_created_time timestamp without time zone ENCODE az64,
    ttb_dw_updated_time timestamp without time zone ENCODE az64,
    ttb_dw_deleted_time timestamp without time zone ENCODE az64,
    ttb_test_blueprint_id character varying(36) ENCODE raw,
    ttb_tenant_id character varying(36) ENCODE lzo,
    ttb_test_blueprint_class_id character varying(36) ENCODE lzo,
    ttb_test_blueprint_title character varying(255) ENCODE lzo,
    ttb_test_blueprint_domain_id character varying(36) ENCODE lzo,
    ttb_test_blueprint_guidance_type character varying(255) ENCODE lzo,
    ttb_test_blueprint_major_version integer ENCODE az64,
    ttb_test_blueprint_minor_version integer ENCODE az64,
    ttb_test_blueprint_revision_version integer ENCODE az64,
    ttb_test_blueprint_number_of_question integer ENCODE az64,
    ttb_test_blueprint_created_by_id character varying(36) ENCODE lzo,
    ttb_test_blueprint_updated_by_id character varying(36) ENCODE lzo,
    ttb_test_blueprint_published_by_id character varying(36) ENCODE lzo,
    ttb_test_blueprint_status character varying(40) ENCODE lzo,
    ttb_status integer ENCODE az64
)
DISTSTYLE AUTO
SORTKEY ( ttb_test_blueprint_id );
CREATE TABLE devcoredw.fact_student_proficiency_tracker (
    dw_id bigint ENCODE az64,
    event_type character varying(100) ENCODE lzo,
    _trace_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    tenant_dw_id bigint ENCODE az64,
    date_dw_id bigint ENCODE az64,
    uuid character varying(36) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    student_id character varying(36) ENCODE lzo distkey,
    student_dw_id bigint ENCODE az64,
    class_id character varying(36) ENCODE lzo,
    class_dw_id bigint ENCODE az64,
    school_id character varying(36) ENCODE lzo,
    school_dw_id bigint ENCODE az64,
    pathway_id character varying(36) ENCODE lzo,
    pathway_dw_id bigint ENCODE az64,
    level_id character varying(36) ENCODE lzo,
    level_dw_id bigint ENCODE az64,
    academic_year_tag character varying(40) ENCODE lzo,
    session_id character varying(36) ENCODE lzo,
    ml_session_id character varying(36) ENCODE lzo,
    level_proficiency_score double precision ENCODE raw,
    level_proficiency_tier character varying(50) ENCODE lzo,
    assessment_id character varying(36) ENCODE lzo,
    session_attempt integer ENCODE az64,
    stars integer ENCODE az64,
    time_spent integer ENCODE az64,
    skill_proficiency_tier character varying(40) ENCODE lzo,
    skill_proficiency_score double precision ENCODE raw,
    skill_id character varying(36) ENCODE lzo,
    skill_dw_id bigint ENCODE az64,
    status character varying(50) ENCODE lzo,
    previous_proficiency_tier character varying(50) ENCODE lzo,
    _ingestion_type character varying(10) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw.dim_organization (
    organization_dw_id bigint identity(1,1) ENCODE raw,
    organization_created_time timestamp without time zone ENCODE az64,
    organization_deleted_time timestamp without time zone ENCODE az64,
    organization_updated_time timestamp without time zone ENCODE az64,
    organization_dw_created_time timestamp without time zone ENCODE az64,
    organization_dw_updated_time timestamp without time zone ENCODE az64,
    organization_dw_deleted_time timestamp without time zone ENCODE az64,
    organization_id character varying(36) ENCODE lzo,
    organization_name character varying(50) ENCODE lzo,
    organization_code character varying(50) ENCODE lzo,
    organization_country character varying(20) ENCODE lzo,
    organization_tenant_code character varying(20) ENCODE lzo,
    organization_status integer ENCODE az64,
    organization_created_by character varying(36) ENCODE lzo,
    organization_updated_by character varying(36) ENCODE lzo
)
DISTSTYLE ALL
SORTKEY ( organization_dw_id );
CREATE TABLE devcoredw_stage.staging_teacher_test_candidate_progress (
    fttcp_dw_id bigint ENCODE az64,
    fttcp_session_id character varying(36) ENCODE lzo,
    fttcp_candidate_id character varying(36) ENCODE lzo,
    fttcp_test_delivery_id character varying(36) ENCODE lzo,
    fttcp_assessment_id character varying(36) ENCODE lzo,
    fttcp_score double precision ENCODE raw,
    fttcp_stars_awarded integer ENCODE az64,
    fttcp_status character varying(50) ENCODE lzo,
    fttcp_updated_at timestamp without time zone ENCODE az64,
    fttcp_created_at timestamp without time zone ENCODE az64,
    fttcp_date_dw_id bigint ENCODE az64,
    fttcp_created_time timestamp without time zone ENCODE az64,
    fttcp_dw_created_time timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.try_date_char (
    date_diff character varying(1000) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_content_slide (
    dw_id bigint NOT NULL ENCODE raw distkey,
    event_type character varying(100) ENCODE lzo,
    _trace_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    id character varying(36) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    status smallint ENCODE az64,
    active_until character varying(36) ENCODE lzo,
    section_id character varying(36) ENCODE lzo,
    source_id character varying(36) ENCODE lzo,
    sequence smallint ENCODE az64,
    show_progressbar boolean ENCODE raw,
    disable_primary_button boolean ENCODE raw,
    is_default_disabled boolean ENCODE raw,
    is_last_slide boolean ENCODE raw,
    widget_id character varying(50) ENCODE lzo,
    widget_type character varying(50) ENCODE lzo,
    widget_sub_type character varying(50) ENCODE lzo,
    widget_version character varying(5) ENCODE lzo,
    widget_title character varying(750) ENCODE lzo,
    widget_subtitle character varying(1200) ENCODE lzo,
    widget_has_passage boolean ENCODE raw,
    widget_video boolean ENCODE raw,
    widget_audio boolean ENCODE raw,
    widget_need_help boolean ENCODE raw,
    widget_submit_limit integer ENCODE az64,
    widget_shuffled boolean ENCODE raw,
    widget_feedback boolean ENCODE raw,
    widget_multiple_answer boolean ENCODE raw,
    _ingestion_type character varying(10) ENCODE lzo,
    PRIMARY KEY (dw_id)
)
DISTSTYLE AUTO
SORTKEY ( dw_id );
CREATE TABLE devcoredw_stage.rel_course_resource_activity_outcome_association (
    craoa_dw_id bigint ENCODE az64,
    craoa_created_time timestamp without time zone ENCODE raw,
    craoa_updated_time timestamp without time zone ENCODE az64,
    craoa_dw_created_time timestamp without time zone ENCODE az64,
    craoa_dw_updated_time timestamp without time zone ENCODE az64,
    craoa_status integer ENCODE az64,
    craoa_course_id character varying(36) ENCODE lzo,
    craoa_activity_id character varying(36) ENCODE lzo,
    craoa_outcome_id character varying(36) ENCODE lzo,
    craoa_outcome_type character varying(50) ENCODE lzo,
    craoa_curr_id bigint ENCODE az64,
    craoa_curr_grade_id bigint ENCODE az64,
    craoa_curr_subject_id bigint ENCODE az64 distkey
)
DISTSTYLE AUTO
SORTKEY ( craoa_created_time );
CREATE TABLE devcoredw_stage.rel_ic_lesson_association (
    rel_ic_lesson_id bigint identity(1,1) ENCODE az64,
    ic_lesson_created_time timestamp without time zone ENCODE az64,
    ic_lesson_dw_created_time timestamp without time zone ENCODE az64,
    ic_lesson_updated_time timestamp without time zone ENCODE az64,
    ic_lesson_dw_updated_time timestamp without time zone ENCODE az64,
    ic_lesson_status smallint ENCODE az64,
    ic_lesson_attach_status smallint ENCODE az64,
    ic_lesson_type smallint ENCODE az64,
    ic_uuid character varying(36) ENCODE lzo,
    lo_uuid character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_principal (
    rel_principal_id bigint identity(1,1) ENCODE lzo,
    principal_created_time timestamp without time zone ENCODE lzo,
    principal_updated_time timestamp without time zone ENCODE lzo,
    principal_deleted_time timestamp without time zone ENCODE lzo,
    principal_dw_created_time timestamp without time zone ENCODE lzo,
    principal_dw_updated_time timestamp without time zone ENCODE lzo,
    principal_active_until timestamp without time zone ENCODE lzo,
    principal_status integer ENCODE lzo,
    principal_uuid character varying(36) ENCODE raw,
    principal_onboarded boolean ENCODE raw,
    school_uuid character varying(36) ENCODE lzo,
    principal_expirable boolean ENCODE raw
)
DISTSTYLE AUTO
SORTKEY ( principal_uuid );
CREATE TABLE devcoredw_stage.staging_pathway_leaderboard (
    fpl_staging_id bigint identity(1,1) ENCODE raw distkey,
    fpl_created_time timestamp without time zone ENCODE az64,
    fpl_dw_created_time timestamp without time zone ENCODE az64,
    fpl_date_dw_id bigint ENCODE az64,
    fpl_id character varying(36) ENCODE lzo,
    fpl_student_id character varying(36) ENCODE lzo,
    fpl_pathway_id character varying(36) ENCODE lzo,
    fpl_class_id character varying(36) ENCODE lzo,
    fpl_grade_id character varying(36) ENCODE lzo,
    fpl_academic_year_id character varying(36) ENCODE lzo,
    fpl_start_date date ENCODE az64,
    fpl_end_date date ENCODE az64,
    fpl_order smallint ENCODE az64,
    fpl_level_competed_count smallint ENCODE az64,
    fpl_average_score double precision ENCODE raw,
    fpl_total_stars smallint ENCODE az64,
    fpl_tenant_id character varying(36) ENCODE lzo,
    fpl_average_proficiency_score double precision ENCODE raw
)
DISTSTYLE AUTO
SORTKEY ( fpl_staging_id );
CREATE TABLE devcoredw_stage.staging_student_queries (
    dw_id bigint ENCODE az64,
    created_time timestamp without time zone ENCODE raw,
    dw_created_time timestamp without time zone ENCODE az64,
    date_dw_id bigint ENCODE az64,
    _trace_id character varying(36) ENCODE lzo,
    event_type character varying(36) ENCODE lzo,
    message_id character varying(36) ENCODE lzo,
    query_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    school_id character varying(36) ENCODE lzo,
    grade_id character varying(36) ENCODE lzo,
    class_id character varying(36) ENCODE lzo,
    section_id character varying(36) ENCODE lzo,
    teacher_id character varying(36) ENCODE lzo,
    academic_year_id character varying(36) ENCODE lzo,
    student_id character varying(36) ENCODE lzo distkey,
    mlo_id character varying(36) ENCODE lzo,
    activity_id character varying(36) ENCODE lzo,
    activity_type character varying(100) ENCODE lzo,
    can_student_reply boolean ENCODE raw,
    with_audio boolean ENCODE raw,
    with_text boolean ENCODE raw,
    material_type character varying(100) ENCODE lzo,
    gen_subject character varying(100) ENCODE lzo,
    lang_code character varying(100) ENCODE lzo,
    is_follow_up boolean ENCODE raw,
    has_screenshot boolean ENCODE raw,
    _ingestion_type character varying(10) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( created_time );
CREATE TABLE devcoredw_stage.staging_guardian_app_activities (
    fgaa_staging_id bigint identity(1,1) ENCODE lzo,
    fgaa_created_time timestamp without time zone ENCODE lzo,
    fgaa_actor_object_type character varying(100) ENCODE lzo,
    fgaa_actor_account_homepage character varying(100) ENCODE lzo,
    fgaa_verb_display character varying(100) ENCODE lzo,
    fgaa_verb_id character varying(100) ENCODE lzo,
    fgaa_object_id character varying(2000) ENCODE lzo,
    fgaa_object_type character varying(100) ENCODE lzo,
    fgaa_object_account_homepage character varying(100) ENCODE lzo,
    fgaa_dw_created_time timestamp without time zone ENCODE lzo,
    fgaa_event_type character varying(100) ENCODE lzo,
    fgaa_date_dw_id bigint ENCODE lzo,
    fgaa_device character varying(100) ENCODE lzo,
    tenant_uuid character varying(36) ENCODE lzo,
    guardian_uuid character varying(36) ENCODE lzo,
    student_uuid character varying(36) ENCODE lzo,
    school_uuid character varying(36) ENCODE lzo,
    fgaa_timestamp_local character varying(100) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_skill_content_unavailable (
    scu_staging_id bigint identity(1,1) ENCODE lzo,
    scu_created_time timestamp without time zone ENCODE lzo,
    scu_dw_created_time timestamp without time zone ENCODE lzo,
    scu_date_dw_id bigint ENCODE lzo,
    tenant_uuid character varying(36) ENCODE lzo,
    lo_uuid character varying(36) ENCODE lzo,
    skill_uuid character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_section_schedule (
    rel_section_schedule_id bigint identity(1,1) ENCODE lzo,
    section_schedule_day_of_week character varying(10) ENCODE lzo,
    section_schedule_start_time character varying(20) ENCODE lzo,
    section_schedule_end_time character varying(20) ENCODE lzo,
    section_schedule_created_time timestamp without time zone ENCODE lzo,
    section_schedule_updated_time timestamp without time zone ENCODE lzo,
    section_schedule_deleted_time timestamp without time zone ENCODE lzo,
    section_schedule_dw_created_time timestamp without time zone ENCODE lzo,
    section_schedule_dw_updated_time timestamp without time zone ENCODE lzo,
    section_schedule_active_until timestamp without time zone ENCODE lzo,
    section_schedule_status integer ENCODE lzo,
    section_uuid character varying(36) ENCODE lzo,
    tenant_uuid character varying(36) ENCODE lzo,
    subject_uuid character varying(36) ENCODE lzo,
    teacher_uuid character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_teacher_task_center (
    dw_id bigint ENCODE az64,
    created_time timestamp without time zone ENCODE raw,
    dw_created_time timestamp without time zone ENCODE az64,
    date_dw_id bigint ENCODE az64,
    _trace_id character varying(36) ENCODE lzo,
    event_type character varying(36) ENCODE lzo,
    event_id character varying(36) ENCODE lzo,
    task_id character varying(36) ENCODE lzo,
    task_type character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    school_id character varying(36) ENCODE lzo,
    class_id character varying(36) ENCODE lzo,
    teacher_id character varying(36) ENCODE lzo distkey,
    _ingestion_type character varying(10) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( created_time );
CREATE TABLE devcoredw_stage.staging_weekly_goal (
    fwg_dw_id bigint identity(1,1) ENCODE az64,
    fwg_created_time timestamp without time zone ENCODE az64,
    fwg_dw_created_time timestamp without time zone ENCODE az64,
    fwg_id character varying(36) ENCODE lzo,
    fwg_action_status integer ENCODE az64,
    fwg_type_id character varying(36) ENCODE lzo,
    fwg_student_id character varying(36) ENCODE lzo,
    fwg_tenant_id character varying(36) ENCODE lzo,
    fwg_class_id character varying(36) ENCODE lzo,
    fwg_star_earned integer ENCODE az64,
    fwg_date_dw_id bigint ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_candidate_assessment_progress (
    dw_id bigint ENCODE az64,
    _trace_id character varying(36) ENCODE lzo,
    event_type character varying(50) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    date_dw_id bigint ENCODE az64,
    tenant_id character varying(36) ENCODE lzo,
    academic_year_tag character varying(20) ENCODE lzo,
    assessment_id character varying(36) ENCODE lzo,
    school_id character varying(36) ENCODE lzo,
    grade_id character varying(36) ENCODE lzo,
    class_id character varying(36) ENCODE lzo,
    candidate_id character varying(36) ENCODE lzo,
    grade integer ENCODE az64,
    material_type character varying(50) ENCODE lzo,
    attempt_number integer ENCODE az64,
    skill character varying(20) ENCODE lzo,
    subject character varying(50) ENCODE lzo,
    language character varying(20) ENCODE lzo,
    status character varying(20) ENCODE lzo,
    test_level_session_id character varying(36) ENCODE lzo,
    test_level character varying(20) ENCODE lzo,
    test_id character varying(36) ENCODE lzo,
    test_version bigint ENCODE az64,
    test_level_id character varying(36) ENCODE lzo,
    test_level_version bigint ENCODE az64,
    test_level_section_id character varying(36) ENCODE lzo distkey,
    report_id character varying(36) ENCODE lzo,
    total_timespent bigint ENCODE az64,
    final_score bigint ENCODE az64,
    final_grade bigint ENCODE az64,
    final_category character varying(20) ENCODE lzo,
    final_uncertainty double precision ENCODE raw,
    time_to_return bigint ENCODE az64,
    framework character varying(20) ENCODE lzo,
    _ingestion_type character varying(10) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_challenge_game_progress (
    fgc_dw_id bigint ENCODE az64,
    fgc_created_time timestamp without time zone ENCODE az64,
    fgc_dw_created_time timestamp without time zone ENCODE az64,
    fgc_date_dw_id bigint ENCODE az64,
    fgc_id character varying(36) ENCODE lzo,
    fgc_game_id character varying(36) ENCODE lzo,
    fgc_state character varying(20) ENCODE lzo,
    fgc_tenant_id character varying(36) ENCODE lzo,
    fgc_student_id character varying(36) ENCODE lzo,
    fgc_academic_year_id character varying(36) ENCODE lzo,
    fgc_academic_year_tag character varying(10) ENCODE lzo,
    fgc_school_id character varying(36) ENCODE lzo,
    fgc_grade integer ENCODE az64,
    fgc_organization character varying(100) ENCODE lzo,
    fgc_score integer ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.new_try_date (
    practice_session_created_time timestamp without time zone ENCODE az64,
    practice_session_dw_created_time timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_course_activity_association (
    caa_dw_id bigint ENCODE az64,
    caa_created_time timestamp without time zone ENCODE az64,
    caa_updated_time timestamp without time zone ENCODE az64,
    caa_deleted_time timestamp without time zone ENCODE az64,
    caa_dw_created_time timestamp without time zone ENCODE az64,
    caa_dw_updated_time timestamp without time zone ENCODE az64,
    caa_dw_deleted_time timestamp without time zone ENCODE az64,
    caa_status integer ENCODE az64,
    caa_attach_status integer ENCODE az64,
    caa_course_id character varying(36) ENCODE lzo,
    caa_container_id character varying(36) ENCODE lzo,
    caa_activity_id character varying(36) ENCODE lzo,
    caa_activity_type integer ENCODE az64,
    caa_activity_pacing character varying(50) ENCODE lzo,
    caa_activity_index integer ENCODE az64,
    caa_course_version character varying(10) ENCODE lzo,
    caa_is_parent_deleted boolean ENCODE raw,
    caa_grade character varying(10) ENCODE lzo,
    caa_activity_is_optional boolean ENCODE raw,
    caa_is_joint_parent_activity boolean ENCODE raw
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_ktg (
    ktg_staging_id bigint identity(1,1) ENCODE lzo,
    ktg_id character varying(256) ENCODE lzo,
    ktg_created_time timestamp without time zone ENCODE lzo,
    ktg_dw_created_time timestamp without time zone ENCODE lzo,
    ktg_date_dw_id bigint ENCODE lzo,
    tenant_uuid character varying(36) ENCODE lzo,
    student_uuid character varying(36) ENCODE lzo distkey,
    subject_uuid character varying(36) ENCODE lzo,
    school_uuid character varying(36) ENCODE lzo,
    grade_uuid character varying(36) ENCODE lzo,
    section_uuid character varying(36) ENCODE lzo,
    lo_uuid character varying(36) ENCODE lzo,
    academic_year_uuid character varying(36) ENCODE lzo,
    ktg_num_key_terms smallint ENCODE lzo,
    ktg_kt_collection_id bigint ENCODE lzo,
    ktg_trimester_id character varying(256) ENCODE lzo,
    ktg_trimester_order smallint ENCODE lzo,
    ktg_type character varying(200) ENCODE lzo,
    ktg_question_type character varying(200) ENCODE lzo,
    ktg_min_question smallint ENCODE lzo,
    ktg_max_question smallint ENCODE lzo,
    ktg_question_time_allotted integer ENCODE lzo,
    ktg_instructional_plan_id character varying(36) ENCODE lzo,
    ktg_learning_path_id character varying(36) ENCODE lzo,
    class_uuid character varying(36) ENCODE lzo,
    ktg_material_id character varying(36) ENCODE lzo,
    ktg_material_type character varying(20) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_content_repository (
    rel_content_repository_id bigint identity(1,1) ENCODE raw,
    content_repository_id character varying(36) ENCODE lzo,
    content_repository_name character varying(50) ENCODE lzo,
    content_repository_organisation_owner character varying(50) ENCODE lzo,
    content_repository_created_time timestamp without time zone ENCODE az64,
    content_repository_dw_created_time timestamp without time zone ENCODE az64,
    content_repository_updated_time timestamp without time zone ENCODE az64,
    content_repository_dw_updated_time timestamp without time zone ENCODE az64,
    content_repository_status integer ENCODE az64
)
DISTSTYLE ALL
SORTKEY ( rel_content_repository_id );
CREATE TABLE devcoredw_stage.staging_tutor_conversation (
    ftc_dw_id bigint identity(1,1) ENCODE raw,
    ftc_created_time timestamp without time zone ENCODE az64,
    ftc_dw_created_time timestamp without time zone ENCODE az64,
    ftc_date_dw_id bigint ENCODE az64,
    ftc_tenant_id character varying(36) ENCODE lzo,
    ftc_school_id character varying(36) ENCODE lzo,
    ftc_user_id character varying(36) ENCODE lzo,
    ftc_role character varying(20) ENCODE lzo,
    ftc_grade integer ENCODE az64,
    ftc_grade_id character varying(36) ENCODE lzo,
    ftc_context_id character varying(36) ENCODE lzo,
    ftc_session_id character varying(36) ENCODE lzo,
    ftc_subject_id bigint ENCODE az64,
    ftc_subject character varying(20) ENCODE lzo,
    ftc_language character varying(20) ENCODE lzo,
    ftc_activity_id character varying(36) ENCODE lzo,
    ftc_activity_status character varying(20) ENCODE lzo,
    ftc_material_id character varying(36) ENCODE lzo,
    ftc_material_type character varying(20) ENCODE lzo,
    ftc_level_id character varying(36) ENCODE lzo,
    ftc_outcome_id character varying(36) ENCODE lzo,
    ftc_conversation_max_tokens integer ENCODE az64,
    ftc_conversation_token_count integer ENCODE az64,
    ftc_system_prompt_tokens integer ENCODE az64,
    ftc_message_language character varying(30) ENCODE lzo,
    ftc_user_message_source character varying(30) ENCODE lzo,
    ftc_user_message_tokens integer ENCODE az64,
    ftc_user_message_timestamp timestamp without time zone ENCODE az64,
    ftc_bot_message_source character varying(30) ENCODE lzo,
    ftc_bot_message_tokens integer ENCODE az64,
    ftc_bot_message_timestamp timestamp without time zone ENCODE az64,
    ftc_bot_message_confidence double precision ENCODE raw,
    ftc_bot_message_response_time double precision ENCODE raw,
    ftc_session_state integer ENCODE az64,
    ftc_session_status character varying(20) ENCODE lzo,
    ftc_message_id character varying(36) ENCODE lzo,
    ftc_conversation_id character varying(36) ENCODE lzo,
    ftc_suggestions_prompt_tokens character varying(256) ENCODE lzo,
    ftc_message_tokens character varying(256) ENCODE lzo,
    ftc_activity_page_context_id character varying(256) ENCODE lzo,
    ftc_student_location character varying(256) ENCODE lzo,
    ftc_suggestion_clicked boolean ENCODE raw,
    ftc_clicked_suggestion_id character varying(36) ENCODE lzo,
    ftc_message_feedback character varying(10) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( ftc_dw_id );
CREATE TABLE devcoredw_stage.rel_class_backup_20220118 (
    rel_class_id bigint ENCODE az64,
    class_created_time timestamp without time zone ENCODE az64,
    class_updated_time timestamp without time zone ENCODE az64,
    class_deleted_time timestamp without time zone ENCODE az64,
    class_dw_created_time timestamp without time zone ENCODE az64,
    class_dw_updated_time timestamp without time zone ENCODE az64,
    class_status integer ENCODE az64,
    class_id character varying(36) ENCODE lzo,
    class_title character varying(255) ENCODE lzo,
    class_school_id character varying(36) ENCODE lzo,
    class_grade_id character varying(36) ENCODE lzo,
    class_section_id character varying(36) ENCODE lzo,
    class_academic_year_id character varying(36) ENCODE lzo,
    class_gen_subject character varying(255) ENCODE lzo,
    class_curriculum_id bigint ENCODE az64,
    class_curriculum_grade_id bigint ENCODE az64,
    class_curriculum_subject_id bigint ENCODE az64,
    class_content_academic_year integer ENCODE az64,
    class_tutor_dhabi_enabled boolean ENCODE raw,
    class_language_direction character varying(25) ENCODE lzo,
    class_online boolean ENCODE raw,
    class_practice boolean ENCODE raw,
    class_course_status character varying(50) ENCODE lzo,
    class_source_id character varying(255) ENCODE lzo,
    class_curriculum_instructional_plan_id character varying(36) ENCODE lzo,
    class_category_id character varying(36) ENCODE lzo,
    class_active_until timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_tutor_challenge_question_answer (
    ftcqa_bot_question_timestamp timestamp without time zone ENCODE az64,
    ftcqa_bot_question_source character varying(10) ENCODE lzo,
    ftcqa_bot_question_id character varying(36) ENCODE lzo,
    ftcqa_bot_question_tokens integer ENCODE az64,
    ftcqa_conversation_id character varying(36) ENCODE lzo,
    ftcqa_session_id character varying(36) ENCODE lzo,
    ftcqa_message_id character varying(36) ENCODE lzo,
    ftcqa_user_id character varying(36) ENCODE lzo,
    ftcqa_tenant_id character varying(36) ENCODE lzo,
    ftcqa_date_dw_id bigint ENCODE az64,
    ftcqa_created_time timestamp without time zone ENCODE az64,
    ftcqa_dw_created_time timestamp without time zone ENCODE az64,
    ftcqa_is_answer_evaluated boolean ENCODE raw,
    ftcqa_dw_id bigint ENCODE az64,
    ftcqa_user_attempt_tokens integer ENCODE az64,
    ftcqa_user_attempt_number integer ENCODE az64,
    ftcqa_user_remaining_attempts integer ENCODE az64,
    ftcqa_user_attempt_timestamp timestamp without time zone ENCODE az64,
    ftcqa_user_attempt_is_correct boolean ENCODE raw,
    ftcqa_user_attempt_source character varying(20) ENCODE lzo,
    ftcqa_user_attempt_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_tutor_user_context (
    ftc_dw_id bigint identity(1,1) ENCODE raw,
    ftc_created_time timestamp without time zone ENCODE az64,
    ftc_dw_created_time timestamp without time zone ENCODE az64,
    ftc_date_dw_id bigint ENCODE az64,
    ftc_tenant_id character varying(36) ENCODE lzo,
    ftc_user_id character varying(36) ENCODE lzo,
    ftc_role character varying(20) ENCODE lzo,
    ftc_context_id character varying(36) ENCODE lzo,
    ftc_school_id character varying(36) ENCODE lzo,
    ftc_grade_id character varying(36) ENCODE lzo,
    ftc_grade bigint ENCODE az64,
    ftc_subject_id character varying(36) ENCODE lzo,
    ftc_subject character varying(20) ENCODE lzo,
    ftc_language character varying(20) ENCODE lzo,
    ftc_tutor_locked boolean ENCODE raw
)
DISTSTYLE AUTO
SORTKEY ( ftc_dw_id );
CREATE TABLE devcoredw_stage.rel_course_activity_ip_association (
    dw_id bigint ENCODE az64,
    event_type character varying(100) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    active_until timestamp without time zone ENCODE az64,
    status integer ENCODE az64,
    ip_id character varying(36) ENCODE lzo,
    course_id character varying(36) ENCODE lzo,
    course_type character varying(255) ENCODE lzo,
    course_version character varying(255) ENCODE lzo,
    course_status character varying(255) ENCODE lzo,
    frame_id character varying(36) ENCODE lzo,
    frame_is_hidden boolean ENCODE raw,
    parent_container_id character varying(36) ENCODE lzo,
    parent_container_title character varying(255) ENCODE lzo,
    activity_id character varying(36) ENCODE lzo,
    activity_is_joint_parent_activity boolean ENCODE raw,
    activity_type character varying(255) ENCODE lzo,
    activity_is_hidden boolean ENCODE raw
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_adaptive_practice_progress (
    dw_id bigint ENCODE az64,
    event_type character varying(100) ENCODE lzo,
    _trace_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    date_dw_id bigint ENCODE az64,
    uuid character varying(36) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    student_id character varying(36) ENCODE lzo distkey,
    class_id character varying(36) ENCODE lzo,
    school_id character varying(36) ENCODE lzo,
    pathway_id character varying(36) ENCODE lzo,
    level_id character varying(36) ENCODE lzo,
    academic_year_tag character varying(40) ENCODE lzo,
    session_id character varying(36) ENCODE lzo,
    ml_session_id character varying(36) ENCODE lzo,
    level_proficiency_score double precision ENCODE raw,
    level_proficiency_tier character varying(50) ENCODE lzo,
    assessment_id character varying(36) ENCODE lzo,
    session_attempt integer ENCODE az64,
    stars integer ENCODE az64,
    time_spent integer ENCODE az64,
    question_id character varying(36) ENCODE lzo,
    question_skill_id character varying(36) ENCODE lzo,
    question_difficulty_label character varying(30) ENCODE lzo,
    skill_proficiency_tier character varying(40) ENCODE lzo,
    skill_proficiency_score double precision ENCODE raw,
    answer_score double precision ENCODE raw,
    time_spent_on_question integer ENCODE az64,
    hint_used boolean ENCODE raw,
    is_answer_correct boolean ENCODE raw,
    next_question_id character varying(36) ENCODE lzo,
    attempt_number integer ENCODE az64,
    next_question_skill_id character varying(36) ENCODE lzo,
    next_question_difficulty_label character varying(30) ENCODE lzo,
    _ingestion_type character varying(10) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_experience_submitted (
    fes_staging_id bigint identity(1,1) ENCODE az64,
    fes_created_time timestamp without time zone ENCODE az64,
    fes_dw_created_time timestamp without time zone ENCODE az64,
    fes_date_dw_id bigint ENCODE az64,
    fes_id character varying(36) ENCODE lzo,
    exp_uuid character varying(36) ENCODE lzo,
    fes_ls_id character varying(36) ENCODE lzo,
    fes_content_id character varying(36) ENCODE lzo,
    lo_uuid character varying(36) ENCODE lzo,
    student_uuid character varying(36) ENCODE lzo,
    section_uuid character varying(36) ENCODE lzo,
    class_uuid character varying(36) ENCODE raw,
    subject_uuid character varying(36) ENCODE lzo,
    grade_uuid character varying(36) ENCODE raw,
    tenant_uuid character varying(36) ENCODE lzo,
    school_uuid character varying(36) ENCODE raw,
    lp_uuid character varying(36) ENCODE lzo,
    fes_instructional_plan_id character varying(36) ENCODE lzo,
    fes_content_package_id character varying(36) ENCODE lzo,
    fes_content_title character varying(100) ENCODE lzo,
    fes_content_type character varying(100) ENCODE lzo,
    fes_start_time timestamp without time zone ENCODE az64,
    fes_lesson_type character varying(50) ENCODE lzo,
    fes_is_retry boolean ENCODE raw,
    fes_outside_of_school boolean ENCODE raw,
    fes_attempt integer ENCODE az64,
    fes_academic_period_order integer ENCODE az64,
    academic_year_uuid character varying(36) ENCODE lzo,
    fes_content_academic_year integer ENCODE az64,
    fes_lesson_category character varying(100) ENCODE lzo,
    fes_suid character varying(36) ENCODE lzo,
    fes_abbreviation character varying(100) ENCODE lzo,
    fes_activity_type character varying(100) ENCODE lzo,
    fes_activity_component_type character varying(100) ENCODE lzo,
    fes_completion_node boolean ENCODE raw,
    fes_main_component boolean ENCODE raw,
    fes_exit_ticket boolean ENCODE raw,
    fes_material_id character varying(36) ENCODE lzo,
    fes_material_type character varying(20) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( school_uuid, grade_uuid, class_uuid );
CREATE TABLE devcoredw_stage.rel_course_activity_outcome_association (
    caoa_dw_id bigint ENCODE az64,
    caoa_created_time timestamp without time zone ENCODE az64,
    caoa_updated_time timestamp without time zone ENCODE az64,
    caoa_dw_created_time timestamp without time zone ENCODE az64,
    caoa_dw_updated_time timestamp without time zone ENCODE az64,
    caoa_status integer ENCODE az64,
    caoa_course_id character varying(36) ENCODE lzo,
    caoa_activity_id character varying(36) ENCODE lzo,
    caoa_outcome_id character varying(36) ENCODE lzo,
    caoa_outcome_type character varying(50) ENCODE lzo,
    caoa_curr_id bigint ENCODE az64,
    caoa_curr_grade_id bigint ENCODE az64,
    caoa_curr_subject_id bigint ENCODE az64 distkey
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_ktg_session (
    ktg_session_staging_id bigint identity(1,1) ENCODE lzo,
    ktg_session_id character varying(256) ENCODE lzo,
    ktg_session_created_time timestamp without time zone ENCODE lzo,
    ktg_session_dw_created_time timestamp without time zone ENCODE lzo,
    ktg_session_date_dw_id bigint ENCODE lzo,
    ktg_session_question_id character varying(256) ENCODE lzo,
    ktg_session_kt_id character varying(256) ENCODE lzo,
    tenant_uuid character varying(36) ENCODE lzo,
    student_uuid character varying(36) ENCODE lzo,
    subject_uuid character varying(36) ENCODE lzo,
    school_uuid character varying(36) ENCODE lzo,
    grade_uuid character varying(36) ENCODE lzo,
    section_uuid character varying(36) ENCODE lzo,
    lo_uuid character varying(36) ENCODE lzo,
    academic_year_uuid character varying(36) ENCODE lzo,
    ktg_session_outside_of_school boolean ENCODE raw,
    ktg_session_trimester_id character varying(256) ENCODE lzo,
    ktg_session_trimester_order smallint ENCODE lzo,
    ktg_session_type character varying(200) ENCODE lzo,
    ktg_session_question_time_allotted integer ENCODE lzo,
    ktg_session_answer character varying(5000) ENCODE lzo,
    ktg_session_num_attempts smallint ENCODE lzo,
    ktg_session_score double precision ENCODE raw,
    ktg_session_max_score double precision ENCODE raw,
    ktg_session_stars integer ENCODE lzo,
    ktg_session_is_attended boolean ENCODE raw,
    ktg_session_event_type integer ENCODE lzo,
    ktg_session_is_start boolean ENCODE raw,
    ktg_session_is_start_event_processed boolean ENCODE raw,
    ktg_session_instructional_plan_id character varying(36) ENCODE lzo,
    ktg_session_learning_path_id character varying(36) ENCODE lzo,
    class_uuid character varying(36) ENCODE lzo,
    ktg_session_material_id character varying(36) ENCODE lzo,
    ktg_session_material_type character varying(20) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_tutor_onboarding (
    fto_dw_id bigint ENCODE az64,
    fto_created_time timestamp without time zone ENCODE az64,
    fto_dw_created_time timestamp without time zone ENCODE az64,
    fto_date_dw_id bigint ENCODE az64,
    fto_user_id character varying(36) ENCODE lzo,
    fto_tenant_id character varying(36) ENCODE lzo,
    fto_question_id character varying(36) ENCODE lzo,
    fto_question_category character varying(50) ENCODE lzo,
    fto_user_free_text_response boolean ENCODE raw,
    fto_onboarding_complete boolean ENCODE raw,
    fto_onboarding_skipped boolean ENCODE raw
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_pathway_skill_gap_tracker (
    dw_id bigint ENCODE az64,
    event_type character varying(100) ENCODE lzo,
    _trace_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    date_dw_id bigint ENCODE az64,
    uuid character varying(36) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    student_id character varying(36) ENCODE lzo distkey,
    class_id character varying(36) ENCODE lzo,
    school_id character varying(36) ENCODE lzo,
    pathway_id character varying(36) ENCODE lzo,
    level_id character varying(36) ENCODE lzo,
    academic_year_tag character varying(40) ENCODE lzo,
    session_id character varying(36) ENCODE lzo,
    ml_session_id character varying(36) ENCODE lzo,
    level_proficiency_score double precision ENCODE raw,
    level_proficiency_tier character varying(50) ENCODE lzo,
    assessment_id character varying(36) ENCODE lzo,
    session_attempt integer ENCODE az64,
    stars integer ENCODE az64,
    time_spent integer ENCODE az64,
    skill_proficiency_tier character varying(40) ENCODE lzo,
    skill_proficiency_score double precision ENCODE raw,
    skill_id character varying(36) ENCODE lzo,
    status character varying(50) ENCODE lzo,
    _ingestion_type character varying(10) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_item_purchase (
    fip_dw_id bigint ENCODE az64,
    fip_created_time timestamp without time zone ENCODE az64,
    fip_dw_created_time timestamp without time zone ENCODE az64,
    fip_date_dw_id bigint ENCODE az64,
    fip_id character varying(36) ENCODE lzo,
    fip_item_id character varying(36) ENCODE lzo,
    fip_item_type character varying(50) ENCODE lzo,
    fip_item_title character varying(50) ENCODE lzo,
    fip_item_description character varying(50) ENCODE lzo,
    fip_transaction_id character varying(36) ENCODE lzo,
    fip_school_id character varying(36) ENCODE lzo,
    fip_grade_id character varying(36) ENCODE lzo,
    fip_section_id character varying(36) ENCODE lzo,
    fip_academic_year_id character varying(36) ENCODE lzo,
    fip_academic_year integer ENCODE az64,
    fip_student_id character varying(36) ENCODE lzo,
    fip_tenant_id character varying(36) ENCODE lzo,
    fip_redeemed_stars integer ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_student_certificate_awarded (
    fsca_dw_id bigint identity(1,1) ENCODE raw,
    fsca_created_time timestamp without time zone ENCODE az64,
    fsca_dw_created_time timestamp without time zone ENCODE az64,
    fsca_date_dw_id bigint ENCODE az64,
    fsca_certificate_id character varying(36) ENCODE lzo,
    fsca_student_id character varying(36) ENCODE lzo,
    fsca_award_category character varying(50) ENCODE lzo,
    fsca_award_purpose character varying(100) ENCODE lzo,
    fsca_academic_year_id character varying(36) ENCODE lzo,
    fsca_class_id character varying(36) ENCODE lzo,
    fsca_grade_id character varying(36) ENCODE lzo,
    fsca_teacher_id character varying(36) ENCODE lzo,
    fsca_language character varying(36) ENCODE lzo,
    fsca_tenant_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( fsca_dw_id );
CREATE TABLE devcoredw_stage.rel_tdc (
    rel_tdc_id bigint identity(1,1) ENCODE lzo,
    tdc_created_time timestamp without time zone ENCODE lzo,
    tdc_updated_time timestamp without time zone ENCODE lzo,
    tdc_deleted_time timestamp without time zone ENCODE lzo,
    tdc_dw_created_time timestamp without time zone ENCODE lzo,
    tdc_dw_updated_time timestamp without time zone ENCODE lzo,
    tdc_active_until timestamp without time zone ENCODE lzo,
    tdc_status integer ENCODE lzo,
    tdc_uuid character varying(36) ENCODE raw,
    tdc_onboarded boolean ENCODE raw,
    school_uuid character varying(36) ENCODE lzo,
    tdc_expirable boolean ENCODE raw
)
DISTSTYLE AUTO
SORTKEY ( tdc_uuid );
CREATE TABLE devcoredw_stage.rel_question_pool_association (
    rel_question_pool_association_id bigint identity(1,1) ENCODE raw,
    question_pool_association_created_time timestamp without time zone ENCODE az64,
    question_pool_association_updated_time timestamp without time zone ENCODE az64,
    question_pool_association_dw_created_time timestamp without time zone ENCODE az64,
    question_pool_association_dw_updated_time timestamp without time zone ENCODE az64,
    question_pool_association_status integer ENCODE az64,
    question_pool_association_assign_status integer ENCODE az64,
    question_pool_association_question_code character varying(120) ENCODE lzo,
    question_pool_uuid character varying(36) ENCODE lzo,
    question_pool_association_triggered_by character varying(100) ENCODE lzo
)
DISTSTYLE ALL
SORTKEY ( rel_question_pool_association_id );
CREATE TABLE devcoredw_stage.rel_course_activity_grade_association (
    caga_dw_id bigint ENCODE az64,
    caga_created_time timestamp without time zone ENCODE az64,
    caga_updated_time timestamp without time zone ENCODE az64,
    caga_deleted_time timestamp without time zone ENCODE az64,
    caga_dw_created_time timestamp without time zone ENCODE az64,
    caga_dw_updated_time timestamp without time zone ENCODE az64,
    caga_dw_deleted_time timestamp without time zone ENCODE az64,
    caga_status integer ENCODE az64,
    caga_course_id character varying(36) ENCODE lzo,
    caga_activity_id character varying(36) ENCODE lzo,
    caga_grade_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_levels_recommended (
    flr_dw_id bigint identity(1,1) ENCODE raw,
    flr_created_time timestamp without time zone ENCODE az64,
    flr_dw_created_time timestamp without time zone ENCODE az64,
    flr_date_dw_id bigint ENCODE az64,
    flr_recommended_on timestamp without time zone ENCODE az64,
    flr_tenant_id character varying(36) ENCODE lzo,
    flr_student_id character varying(36) ENCODE lzo,
    flr_class_id character varying(36) ENCODE lzo,
    flr_pathway_id character varying(36) ENCODE lzo,
    flr_completed_level_id character varying(36) ENCODE lzo,
    flr_level_id character varying(36) ENCODE lzo,
    flr_status integer ENCODE az64,
    flr_recommendation_type integer ENCODE az64,
    flr_academic_year character varying(50) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( flr_dw_id );
CREATE TABLE devcoredw_stage.rel_course_subject_association (
    cs_dw_id bigint ENCODE az64,
    cs_course_dw_id bigint ENCODE az64,
    cs_course_id character varying(36) ENCODE lzo,
    cs_subject_id integer ENCODE az64,
    cs_status integer ENCODE az64,
    cs_created_time timestamp without time zone ENCODE az64,
    cs_dw_created_time timestamp without time zone ENCODE az64,
    cs_updated_time timestamp without time zone ENCODE az64,
    cs_dw_updated_time timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_user_avatar (
    fua_dw_id bigint ENCODE az64,
    fua_created_time timestamp without time zone ENCODE az64,
    fua_dw_created_time timestamp without time zone ENCODE az64,
    fua_date_dw_id bigint ENCODE az64,
    fua_id character varying(255) ENCODE lzo,
    fua_user_id character varying(72) ENCODE lzo,
    fua_tenant_id character varying(36) ENCODE lzo,
    fua_school_id character varying(36) ENCODE lzo,
    fua_grade_id character varying(36) ENCODE lzo,
    fua_avatar_type character varying(36) ENCODE lzo,
    fua_avatar_file_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_content_session (
    fcs_staging_id bigint identity(1,1) ENCODE az64,
    fcs_created_time timestamp without time zone ENCODE az64,
    fcs_dw_created_time timestamp without time zone ENCODE az64,
    fcs_date_dw_id bigint ENCODE az64,
    fcs_id character varying(36) ENCODE lzo,
    fcs_event_type smallint ENCODE az64,
    fcs_is_start boolean ENCODE raw,
    fcs_ls_id character varying(36) ENCODE lzo,
    fcs_content_id character varying(36) ENCODE lzo,
    fcs_lo_id character varying(36) ENCODE lzo,
    fcs_student_id character varying(36) ENCODE lzo,
    fcs_class_id character varying(36) ENCODE lzo,
    fcs_grade_id character varying(36) ENCODE lzo,
    fcs_tenant_id character varying(36) ENCODE lzo,
    fcs_school_id character varying(36) ENCODE lzo,
    fcs_ay_id character varying(36) ENCODE lzo,
    fcs_section_id character varying(36) ENCODE lzo,
    fcs_lp_id character varying(108) ENCODE lzo,
    fcs_ip_id character varying(36) ENCODE lzo,
    fcs_outside_of_school boolean ENCODE raw,
    fcs_content_academic_year character varying(4) ENCODE lzo,
    fcs_app_timespent double precision ENCODE raw,
    fcs_app_score double precision ENCODE raw
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_assessment_answer_submitted (
    dw_id bigint ENCODE az64,
    _trace_id character varying(36) ENCODE lzo,
    event_type character varying(100) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    date_dw_id bigint ENCODE az64,
    assessment_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    academic_year_tag character varying(10) ENCODE lzo,
    attempt_number integer ENCODE az64,
    candidate_id character varying(36) ENCODE lzo,
    class_id character varying(36) ENCODE lzo,
    grade integer ENCODE az64,
    grade_id character varying(36) ENCODE lzo,
    time_spent integer ENCODE az64,
    subject character varying(10) ENCODE lzo,
    school_id character varying(36) ENCODE lzo,
    language character varying(10) ENCODE lzo,
    question_id character varying(36) ENCODE lzo,
    question_code character varying(50) ENCODE lzo,
    question_version integer ENCODE az64,
    test_level_session_id character varying(36) ENCODE lzo,
    test_level_id character varying(36) ENCODE lzo,
    test_level_version bigint ENCODE az64,
    test_level_section_id character varying(36) ENCODE lzo distkey,
    reference_code character varying(50) ENCODE lzo,
    test_level character varying(20) ENCODE lzo,
    skill character varying(20) ENCODE lzo,
    material_type character varying(20) ENCODE lzo,
    _ingestion_type character varying(10) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.try_date (
    date_diff bigint ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_class (
    class_created_time timestamp without time zone ENCODE az64,
    class_updated_time timestamp without time zone ENCODE az64,
    class_deleted_time timestamp without time zone ENCODE az64,
    class_dw_created_time timestamp without time zone ENCODE az64,
    class_dw_updated_time timestamp without time zone ENCODE az64,
    class_status integer ENCODE az64,
    class_id character varying(36) ENCODE lzo,
    class_title character varying(255) ENCODE lzo,
    class_school_id character varying(36) ENCODE lzo,
    class_grade_id character varying(36) ENCODE lzo,
    class_section_id character varying(36) ENCODE lzo,
    class_academic_year_id character varying(36) ENCODE lzo,
    class_gen_subject character varying(255) ENCODE lzo,
    class_curriculum_id bigint ENCODE az64,
    class_curriculum_grade_id bigint ENCODE az64,
    class_curriculum_subject_id bigint ENCODE az64,
    class_content_academic_year integer ENCODE az64,
    class_tutor_dhabi_enabled boolean ENCODE raw,
    class_language_direction character varying(25) ENCODE lzo,
    class_online boolean ENCODE raw,
    class_practice boolean ENCODE raw,
    class_course_status character varying(50) ENCODE lzo,
    class_source_id character varying(255) ENCODE lzo,
    class_curriculum_instructional_plan_id character varying(36) ENCODE lzo,
    class_category_id character varying(36) ENCODE lzo,
    class_active_until timestamp without time zone ENCODE az64,
    class_material_id character varying(36) ENCODE lzo,
    class_material_type character varying(20) ENCODE lzo,
    rel_class_dw_id bigint ENCODE az64,
    class_academic_calendar_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_course_activity_container (
    course_activity_container_is_accelerated boolean ENCODE raw,
    course_activity_container_pacing character varying(50) ENCODE lzo,
    course_activity_container_grade character varying(10) ENCODE lzo,
    course_activity_container_sequence integer ENCODE az64,
    course_activity_container_course_version character varying(10) ENCODE lzo,
    course_activity_container_attach_status integer ENCODE az64,
    course_activity_container_id character varying(36) ENCODE lzo,
    course_activity_container_longname character varying(255) ENCODE lzo,
    course_activity_container_updated_time timestamp without time zone ENCODE az64,
    course_activity_container_dw_created_time timestamp without time zone ENCODE az64,
    course_activity_container_title character varying(50) ENCODE lzo,
    course_activity_container_created_time timestamp without time zone ENCODE az64,
    course_activity_container_course_id character varying(36) ENCODE lzo,
    course_activity_container_domain character varying(50) ENCODE lzo,
    course_activity_container_status integer ENCODE az64,
    course_activity_container_dw_updated_time timestamp without time zone ENCODE az64,
    course_activity_container_index integer ENCODE az64,
    rel_course_activity_container_dw_id bigint ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_tutor_suggestions (
    fts_dw_id bigint ENCODE az64,
    fts_message_id character varying(36) ENCODE lzo,
    fts_suggestion_id character varying(36) ENCODE lzo,
    fts_created_time timestamp without time zone ENCODE az64,
    fts_dw_created_time timestamp without time zone ENCODE az64,
    fts_user_id character varying(36) ENCODE lzo,
    fts_session_id character varying(36) ENCODE lzo,
    fts_conversation_id character varying(36) ENCODE lzo,
    fts_response_time double precision ENCODE raw,
    fts_success_parser_tokens integer ENCODE az64,
    fts_failure_parser_tokens integer ENCODE az64,
    fts_suggestion_clicked boolean ENCODE raw,
    fts_date_dw_id bigint ENCODE az64,
    fts_tenant_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_lesson_assignment (
    rel_lesson_assignment_id bigint identity(1,1) ENCODE raw,
    lesson_assignment_created_time timestamp without time zone ENCODE az64,
    lesson_assignment_updated_time timestamp without time zone ENCODE az64,
    lesson_assignment_dw_created_time timestamp without time zone ENCODE az64,
    lesson_assignment_dw_updated_time timestamp without time zone ENCODE az64,
    lesson_assignment_status integer ENCODE az64,
    student_uuid character varying(36) ENCODE lzo,
    lo_uuid character varying(36) ENCODE lzo,
    class_uuid character varying(36) ENCODE lzo,
    teacher_uuid character varying(36) ENCODE lzo,
    lesson_assignment_assign_status integer ENCODE az64,
    lesson_assignment_type integer ENCODE az64
)
DISTSTYLE ALL
SORTKEY ( rel_lesson_assignment_id );
CREATE TABLE devcoredw_stage.staging_user_login (
    ful_staging_id bigint identity(1,1) ENCODE raw,
    ful_created_time timestamp without time zone ENCODE raw,
    ful_dw_created_time timestamp without time zone ENCODE raw,
    ful_date_dw_id bigint ENCODE raw,
    ful_id character varying(36) ENCODE raw,
    user_uuid character varying(36) ENCODE raw distkey,
    role_uuid character varying(36) ENCODE raw,
    tenant_uuid character varying(36) ENCODE raw,
    school_uuid character varying(36) ENCODE raw,
    ful_outside_of_school boolean ENCODE raw,
    ful_login_time timestamp without time zone ENCODE raw
)
DISTSTYLE AUTO
SORTKEY ( school_uuid );
CREATE TABLE devcoredw_stage.staging_pathway_activity_completed (
    fpac_dw_id bigint identity(1,1) ENCODE raw distkey,
    fpac_created_time timestamp without time zone ENCODE az64,
    fpac_dw_created_time timestamp without time zone ENCODE az64,
    fpac_date_dw_id bigint ENCODE az64,
    fpac_tenant_id character varying(36) ENCODE lzo,
    fpac_student_id character varying(36) ENCODE lzo,
    fpac_class_id character varying(36) ENCODE lzo,
    fpac_pathway_id character varying(36) ENCODE lzo,
    fpac_level_id character varying(36) ENCODE lzo,
    fpac_activity_id character varying(36) ENCODE lzo,
    fpac_activity_type integer ENCODE az64,
    fpac_score double precision ENCODE raw,
    fpac_learning_session_id character varying(36) ENCODE lzo,
    fpac_attempt integer ENCODE az64,
    fpac_academic_year character varying(50) ENCODE lzo,
    fpac_time_spent integer ENCODE az64
)
DISTSTYLE AUTO
SORTKEY ( fpac_dw_id );
CREATE TABLE devcoredw_stage.staging_ebook_progress (
    fep_dw_id bigint ENCODE az64,
    fep_id character varying(36) ENCODE lzo,
    fep_created_time timestamp without time zone ENCODE az64,
    fep_dw_created_time timestamp without time zone ENCODE az64,
    fep_date_dw_id bigint ENCODE az64,
    fep_session_id character varying(36) ENCODE lzo,
    fep_exp_id character varying(36) ENCODE lzo,
    fep_student_id character varying(36) ENCODE lzo,
    feb_ay_tag character varying(10) ENCODE lzo,
    fep_tenant_id character varying(36) ENCODE lzo,
    fep_school_id character varying(36) ENCODE lzo,
    fep_grade_id character varying(36) ENCODE lzo,
    fep_class_id character varying(36) ENCODE lzo,
    fep_lo_id character varying(36) ENCODE lzo,
    fep_step_instance_step_id character varying(36) ENCODE lzo,
    fep_content_hash character varying(256) ENCODE lzo,
    fep_material_type character varying(20) ENCODE lzo,
    fep_title character varying(512) ENCODE lzo,
    fep_total_pages integer ENCODE az64,
    fep_has_audio boolean ENCODE raw,
    fep_action character varying(50) ENCODE lzo,
    fep_is_last_page boolean ENCODE raw,
    fep_location character varying(100) ENCODE lzo,
    fep_state character varying(50) ENCODE lzo,
    fep_time_spent numeric(18,0) ENCODE az64,
    fep_bookmark_location character varying(255) ENCODE lzo,
    fep_highlight_location character varying(255) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_user (
    user_dw_id bigint identity(1,1) ENCODE raw,
    user_id character varying(36) ENCODE raw distkey,
    user_type character varying(50) ENCODE lzo,
    user_created_time timestamp without time zone ENCODE az64,
    user_dw_created_time timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO
SORTKEY ( user_dw_id );
CREATE TABLE devcoredw_stage.rel_course_activity_container_grade_association (
    cacga_dw_id bigint ENCODE az64,
    cacga_container_id character varying(36) ENCODE lzo,
    cacga_course_id character varying(36) ENCODE lzo,
    cacga_grade character varying(10) ENCODE lzo,
    cacga_created_time timestamp without time zone ENCODE az64,
    cacga_dw_created_time timestamp without time zone ENCODE az64,
    cacga_updated_time timestamp without time zone ENCODE az64,
    cacga_dw_updated_time timestamp without time zone ENCODE az64,
    cacga_status integer ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_pathway_skill_learning_progress (
    dw_id bigint ENCODE az64,
    event_type character varying(100) ENCODE lzo,
    uuid character varying(36) ENCODE lzo,
    _trace_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    date_dw_id bigint ENCODE az64,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    skill_session_id character varying(36) ENCODE lzo,
    experience_id character varying(36) ENCODE lzo,
    time_spent_on_activity integer ENCODE az64,
    time_spent_this_time_on_activity integer ENCODE az64,
    component_id character varying(36) ENCODE lzo,
    class_id character varying(36) ENCODE lzo,
    school_id character varying(36) ENCODE lzo,
    student_id character varying(36) ENCODE lzo distkey,
    skill_id character varying(36) ENCODE lzo,
    material_id character varying(36) ENCODE lzo,
    academic_year character varying(40) ENCODE lzo,
    skill_completion_percentage double precision ENCODE raw,
    is_activity_completed boolean ENCODE raw,
    _ingestion_type character varying(10) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_teacher (
    rel_teacher_id bigint identity(1,1) ENCODE raw,
    teacher_created_time timestamp without time zone ENCODE raw,
    teacher_updated_time timestamp without time zone ENCODE raw,
    teacher_deleted_time timestamp without time zone ENCODE raw,
    teacher_dw_created_time timestamp without time zone ENCODE raw,
    teacher_dw_updated_time timestamp without time zone ENCODE raw,
    teacher_active_until timestamp without time zone ENCODE raw,
    teacher_status integer ENCODE raw,
    teacher_id character varying(36) ENCODE raw distkey,
    subject_id character varying(36) ENCODE raw,
    school_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( teacher_id );
CREATE TABLE devcoredw_stage.staging_lesson_feedback (
    lesson_feedback_staging_id bigint identity(1,1) ENCODE lzo,
    lesson_feedback_id character varying(36) ENCODE lzo,
    lesson_feedback_created_time timestamp without time zone ENCODE lzo,
    lesson_feedback_dw_created_time timestamp without time zone ENCODE lzo,
    lesson_feedback_date_dw_id bigint ENCODE lzo,
    tenant_uuid character varying(36) ENCODE lzo,
    school_uuid character varying(36) ENCODE lzo,
    academic_year_uuid character varying(36) ENCODE lzo,
    grade_uuid character varying(36) ENCODE lzo,
    section_uuid character varying(36) ENCODE lzo,
    subject_uuid character varying(36) ENCODE lzo,
    student_uuid character varying(36) ENCODE lzo,
    lo_uuid character varying(36) ENCODE lzo,
    curr_uuid character varying(36) ENCODE lzo,
    curr_grade_uuid character varying(36) ENCODE lzo,
    curr_subject_uuid character varying(36) ENCODE lzo,
    fle_ls_uuid character varying(36) ENCODE lzo,
    lesson_feedback_trimester_id character varying(36) ENCODE lzo,
    lesson_feedback_trimester_order integer ENCODE lzo,
    lesson_feedback_content_academic_year integer ENCODE lzo,
    lesson_feedback_rating integer ENCODE lzo,
    lesson_feedback_rating_text character varying(36) ENCODE lzo,
    lesson_feedback_has_comment boolean ENCODE raw,
    lesson_feedback_is_cancelled boolean ENCODE raw,
    lesson_feedback_instructional_plan_id character varying(36) ENCODE lzo,
    lesson_feedback_learning_path_id character varying(36) ENCODE lzo,
    class_uuid character varying(36) ENCODE lzo,
    lesson_feedback_teaching_period_id character varying(36) ENCODE lzo,
    lesson_feedback_teaching_period_title character varying(50) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_student (
    rel_student_id bigint identity(1,1) ENCODE az64,
    student_created_time timestamp without time zone ENCODE az64,
    student_updated_time timestamp without time zone ENCODE az64,
    student_deleted_time timestamp without time zone ENCODE az64,
    student_dw_created_time timestamp without time zone ENCODE az64,
    student_dw_updated_time timestamp without time zone ENCODE az64,
    student_active_until timestamp without time zone ENCODE az64,
    student_status integer ENCODE az64,
    student_uuid character varying(36) ENCODE lzo distkey,
    student_username character varying(256) ENCODE lzo,
    school_uuid character varying(36) ENCODE lzo,
    grade_uuid character varying(36) ENCODE lzo,
    section_uuid character varying(36) ENCODE lzo,
    student_tags character varying(256) ENCODE lzo,
    student_special_needs character varying(1000) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_adt_attempt_threshold (
    aat_dw_id bigint ENCODE az64,
    aat_created_time timestamp without time zone ENCODE az64,
    aat_updated_time timestamp without time zone ENCODE az64,
    aat_dw_created_time timestamp without time zone ENCODE az64,
    aat_dw_updated_time timestamp without time zone ENCODE az64,
    aat_status integer ENCODE az64,
    aat_id character varying(36) ENCODE lzo,
    aat_academic_year_id character varying(36) ENCODE lzo,
    aat_tenant_id character varying(36) ENCODE lzo,
    aat_school_id character varying(36) ENCODE lzo,
    aat_state character varying(50) ENCODE lzo,
    aat_attempt_title character varying(100) ENCODE lzo,
    aat_attempt_start_time timestamp without time zone ENCODE az64,
    aat_attempt_end_time timestamp without time zone ENCODE az64,
    aat_attempt_number integer ENCODE az64,
    aat_total_attempts integer ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_core_activity_assign (
    cta_dw_id bigint ENCODE az64,
    cta_event_type character varying(100) ENCODE lzo,
    cta_id character varying(36) ENCODE raw,
    cta_created_time timestamp without time zone ENCODE az64,
    cta_dw_created_time timestamp without time zone ENCODE az64,
    cta_status smallint ENCODE az64,
    cta_active_until timestamp without time zone ENCODE az64,
    cta_action_time timestamp without time zone ENCODE az64,
    cta_start_date character varying(10) ENCODE lzo,
    cta_end_date character varying(10) ENCODE lzo,
    cta_ay_tag character varying(10) ENCODE lzo,
    cta_tenant_id character varying(36) ENCODE lzo,
    cta_student_id character varying(36) ENCODE lzo distkey,
    cta_course_id character varying(36) ENCODE lzo,
    cta_class_id character varying(36) ENCODE lzo,
    cta_teacher_id character varying(36) ENCODE lzo,
    cta_activity_id character varying(36) ENCODE lzo,
    cta_activity_type character varying(20) ENCODE lzo,
    cta_progress_status character varying(30) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( cta_id );
CREATE TABLE devcoredw_stage.rel_instructional_plan (
    rel_instructional_plan_id bigint identity(1,1) ENCODE az64,
    instructional_plan_created_time timestamp without time zone ENCODE az64,
    instructional_plan_updated_time timestamp without time zone ENCODE az64,
    instructional_plan_deleted_time timestamp without time zone ENCODE az64,
    instructional_plan_dw_created_time timestamp without time zone ENCODE az64,
    instructional_plan_dw_updated_time timestamp without time zone ENCODE az64,
    instructional_plan_status integer ENCODE az64,
    instructional_plan_id character varying(36) ENCODE lzo,
    instructional_plan_name character varying(100) ENCODE lzo,
    instructional_plan_curriculum_id bigint ENCODE az64,
    instructional_plan_curriculum_subject_id bigint ENCODE az64,
    instructional_plan_curriculum_grade_id bigint ENCODE az64,
    instructional_plan_content_academic_year_id integer ENCODE az64,
    instructional_plan_item_order integer ENCODE az64,
    week_uuid character varying(36) ENCODE lzo,
    lo_uuid character varying(36) ENCODE lzo,
    instructional_plan_item_ccl_lo_id bigint ENCODE az64,
    instructional_plan_item_optional boolean ENCODE raw,
    instructional_plan_item_instructor_led boolean ENCODE raw,
    instructional_plan_item_default_locked boolean ENCODE raw,
    instructional_plan_item_type character varying(36) ENCODE lzo,
    ic_uuid character varying(36) ENCODE lzo,
    instructional_plan_content_repository_id character varying(36) ENCODE lzo,
    content_repository_uuid character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_adt_student_report (
    fasr_staging_id bigint identity(1,1) ENCODE az64,
    fasr_created_time timestamp without time zone ENCODE az64,
    fasr_dw_created_time timestamp without time zone ENCODE az64,
    fasr_date_dw_id bigint ENCODE az64,
    fasr_tenant_id character varying(36) ENCODE lzo,
    fasr_student_id character varying(36) ENCODE lzo,
    fasr_question_pool_id character varying(36) ENCODE lzo,
    fasr_fle_ls_id character varying(36) ENCODE lzo,
    fasr_id character varying(36) ENCODE lzo,
    fasr_final_score double precision ENCODE raw,
    fasr_final_proficiency double precision ENCODE raw,
    fasr_final_result character varying(20) ENCODE lzo,
    fasr_total_time_spent double precision ENCODE raw,
    fasr_academic_year integer ENCODE az64,
    fasr_academic_term integer ENCODE az64,
    fasr_test_id character varying(36) ENCODE lzo,
    fasr_curriculum_subject_id bigint ENCODE az64,
    fasr_curriculum_subject_name character varying(255) ENCODE lzo,
    fasr_status integer ENCODE az64,
    fasr_final_uncertainty double precision ENCODE raw,
    fasr_framework character varying(36) ENCODE lzo,
    fasr_final_standard_error double precision ENCODE raw,
    fasr_language character varying(50) ENCODE lzo,
    fasr_school_id character varying(36) ENCODE lzo,
    fasr_attempt integer ENCODE az64,
    fasr_final_grade integer ENCODE az64,
    fasr_forecast_score double precision ENCODE raw,
    fasr_final_category character varying(50) ENCODE lzo,
    fasr_grade integer ENCODE az64,
    fasr_grade_id character varying(36) ENCODE lzo,
    fasr_academic_year_id character varying(36) ENCODE lzo,
    fasr_secondary_result character varying(50) ENCODE lzo,
    fasr_class_subject_name character varying(64) ENCODE lzo,
    fasr_skill character varying(20) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_class_user (
    class_user_created_time timestamp without time zone ENCODE az64,
    class_user_updated_time timestamp without time zone ENCODE az64,
    class_user_deleted_time timestamp without time zone ENCODE az64,
    class_user_dw_created_time timestamp without time zone ENCODE az64,
    class_user_dw_updated_time timestamp without time zone ENCODE az64,
    class_user_active_until timestamp without time zone ENCODE az64,
    class_user_status integer ENCODE az64,
    class_uuid character varying(36) ENCODE lzo distkey,
    user_uuid character varying(36) ENCODE lzo,
    role_uuid character varying(20) ENCODE lzo,
    class_user_attach_status integer ENCODE az64,
    rel_class_user_dw_id bigint ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_conversation_occurred (
    fco_staging_id bigint identity(1,1) ENCODE raw,
    fco_created_time timestamp without time zone ENCODE raw,
    fco_dw_created_time timestamp without time zone ENCODE raw,
    fco_date_dw_id bigint ENCODE raw,
    fco_id character varying(36) ENCODE raw,
    student_uuid character varying(36) ENCODE raw,
    school_uuid character varying(36) ENCODE raw,
    tenant_uuid character varying(36) ENCODE raw,
    grade_uuid character varying(36) ENCODE raw,
    subject_uuid character varying(36) ENCODE raw,
    section_uuid character varying(36) ENCODE raw,
    lo_uuid character varying(36) ENCODE raw,
    fco_answer_id character varying(36) ENCODE raw,
    fco_source character varying(256) ENCODE raw,
    fco_question character varying(6138) ENCODE lzo,
    fco_suggestions character varying(15000) ENCODE lzo,
    fco_answer character varying(3000) ENCODE lzo,
    fco_arabic_answer character varying(3000) ENCODE lzo,
    fco_learning_session_id character varying(36) ENCODE lzo,
    fco_subject_category character varying(256) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( school_uuid );
CREATE TABLE devcoredw_stage.staging_adt_lock_status (
    dw_id bigint ENCODE az64,
    _trace_id character varying(36) ENCODE lzo,
    event_type character varying(36) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    date_dw_id bigint ENCODE az64,
    id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    academic_year_tag character varying(10) ENCODE lzo,
    attempt_number bigint ENCODE az64,
    teacher_id character varying(36) ENCODE lzo,
    student_id character varying(36) ENCODE lzo distkey,
    school_id character varying(36) ENCODE lzo,
    class_id character varying(36) ENCODE lzo,
    adt_id character varying(36) ENCODE lzo,
    should_send_notification boolean ENCODE raw,
    _ingestion_type character varying(10) ENCODE lzo,
    source character varying(10) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_guardian_joint_activity (
    fgja_staging_id bigint identity(1,1) ENCODE raw,
    fgja_created_time timestamp without time zone ENCODE az64,
    fgja_dw_created_time timestamp without time zone ENCODE az64,
    fgja_date_dw_id bigint ENCODE az64,
    fgja_tenant_id character varying(256) ENCODE lzo,
    fgja_school_id character varying(256) ENCODE lzo,
    fgja_k12_grade integer ENCODE az64,
    fgja_class_id character varying(256) ENCODE lzo,
    fgja_student_id character varying(256) ENCODE lzo,
    fgja_guardian_id character varying(256) ENCODE lzo,
    fgja_pathway_id character varying(256) ENCODE lzo,
    fgja_pathway_level_id character varying(256) ENCODE lzo,
    fgja_attempt smallint ENCODE az64,
    fgja_rating smallint ENCODE az64,
    fgja_state smallint ENCODE az64
)
DISTSTYLE AUTO
SORTKEY ( fgja_staging_id );
CREATE TABLE devcoredw_stage.staging_student_proficiency_tracker (
    dw_id bigint ENCODE az64,
    event_type character varying(100) ENCODE lzo,
    _trace_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    date_dw_id bigint ENCODE az64,
    uuid character varying(36) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    student_id character varying(36) ENCODE lzo distkey,
    class_id character varying(36) ENCODE lzo,
    school_id character varying(36) ENCODE lzo,
    pathway_id character varying(36) ENCODE lzo,
    level_id character varying(36) ENCODE lzo,
    academic_year_tag character varying(40) ENCODE lzo,
    session_id character varying(36) ENCODE lzo,
    ml_session_id character varying(36) ENCODE lzo,
    level_proficiency_score double precision ENCODE raw,
    level_proficiency_tier character varying(50) ENCODE lzo,
    assessment_id character varying(36) ENCODE lzo,
    session_attempt integer ENCODE az64,
    stars integer ENCODE az64,
    time_spent integer ENCODE az64,
    skill_proficiency_tier character varying(40) ENCODE lzo,
    skill_proficiency_score double precision ENCODE raw,
    skill_id character varying(36) ENCODE lzo,
    status character varying(50) ENCODE lzo,
    previous_proficiency_tier character varying(50) ENCODE lzo,
    _ingestion_type character varying(10) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_interim_checkpoint_rules (
    rel_ic_rule_id bigint identity(1,1) ENCODE az64,
    ic_rule_created_time timestamp without time zone ENCODE az64,
    ic_rule_dw_created_time timestamp without time zone ENCODE az64,
    ic_rule_updated_time timestamp without time zone ENCODE az64,
    ic_rule_dw_updated_time timestamp without time zone ENCODE az64,
    ic_rule_status smallint ENCODE az64,
    ic_rule_attach_status smallint ENCODE az64,
    ic_rule_type smallint ENCODE az64,
    ic_rule_resource_type character varying(50) ENCODE lzo,
    ic_uuid character varying(36) ENCODE lzo,
    outcome_uuid character varying(36) ENCODE lzo,
    ic_rule_no_questions integer ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_pathway_target (
    pt_dw_id bigint ENCODE az64,
    pt_id character varying(36) ENCODE lzo,
    pt_created_time timestamp without time zone ENCODE az64,
    pt_dw_created_time timestamp without time zone ENCODE az64,
    pt_status integer ENCODE az64,
    pt_active_until timestamp without time zone ENCODE az64,
    pt_target_id character varying(36) ENCODE raw,
    pt_target_state character varying(20) ENCODE bytedict,
    pt_start_date character varying(10) ENCODE lzo,
    pt_end_date character varying(10) ENCODE lzo,
    pt_tenant_id character varying(36) ENCODE raw,
    pt_school_id character varying(36) ENCODE bytedict,
    pt_grade_id character varying(36) ENCODE bytedict,
    pt_class_id character varying(36) ENCODE lzo,
    pt_teacher_id character varying(36) ENCODE bytedict distkey,
    pt_pathway_id character varying(36) ENCODE bytedict
)
DISTSTYLE AUTO
SORTKEY ( pt_tenant_id );
CREATE TABLE devcoredw_stage.dim_course_activity_grade_association (
    caga_dw_id bigint ENCODE az64,
    caga_created_time timestamp without time zone ENCODE az64,
    caga_updated_time timestamp without time zone ENCODE az64,
    caga_deleted_time timestamp without time zone ENCODE az64,
    caga_dw_created_time timestamp without time zone ENCODE az64,
    caga_dw_updated_time timestamp without time zone ENCODE az64,
    caga_dw_deleted_time timestamp without time zone ENCODE az64,
    caga_status integer ENCODE az64,
    caga_course_dw_id bigint ENCODE az64,
    caga_course_id character varying(36) ENCODE lzo,
    caga_activity_dw_id bigint ENCODE az64,
    caga_activity_id character varying(36) ENCODE lzo,
    caga_grade_id bigint ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_assignment_instance_student (
    rel_ais_id bigint identity(1,1) ENCODE az64,
    ais_created_time timestamp without time zone ENCODE az64,
    ais_dw_created_time timestamp without time zone ENCODE az64,
    ais_updated_time timestamp without time zone ENCODE az64,
    ais_dw_updated_time timestamp without time zone ENCODE az64,
    ais_deleted_time timestamp without time zone ENCODE az64,
    ais_status integer ENCODE az64,
    ais_instance_id character varying(36) ENCODE lzo,
    ais_student_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_school_content_repository_association (
    scra_dw_id bigint ENCODE az64,
    scra_school_id character varying(36) ENCODE lzo,
    scra_content_repository_id character varying(36) ENCODE lzo,
    scra_status integer ENCODE az64,
    scra_active_until timestamp without time zone ENCODE az64,
    scra_created_time timestamp without time zone ENCODE az64,
    scra_dw_created_time timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_assignment_instance (
    assignment_instance_staging_id bigint identity(1,1) ENCODE az64,
    assignment_instance_created_time timestamp without time zone ENCODE az64,
    assignment_instance_updated_time timestamp without time zone ENCODE az64,
    assignment_instance_deleted_time timestamp without time zone ENCODE az64,
    assignment_instance_dw_created_time timestamp without time zone ENCODE az64,
    assignment_instance_dw_updated_time timestamp without time zone ENCODE az64,
    assignment_instance_id character varying(36) ENCODE lzo,
    assignment_instance_instructional_plan_id character varying(36) ENCODE lzo,
    assignment_uuid character varying(36) ENCODE lzo,
    assignment_instance_due_on timestamp without time zone ENCODE az64,
    assignment_instance_allow_late_submission boolean ENCODE raw,
    teacher_uuid character varying(36) ENCODE lzo,
    assignment_instance_type character varying(10) ENCODE lzo,
    grade_uuid character varying(36) ENCODE raw,
    subject_uuid character varying(36) ENCODE lzo,
    class_uuid character varying(36) ENCODE raw,
    learning_path_uuid character varying(36) ENCODE lzo,
    lo_uuid character varying(36) ENCODE lzo,
    section_uuid character varying(36) ENCODE lzo,
    assignment_instance_start_on timestamp without time zone ENCODE az64,
    assignment_instance_status integer ENCODE az64,
    student_uuid character varying(36) ENCODE raw,
    tenant_uuid character varying(36) ENCODE lzo,
    assignment_instance_trimester_id character varying(36) ENCODE lzo,
    assignment_instance_teaching_period_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( grade_uuid, class_uuid, student_uuid );
CREATE TABLE devcoredw_stage.rel_dw_id_mappings (
    dw_id bigint identity(1,1) ENCODE az64,
    id character varying(36) ENCODE lzo distkey,
    entity_type character varying(50) ENCODE raw,
    entity_dw_created_time timestamp without time zone ENCODE az64,
    entity_created_time timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO
SORTKEY ( entity_type );
CREATE TABLE devcoredw_stage.staging_assessment_lock_action (
    dw_id bigint ENCODE az64,
    _trace_id character varying(36) ENCODE lzo,
    event_type character varying(36) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    date_dw_id bigint ENCODE az64,
    id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    academic_year_tag character varying(10) ENCODE lzo,
    attempt bigint ENCODE az64,
    teacher_id character varying(36) ENCODE lzo distkey,
    candidate_id character varying(36) ENCODE lzo,
    school_id character varying(36) ENCODE lzo,
    class_id character varying(36) ENCODE lzo,
    test_part_session_id character varying(36) ENCODE lzo,
    test_level_name character varying(20) ENCODE lzo,
    test_level_id character varying(36) ENCODE lzo,
    test_level_version bigint ENCODE az64,
    skill character varying(50) ENCODE lzo,
    subject character varying(50) ENCODE lzo,
    _ingestion_type character varying(10) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_course (
    rel_course_dw_id bigint ENCODE az64,
    course_type character varying(25) ENCODE lzo,
    course_id character varying(36) ENCODE lzo,
    course_status integer ENCODE az64,
    course_name character varying(255) ENCODE lzo,
    course_code character varying(50) ENCODE lzo,
    course_subject_id integer ENCODE az64,
    course_organization character varying(50) ENCODE lzo,
    course_created_time timestamp without time zone ENCODE az64,
    course_deleted_time timestamp without time zone ENCODE az64,
    course_updated_time timestamp without time zone ENCODE az64,
    course_dw_created_time timestamp without time zone ENCODE az64,
    course_dw_updated_time timestamp without time zone ENCODE az64,
    course_dw_deleted_time timestamp without time zone ENCODE az64,
    course_lang_code character varying(10) ENCODE lzo,
    course_program_enabled boolean ENCODE raw,
    course_resources_enabled boolean ENCODE raw,
    course_placement_type character varying(50) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_activity_setting (
    fas_activity_id character varying(36) ENCODE lzo,
    fas_class_id character varying(36) ENCODE lzo,
    fas_created_time timestamp without time zone ENCODE az64,
    fas_dw_created_time timestamp without time zone ENCODE az64,
    fas_dw_id bigint ENCODE az64,
    fas_grade_id character varying(36) ENCODE lzo,
    fas_k12_grade integer ENCODE az64,
    fas_open_path_enabled boolean ENCODE raw,
    fas_school_id character varying(36) ENCODE lzo,
    fas_class_gen_subject_name character varying(50) ENCODE lzo,
    fas_teacher_id character varying(36) ENCODE lzo,
    fas_tenant_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_item_transaction (
    fit_dw_id bigint ENCODE az64,
    fit_created_time timestamp without time zone ENCODE az64,
    fit_dw_created_time timestamp without time zone ENCODE az64,
    fit_date_dw_id bigint ENCODE az64,
    fit_id character varying(36) ENCODE lzo,
    fit_available_stars integer ENCODE az64,
    fit_item_cost integer ENCODE az64,
    fit_star_balance integer ENCODE az64,
    fit_item_id character varying(36) ENCODE lzo,
    fit_item_type character varying(50) ENCODE lzo,
    fit_student_id character varying(36) ENCODE lzo,
    fit_tenant_id character varying(36) ENCODE lzo,
    fit_school_id character varying(36) ENCODE lzo,
    fit_grade_id character varying(36) ENCODE lzo,
    fit_section_id character varying(36) ENCODE lzo,
    fit_academic_year_id character varying(36) ENCODE lzo,
    fit_academic_year integer ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.example_table (
    id integer ENCODE az64,
    data super
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_announcement (
    rel_announcement_dw_id bigint identity(1,1) ENCODE az64,
    announcement_created_time timestamp without time zone ENCODE az64,
    announcement_deleted_time timestamp without time zone ENCODE az64,
    announcement_updated_time timestamp without time zone ENCODE az64,
    announcement_dw_created_time timestamp without time zone ENCODE az64,
    announcement_dw_updated_time timestamp without time zone ENCODE az64,
    announcement_status integer ENCODE az64,
    announcement_tenant_id character varying(36) ENCODE lzo,
    announcement_id character varying(36) ENCODE lzo,
    announcement_admin_id character varying(36) ENCODE lzo,
    announcement_role_id character varying(36) ENCODE lzo,
    announcement_recipient_type integer ENCODE az64,
    announcement_recipient_id character varying(36) ENCODE lzo,
    announcement_has_attachment boolean ENCODE raw
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_pathway_placement (
    fpp_staging_id bigint identity(1,1) ENCODE az64 distkey,
    fpp_created_time timestamp without time zone ENCODE raw,
    fpp_dw_created_time timestamp without time zone ENCODE az64,
    fpp_date_dw_id bigint ENCODE az64,
    fpp_previous_pathway_domain character varying(100) ENCODE bytedict,
    fpp_pathway_id character varying(36) ENCODE bytedict,
    fpp_new_pathway_domain character varying(100) ENCODE bytedict,
    fpp_new_pathway_grade integer ENCODE az64,
    fpp_class_id character varying(36) ENCODE bytedict,
    fpp_student_id character varying(36) ENCODE lzo,
    fpp_previous_pathway_grade integer ENCODE az64,
    fpp_tenant_id character varying(36) ENCODE lzo,
    fpp_placement_type integer ENCODE az64,
    fpp_overall_grade integer ENCODE az64,
    fpp_created_by character varying(36) ENCODE bytedict,
    fpp_is_initial boolean DEFAULT true ENCODE raw,
    fpp_has_accelerated_domains boolean ENCODE raw,
    fpp_academic_year_tag character varying(40) ENCODE lzo
)
DISTSTYLE KEY
SORTKEY ( fpp_created_time );
CREATE TABLE devcoredw_stage.rel_course_activity_container_domain (
    cacd_dw_id bigint ENCODE az64,
    cacd_container_id character varying(36) ENCODE lzo,
    cacd_course_id character varying(36) ENCODE lzo,
    cacd_domain character varying(50) ENCODE lzo,
    cacd_sequence integer ENCODE az64,
    cacd_created_time timestamp without time zone ENCODE az64,
    cacd_dw_created_time timestamp without time zone ENCODE az64,
    cacd_updated_time timestamp without time zone ENCODE az64,
    cacd_dw_updated_time timestamp without time zone ENCODE az64,
    cacd_status integer ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_practice_session (
    practice_session_staging_id bigint identity(1,1) ENCODE az64,
    practice_session_created_time timestamp without time zone ENCODE az64,
    practice_session_dw_created_time timestamp without time zone ENCODE az64,
    practice_session_date_dw_id integer ENCODE bytedict,
    practice_session_id character varying(36) ENCODE lzo,
    lo_uuid character varying(36) ENCODE lzo,
    student_uuid character varying(36) ENCODE raw,
    subject_uuid character varying(36) ENCODE runlength,
    grade_uuid character varying(36) ENCODE raw,
    tenant_uuid character varying(36) ENCODE lzo,
    school_uuid character varying(36) ENCODE raw,
    section_uuid character varying(36) ENCODE raw,
    practice_session_sa_score numeric(10,4) ENCODE az64,
    practice_session_item_lo_uuid character varying(36) DEFAULT 'n/a'::character varying ENCODE lzo,
    practice_session_item_step_id character varying(36) DEFAULT 'n/a'::character varying ENCODE lzo,
    practice_session_item_content_title character varying(100) DEFAULT 'n/a'::character varying ENCODE lzo,
    practice_session_item_content_lesson_type character varying(50) DEFAULT 'n/a'::character varying ENCODE lzo,
    practice_session_item_content_location character varying(200) DEFAULT 'n/a'::character varying ENCODE lzo,
    practice_session_score numeric(10,4) ENCODE az64,
    practice_session_event_type integer ENCODE az64,
    practice_session_is_start boolean DEFAULT false ENCODE raw,
    practice_session_is_start_event_processed boolean DEFAULT false ENCODE raw,
    practice_session_outside_of_school boolean ENCODE raw,
    practice_session_stars integer ENCODE az64,
    academic_year_uuid character varying(256) ENCODE lzo,
    practice_session_instructional_plan_id character varying(36) ENCODE lzo,
    practice_session_learning_path_id character varying(36) ENCODE lzo,
    class_uuid character varying(36) ENCODE lzo,
    practice_session_item_content_uuid character varying(36) DEFAULT 'n/a'::character varying ENCODE lzo,
    practice_session_material_id character varying(36) ENCODE lzo,
    practice_session_material_type character varying(20) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( school_uuid, grade_uuid, section_uuid, student_uuid );
CREATE TABLE devcoredw_stage.rel_course_grade_association (
    cg_dw_id bigint ENCODE az64,
    cg_course_id character varying(36) ENCODE lzo,
    cg_grade_id integer ENCODE az64,
    cg_status integer ENCODE az64,
    cg_created_time timestamp without time zone ENCODE az64,
    cg_dw_created_time timestamp without time zone ENCODE az64,
    cg_updated_time timestamp without time zone ENCODE az64,
    cg_dw_updated_time timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_ktgskipped (
    ktgskipped_staging_id bigint identity(1,1) ENCODE lzo,
    ktgskipped_created_time timestamp without time zone ENCODE lzo,
    ktgskipped_dw_created_time timestamp without time zone ENCODE lzo,
    ktgskipped_date_dw_id bigint ENCODE lzo,
    tenant_uuid character varying(36) ENCODE lzo,
    student_uuid character varying(36) ENCODE lzo distkey,
    subject_uuid character varying(36) ENCODE lzo,
    school_uuid character varying(36) ENCODE lzo,
    grade_uuid character varying(36) ENCODE lzo,
    section_uuid character varying(36) ENCODE lzo,
    lo_uuid character varying(36) ENCODE lzo,
    academic_year_uuid character varying(36) ENCODE lzo,
    ktgskipped_num_key_terms smallint ENCODE lzo,
    ktgskipped_kt_collection_id bigint ENCODE lzo,
    ktgskipped_trimester_id character varying(256) ENCODE lzo,
    ktgskipped_trimester_order smallint ENCODE lzo,
    ktgskipped_type character varying(200) ENCODE lzo,
    ktgskipped_min_question smallint ENCODE lzo,
    ktgskipped_max_question smallint ENCODE lzo,
    ktgskipped_question_type character varying(1000) ENCODE lzo,
    ktgskipped_question_time_allotted integer ENCODE lzo,
    ktgskipped_instructional_plan_id character varying(36) ENCODE lzo,
    ktgskipped_learning_path_id character varying(36) ENCODE lzo,
    class_uuid character varying(36) ENCODE lzo,
    ktgskipped_material_id character varying(36) ENCODE lzo,
    ktgskipped_material_type character varying(20) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.flyway_schema_history (
    installed_rank integer ENCODE az64,
    version character varying(50) ENCODE lzo,
    description character varying(200) ENCODE lzo,
    type character varying(20) ENCODE lzo,
    script character varying(1000) ENCODE lzo,
    checksum integer ENCODE az64,
    installed_by character varying(100) ENCODE lzo,
    installed_on timestamp without time zone ENCODE az64,
    execution_time integer ENCODE az64,
    success boolean ENCODE raw
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_course_content_repository_association (
    ccr_dw_id bigint ENCODE az64,
    ccr_course_id character varying(36) ENCODE lzo,
    ccr_repository_id character varying(36) ENCODE lzo,
    ccr_status integer ENCODE az64,
    ccr_created_time timestamp without time zone ENCODE az64,
    ccr_updated_time timestamp without time zone ENCODE az64,
    ccr_deleted_time timestamp without time zone ENCODE az64,
    ccr_dw_created_time timestamp without time zone ENCODE az64,
    ccr_dw_updated_time timestamp without time zone ENCODE az64,
    ccr_course_type character varying(50) ENCODE lzo,
    ccr_attach_status integer ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_assignment_submission (
    assignment_submission_staging_id bigint identity(1,1) ENCODE az64,
    assignment_submission_id character varying(36) ENCODE lzo,
    assignment_submission_assignment_id character varying(36) ENCODE lzo,
    assignment_submission_referrer_id character varying(36) ENCODE lzo,
    assignment_submission_type character varying(100) ENCODE lzo,
    assignment_submission_updated_on timestamp without time zone ENCODE az64,
    assignment_submission_returned_on timestamp without time zone ENCODE az64,
    assignment_submission_submitted_on timestamp without time zone ENCODE az64,
    assignment_submission_graded_on timestamp without time zone ENCODE az64,
    assignment_submission_evaluated_on timestamp without time zone ENCODE az64,
    assignment_submission_status character varying(20) ENCODE lzo,
    assignment_submission_student_attachment_file_name character varying(200) ENCODE lzo,
    assignment_submission_student_attachment_path character varying(200) ENCODE lzo,
    assignment_submission_teacher_attachment_path character varying(200) ENCODE lzo,
    assignment_submission_teacher_attachment_file_name character varying(200) ENCODE lzo,
    assignment_submission_teacher_score double precision ENCODE raw,
    assignment_submission_date_dw_id character varying(36) ENCODE lzo,
    assignment_submission_created_time timestamp without time zone ENCODE az64,
    assignment_submission_dw_created_time timestamp without time zone ENCODE az64,
    assignment_submission_has_teacher_comment boolean ENCODE raw,
    assignment_submission_has_student_comment boolean ENCODE raw,
    assignment_submission_assignment_instance_id character varying(36) ENCODE lzo,
    assignment_submission_student_id character varying(36) ENCODE lzo,
    assignment_submission_teacher_id character varying(36) ENCODE lzo,
    assignment_submission_tenant_id character varying(36) ENCODE lzo,
    eventdate date ENCODE az64,
    assignment_submission_resubmission_count integer ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_tutor_analogous (
    fta_dw_id bigint ENCODE az64,
    fta_created_time timestamp without time zone ENCODE az64,
    fta_dw_created_time timestamp without time zone ENCODE az64,
    fta_date_dw_id bigint ENCODE az64,
    fta_user_id character varying(36) ENCODE lzo,
    fta_tenant_id character varying(36) ENCODE lzo,
    fta_message_id character varying(36) ENCODE lzo,
    fta_session_id character varying(36) ENCODE lzo,
    fta_conversation_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_user_heartbeat_hourly_aggregated (
    fuhha_staging_id bigint identity(1,1) ENCODE raw,
    fuhha_created_time timestamp without time zone ENCODE az64,
    fuhha_dw_created_time timestamp without time zone ENCODE az64,
    fuhha_date_dw_id bigint ENCODE az64,
    fuhha_role character varying(36) ENCODE lzo,
    fuhha_channel character varying(36) ENCODE lzo,
    fuhha_activity_date_hour timestamp without time zone ENCODE az64,
    fuhha_tenant_id character varying(36) ENCODE lzo,
    fuhha_user_id character varying(36) ENCODE lzo,
    fuhha_dw_updated_time timestamp without time zone ENCODE az64,
    fuhha_school_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( fuhha_staging_id );
CREATE TABLE devcoredw_stage.rel_assignment (
    rel_assignment_id bigint identity(1,1) ENCODE az64,
    assignment_created_time timestamp without time zone ENCODE az64,
    assignment_updated_time timestamp without time zone ENCODE az64,
    assignment_deleted_time timestamp without time zone ENCODE az64,
    assignment_dw_created_time timestamp without time zone ENCODE az64,
    assignment_dw_updated_time timestamp without time zone ENCODE az64,
    assignment_id character varying(36) ENCODE lzo,
    assignment_title character varying(100) ENCODE lzo,
    assignment_description character varying(250) ENCODE lzo,
    assignment_max_score numeric(10,4) ENCODE az64,
    assignment_attachment_file_id character varying(100) ENCODE lzo,
    assignment_attachment_file_name character varying(100) ENCODE lzo,
    assignment_attachment_path character varying(200) ENCODE lzo,
    assignment_allow_submission boolean ENCODE raw,
    assignment_language character varying(36) ENCODE lzo,
    assignment_status integer ENCODE az64,
    assignment_is_gradeable boolean ENCODE raw,
    assignment_assignment_status character varying(36) ENCODE lzo,
    assignment_created_by character varying(36) ENCODE lzo,
    assignment_updated_by character varying(36) ENCODE lzo,
    assignment_published_on timestamp without time zone ENCODE az64,
    assignment_attachment_required boolean ENCODE raw,
    assignment_comment_required boolean ENCODE raw,
    assignment_type character varying(36) ENCODE lzo,
    assignment_metadata_author character varying(36) ENCODE lzo,
    assignment_metadata_is_sa boolean ENCODE raw,
    assignment_metadata_authored_date character varying(36) ENCODE lzo,
    assignment_metadata_language character varying(36) ENCODE lzo,
    assignment_metadata_format_type character varying(36) ENCODE lzo,
    assignment_metadata_lexile_level character varying(36) ENCODE lzo,
    assignment_metadata_difficulty_level character varying(36) ENCODE lzo,
    assignment_metadata_resource_type character varying(36) ENCODE lzo,
    assignment_metadata_knowledge_dimensions character varying(36) ENCODE lzo,
    assignment_school_id character varying(36) ENCODE lzo,
    assignment_tenant_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_pathway_teacher_activity (
    fpta_dw_id bigint ENCODE az64,
    fpta_created_time timestamp without time zone ENCODE az64,
    fpta_dw_created_time timestamp without time zone ENCODE az64,
    fpta_date_dw_id bigint ENCODE az64,
    fpta_student_id character varying(36) ENCODE lzo,
    fpta_level_id character varying(36) ENCODE lzo,
    fpta_pathway_id character varying(36) ENCODE lzo,
    fpta_tenant_id character varying(36) ENCODE lzo,
    fpta_action_name character varying(255) ENCODE lzo,
    fpta_class_id character varying(36) ENCODE lzo,
    fpta_teacher_id character varying(36) ENCODE lzo,
    fpta_activity_id character varying(36) ENCODE lzo,
    fpta_action_time timestamp without time zone ENCODE az64,
    fpta_activity_type integer ENCODE az64,
    fpta_start_date date ENCODE az64,
    fpta_end_date date ENCODE az64,
    fpta_activity_progress_status character varying(30) ENCODE lzo,
    fpta_activity_type_value character varying(50) ENCODE lzo,
    fpta_is_added_as_resource boolean DEFAULT false ENCODE raw
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_tutor_simplification (
    fts_dw_id bigint ENCODE az64,
    fts_created_time timestamp without time zone ENCODE az64,
    fts_dw_created_time timestamp without time zone ENCODE az64,
    fts_date_dw_id bigint ENCODE az64,
    fts_user_id character varying(36) ENCODE lzo,
    fts_tenant_id character varying(36) ENCODE lzo,
    fts_message_id character varying(36) ENCODE lzo,
    fts_session_id character varying(36) ENCODE lzo,
    fts_conversation_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_star_awarded (
    fsa_staging_id bigint identity(1,1) ENCODE raw,
    fsa_created_time timestamp without time zone ENCODE raw,
    fsa_dw_created_time timestamp without time zone ENCODE raw,
    fsa_date_dw_id bigint ENCODE raw,
    fsa_id character varying(36) ENCODE raw,
    award_category_uuid character varying(36) ENCODE raw,
    student_uuid character varying(36) ENCODE raw,
    tenant_uuid character varying(36) ENCODE raw,
    school_uuid character varying(36) ENCODE raw,
    subject_uuid character varying(36) ENCODE raw,
    teacher_uuid character varying(36) ENCODE raw,
    grade_uuid character varying(36) ENCODE raw,
    fsa_award_comments boolean ENCODE raw,
    academic_year_uuid character varying(256) ENCODE lzo,
    class_uuid character varying(36) ENCODE lzo,
    fsa_stars integer ENCODE az64
)
DISTSTYLE AUTO
SORTKEY ( school_uuid, subject_uuid );
CREATE TABLE devcoredw_stage.temp_practice_session (
    practice_session_staging_id bigint ENCODE lzo,
    practice_session_created_time timestamp without time zone ENCODE lzo,
    practice_session_dw_created_time timestamp without time zone ENCODE lzo,
    practice_session_date_dw_id integer ENCODE lzo,
    practice_session_id character varying(36) ENCODE lzo,
    lo_uuid character varying(36) ENCODE lzo,
    student_uuid character varying(36) ENCODE lzo,
    subject_uuid character varying(36) ENCODE lzo,
    grade_uuid character varying(36) ENCODE lzo,
    tenant_uuid character varying(36) ENCODE lzo,
    school_uuid character varying(36) ENCODE lzo,
    class_uuid character varying(36) ENCODE lzo,
    skill_uuid character varying(36) ENCODE lzo,
    practice_session_sa_score bigint ENCODE lzo,
    practice_session_item_lo_uuid character varying(36) ENCODE lzo,
    practice_session_item_skill_uuid character varying(36) ENCODE lzo,
    practice_session_item_content_uuid character varying(36) ENCODE lzo,
    practice_session_item_content_title character varying(100) ENCODE lzo,
    practice_session_item_content_lesson_type character varying(50) ENCODE lzo,
    practice_session_item_content_location character varying(200) ENCODE lzo,
    practice_session_score bigint ENCODE lzo,
    practice_session_event_type integer ENCODE lzo,
    practice_session_is_start boolean ENCODE raw,
    practice_session_is_start_event_processed boolean ENCODE raw
)
DISTSTYLE EVEN;
CREATE TABLE devcoredw_stage.staging_practice (
    practice_staging_id bigint ENCODE az64,
    practice_created_time timestamp without time zone ENCODE az64,
    practice_dw_created_time timestamp without time zone ENCODE az64,
    practice_date_dw_id integer ENCODE az64,
    practice_id character varying(36) ENCODE lzo,
    lo_uuid character varying(36) ENCODE lzo,
    student_uuid character varying(36) ENCODE lzo,
    subject_uuid character varying(36) ENCODE lzo,
    grade_uuid character varying(36) ENCODE lzo,
    tenant_uuid character varying(36) ENCODE lzo,
    school_uuid character varying(36) ENCODE lzo,
    section_uuid character varying(36) ENCODE lzo,
    skill_uuid character varying(36) ENCODE lzo,
    practice_sa_score numeric(10,4) ENCODE az64,
    item_lo_uuid character varying(36) ENCODE lzo,
    item_skill_uuid character varying(36) ENCODE lzo,
    practice_item_step_id character varying(36) ENCODE lzo,
    practice_item_content_title character varying(100) ENCODE lzo,
    practice_item_content_lesson_type character varying(50) ENCODE lzo,
    practice_item_content_location character varying(200) ENCODE lzo,
    academic_year_uuid character varying(256) ENCODE lzo,
    practice_instructional_plan_id character varying(36) ENCODE lzo,
    practice_learning_path_id character varying(36) ENCODE lzo,
    class_uuid character varying(36) ENCODE lzo,
    practice_material_id character varying(36) ENCODE lzo,
    practice_material_type character varying(20) ENCODE lzo,
    section_uuid_new character varying(144) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_content_repository_material_association_a (
    rel_crma_dw_id bigint identity(1,1) ENCODE az64 distkey,
    crma_content_repository_id character varying(36) ENCODE lzo,
    crma_material_id character varying(36) ENCODE lzo,
    crma_status integer ENCODE az64,
    crma_type integer ENCODE az64,
    crma_attach_status integer ENCODE az64,
    crma_created_time timestamp without time zone ENCODE raw,
    crma_dw_created_time timestamp without time zone ENCODE az64,
    crma_updated_time timestamp without time zone ENCODE az64,
    crma_dw_updated_time timestamp without time zone ENCODE az64
)
DISTSTYLE KEY
SORTKEY ( crma_created_time );
CREATE TABLE devcoredw_stage.staging_inc_game (
    inc_game_staging_id bigint identity(1,1) ENCODE lzo,
    inc_game_id character varying(36) ENCODE lzo,
    inc_game_event_type integer ENCODE lzo,
    inc_game_created_time timestamp without time zone ENCODE lzo,
    inc_game_dw_created_time timestamp without time zone ENCODE lzo,
    inc_game_date_dw_id bigint ENCODE lzo,
    tenant_uuid character varying(36) ENCODE lzo,
    school_uuid character varying(36) ENCODE lzo,
    section_uuid character varying(36) ENCODE lzo,
    lo_uuid character varying(36) ENCODE lzo,
    inc_game_title character varying(256) ENCODE lzo,
    teacher_uuid character varying(36) ENCODE lzo,
    subject_uuid character varying(36) ENCODE lzo,
    grade_uuid character varying(36) ENCODE lzo,
    learning_path_uuid character varying(36) ENCODE lzo,
    inc_game_num_questions integer ENCODE lzo,
    inc_game_instructional_plan_id character varying(36) ENCODE lzo,
    class_uuid character varying(36) ENCODE lzo,
    inc_game_is_assessment boolean DEFAULT false ENCODE raw,
    inc_game_lesson_component_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_guardian (
    rel_guardian_dw_id bigint ENCODE az64,
    guardian_created_time timestamp without time zone ENCODE az64,
    guardian_updated_time timestamp without time zone ENCODE az64,
    guardian_deleted_time timestamp without time zone ENCODE az64,
    guardian_dw_created_time timestamp without time zone ENCODE az64,
    guardian_dw_updated_time timestamp without time zone ENCODE az64,
    guardian_active_until timestamp without time zone ENCODE az64,
    guardian_status integer ENCODE az64,
    guardian_id character varying(36) ENCODE lzo,
    student_id character varying(36) ENCODE raw distkey,
    guardian_invitation_status integer ENCODE az64
)
DISTSTYLE AUTO
SORTKEY ( student_id );
CREATE TABLE devcoredw_stage.staging_tutor_session (
    fts_dw_id bigint identity(1,1) ENCODE raw,
    fts_created_time timestamp without time zone ENCODE az64,
    fts_dw_created_time timestamp without time zone ENCODE az64,
    fts_date_dw_id bigint ENCODE az64,
    fts_session_id character varying(36) ENCODE lzo,
    fts_tenant_id character varying(36) ENCODE lzo,
    fts_school_id character varying(36) ENCODE lzo,
    fts_user_id character varying(36) ENCODE lzo,
    fts_grade_id character varying(36) ENCODE lzo,
    fts_context_id character varying(36) ENCODE lzo,
    fts_role character varying(20) ENCODE lzo,
    fts_grade integer ENCODE az64,
    fts_subject_id character varying(36) ENCODE lzo,
    fts_subject character varying(20) ENCODE lzo,
    fts_language character varying(20) ENCODE lzo,
    fts_session_state character varying(20) ENCODE lzo,
    fts_activity_id character varying(36) ENCODE lzo,
    fts_activity_status character varying(20) ENCODE lzo,
    fts_material_id character varying(36) ENCODE lzo,
    fts_material_type character varying(20) ENCODE lzo,
    fts_level_id character varying(36) ENCODE lzo,
    fts_outcome_id character varying(36) ENCODE lzo,
    fts_session_message_limit_reached boolean ENCODE raw,
    fts_learning_session_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( fts_dw_id );
CREATE TABLE devcoredw_stage.rel_question (
    rel_question_id bigint identity(1,1) ENCODE raw,
    question_created_time timestamp without time zone ENCODE az64,
    question_updated_time timestamp without time zone ENCODE az64,
    question_deleted_time timestamp without time zone ENCODE az64,
    question_dw_created_time timestamp without time zone ENCODE az64,
    question_dw_updated_time timestamp without time zone ENCODE az64,
    question_status integer ENCODE az64,
    question_id character varying(36) ENCODE lzo,
    question_code character varying(128) ENCODE lzo,
    question_triggered_by character varying(50) ENCODE lzo,
    question_language character varying(50) ENCODE lzo,
    question_type character varying(50) ENCODE lzo,
    question_max_score double precision ENCODE raw,
    question_version integer ENCODE az64,
    question_stage character varying(50) ENCODE lzo,
    question_variant character varying(5) ENCODE lzo,
    question_active_until timestamp without time zone ENCODE az64,
    question_format_type character varying(30) ENCODE lzo,
    question_resource_type character varying(10) ENCODE lzo,
    question_summative_assessment boolean ENCODE raw,
    question_difficulty_level character varying(50) ENCODE lzo,
    question_knowledge_dimensions character varying(128) ENCODE lzo,
    question_lexile_level character varying(36) ENCODE lzo,
    question_author character varying(70) ENCODE lzo,
    question_authored_date timestamp without time zone ENCODE az64,
    question_skill_id character varying(36) ENCODE lzo,
    question_cefr_level character varying(50) ENCODE lzo,
    question_proficiency character varying(50) ENCODE lzo
)
DISTSTYLE ALL
SORTKEY ( rel_question_id );
CREATE TABLE devcoredw_stage.staging_adt_next_question (
    fanq_staging_id bigint identity(1,1) ENCODE az64,
    fanq_created_time timestamp without time zone ENCODE az64,
    fanq_dw_created_time timestamp without time zone ENCODE az64,
    fanq_date_dw_id bigint ENCODE raw distkey,
    fanq_id character varying(36) ENCODE lzo,
    fle_ls_uuid character varying(36) ENCODE lzo,
    student_uuid character varying(36) ENCODE lzo,
    fanq_question_pool_id character varying(36) ENCODE lzo,
    tenant_uuid character varying(36) ENCODE lzo,
    fanq_response boolean ENCODE raw,
    fanq_proficiency double precision ENCODE raw,
    fanq_next_question_id character varying(4000) ENCODE lzo,
    fanq_time_spent double precision ENCODE raw,
    fanq_current_question_id character varying(1000) ENCODE lzo,
    fanq_intest_progress double precision ENCODE raw,
    fanq_status integer ENCODE az64,
    fanq_curriculum_subject_id integer ENCODE az64,
    fanq_curriculum_subject_name character varying(36) ENCODE lzo,
    fanq_language character varying(50) ENCODE lzo,
    fanq_standard_error double precision ENCODE raw,
    fanq_attempt integer ENCODE az64,
    school_uuid character varying(36) ENCODE lzo,
    fanq_grade integer ENCODE az64,
    fanq_grade_id character varying(36) ENCODE lzo,
    fanq_academic_year integer ENCODE az64,
    fanq_academic_year_id character varying(36) ENCODE lzo,
    fanq_academic_term smallint ENCODE az64,
    fanq_class_subject_name character varying(64) ENCODE lzo,
    fanq_skill character varying(20) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( fanq_date_dw_id );
CREATE TABLE devcoredw_stage.staging_teacher_activities (
    fta_staging_id bigint identity(1,1) ENCODE raw,
    fta_created_time timestamp without time zone ENCODE raw,
    fta_dw_created_time timestamp without time zone ENCODE raw,
    fta_actor_object_type character varying(100) ENCODE raw,
    fta_actor_account_homepage character varying(100) ENCODE raw,
    fta_verb_id character varying(100) ENCODE raw,
    fta_verb_display character varying(100) ENCODE raw,
    fta_object_id character varying(2000) ENCODE raw,
    fta_object_type character varying(100) ENCODE raw,
    fta_object_definition_type character varying(100) ENCODE raw,
    fta_object_definition_name character varying(2000) ENCODE raw,
    fta_context_category character varying(100) ENCODE raw,
    fta_outside_of_school boolean ENCODE raw,
    fta_event_type character varying(100) ENCODE raw,
    fta_prev_event_type character varying(100) ENCODE raw,
    fta_next_event_type character varying(100) ENCODE raw,
    fta_date_dw_id bigint ENCODE raw,
    tenant_uuid character varying(36) ENCODE raw,
    school_uuid character varying(36) ENCODE raw,
    grade_uuid character varying(36) ENCODE raw,
    section_uuid character varying(36) ENCODE raw,
    subject_uuid character varying(36) ENCODE raw,
    teacher_uuid character varying(36) ENCODE raw distkey,
    fta_start_time timestamp without time zone ENCODE raw,
    fta_end_time timestamp without time zone ENCODE raw,
    fta_timestamp_local character varying(100) ENCODE raw,
    fta_time_spent double precision ENCODE raw
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_student_slide_progress (
    dw_id bigint ENCODE az64,
    event_type character varying(100) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    _trace_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    date_dw_id bigint ENCODE az64,
    experience_id character varying(36) ENCODE lzo,
    learning_session_id character varying(36) ENCODE lzo,
    content_section_id character varying(36) ENCODE lzo,
    slide_id character varying(36) ENCODE lzo,
    widget_id character varying(50) ENCODE lzo,
    status character varying(20) ENCODE lzo,
    active_time integer ENCODE az64,
    idle_time integer ENCODE az64,
    total_time_spent integer ENCODE az64,
    result character varying(20) ENCODE lzo,
    attempt integer ENCODE az64,
    student_id character varying(36) ENCODE lzo distkey,
    school_id character varying(36) ENCODE lzo,
    grade_id character varying(36) ENCODE lzo,
    student_section_id character varying(36) ENCODE lzo,
    class_id character varying(36) ENCODE lzo,
    activity_id character varying(36) ENCODE lzo,
    academic_year_tag character varying(20) ENCODE lzo,
    material_id character varying(36) ENCODE lzo,
    material_type character varying(20) ENCODE lzo,
    ccl_content_id bigint ENCODE az64,
    channel character varying(50) ENCODE lzo,
    _ingestion_type character varying(10) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_student_queries_copy_jyo (
    dw_id bigint ENCODE az64,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    date_dw_id bigint ENCODE az64,
    _trace_id character varying(36) ENCODE lzo,
    event_type character varying(36) ENCODE lzo,
    message_id character varying(36) ENCODE lzo,
    query_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    school_id character varying(36) ENCODE lzo,
    grade_id character varying(36) ENCODE lzo,
    class_id character varying(36) ENCODE lzo,
    section_id character varying(36) ENCODE lzo,
    teacher_id character varying(36) ENCODE lzo,
    academic_year_id character varying(36) ENCODE lzo,
    student_id character varying(36) ENCODE lzo,
    mlo_id character varying(36) ENCODE lzo,
    activity_id character varying(36) ENCODE lzo,
    activity_title character varying(100) ENCODE lzo,
    activity_type character varying(100) ENCODE lzo,
    can_student_reply boolean ENCODE raw,
    with_audio boolean ENCODE raw,
    with_text boolean ENCODE raw,
    material_type character varying(100) ENCODE lzo,
    crumb_title character varying(100) ENCODE lzo,
    gen_subject character varying(100) ENCODE lzo,
    lang_code character varying(100) ENCODE lzo,
    is_follow_up boolean ENCODE raw,
    has_screenshot boolean ENCODE raw
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_pacing_guide (
    pacing_id character varying(36) ENCODE lzo,
    pacing_dw_id bigint ENCODE az64,
    pacing_course_id character varying(36) ENCODE bytedict,
    pacing_class_id character varying(36) ENCODE lzo,
    pacing_academic_calendar_id character varying(36) ENCODE lzo,
    pacing_academic_year_id character varying(36) ENCODE lzo,
    pacing_activity_id character varying(36) ENCODE lzo,
    pacing_tenant_id character varying(36) ENCODE lzo,
    pacing_status integer ENCODE az64,
    pacing_activity_order integer ENCODE az64,
    pacing_ip_id character varying(36) ENCODE lzo,
    pacing_period_start_date date ENCODE az64,
    pacing_period_label character varying(25) ENCODE lzo,
    pacing_period_id character varying(36) ENCODE lzo,
    pacing_period_end_date date ENCODE az64,
    pacing_interval_id character varying(36) ENCODE bytedict,
    pacing_interval_start_date date ENCODE az64,
    pacing_interval_label character varying(240) ENCODE lzo,
    pacing_interval_end_date date ENCODE az64,
    pacing_created_time timestamp without time zone ENCODE az64,
    pacing_dw_created_time timestamp without time zone ENCODE az64,
    pacing_updated_time timestamp without time zone ENCODE az64,
    pacing_dw_updated_time timestamp without time zone ENCODE az64,
    pacing_interval_type character varying(20) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_academic_calendar (
    academic_calendar_dw_id bigint ENCODE az64,
    academic_calendar_created_time timestamp without time zone ENCODE az64,
    academic_calendar_updated_time timestamp without time zone ENCODE az64,
    academic_calendar_deleted_time timestamp without time zone ENCODE az64,
    academic_calendar_dw_created_time timestamp without time zone ENCODE az64,
    academic_calendar_dw_updated_time timestamp without time zone ENCODE az64,
    academic_calendar_status integer ENCODE az64,
    academic_calendar_tenant_id character varying(36) ENCODE lzo,
    academic_calendar_title character varying(50) ENCODE lzo,
    academic_calendar_id character varying(36) ENCODE lzo,
    academic_calendar_school_id character varying(36) ENCODE lzo,
    academic_calendar_is_default boolean ENCODE raw,
    academic_calendar_type character varying(30) ENCODE lzo,
    academic_calendar_organization character varying(50) ENCODE lzo,
    academic_calendar_academic_year_id character varying(36) ENCODE lzo,
    academic_calendar_created_by_id character varying(36) ENCODE lzo,
    academic_calendar_updated_by_id character varying(36) ENCODE lzo,
    academic_calendar_organization_code character varying(20) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_academic_year (
    academic_year_delta_dw_id bigint ENCODE az64,
    academic_year_created_time timestamp without time zone ENCODE az64,
    academic_year_updated_time timestamp without time zone ENCODE az64,
    academic_year_deleted_time timestamp without time zone ENCODE az64,
    academic_year_dw_created_time timestamp without time zone ENCODE az64,
    academic_year_dw_updated_time timestamp without time zone ENCODE az64,
    academic_year_status smallint ENCODE az64,
    academic_year_id character varying(36) ENCODE lzo,
    academic_year_organization_code character varying(50) ENCODE lzo,
    academic_year_school_id character varying(36) ENCODE lzo,
    academic_year_state character varying(50) ENCODE lzo,
    academic_year_start_date date ENCODE az64,
    academic_year_end_date date ENCODE az64,
    academic_year_created_by character varying(36) ENCODE lzo,
    academic_year_updated_by character varying(36) ENCODE lzo,
    academic_year_is_roll_over_completed boolean DEFAULT false ENCODE raw,
    academic_year_type character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_pathway_target_progress (
    fptp_dw_id bigint ENCODE az64,
    fptp_id character varying(36) ENCODE lzo,
    fptp_created_time timestamp without time zone ENCODE az64,
    fptp_dw_created_time timestamp without time zone ENCODE az64,
    fptp_date_dw_id bigint ENCODE az64,
    fptp_student_target_id character varying(36) ENCODE lzo,
    fptp_target_id character varying(36) ENCODE lzo,
    fptp_student_id character varying(36) ENCODE lzo,
    fptp_tenant_id character varying(36) ENCODE lzo,
    fptp_school_id character varying(36) ENCODE lzo,
    fptp_grade_id character varying(36) ENCODE lzo,
    fptp_class_id character varying(36) ENCODE lzo,
    fptp_teacher_id character varying(36) ENCODE lzo,
    fptp_pathway_id character varying(36) ENCODE lzo,
    fptp_target_state character varying(20) ENCODE lzo,
    fptp_recommended_target_level integer ENCODE az64,
    fptp_finalized_target_level integer ENCODE az64,
    fptp_levels_completed integer ENCODE az64,
    fptp_earned_stars integer ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_teacher_feedback_thread (
    rel_tft_id bigint identity(1,1) ENCODE az64,
    tft_status smallint ENCODE az64,
    tft_created_time timestamp without time zone ENCODE az64,
    tft_dw_created_time timestamp without time zone ENCODE az64,
    tft_deleted_time timestamp without time zone ENCODE az64,
    tft_updated_time timestamp without time zone ENCODE az64,
    tft_dw_updated_time timestamp without time zone ENCODE az64,
    tft_thread_id character varying(36) ENCODE lzo,
    tft_actor_type smallint ENCODE az64,
    tft_guardian_id character varying(36) ENCODE lzo,
    tft_message_id character varying(36) ENCODE lzo,
    tft_response_enabled boolean ENCODE raw,
    tft_feedback_type smallint ENCODE az64,
    tft_teacher_id character varying(36) ENCODE lzo,
    tft_student_id character varying(36) ENCODE lzo,
    tft_class_id character varying(36) ENCODE lzo,
    tft_is_read boolean ENCODE raw,
    tft_event_subject smallint ENCODE az64,
    tft_is_first_of_thread boolean ENCODE raw
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_inc_game_session (
    inc_game_session_staging_id bigint identity(1,1) ENCODE lzo,
    inc_game_session_id character varying(36) ENCODE lzo,
    inc_game_session_created_time timestamp without time zone ENCODE lzo,
    inc_game_session_dw_created_time timestamp without time zone ENCODE lzo,
    inc_game_session_date_dw_id bigint ENCODE lzo,
    tenant_uuid character varying(36) ENCODE lzo,
    game_uuid character varying(36) ENCODE lzo,
    inc_game_session_title character varying(256) ENCODE lzo,
    inc_game_session_num_players integer ENCODE lzo,
    inc_game_session_num_joined_players integer ENCODE lzo,
    inc_game_session_started_by character varying(36) ENCODE lzo,
    inc_game_session_status integer ENCODE lzo,
    inc_game_session_is_start boolean DEFAULT false ENCODE raw,
    inc_game_session_is_start_event_processed boolean DEFAULT false ENCODE raw,
    inc_game_session_is_assessment boolean DEFAULT false ENCODE raw
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_learning_score_breakdown (
    fle_scbd_dw_id bigint identity(1,1) ENCODE raw,
    fle_scbd_created_time timestamp without time zone ENCODE az64,
    fle_scbd_dw_created_time timestamp without time zone ENCODE az64,
    fle_scbd_date_dw_id bigint ENCODE az64,
    fle_scbd_fle_exp_id character varying(36) ENCODE lzo,
    fle_scbd_fle_ls_id character varying(36) ENCODE lzo,
    fle_scbd_question_id character varying(36) ENCODE lzo,
    fle_scbd_code character varying(50) ENCODE lzo,
    fle_scbd_time_spent double precision ENCODE raw,
    fle_scbd_hints_used boolean ENCODE raw,
    fle_scbd_max_score double precision ENCODE raw,
    fle_scbd_score double precision ENCODE raw,
    fle_scbd_lo_id character varying(36) ENCODE bytedict,
    fle_scbd_type character varying(250) ENCODE lzo,
    fle_scbd_version integer ENCODE az64,
    fle_scbd_is_attended boolean ENCODE raw
)
DISTSTYLE AUTO
SORTKEY ( fle_scbd_dw_id );
CREATE TABLE devcoredw_stage.staging_badge_awarded (
    fba_dw_id bigint identity(1,1) ENCODE raw distkey,
    fba_id character varying(36) ENCODE lzo,
    fba_created_time timestamp without time zone ENCODE az64,
    fba_dw_created_time timestamp without time zone ENCODE az64,
    fba_date_dw_id bigint ENCODE az64,
    fba_student_id character varying(36) ENCODE lzo,
    fba_tenant_id character varying(36) ENCODE lzo,
    fba_badge_type character varying(100) ENCODE lzo,
    fba_badge_type_id character varying(36) ENCODE lzo,
    fba_tier character varying(50) ENCODE lzo,
    fba_academic_year_id character varying(36) ENCODE lzo,
    fba_section_id character varying(36) ENCODE lzo,
    fba_grade_id character varying(36) ENCODE lzo,
    fba_school_id character varying(36) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( fba_dw_id );
CREATE TABLE devcoredw_stage.staging_inc_game_outcome (
    inc_game_outcome_staging_id bigint identity(1,1) ENCODE lzo,
    inc_game_outcome_id character varying(36) ENCODE lzo,
    inc_game_outcome_created_time timestamp without time zone ENCODE lzo,
    inc_game_outcome_dw_created_time timestamp without time zone ENCODE lzo,
    inc_game_outcome_date_dw_id bigint ENCODE lzo,
    tenant_uuid character varying(36) ENCODE lzo,
    session_uuid character varying(36) ENCODE lzo,
    game_uuid character varying(36) ENCODE lzo,
    player_uuid character varying(36) ENCODE lzo,
    lo_uuid character varying(36) ENCODE lzo,
    inc_game_outcome_score double precision ENCODE raw,
    inc_game_outcome_status integer ENCODE lzo,
    inc_game_outcome_is_assessment boolean DEFAULT false ENCODE raw
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_course_resource_activity_grade_association (
    craga_dw_id bigint ENCODE az64,
    craga_created_time timestamp without time zone ENCODE raw,
    craga_updated_time timestamp without time zone ENCODE az64,
    craga_deleted_time timestamp without time zone ENCODE az64,
    craga_dw_created_time timestamp without time zone ENCODE az64,
    craga_dw_updated_time timestamp without time zone ENCODE az64,
    craga_dw_deleted_time timestamp without time zone ENCODE az64,
    craga_status integer ENCODE az64,
    craga_course_id character varying(36) ENCODE lzo,
    craga_activity_id character varying(36) ENCODE lzo,
    craga_grade_id character varying(5) ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( craga_created_time );
CREATE TABLE devcoredw_stage.rel_activity_section_association (
    dw_id bigint ENCODE az64,
    event_type character varying(100) ENCODE lzo,
    _trace_id character varying(36) ENCODE lzo,
    tenant_id character varying(36) ENCODE lzo,
    id character varying(36) ENCODE lzo,
    created_time timestamp without time zone ENCODE az64,
    dw_created_time timestamp without time zone ENCODE az64,
    status smallint ENCODE az64,
    active_until timestamp without time zone ENCODE az64,
    section_id character varying(36) ENCODE lzo,
    activity_id character varying(36) ENCODE lzo,
    template_component_uuid character varying(36) ENCODE lzo,
    content_id bigint ENCODE az64,
    _ingestion_type character varying(10) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_level_completed (
    flc_dw_id bigint identity(1,1) ENCODE raw,
    flc_created_time timestamp without time zone ENCODE az64,
    flc_dw_created_time timestamp without time zone ENCODE az64,
    flc_date_dw_id bigint ENCODE az64,
    flc_completed_on timestamp without time zone ENCODE az64,
    flc_tenant_id character varying(36) ENCODE lzo,
    flc_student_id character varying(36) ENCODE lzo,
    flc_class_id character varying(36) ENCODE lzo,
    flc_pathway_id character varying(36) ENCODE lzo,
    flc_level_id character varying(36) ENCODE lzo,
    flc_total_stars integer ENCODE az64,
    flc_academic_year character varying(50) ENCODE lzo,
    flc_score integer ENCODE az64
)
DISTSTYLE AUTO
SORTKEY ( flc_dw_id );
CREATE TABLE devcoredw_stage.rel_staff_user (
    rel_staff_user_dw_id bigint ENCODE az64,
    staff_user_event_type character varying(50) ENCODE lzo distkey,
    staff_user_created_time timestamp without time zone ENCODE az64,
    staff_user_dw_created_time timestamp without time zone ENCODE az64,
    staff_user_active_until timestamp without time zone ENCODE az64,
    staff_user_status integer ENCODE az64,
    staff_user_id character varying(36) ENCODE lzo,
    staff_user_onboarded boolean ENCODE raw,
    staff_user_expirable boolean DEFAULT false ENCODE raw,
    staff_user_exclude_from_report boolean DEFAULT false ENCODE raw,
    staff_user_avatar character varying(100) ENCODE lzo,
    staff_user_enabled boolean ENCODE raw
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_team_student_association (
    rel_team_student_association_id bigint identity(1,1) ENCODE az64,
    team_student_association_created_time timestamp without time zone ENCODE az64,
    team_student_association_updated_time timestamp without time zone ENCODE az64,
    team_student_association_dw_created_time timestamp without time zone ENCODE az64,
    team_student_association_dw_updated_time timestamp without time zone ENCODE az64,
    team_student_association_status smallint ENCODE az64,
    team_student_association_active_until timestamp without time zone ENCODE az64,
    team_uuid character varying(36) ENCODE lzo,
    student_uuid character varying(36) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_announcement (
    fa_dw_id bigint identity(1,1) ENCODE az64,
    fa_created_time timestamp without time zone ENCODE az64,
    fa_dw_created_time timestamp without time zone ENCODE az64,
    fa_status integer ENCODE az64,
    fa_tenant_id character varying(36) ENCODE lzo,
    fa_id character varying(36) ENCODE lzo,
    fa_admin_id character varying(36) ENCODE lzo,
    fa_role_id character varying(36) ENCODE lzo,
    fa_recipient_type integer ENCODE az64,
    fa_recipient_type_description character varying(50) ENCODE lzo,
    fa_recipient_id character varying(36) ENCODE lzo,
    fa_has_attachment boolean ENCODE raw,
    fa_type integer ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_staff_user_school_role_association (
    susra_dw_id bigint ENCODE az64,
    susra_event_type character varying(50) ENCODE lzo,
    susra_staff_id character varying(36) ENCODE lzo,
    susra_school_id character varying(36) ENCODE lzo,
    susra_role_name character varying(50) ENCODE lzo,
    susra_role_uuid character varying(36) ENCODE lzo,
    susra_organization character varying(50) ENCODE lzo,
    susra_status integer ENCODE az64,
    susra_created_time timestamp without time zone ENCODE az64,
    susra_dw_created_time timestamp without time zone ENCODE az64,
    susra_active_until timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_course_curriculum_association (
    cc_dw_id bigint ENCODE az64,
    cc_course_id character varying(36) ENCODE lzo,
    cc_curr_id bigint ENCODE az64,
    cc_curr_grade_id bigint ENCODE az64,
    cc_curr_subject_id bigint ENCODE az64 distkey,
    cc_status integer ENCODE az64,
    cc_created_time timestamp without time zone ENCODE az64,
    cc_updated_time timestamp without time zone ENCODE az64,
    cc_deleted_time timestamp without time zone ENCODE az64,
    cc_dw_created_time timestamp without time zone ENCODE az64,
    cc_dw_updated_time timestamp without time zone ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.rel_tag (
    tag_dw_id bigint ENCODE az64,
    tag_created_time timestamp without time zone ENCODE az64,
    tag_updated_time timestamp without time zone ENCODE az64,
    tag_dw_created_time timestamp without time zone ENCODE az64,
    tag_dw_updated_time timestamp without time zone ENCODE az64,
    tag_id character varying(36) ENCODE lzo,
    tag_name character varying(1024) ENCODE lzo,
    tag_status integer ENCODE az64,
    tag_type character varying(36) ENCODE lzo,
    tag_association_id character varying(36) ENCODE lzo,
    tag_association_type integer ENCODE az64,
    tag_association_attach_status integer ENCODE az64
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_tutor_translation (
    ftt_dw_id bigint ENCODE az64,
    ftt_created_time timestamp without time zone ENCODE az64,
    ftt_dw_created_time timestamp without time zone ENCODE az64,
    ftt_date_dw_id bigint ENCODE az64,
    ftt_user_id character varying(36) ENCODE lzo,
    ftt_tenant_id character varying(36) ENCODE lzo,
    ftt_message_id character varying(36) ENCODE lzo,
    ftt_session_id character varying(36) ENCODE lzo,
    ftt_conversation_id character varying(36) ENCODE lzo,
    ftt_translation_language character varying(50) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.staging_learning_experience (
    fle_staging_id bigint identity(1,1) ENCODE raw,
    fle_created_time timestamp without time zone ENCODE raw,
    fle_dw_created_time timestamp without time zone ENCODE raw,
    fle_date_dw_id bigint ENCODE raw,
    fle_exp_id character varying(36) ENCODE raw,
    fle_ls_id character varying(36) ENCODE raw,
    fle_step_id character varying(36) ENCODE raw,
    lo_uuid character varying(36) ENCODE raw,
    student_uuid character varying(36) ENCODE raw distkey,
    subject_uuid character varying(36) ENCODE raw,
    grade_uuid character varying(36) ENCODE raw,
    curr_subject_uuid character varying(36) ENCODE raw,
    curr_grade_uuid character varying(36) ENCODE raw,
    curr_uuid character varying(36) ENCODE raw,
    tenant_uuid character varying(36) ENCODE raw,
    school_uuid character varying(36) ENCODE raw,
    section_uuid character varying(36) ENCODE raw,
    lp_uuid character varying(36) ENCODE raw,
    fle_start_time timestamp without time zone ENCODE raw,
    fle_end_time timestamp without time zone ENCODE raw,
    fle_total_time double precision ENCODE raw,
    fle_score integer ENCODE raw,
    fle_star_earned integer ENCODE raw,
    fle_lesson_type character varying(50) ENCODE raw,
    fle_is_retry boolean ENCODE raw,
    fle_outside_of_school boolean ENCODE raw,
    fle_attempt integer ENCODE raw,
    fle_exp_ls_flag boolean ENCODE raw,
    fle_academic_period_order character varying(20) ENCODE raw,
    academic_year_uuid character varying(256) ENCODE lzo,
    fle_content_academic_year character varying(36) ENCODE lzo,
    fle_time_spent_app integer ENCODE lzo,
    fle_instructional_plan_id character varying(36) ENCODE lzo,
    class_uuid character varying(36) ENCODE lzo,
    fle_lesson_category character varying(40) ENCODE lzo,
    fle_adt_level character varying(20) ENCODE lzo,
    fle_abbreviation character varying(100) ENCODE lzo,
    fle_activity_template_id character varying(100) ENCODE lzo,
    fle_activity_type character varying(100) ENCODE lzo,
    fle_activity_component_type character varying(100) ENCODE lzo,
    fle_exit_ticket boolean ENCODE raw,
    fle_main_component boolean ENCODE raw,
    fle_completion_node boolean ENCODE raw,
    fle_total_score numeric(10,4) ENCODE az64,
    fle_is_activity_completed boolean ENCODE raw,
    fle_material_id character varying(36) ENCODE lzo,
    fle_material_type character varying(20) ENCODE lzo,
    fle_state smallint ENCODE az64,
    fle_total_stars smallint ENCODE az64,
    fle_open_path_enabled boolean DEFAULT false ENCODE raw,
    fle_source character varying(10) ENCODE lzo,
    fle_teaching_period_id character varying(36) ENCODE lzo,
    fle_academic_year character varying(10) ENCODE lzo,
    fle_assessment_id character varying(36) ENCODE lzo,
    fle_is_gamified boolean DEFAULT false ENCODE raw,
    fle_is_additional_resource boolean DEFAULT false ENCODE raw,
    fle_bonus_stars integer DEFAULT -1 ENCODE az64,
    fle_bonus_stars_scheme character varying(40) DEFAULT 'NA'::character varying ENCODE lzo
)
DISTSTYLE AUTO
SORTKEY ( school_uuid, grade_uuid, section_uuid );
CREATE TABLE devcoredw_stage.staging_student_activities (
    fsta_staging_id bigint identity(1,1) ENCODE lzo,
    fsta_created_time timestamp without time zone ENCODE lzo,
    fsta_dw_created_time timestamp without time zone ENCODE lzo,
    fsta_actor_object_type character varying(100) ENCODE lzo,
    fsta_actor_account_homepage character varying(100) ENCODE lzo,
    fsta_verb_display character varying(100) ENCODE lzo,
    fsta_verb_id character varying(100) ENCODE lzo,
    fsta_object_id character varying(2000) ENCODE lzo,
    fsta_object_type character varying(100) ENCODE lzo,
    fsta_object_definition_type character varying(100) ENCODE lzo,
    fsta_object_definition_name character varying(2000) ENCODE lzo,
    fsta_from_time numeric(5,0) ENCODE lzo,
    fsta_to_time numeric(5,0) ENCODE lzo,
    fsta_outside_of_school boolean ENCODE raw,
    fsta_event_type character varying(100) ENCODE lzo,
    fsta_prev_event_type character varying(100) ENCODE lzo,
    fsta_next_event_type character varying(100) ENCODE lzo,
    fsta_date_dw_id bigint ENCODE lzo,
    fsta_attempt smallint ENCODE lzo,
    fsta_score_scaled numeric(6,2) ENCODE lzo,
    fsta_score_max numeric(6,2) ENCODE lzo,
    fsta_score_min numeric(6,2) ENCODE lzo,
    fsta_lesson_position smallint ENCODE lzo,
    fsta_exp_id character varying(36) ENCODE lzo,
    fsta_ls_id character varying(36) ENCODE lzo,
    tenant_uuid character varying(36) ENCODE lzo,
    school_uuid character varying(36) ENCODE lzo,
    grade_uuid character varying(36) ENCODE lzo,
    section_uuid character varying(36) ENCODE lzo,
    subject_uuid character varying(36) ENCODE lzo,
    student_uuid character varying(36) ENCODE lzo distkey,
    academic_year_uuid character varying(36) ENCODE lzo,
    fsta_timestamp_local character varying(100) ENCODE lzo,
    fsta_start_time timestamp without time zone ENCODE lzo,
    fsta_end_time timestamp without time zone ENCODE lzo,
    fsta_time_spent double precision ENCODE raw,
    fsta_score_raw numeric(8,2) ENCODE az64,
    fsta_is_completion_node boolean ENCODE raw,
    fsta_is_flexible_lesson boolean ENCODE raw,
    fsta_academic_calendar_id character varying(36) ENCODE lzo,
    fsta_teaching_period_id character varying(36) ENCODE lzo,
    fsta_teaching_period_title character varying(50) ENCODE lzo
)
DISTSTYLE AUTO;
CREATE TABLE devcoredw_stage.test_table_stage (
    id bigint ENCODE az64
)
DISTSTYLE AUTO;
