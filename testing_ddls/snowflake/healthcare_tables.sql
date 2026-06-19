-- Snowflake: Healthcare Domain Tables

CREATE OR REPLACE TABLE healthcare.patients (
    patient_id      BIGINT NOT NULL AUTOINCREMENT,
    mrn             VARCHAR(20) NOT NULL UNIQUE,
    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    date_of_birth   DATE NOT NULL,
    gender          VARCHAR(10),
    blood_type      VARCHAR(5),
    phone           VARCHAR(30),
    email           VARCHAR(255),
    address_line1   VARCHAR(255),
    city            VARCHAR(100),
    state           VARCHAR(50),
    postal_code     VARCHAR(20),
    country_code    CHAR(2) DEFAULT 'US',
    insurance_id    VARCHAR(50),
    insurance_plan  VARCHAR(100),
    emergency_contact   VARCHAR(200),
    emergency_phone     VARCHAR(30),
    registered_at   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (patient_id)
);

CREATE OR REPLACE TABLE healthcare.providers (
    provider_id     INTEGER NOT NULL AUTOINCREMENT,
    npi             VARCHAR(10) UNIQUE,
    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    specialty       VARCHAR(150),
    sub_specialty   VARCHAR(150),
    license_number  VARCHAR(50),
    license_state   CHAR(2),
    department_id   INTEGER,
    is_active       BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (provider_id)
);

CREATE OR REPLACE TABLE healthcare.appointments (
    appointment_id  BIGINT NOT NULL AUTOINCREMENT,
    patient_id      BIGINT NOT NULL,
    provider_id     INTEGER NOT NULL,
    appointment_type VARCHAR(50),
    scheduled_at    TIMESTAMP_NTZ NOT NULL,
    duration_min    SMALLINT DEFAULT 30,
    location        VARCHAR(100),
    room            VARCHAR(20),
    status          VARCHAR(30) DEFAULT 'SCHEDULED',
    reason          TEXT,
    notes           TEXT,
    cancelled_at    TIMESTAMP_NTZ,
    cancel_reason   VARCHAR(200),
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (appointment_id),
    FOREIGN KEY (patient_id) REFERENCES healthcare.patients(patient_id),
    FOREIGN KEY (provider_id) REFERENCES healthcare.providers(provider_id)
);

CREATE OR REPLACE TABLE healthcare.diagnoses (
    diagnosis_id    BIGINT NOT NULL AUTOINCREMENT,
    patient_id      BIGINT NOT NULL,
    provider_id     INTEGER NOT NULL,
    appointment_id  BIGINT,
    icd10_code      VARCHAR(10) NOT NULL,
    description     TEXT NOT NULL,
    diagnosis_date  DATE NOT NULL,
    is_primary      BOOLEAN DEFAULT TRUE,
    status          VARCHAR(20) DEFAULT 'ACTIVE',
    resolved_date   DATE,
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (diagnosis_id)
);

CREATE OR REPLACE TABLE healthcare.prescriptions (
    rx_id           BIGINT NOT NULL AUTOINCREMENT,
    patient_id      BIGINT NOT NULL,
    provider_id     INTEGER NOT NULL,
    ndc_code        VARCHAR(15),
    drug_name       VARCHAR(200) NOT NULL,
    dosage          VARCHAR(100),
    frequency       VARCHAR(100),
    days_supply     SMALLINT,
    refills         SMALLINT DEFAULT 0,
    prescribed_at   TIMESTAMP_NTZ NOT NULL,
    filled_at       TIMESTAMP_NTZ,
    expiry_date     DATE,
    status          VARCHAR(20) DEFAULT 'ACTIVE',
    PRIMARY KEY (rx_id)
);

CREATE OR REPLACE TABLE healthcare.lab_results (
    result_id       BIGINT NOT NULL AUTOINCREMENT,
    patient_id      BIGINT NOT NULL,
    provider_id     INTEGER,
    appointment_id  BIGINT,
    test_code       VARCHAR(20),
    test_name       VARCHAR(200) NOT NULL,
    result_value    VARCHAR(100),
    unit            VARCHAR(30),
    reference_range VARCHAR(100),
    flag            VARCHAR(10),
    collected_at    TIMESTAMP_NTZ,
    resulted_at     TIMESTAMP_NTZ,
    created_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (result_id)
);

CREATE OR REPLACE TABLE healthcare.insurance_claims (
    claim_id        BIGINT NOT NULL AUTOINCREMENT,
    patient_id      BIGINT NOT NULL,
    appointment_id  BIGINT,
    claim_number    VARCHAR(50) NOT NULL UNIQUE,
    payer_name      VARCHAR(200),
    insurance_id    VARCHAR(50),
    service_date    DATE NOT NULL,
    billed_amount   DECIMAL(12,2) NOT NULL,
    allowed_amount  DECIMAL(12,2),
    paid_amount     DECIMAL(12,2),
    patient_liability DECIMAL(12,2),
    status          VARCHAR(30) DEFAULT 'SUBMITTED',
    submitted_at    TIMESTAMP_NTZ NOT NULL,
    adjudicated_at  TIMESTAMP_NTZ,
    PRIMARY KEY (claim_id)
);
