-- 002_customers_terms_and_backlog.sql

-- Add new fields to customers
ALTER TABLE customers
  ADD COLUMN country VARCHAR(2) NULL AFTER name,
  ADD COLUMN type ENUM('bank','fintech','digital_bank','government','nfi','other') NULL AFTER country,
  ADD COLUMN commercial_registration VARCHAR(100) NULL AFTER type,
  ADD COLUMN vat_number VARCHAR(100) NULL AFTER commercial_registration;

-- Contacts table (1..N per customer)
CREATE TABLE IF NOT EXISTS customer_contacts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  role VARCHAR(100) NULL,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NULL,
  phone VARCHAR(50) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

-- Project payment terms per project (sum must be 100% - enforced in API)
CREATE TABLE IF NOT EXISTS project_terms (
  id INT AUTO_INCREMENT PRIMARY KEY,
  project_id INT NOT NULL,
  seq INT NOT NULL DEFAULT 1,
  percentage DECIMAL(6,3) NOT NULL,
  description VARCHAR(500) NOT NULL,
  status_id INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (status_id) REFERENCES statuses(id)
);

-- Projects: add contract_value, drop backlog_2025
ALTER TABLE projects
  ADD COLUMN contract_value DECIMAL(15,2) NOT NULL DEFAULT 0 AFTER invoice_status_id;

ALTER TABLE projects
  DROP COLUMN IF EXISTS backlog_2025;

-- Add 'term_status' type in statuses.type ENUM
-- MySQL requires full enum literal replacement
ALTER TABLE statuses
  MODIFY COLUMN type ENUM('project_status','invoice_status','po_status','term_status') NOT NULL;

-- Seed default term statuses if not present
INSERT IGNORE INTO statuses (type, name, is_active) VALUES
 ('term_status','Planned',1),
 ('term_status','Due',1),
 ('term_status','In Progress',1),
 ('term_status','Paid',1),
 ('term_status','Cancelled',1);
