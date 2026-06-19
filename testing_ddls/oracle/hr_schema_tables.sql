-- Oracle HR Sample Schema Tables (from oracle-samples/db-sample-schemas)
-- Source: https://github.com/oracle-samples/db-sample-schemas

CREATE TABLE hr.regions (
    region_id   NUMBER        CONSTRAINT region_id_nn NOT NULL,
    region_name VARCHAR2(25)
);

CREATE TABLE hr.countries (
    country_id   CHAR(2)      CONSTRAINT country_id_nn NOT NULL,
    country_name VARCHAR2(60),
    region_id    NUMBER,
    CONSTRAINT country_c_id_pk PRIMARY KEY (country_id)
);

CREATE TABLE hr.locations (
    location_id    NUMBER(4),
    street_address VARCHAR2(40),
    postal_code    VARCHAR2(12),
    city           VARCHAR2(30) CONSTRAINT loc_city_nn NOT NULL,
    state_province VARCHAR2(25),
    country_id     CHAR(2)
);

CREATE TABLE hr.departments (
    department_id   NUMBER(4),
    department_name VARCHAR2(30) CONSTRAINT dept_name_nn NOT NULL,
    manager_id      NUMBER(6),
    location_id     NUMBER(4)
);

CREATE TABLE hr.jobs (
    job_id    VARCHAR2(10),
    job_title VARCHAR2(35) CONSTRAINT job_title_nn NOT NULL,
    min_salary NUMBER(6),
    max_salary NUMBER(6)
);

CREATE TABLE hr.employees (
    employee_id    NUMBER(6),
    first_name     VARCHAR2(20),
    last_name      VARCHAR2(25)  CONSTRAINT emp_last_name_nn NOT NULL,
    email          VARCHAR2(25)  CONSTRAINT emp_email_nn NOT NULL,
    phone_number   VARCHAR2(20),
    hire_date      DATE          CONSTRAINT emp_hire_date_nn NOT NULL,
    job_id         VARCHAR2(10)  CONSTRAINT emp_job_nn NOT NULL,
    salary         NUMBER(8,2),
    commission_pct NUMBER(2,2),
    manager_id     NUMBER(6),
    department_id  NUMBER(4),
    CONSTRAINT emp_salary_min CHECK (salary > 0),
    CONSTRAINT emp_email_uk UNIQUE (email)
);

CREATE TABLE hr.job_history (
    employee_id   NUMBER(6)   CONSTRAINT jhist_employee_nn NOT NULL,
    start_date    DATE        CONSTRAINT jhist_start_date_nn NOT NULL,
    end_date      DATE        CONSTRAINT jhist_end_date_nn NOT NULL,
    job_id        VARCHAR2(10) CONSTRAINT jhist_job_nn NOT NULL,
    department_id NUMBER(4),
    CONSTRAINT jhist_date_interval CHECK (end_date > start_date)
);
