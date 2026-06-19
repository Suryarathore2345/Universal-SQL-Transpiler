CREATE OR REPLACE TABLE `analytics`.`orders` (
    `order_id` TINYINT NOT NULL,
    `customer_id` TINYINT NOT NULL,
    `amount` DECIMAL(18,2) NOT NULL,
    `status` CHAR DEFAULT 'pending',
    `created_at` TIMESTAMP NOT NULL
)
USING DELTA
PARTITIONED BY (`created_at`);