-- Skema MySQL opsional untuk pengembangan backend.
-- Aplikasi starter ini menggunakan localStorage dan belum mengirim data ke MySQL.
CREATE DATABASE IF NOT EXISTS orion_corndog_pos
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE orion_corndog_pos;

CREATE TABLE categories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  category_id INT NULL,
  price DECIMAL(10,2) NOT NULL,
  hpp DECIMAL(10,2) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories(id)
);

CREATE TABLE transactions (
  id VARCHAR(40) PRIMARY KEY,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  total_sales DECIMAL(12,2) NOT NULL,
  total_hpp DECIMAL(12,2) NOT NULL,
  gross_profit DECIMAL(12,2) NOT NULL,
  payment_method ENUM('CASH','QRIS') NOT NULL,
  cash_received DECIMAL(12,2) NOT NULL DEFAULT 0,
  change_amount DECIMAL(12,2) NOT NULL DEFAULT 0
);

CREATE TABLE transaction_details (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  transaction_id VARCHAR(40) NOT NULL,
  product_id INT NOT NULL,
  product_name_at_sale VARCHAR(100) NOT NULL,
  qty INT UNSIGNED NOT NULL,
  price_at_sale DECIMAL(10,2) NOT NULL,
  hpp_at_sale DECIMAL(10,2) NOT NULL,
  subtotal DECIMAL(12,2) NOT NULL,
  CONSTRAINT fk_details_transaction FOREIGN KEY (transaction_id) REFERENCES transactions(id),
  CONSTRAINT fk_details_product FOREIGN KEY (product_id) REFERENCES products(id)
);

INSERT INTO categories (name) VALUES
('Sweet Corndog'), ('Original Corndog'), ('Potato Corndog'),
('Dimsum & Fries'), ('Sosis Bakar');
