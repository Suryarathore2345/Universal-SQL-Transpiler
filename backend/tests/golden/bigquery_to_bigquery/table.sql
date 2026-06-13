CREATE TABLE `analytics`.`orders` (
  `order_id` INT64 NOT NULL,
  `customer_id` INT64 NOT NULL,
  `amount` NUMERIC(18,2) NOT NULL,
  `status` STRING DEFAULT 'pending',
  `created_at` TIMESTAMP NOT NULL
)
PARTITION BY DATE(created_at);