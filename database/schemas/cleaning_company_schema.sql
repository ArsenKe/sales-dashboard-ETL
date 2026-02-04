-- ============================================
-- REINIGUNGSFIRMA DASHBOARD SCHEMA
-- Speziell für Reinigungsdienstleistungen
-- ============================================

-- 1. ZEITDIMENSION - Für Terminplanung und Auswertungen
-- ------------------------------------------------------------
CREATE TABLE dim_date (
    date_id SERIAL PRIMARY KEY,
    full_date DATE UNIQUE NOT NULL,
    
    -- Kalenderdetails
    calendar_year INTEGER NOT NULL,
    calendar_month INTEGER NOT NULL,
    calendar_day INTEGER NOT NULL,
    calendar_quarter INTEGER NOT NULL,
    
    -- Wochendetails
    week_number INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,  -- 0=Montag, 6=Sonntag
    day_name VARCHAR(20) NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    
    -- Business Flags
    is_weekend BOOLEAN NOT NULL,
    is_holiday BOOLEAN DEFAULT FALSE,
    is_business_day BOOLEAN DEFAULT TRUE,
    
    -- Indizes
    
);

-- 2. KUNDENDIMENSION - Firmenkunden + Privatkunden
-- ------------------------------------------------------------
CREATE TABLE dim_customer (
    customer_id SERIAL PRIMARY KEY,
    customer_type VARCHAR(20) NOT NULL,  -- 'Business', 'Private', 'Commercial'
    
    -- Für Firmenkunden
    company_name VARCHAR(255),
    company_vat_number VARCHAR(50),
    contact_person VARCHAR(255),
    
    -- Für Privatkunden
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    
    -- Kontaktdaten (für alle)
    email VARCHAR(255),
    phone VARCHAR(50),
    mobile VARCHAR(50),
    
    -- Adresse (WICHTIG für Reinigungsfirma!)
    address_street VARCHAR(255),
    address_street_number VARCHAR(20),
    address_postal_code VARCHAR(20),
    address_city VARCHAR(100),
    address_country VARCHAR(100) DEFAULT 'Austria',
    address_notes TEXT,  -- "3. Stock, Code 1234"
    
    -- Immobilien-Info (Relevanz für Reinigung)
    property_type VARCHAR(50),  -- 'Apartment', 'Office', 'Warehouse', 'Retail'
    property_size_sqm INTEGER,   -- Größe in m²
    rooms_count INTEGER,         -- Anzahl Zimmer
    bathrooms_count INTEGER,     -- Anzahl Badezimmer
    
    -- Vertragsdetails
    contract_type VARCHAR(50),   -- 'One-time', 'Weekly', 'Bi-weekly', 'Monthly'
    contract_start_date DATE,
    contract_end_date DATE,
    billing_cycle VARCHAR(50),   -- 'Monthly', 'Quarterly', 'On-demand'
    
    -- Preiseinstellungen
    hourly_rate DECIMAL(10,2),
    special_conditions TEXT,
    
    -- Status
    customer_status VARCHAR(50) DEFAULT 'Active',  -- 'Active', 'Inactive', 'On-hold'
    customer_segment VARCHAR(50),  -- 'Premium', 'Standard', 'Budget'
    
    -- System
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    
    -- Indizes
    
);

-- 3. DIENSTLEISTUNGSDIMENSION - Was wird angeboten?
-- ------------------------------------------------------------
CREATE TABLE dim_service (
    service_id SERIAL PRIMARY KEY,
    service_code VARCHAR(50) UNIQUE NOT NULL,  -- 'CLEAN_BASIC', 'CLEAN_DEEP', 'WINDOW'
    
    -- Service Details
    service_name VARCHAR(255) NOT NULL,  -- 'Grundreinigung', 'Fensterreinigung', 'Teppichreinigung'
    service_description TEXT,
    service_category VARCHAR(100),  -- 'Cleaning', 'Special', 'Maintenance'
    
    -- Preismodelle
    pricing_model VARCHAR(50) NOT NULL,  -- 'Hourly', 'Per m²', 'Fixed', 'Package'
    base_price DECIMAL(10,2) NOT NULL,
    price_per_hour DECIMAL(10,2),
    price_per_sqm DECIMAL(10,2),
    minimum_price DECIMAL(10,2),
    
    -- Zeitaufwand
    estimated_hours_min DECIMAL(5,2),  -- Minimale Stunden
    estimated_hours_max DECIMAL(5,2),  -- Maximale Stunden
    
    -- Service Eigenschaften
    required_equipment TEXT,  -- 'Staubsauger, Reinigungsmittel, Leiter'
    required_cleaning_supplies TEXT,
    skill_level VARCHAR(50),  -- 'Basic', 'Advanced', 'Specialist'
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    service_notes TEXT,
    
    -- System
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. MITARBEITERDIMENSION - Reinigungskräfte
-- ------------------------------------------------------------
CREATE TABLE dim_employee (
    employee_id SERIAL PRIMARY KEY,
    employee_code VARCHAR(50) UNIQUE NOT NULL,  -- 'EMP001'
    
    -- Personaldaten
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    full_name VARCHAR(255) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
    
    -- Kontakt
    email VARCHAR(255),
    phone VARCHAR(50),
    mobile VARCHAR(50),
    
    -- Anschrift
    address_street VARCHAR(255),
    address_city VARCHAR(100),
    
    -- Arbeitsdaten
    employment_type VARCHAR(50) NOT NULL,  -- 'Full-time', 'Part-time', 'Freelancer'
    hire_date DATE NOT NULL,
    termination_date DATE,
    
    -- Qualifikationen
    certifications TEXT,  -- 'Reinigungsfachkraft, Fensterreinigungsspezialist'
    skills TEXT,  -- 'Carpet cleaning, Window cleaning, Deep cleaning'
    available_equipment TEXT,  -- 'Eigener Staubsauger, Leiter'
    
    -- Verfügbarkeit
    work_schedule TEXT,  -- JSON oder Text mit Verfügbarkeit
    preferred_working_hours TEXT,
    
    -- Bezahlung
    hourly_wage DECIMAL(10,2),
    payment_method VARCHAR(50),
    
    -- Status
    employee_status VARCHAR(50) DEFAULT 'Active',  -- 'Active', 'On-leave', 'Inactive'
    performance_rating DECIMAL(3,2),
    
    -- System
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Indizes
    
);

-- 5. FAKTTABELLE - AUFTRÄGE/TERMINE (Das HERZSTÜCK!)
-- ------------------------------------------------------------
CREATE TABLE fact_job (
    job_id SERIAL PRIMARY KEY,
    job_number VARCHAR(100) UNIQUE NOT NULL,  -- 'JOB-2024-001'
    
    -- Fremdschlüssel
    customer_id INTEGER NOT NULL REFERENCES dim_customer(customer_id),
    service_id INTEGER NOT NULL REFERENCES dim_service(service_id),
    assigned_employee_id INTEGER REFERENCES dim_employee(employee_id),
    date_id INTEGER NOT NULL REFERENCES dim_date(date_id),
    
    -- Terminplanung
    scheduled_date DATE NOT NULL,
    scheduled_start_time TIME,
    scheduled_end_time TIME,
    actual_start_time TIMESTAMP,
    actual_end_time TIMESTAMP,
    duration_planned_hours DECIMAL(5,2),  -- Geplante Stunden
    duration_actual_hours DECIMAL(5,2),   -- Tatsächliche Stunden
    
    -- Job Details
    job_type VARCHAR(50) NOT NULL,  -- 'One-time', 'Recurring', 'Emergency'
    job_status VARCHAR(50) NOT NULL DEFAULT 'Scheduled',  -- 'Scheduled', 'In Progress', 'Completed', 'Cancelled'
    priority VARCHAR(50) DEFAULT 'Normal',  -- 'Low', 'Normal', 'High', 'Emergency'
    
    -- Ort/Adresse (kann von Kundenadresse abweichen)
    job_address_street VARCHAR(255),
    job_address_city VARCHAR(100),
    job_address_notes TEXT,
    access_instructions TEXT,  -- "Schlüssel beim Nachbarn, Code 1234"
    
    -- Service-spezifische Details
    property_size_sqm INTEGER,
    rooms_to_clean INTEGER,
    bathrooms_to_clean INTEGER,
    windows_to_clean INTEGER,
    special_instructions TEXT,  -- "Keine chemischen Mittel verwenden"
    
    -- Preiskalkulation
    base_price DECIMAL(10,2) NOT NULL,
    additional_charges DECIMAL(10,2) DEFAULT 0,  -- Zusatzleistungen
    discount_amount DECIMAL(10,2) DEFAULT 0,
    travel_cost DECIMAL(10,2) DEFAULT 0,  -- Anfahrtskosten
    material_cost DECIMAL(10,2) DEFAULT 0,  -- Materialkosten
    total_price DECIMAL(10,2) NOT NULL,  -- Endpreis
    
    -- Zahlung
    payment_method VARCHAR(50),
    payment_status VARCHAR(50) DEFAULT 'Pending',  -- 'Pending', 'Paid', 'Overdue'
    invoice_number VARCHAR(100),
    invoice_date DATE,
    payment_date DATE,
    
    -- Qualitätskontrolle
    quality_check_done BOOLEAN DEFAULT FALSE,
    quality_score INTEGER CHECK (quality_score BETWEEN 1 AND 5),
    customer_feedback TEXT,
    customer_rating INTEGER CHECK (customer_rating BETWEEN 1 AND 5),
    
    -- Materialverbrauch
    cleaning_supplies_used TEXT,
    equipment_used TEXT,
    
    -- Notizen
    internal_notes TEXT,
    completion_notes TEXT,
    
    -- System
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    
    -- Indizes für Performance
    
);

-- 6. WIEDERKEHRENDE AUFTRÄGE
-- ------------------------------------------------------------
CREATE TABLE fact_recurring_job (
    recurring_job_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES dim_customer(customer_id),
    service_id INTEGER NOT NULL REFERENCES dim_service(service_id),
    
    -- Wiederholungsmuster
    recurrence_pattern VARCHAR(50) NOT NULL,  -- 'Weekly', 'Bi-weekly', 'Monthly'
    recurrence_days TEXT,  -- 'Monday,Wednesday,Friday' oder '1,15' für Monatstage
    start_date DATE NOT NULL,
    end_date DATE,
    
    -- Terminzeiten
    preferred_time TIME,
    preferred_day VARCHAR(20),
    
    -- Details
    base_price DECIMAL(10,2),
    notes TEXT,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    last_generated_date DATE,
    
    -- System
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. MATERIAL/LAGER
-- ------------------------------------------------------------
CREATE TABLE fact_inventory (
    inventory_id SERIAL PRIMARY KEY,
    item_name VARCHAR(255) NOT NULL,
    item_category VARCHAR(100),  -- 'Cleaning Supplies', 'Equipment', 'Safety'
    
    -- Bestand
    current_quantity INTEGER DEFAULT 0,
    minimum_quantity INTEGER DEFAULT 10,
    maximum_quantity INTEGER DEFAULT 100,
    unit_of_measure VARCHAR(50),  -- 'Liter', 'Kilogramm', 'Stück'
    
    -- Kosten
    unit_cost DECIMAL(10,2),
    supplier_name VARCHAR(255),
    
    -- Verwendung
    used_in_services TEXT,  -- Welche Services verwenden dieses Material
    
    -- System
    last_restock_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- HILFSFUNKTIONEN
-- ============================================

-- Funktion für updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger für alle Tabellen
CREATE TRIGGER update_customer_updated_at 
    BEFORE UPDATE ON dim_customer FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_service_updated_at 
    BEFORE UPDATE ON dim_service FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_employee_updated_at 
    BEFORE UPDATE ON dim_employee FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_job_updated_at 
    BEFORE UPDATE ON fact_job FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- VIEWS FÜR DASHBOARDS
-- ============================================

-- View: Tägliche Auftragsübersicht
CREATE VIEW vw_daily_jobs AS
SELECT 
    dd.full_date,
    dd.day_name,
    COUNT(DISTINCT fj.job_id) AS total_jobs,
    COUNT(DISTINCT fj.customer_id) AS unique_customers,
    SUM(fj.duration_actual_hours) AS total_worked_hours,
    SUM(fj.total_price) AS daily_revenue,
    AVG(fj.quality_score) AS avg_quality_score,
    SUM(CASE WHEN fj.job_status = 'Completed' THEN 1 ELSE 0 END) AS completed_jobs,
    SUM(CASE WHEN fj.payment_status = 'Paid' THEN 1 ELSE 0 END) AS paid_jobs
FROM fact_job fj
JOIN dim_date dd ON fj.date_id = dd.date_id
GROUP BY dd.full_date, dd.day_name
ORDER BY dd.full_date DESC;

-- View: Mitarbeiterleistung
CREATE VIEW vw_employee_performance AS
SELECT 
    de.employee_id,
    de.full_name,
    de.employee_status,
    COUNT(DISTINCT fj.job_id) AS total_jobs_assigned,
    SUM(fj.duration_actual_hours) AS total_hours_worked,
    SUM(fj.total_price) AS total_revenue_generated,
    AVG(fj.quality_score) AS avg_quality_score,
    AVG(fj.customer_rating) AS avg_customer_rating
FROM dim_employee de
LEFT JOIN fact_job fj ON de.employee_id = fj.assigned_employee_id
GROUP BY de.employee_id, de.full_name, de.employee_status
ORDER BY total_revenue_generated DESC NULLS LAST;

-- View: Kundenübersicht
CREATE VIEW vw_customer_overview AS
SELECT 
    dc.customer_id,
    dc.company_name,
    dc.contact_person,
    dc.address_city,
    dc.customer_type,
    dc.customer_status,
    dc.contract_type,
    COUNT(DISTINCT fj.job_id) AS total_jobs,
    SUM(fj.total_price) AS total_spent,
    AVG(fj.customer_rating) AS avg_rating
FROM dim_customer dc
LEFT JOIN fact_job fj ON dc.customer_id = fj.customer_id
GROUP BY dc.customer_id, dc.company_name, dc.contact_person, dc.address_city, 
         dc.customer_type, dc.customer_status, dc.contract_type
ORDER BY total_spent DESC NULLS LAST;

-- View: Dienstleistungsanalyse
CREATE VIEW vw_service_analysis AS
SELECT 
    ds.service_id,
    ds.service_name,
    ds.service_category,
    ds.pricing_model,
    COUNT(DISTINCT fj.job_id) AS times_booked,
    COUNT(DISTINCT fj.customer_id) AS unique_customers,
    SUM(fj.total_price) AS total_revenue,
    AVG(fj.duration_actual_hours) AS avg_duration_hours
FROM dim_service ds
LEFT JOIN fact_job fj ON ds.service_id = fj.service_id
GROUP BY ds.service_id, ds.service_name, ds.service_category, ds.pricing_model
ORDER BY total_revenue DESC NULLS LAST;

-- View: Offene Zahlungen
CREATE VIEW vw_outstanding_payments AS
SELECT 
    fj.job_number,
    dc.company_name,
    dc.contact_person,
    fj.scheduled_date,
    fj.total_price,
    fj.payment_status,
    fj.invoice_number,
    fj.invoice_date
FROM fact_job fj
JOIN dim_customer dc ON fj.customer_id = dc.customer_id
WHERE fj.payment_status IN ('Pending', 'Overdue')
ORDER BY fj.invoice_date DESC;

-- ============================================
-- BEISPIELDATEN
-- ============================================

-- Beispiel: Dienstleistungen
INSERT INTO dim_service (service_code, service_name, service_category, pricing_model, base_price, price_per_hour) VALUES
('CLEAN_BASIC', 'Grundreinigung', 'Cleaning', 'Hourly', 25.00, 25.00),
('CLEAN_DEEP', 'Großreinigung', 'Cleaning', 'Hourly', 35.00, 35.00),
('CLEAN_WINDOW', 'Fensterreinigung', 'Special', 'Fixed', 150.00, NULL),
('CLEAN_CARPET', 'Teppichreinigung', 'Special', 'Per m²', 5.00, NULL),
('CLEAN_OFFICE', 'Büroreinigung', 'Cleaning', 'Monthly', 300.00, 30.00);

-- Beispiel: Kunden
INSERT INTO dim_customer (customer_type, company_name, contact_person, email, phone, address_city, contract_type) VALUES
('Business', 'Tech Solutions GmbH', 'Herr Müller', 'mueller@tech-solutions.at', '+43 123 456789', 'Vienna', 'Monthly'),
('Business', 'Bäckerei Schmidt', 'Frau Schmidt', 'office@baeckerei-schmidt.at', '+43 987 654321', 'Graz', 'Weekly'),
('Private', NULL, 'Familie Bauer', 'bauer.familie@email.com', '+43 555 123456', 'Linz', 'One-time');

-- Beispiel: Mitarbeiter
INSERT INTO dim_employee (employee_code, first_name, last_name, employment_type, hire_date, hourly_wage) VALUES
('EMP001', 'Anna', 'Schmidt', 'Full-time', '2023-01-15', 18.50),
('EMP002', 'Markus', 'Weber', 'Part-time', '2023-03-20', 17.00),
('EMP003', 'Lisa', 'Bauer', 'Freelancer', '2024-01-10', 20.00);

-- ============================================
--  INDICES CREATED SEPARATELY (after all tables)

CREATE INDEX IF NOT EXISTS idx_dim_date_full_date ON dim_date(full_date);
CREATE INDEX IF NOT EXISTS idx_customer_type ON dim_customer(customer_type);
CREATE INDEX IF NOT EXISTS idx_customer_city ON dim_customer(address_city);
CREATE INDEX IF NOT EXISTS idx_customer_status ON dim_customer(customer_status);
CREATE INDEX IF NOT EXISTS idx_employee_status ON dim_employee(employee_status);
CREATE INDEX IF NOT EXISTS idx_employee_type ON dim_employee(employment_type);
CREATE INDEX IF NOT EXISTS idx_job_date ON fact_job(date_id);
CREATE INDEX IF NOT EXISTS idx_job_customer ON fact_job(customer_id);
CREATE INDEX IF NOT EXISTS idx_job_employee ON fact_job(assigned_employee_id);
CREATE INDEX IF NOT EXISTS idx_job_status ON fact_job(job_status);
CREATE INDEX IF NOT EXISTS idx_job_scheduled_date ON fact_job(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_job_payment_status ON fact_job(payment_status);
CREATE INDEX IF NOT EXISTS idx_job_created_at ON fact_job(created_at DESC);