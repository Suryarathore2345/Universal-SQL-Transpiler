CREATE TABLE `dbo`.`orders` (
  `order_id` INT64 NOT NULL,
  `customer_id` INT64 NOT NULL,
  `amount` NUMERIC(18,2) NOT NULL,
  `status` VARCHAR(MAX) DEFAULT 'pending',
  `created_at` DATETIME NOT NULL,
  PRIMARY KEY (`order_id`) NOT ENFORCED
);