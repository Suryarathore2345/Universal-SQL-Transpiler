CREATE TABLE "dbo"."orders" (
    "order_id" NUMBER(19) GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) NOT NULL,
    "customer_id" NUMBER(10) NOT NULL,
    "amount" NUMBER(18,2) NOT NULL,
    "status" VARCHAR(MAX) DEFAULT 'pending',
    "created_at" TIMESTAMP NOT NULL,
    PRIMARY KEY ("order_id")
);