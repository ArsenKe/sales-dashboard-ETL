-- Simple initialization for Cleaning Company

-- Create basic tables
CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255),
    city VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS services (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    price DECIMAL(10,2)
);

CREATE TABLE IF NOT EXISTS employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    hourly_wage DECIMAL(10,2)
);

CREATE TABLE IF NOT EXISTS jobs (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER,
    service_id INTEGER,
    employee_id INTEGER,
    job_date DATE,
    hours DECIMAL(5,2),
    total_price DECIMAL(10,2),
    status VARCHAR(50)
);

-- Insert sample data
INSERT INTO customers (name, email, city) VALUES 
('Firma Müller GmbH', 'mueller@test.at', 'Vienna'),
('Bäckerei Schmidt', 'office@baeckerei.at', 'Graz');

INSERT INTO services (name, price) VALUES
('Grundreinigung', 25.00),
('Fensterreinigung', 35.00);

INSERT INTO employees (name, hourly_wage) VALUES
('Anna Schmidt', 18.50),
('Markus Weber', 17.00);

INSERT INTO jobs (customer_id, service_id, employee_id, job_date, hours, total_price, status) VALUES
(1, 1, 1, '2024-01-15', 4.5, 112.50, 'Completed'),
(2, 2, 2, '2024-01-16', 3.0, 105.00, 'Completed');

SELECT 'Database initialized successfully!' as message;
