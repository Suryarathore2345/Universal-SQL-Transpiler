CREATE TABLE hr.orders (
    "order_id" NUMBER IDENTITY(1,1) NOT NULL,
    "customer_id" NUMBER NOT NULL,
    "amount" NUMBER(18,2) NOT NULL,
    "status" VARCHAR(32) DEFAULT 'pending',
    "created_at" TIMESTAMP_NTZ NOT NULL
);