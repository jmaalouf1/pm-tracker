-- 003_user_assignments.sql

CREATE TABLE IF NOT EXISTS user_customers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  customer_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_user_customer (user_id, customer_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

-- Ensure projects.created_by exists for audit (ignore if already there)
ALTER TABLE projects
  ADD COLUMN IF NOT EXISTS created_by INT NULL,
  ADD CONSTRAINT fk_projects_created_by FOREIGN KEY (created_by) REFERENCES users(id);
