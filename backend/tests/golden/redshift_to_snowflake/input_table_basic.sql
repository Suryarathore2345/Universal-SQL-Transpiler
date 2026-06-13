-- Golden-file test input: Redshift CREATE TABLE with distribution, sortkey, identity
-- Source: https://docs.aws.amazon.com/redshift/latest/dg/r_CREATE_TABLE_NEW.html (example adapted)

CREATE TABLE public.orders (
    order_id    INTEGER     IDENTITY(1,1) NOT NULL,
    customer_id INTEGER     NOT NULL,
    order_date  DATE        NOT NULL,
    amount      DECIMAL(18,2) NOT NULL,
    status      VARCHAR(50),
    notes       VARCHAR(65535),
    is_active   BOOLEAN     DEFAULT TRUE,
    created_at  TIMESTAMPTZ DEFAULT SYSDATE,
    metadata    SUPER,
    raw_bytes   VARBYTE
)
DISTSTYLE KEY
DISTKEY (customer_id)
COMPOUND SORTKEY (order_date, customer_id);
