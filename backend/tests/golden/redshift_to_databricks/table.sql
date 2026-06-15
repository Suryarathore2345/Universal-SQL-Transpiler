CREATE TABLE `analytics`.`orders` (
    `order_id` BIGINT NOT NULL,
    `customer_id` INT NOT NULL,
    `amount` DECIMAL(18,2) NOT NULL,
    `status` STRING(32) DEFAULT 'pending',
    `created_at` TIMESTAMP_NTZ NOT NULL,
    PRIMARY KEY (`order_id`)
)
USING DELTA
CLUSTER BY (`created_at`);