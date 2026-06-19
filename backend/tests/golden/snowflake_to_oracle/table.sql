BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE "analytics"."orders" PURGE';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
CREATE TABLE "analytics"."orders" (
    "order_id" NUMBER(19) NOT NULL,
    "customer_id" NUMBER(10) NOT NULL,
    "amount" NUMBER(18,2) NOT NULL,
    "status" VARCHAR2(32) DEFAULT 'pending',
    "created_at" TIMESTAMP NOT NULL,
    PRIMARY KEY ("order_id")
)
PARTITION BY HASH ("created_at") PARTITIONS 8;