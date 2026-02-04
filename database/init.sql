-- Cleaning Company Dashboard - Database Initialization
-- Docker calls this script automatically on first startup
-- Entry point that loads schema + sample data in correct order

-- 1. Load main schema (dimensions, facts, views, triggers)
\i /docker-entrypoint-initdb.d/schemas/cleaning_company_schema.sql

-- 2. Load sample/demo data
\i /docker-entrypoint-initdb.d/schemas/sample_data.sql

-- 3. Verification & Summary
SELECT '✅ Database initialization completed successfully!' AS status;

-- Show table counts
SELECT 
    'Tables & Data Summary' AS report,
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE') AS total_tables,
    (SELECT COUNT(*) FROM dim_date) AS dim_date_records,
    (SELECT COUNT(*) FROM dim_customer) AS dim_customer_records,
    (SELECT COUNT(*) FROM dim_service) AS dim_service_records,
    (SELECT COUNT(*) FROM dim_employee) AS dim_employee_records,
    (SELECT COUNT(*) FROM fact_job) AS fact_job_records;
