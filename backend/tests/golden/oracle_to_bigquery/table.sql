CREATE TABLE `hr`.`orders` (
  `order_id` NUMERIC NOT NULL,
  `customer_id` NUMERIC NOT NULL,
  `amount` NUMERIC(18,2) NOT NULL,
  `status` STRING(32) DEFAULT 'pending',
  `created_at` DATETIME NOT NULL
);