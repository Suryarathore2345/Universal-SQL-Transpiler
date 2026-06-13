CREATE TABLE `analytics`.`orders` (
  `order_id` INT64 NOT NULL,
  `customer_id` INT64 NOT NULL,
  `amount` NUMERIC(18,2) NOT NULL,
  `status` STRING(32) DEFAULT 'pending',
  `created_at` DATETIME NOT NULL,
  PRIMARY KEY (`order_id`) NOT ENFORCED
)
CLUSTER BY `CREATED_AT`;