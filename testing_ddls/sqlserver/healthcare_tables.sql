-- SQL Server: Healthcare Domain Tables

CREATE TABLE healthcare.patients (
    patient_id      BIGINT NOT NULL IDENTITY(1,1),
    mrn             NVARCHAR(20) NOT NULL,
    first_name      NVARCHAR(100) NOT NULL,
    last_name       NVARCHAR(100) NOT NULL,
    date_of_birth   DATE NOT NULL,
    gender          NVARCHAR(10),
    blood_type      NVARCHAR(5),
    phone           NVARCHAR(30),
    email           NVARCHAR(255),
    address_line1   NVARCHAR(255),
    city            NVARCHAR(100),
    state           NVARCHAR(50),
    postal_code     NVARCHAR(20),
    country_code    CHAR(2) NOT NULL DEFAULT 'US',
    insurance_id    NVARCHAR(50),
    insurance_plan  NVARCHAR(100),
    registered_at   DATETIME2 NOT NULL DEFAULT GETDATE(),
    updated_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_patients PRIMARY KEY (patient_id),
    CONSTRAINT UQ_patient_mrn UNIQUE (mrn)
);

CREATE TABLE healthcare.providers (
    provider_id     INT NOT NULL IDENTITY(1,1),
    npi             NVARCHAR(10),
    first_name      NVARCHAR(100) NOT NULL,
    last_name       NVARCHAR(100) NOT NULL,
    specialty       NVARCHAR(150),
    sub_specialty   NVARCHAR(150),
    license_number  NVARCHAR(50),
    license_state   CHAR(2),
    is_active       BIT NOT NULL DEFAULT 1,
    CONSTRAINT PK_providers PRIMARY KEY (provider_id)
);

CREATE TABLE healthcare.appointments (
    appointment_id  BIGINT NOT NULL IDENTITY(1,1),
    patient_id      BIGINT NOT NULL,
    provider_id     INT NOT NULL,
    appointment_type NVARCHAR(50),
    scheduled_at    DATETIME2 NOT NULL,
    duration_min    SMALLINT NOT NULL DEFAULT 30,
    location        NVARCHAR(100),
    room            NVARCHAR(20),
    status          NVARCHAR(30) NOT NULL DEFAULT 'SCHEDULED',
    reason          NVARCHAR(MAX),
    notes           NVARCHAR(MAX),
    cancelled_at    DATETIME2,
    cancel_reason   NVARCHAR(200),
    created_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_appointments PRIMARY KEY (appointment_id),
    CONSTRAINT FK_appt_patient FOREIGN KEY (patient_id) REFERENCES healthcare.patients(patient_id),
    CONSTRAINT FK_appt_provider FOREIGN KEY (provider_id) REFERENCES healthcare.providers(provider_id)
);

CREATE TABLE healthcare.diagnoses (
    diagnosis_id    BIGINT NOT NULL IDENTITY(1,1),
    patient_id      BIGINT NOT NULL,
    provider_id     INT NOT NULL,
    appointment_id  BIGINT,
    icd10_code      NVARCHAR(10) NOT NULL,
    description     NVARCHAR(MAX) NOT NULL,
    diagnosis_date  DATE NOT NULL,
    is_primary      BIT NOT NULL DEFAULT 1,
    status          NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    resolved_date   DATE,
    created_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_diagnoses PRIMARY KEY (diagnosis_id)
);

CREATE TABLE healthcare.lab_results (
    result_id       BIGINT NOT NULL IDENTITY(1,1),
    patient_id      BIGINT NOT NULL,
    provider_id     INT,
    test_code       NVARCHAR(20),
    test_name       NVARCHAR(200) NOT NULL,
    result_value    NVARCHAR(100),
    unit            NVARCHAR(30),
    reference_range NVARCHAR(100),
    flag            NVARCHAR(10),
    collected_at    DATETIME2,
    resulted_at     DATETIME2,
    created_at      DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_lab_results PRIMARY KEY (result_id)
);

CREATE TABLE healthcare.insurance_claims (
    claim_id        BIGINT NOT NULL IDENTITY(1,1),
    patient_id      BIGINT NOT NULL,
    appointment_id  BIGINT,
    claim_number    NVARCHAR(50) NOT NULL,
    payer_name      NVARCHAR(200),
    service_date    DATE NOT NULL,
    billed_amount   DECIMAL(12,2) NOT NULL,
    allowed_amount  DECIMAL(12,2),
    paid_amount     DECIMAL(12,2),
    patient_liability DECIMAL(12,2),
    status          NVARCHAR(30) NOT NULL DEFAULT 'SUBMITTED',
    submitted_at    DATETIME2 NOT NULL,
    adjudicated_at  DATETIME2,
    CONSTRAINT PK_insurance_claims PRIMARY KEY (claim_id),
    CONSTRAINT UQ_claim_number UNIQUE (claim_number)
);
