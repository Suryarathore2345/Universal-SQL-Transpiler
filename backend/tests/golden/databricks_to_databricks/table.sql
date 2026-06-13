CREATE TABLE `analytics`.`orders` (
    `order_id` BIGINT NOT NULL,
    `customer_id` INT NOT NULL,
    `amount` DECIMAL(18,2) NOT NULL,
    `status` STRING DEFAULT 'pending',
    `created_at` TIMESTAMP NOT NULL
)
USING DELTA
PARTITIONED BY (`created_at`);