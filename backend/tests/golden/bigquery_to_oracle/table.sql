BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE "analytics"."orders" PURGE';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
CREATE TABLE "analytics"."orders" (
    "order_id" NUMBER(19) NOT NULL,
    "customer_id" NUMBER(19) NOT NULL,
    "amount" NUMBER(18,2) NOT NULL,
    "status" CLOB DEFAULT 'pending',
    "created_at" TIMESTAMP WITH TIME ZONE NOT NULL
)
PARTITION BY DATE ("created_at");