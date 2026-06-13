CREATE TABLE `dbo`.`orders` (
    `order_id` BIGINT NOT NULL,
    `customer_id` INT NOT NULL,
    `amount` DECIMAL(18,2) NOT NULL,
    `status` STRING(32) DEFAULT 'pending',
    `created_at` TIMESTAMP_NTZ NOT NULL
)
USING DELTA;