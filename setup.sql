CREATE DATABASE IF NOT EXISTS ems_db;
USE ems_db;

CREATE TABLE IF NOT EXISTS users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  username VARCHAR(50) NOT NULL,
  password VARCHAR(255) NOT NULL,
  role VARCHAR(20) DEFAULT 'ADMIN',
  employee_id INT NULL
);

CREATE TABLE IF NOT EXISTS employees (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL,
  phone VARCHAR(20),
  department VARCHAR(50),
  status VARCHAR(20) DEFAULT 'Inactive'
);

CREATE TABLE IF NOT EXISTS attendance (
  id INT PRIMARY KEY AUTO_INCREMENT,
  employee_id INT NOT NULL,
  attendance_date DATE NOT NULL,
  check_in_time TIME NULL,
  check_out_time TIME NULL,
  status VARCHAR(10) NOT NULL,
  UNIQUE KEY uniq_attendance (employee_id, attendance_date)
);

CREATE TABLE IF NOT EXISTS tasks (
  id INT PRIMARY KEY AUTO_INCREMENT,
  title VARCHAR(150) NOT NULL,
  description TEXT NOT NULL,
  assigned_to INT NOT NULL,
  assigned_by INT NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  priority VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
  due_date DATE NULL,
  reminder_at DATETIME NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_tasks_assigned_to FOREIGN KEY (assigned_to) REFERENCES users(id),
  CONSTRAINT fk_tasks_assigned_by FOREIGN KEY (assigned_by) REFERENCES users(id)
);

INSERT INTO users (username, password, role) VALUES ('admin', 'admin', 'ADMIN');

INSERT INTO users (username, password, role) VALUES ('employee', 'employee', 'EMPLOYEE');
INSERT INTO employees (user_id, name, email, phone, department)
SELECT id, 'Demo Employee', 'employee@example.com', '000-000-0000', 'Operations' FROM users WHERE username = 'employee' LIMIT 1;

ALTER TABLE employees
MODIFY user_id INT NOT NULL;

ALTER TABLE employees
ADD CONSTRAINT fk_user
FOREIGN KEY (user_id) REFERENCES users(id)
ON DELETE CASCADE;
