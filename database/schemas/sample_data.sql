-- Sample Data for Cleaning Company Dashboard

-- 1. Populate dim_date (Calendar 2024-2025)
INSERT INTO dim_date (full_date, calendar_year, calendar_month, calendar_day, calendar_quarter, 
                      week_number, day_of_week, day_name, month_name, is_weekend, is_business_day)
SELECT
    DATE '2024-01-01' + (s || ' days')::INTERVAL,
    EXTRACT(YEAR FROM DATE '2024-01-01' + (s || ' days')::INTERVAL)::INT,
    EXTRACT(MONTH FROM DATE '2024-01-01' + (s || ' days')::INTERVAL)::INT,
    EXTRACT(DAY FROM DATE '2024-01-01' + (s || ' days')::INTERVAL)::INT,
    EXTRACT(QUARTER FROM DATE '2024-01-01' + (s || ' days')::INTERVAL)::INT,
    EXTRACT(WEEK FROM DATE '2024-01-01' + (s || ' days')::INTERVAL)::INT,
    EXTRACT(DOW FROM DATE '2024-01-01' + (s || ' days')::INTERVAL)::INT,
    TO_CHAR(DATE '2024-01-01' + (s || ' days')::INTERVAL, 'Day'),
    TO_CHAR(DATE '2024-01-01' + (s || ' days')::INTERVAL, 'Month'),
    EXTRACT(DOW FROM DATE '2024-01-01' + (s || ' days')::INTERVAL) IN (0, 6),
    EXTRACT(DOW FROM DATE '2024-01-01' + (s || ' days')::INTERVAL) NOT IN (0, 6)
FROM GENERATE_SERIES(0, 730) AS s
ON CONFLICT DO NOTHING;

-- 2. Populate dim_customer
INSERT INTO dim_customer 
(customer_type, company_name, contact_person, email, phone, address_street, address_city, 
 address_postal_code, property_type, property_size_sqm, rooms_count, bathrooms_count, 
 contract_type, hourly_rate, customer_status, customer_segment, created_at)
VALUES
('Business', 'Firma Müller GmbH', 'Herr Müller', 'mueller@test.at', '+43 1 123456', 
 'Hauptstrasse 10', 'Vienna', '1010', 'Office', 250, 5, 2, 'Monthly', 25.00, 'Active', 'Premium', NOW()),

('Business', 'Bäckerei Schmidt', 'Frau Schmidt', 'schmidt@baeckerei.at', '+43 316 987654',
 'Bäckerstrasse 5', 'Graz', '8010', 'Retail', 150, 3, 1, 'Weekly', 20.00, 'Active', 'Standard', NOW()),

('Commercial', 'Hotel Tyrol', 'Direktor Weber', 'info@hotel-tyrol.at', '+43 512 555888',
 'Hauptplatz 1', 'Innsbruck', '6020', 'Office', 500, 10, 5, 'Weekly', 30.00, 'Active', 'Premium', NOW()),

('Private', NULL, 'Familie Bauer', 'bauer.familie@email.at', '+43 664 123456',
 'Bergstrasse 15', 'Linz', '4020', 'Apartment', 120, 4, 1, 'One-time', 22.00, 'Active', 'Standard', NOW())
ON CONFLICT DO NOTHING;

-- 3. Populate dim_service
INSERT INTO dim_service 
(service_code, service_name, service_category, pricing_model, base_price, price_per_hour, 
 estimated_hours_min, estimated_hours_max, skill_level, is_active, created_at)
VALUES
('CLEAN_BASIC', 'Grundreinigung', 'Cleaning', 'Hourly', 25.00, 25.00, 2.0, 4.0, 'Basic', TRUE, NOW()),
('CLEAN_DEEP', 'Großreinigung', 'Cleaning', 'Hourly', 35.00, 35.00, 4.0, 8.0, 'Advanced', TRUE, NOW()),
('CLEAN_WINDOW', 'Fensterreinigung', 'Special', 'Fixed', 150.00, NULL, 1.5, 3.0, 'Specialist', TRUE, NOW()),
('CLEAN_CARPET', 'Teppichreinigung', 'Special', 'Per m²', 5.00, NULL, 1.0, 6.0, 'Advanced', TRUE, NOW()),
('CLEAN_OFFICE', 'Büroreinigung', 'Cleaning', 'Monthly', 300.00, 30.00, 3.0, 5.0, 'Basic', TRUE, NOW())
ON CONFLICT DO NOTHING;

-- 4. Populate dim_employee
INSERT INTO dim_employee 
(employee_code, first_name, last_name, email, employment_type, hire_date, 
 certifications, hourly_wage, employee_status, created_at)
VALUES
('EMP001', 'Anna', 'Schmidt', 'anna.schmidt@company.at', 'Full-time', '2023-01-15', 
 'Reinigungsfachkraft', 18.50, 'Active', NOW()),

('EMP002', 'Markus', 'Weber', 'markus.weber@company.at', 'Part-time', '2023-03-20',
 'Fensterreinigung Specialist', 17.00, 'Active', NOW()),

('EMP003', 'Lisa', 'Bauer', 'lisa.bauer@company.at', 'Full-time', '2024-01-10',
 'Teppichreinigung Specialist', 20.00, 'Active', NOW()),

('EMP004', 'Peter', 'Huber', 'peter.huber@company.at', 'Full-time', '2022-06-01',
 'Reinigungsfachkraft', 19.50, 'Active', NOW()),

('EMP005', 'Sonja', 'Keller', 'sonja.keller@company.at', 'Part-time', '2023-09-15',
 NULL, 17.50, 'Active', NOW())
ON CONFLICT DO NOTHING;

-- 5. Populate fact_job (Sample Jobs)
INSERT INTO fact_job 
(job_number, customer_id, service_id, assigned_employee_id, date_id, scheduled_date, 
 scheduled_start_time, job_status, base_price, total_price, duration_planned_hours, 
 duration_actual_hours, quality_score, customer_rating, payment_status, created_at)
SELECT
    'JOB-2024-' || LPAD(ROW_NUMBER() OVER (), 5, '0'),
    (SELECT customer_id FROM dim_customer WHERE customer_status = 'Active' ORDER BY RANDOM() LIMIT 1),
    (SELECT service_id FROM dim_service WHERE is_active = TRUE ORDER BY RANDOM() LIMIT 1),
    (SELECT employee_id FROM dim_employee WHERE employee_status = 'Active' ORDER BY RANDOM() LIMIT 1),
    (SELECT date_id FROM dim_date WHERE full_date >= '2024-01-01' AND full_date <= '2024-02-04' ORDER BY RANDOM() LIMIT 1),
    DATE '2024-01-15' + (RANDOM() * 20)::INT,
    '08:00:00'::TIME + (RANDOM() * 600)::INT,
    CASE (RANDOM() * 3)::INT 
        WHEN 0 THEN 'Completed' 
        WHEN 1 THEN 'In Progress' 
        ELSE 'Scheduled' 
    END,
    100.00,
    150.00,
    3.0,
    CASE WHEN (RANDOM() * 3)::INT = 0 THEN NULL ELSE 3.0 END,
    CASE WHEN (RANDOM() * 3)::INT = 0 THEN NULL ELSE (3 + RANDOM() * 2)::INT END,
    CASE WHEN (RANDOM() * 2)::INT = 0 THEN NULL ELSE (4 + RANDOM())::INT END,
    CASE (RANDOM() * 3)::INT 
        WHEN 0 THEN 'Pending' 
        WHEN 1 THEN 'Paid'
        ELSE 'Overdue'
    END,
    NOW()
FROM GENERATE_SERIES(1, 50)
ON CONFLICT DO NOTHING;

-- 6. Populate fact_recurring_job
INSERT INTO fact_recurring_job 
(customer_id, service_id, recurrence_pattern, recurrence_days, start_date, 
 preferred_time, base_price, is_active, created_at)
VALUES
((SELECT customer_id FROM dim_customer WHERE company_name = 'Firma Müller GmbH' LIMIT 1),
 (SELECT service_id FROM dim_service WHERE service_code = 'CLEAN_BASIC' LIMIT 1),
 'Weekly', 'Monday,Wednesday,Friday', '2024-01-01', '08:00:00', 75.00, TRUE, NOW()),

((SELECT customer_id FROM dim_customer WHERE company_name = 'Hotel Tyrol' LIMIT 1),
 (SELECT service_id FROM dim_service WHERE service_code = 'CLEAN_OFFICE' LIMIT 1),
 'Monthly', '1,15', '2024-01-01', '09:00:00', 300.00, TRUE, NOW())
ON CONFLICT DO NOTHING;

-- 7. Populate fact_inventory
INSERT INTO fact_inventory 
(item_name, item_category, current_quantity, minimum_quantity, maximum_quantity, 
 unit_of_measure, unit_cost, supplier_name, created_at)
VALUES
('Reinigungsmittel Allzweck', 'Cleaning Supplies', 50, 10, 100, 'Liter', 8.50, 'Supplier ABC', NOW()),
('Mikrofasertücher', 'Cleaning Supplies', 200, 50, 500, 'Stück', 0.50, 'Supplier XYZ', NOW()),
('Staubsauger Profi', 'Equipment', 5, 2, 10, 'Stück', 250.00, 'Supplier ABC', NOW()),
('Eimer 10L', 'Equipment', 20, 5, 50, 'Stück', 5.00, 'Supplier ABC', NOW()),
('Handschuhe Nitrile', 'Safety', 500, 100, 1000, 'Stück', 0.10, 'Supplier XYZ', NOW())
ON CONFLICT DO NOTHING;

-- Final Summary
SELECT 
    'Data loaded successfully!' AS status,
    (SELECT COUNT(*) FROM dim_date) AS dates,
    (SELECT COUNT(*) FROM dim_customer) AS customers,
    (SELECT COUNT(*) FROM dim_service) AS services,
    (SELECT COUNT(*) FROM dim_employee) AS employees,
    (SELECT COUNT(*) FROM fact_job) AS jobs,
    (SELECT COUNT(*) FROM fact_recurring_job) AS recurring_jobs,
    (SELECT COUNT(*) FROM fact_inventory) AS inventory_items;