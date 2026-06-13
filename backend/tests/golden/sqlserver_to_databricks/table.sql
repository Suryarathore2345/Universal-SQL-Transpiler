CREATE TABLE `dbo`.`orders` (
    `order_id` BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) NOT NULL,
    `customer_id` INT NOT NULL,
    `amount` DECIMAL(18,2) NOT NULL,
    `status` VARCHAR(MAX) DEFAULT 'pending',
    `created_at` TIMESTAMP_NTZ NOT NULL,
    PRIMARY KEY (`order_id`)
)
USING DELTA;