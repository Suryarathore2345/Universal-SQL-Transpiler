-- BigQuery: Healthcare Analytics Tables

CREATE OR REPLACE TABLE `analytics.healthcare.patient_records` (
    patient_id      INT64 NOT NULL,
    mrn             STRING NOT NULL,
    demographics    STRUCT<
        first_name  STRING,
        last_name   STRING,
        dob         DATE,
        gender      STRING,
        blood_type  STRING
    >,
    contact         STRUCT<
        phone       STRING,
        email       STRING,
        address     STRING,
        city        STRING,
        state       STRING,
        country     STRING
    >,
    insurance       ARRAY<STRUCT<
        payer_name  STRING,
        plan_name   STRING,
        member_id   STRING,
        group_id    STRING,
        is_primary  BOOL
    >>,
    is_active       BOOL DEFAULT TRUE,
    registered_at   TIMESTAMP,
    updated_at      TIMESTAMP
);

CREATE OR REPLACE TABLE `analytics.healthcare.encounters` (
    encounter_id    INT64 NOT NULL,
    patient_id      INT64 NOT NULL,
    provider_id     INT64,
    facility_id     INT64,
    encounter_type  STRING NOT NULL,
    admit_date      DATE NOT NULL,
    discharge_date  DATE,
    length_of_stay  INT64,
    primary_dx      STRING,
    diagnoses       ARRAY<STRUCT<
        icd10_code  STRING,
        description STRING,
        is_primary  BOOL
    >>,
    procedures      ARRAY<STRUCT<
        cpt_code    STRING,
        description STRING,
        performed_at TIMESTAMP
    >>,
    total_charges   NUMERIC,
    status          STRING DEFAULT 'ACTIVE',
    encounter_date  DATE NOT NULL
)
PARTITION BY encounter_date
CLUSTER BY patient_id, provider_id;

CREATE OR REPLACE TABLE `analytics.healthcare.vitals` (
    vital_id        INT64 NOT NULL,
    patient_id      INT64 NOT NULL,
    encounter_id    INT64,
    heart_rate      FLOAT64,
    systolic_bp     FLOAT64,
    diastolic_bp    FLOAT64,
    temperature_c   FLOAT64,
    respiratory_rate FLOAT64,
    spo2_pct        FLOAT64,
    weight_kg       FLOAT64,
    height_cm       FLOAT64,
    bmi             FLOAT64,
    pain_score      INT64,
    recorded_by     STRING,
    recorded_at     TIMESTAMP NOT NULL,
    vital_date      DATE NOT NULL
)
PARTITION BY vital_date
CLUSTER BY patient_id;

CREATE OR REPLACE TABLE `analytics.healthcare.lab_results` (
    result_id       INT64 NOT NULL,
    patient_id      INT64 NOT NULL,
    encounter_id    INT64,
    order_id        STRING,
    panel_name      STRING,
    results         ARRAY<STRUCT<
        test_code   STRING,
        test_name   STRING,
        value       STRING,
        unit        STRING,
        ref_range   STRING,
        flag        STRING
    >>,
    ordered_at      TIMESTAMP,
    resulted_at     TIMESTAMP NOT NULL,
    result_date     DATE NOT NULL
)
PARTITION BY result_date
CLUSTER BY patient_id;

CREATE OR REPLACE TABLE `analytics.healthcare.claims` (
    claim_id        INT64 NOT NULL,
    patient_id      INT64 NOT NULL,
    encounter_id    INT64,
    payer_id        INT64,
    claim_number    STRING NOT NULL,
    service_date    DATE NOT NULL,
    billed_amount   NUMERIC NOT NULL,
    allowed_amount  NUMERIC,
    paid_amount     NUMERIC,
    denied_amount   NUMERIC,
    denial_codes    ARRAY<STRING>,
    status          STRING DEFAULT 'SUBMITTED',
    submitted_at    TIMESTAMP,
    processed_at    TIMESTAMP,
    claim_date      DATE NOT NULL
)
PARTITION BY claim_date
CLUSTER BY patient_id, payer_id;
