														-- TASK 1 - DATABASE DESIGN AND NORMALIZATION

-- CREATING THE DATABASE

CREATE DATABASE IF NOT EXISTS cardiology_clinic_db;

USE cardiology_clinic_db;

-- CREATING TABLES
-- A. CLINIC STRUCTURE
-- 1. DEPARTMENT --
CREATE TABLE department (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    dept_code VARCHAR(10) NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL UNIQUE,
    phone VARCHAR(30),
    CONSTRAINT ck_dept_code CHECK (dept_code LIKE 'BHC-%')
);

-- 2. PROVIDER
CREATE TABLE provider (
    provider_id INT AUTO_INCREMENT PRIMARY KEY,
    npi VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(80) NOT NULL,
    last_name VARCHAR(80) NOT NULL,
    role VARCHAR(30) NOT NULL,
    phone VARCHAR(30),
    email VARCHAR(120),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT ck_provider_role CHECK (role IN ('CARDIOLOGIST' , 'NURSE', 'TECH', 'ADMIN'))
);

-- 3. STAFF ASSIGNMENT
CREATE TABLE staff_assignment (
    provider_id INT NOT NULL,
    department_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    PRIMARY KEY (provider_id , department_id , start_date),
    FOREIGN KEY (provider_id)
        REFERENCES provider (provider_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (department_id)
        REFERENCES department (department_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_staff_assignment_dates CHECK (end_date IS NULL OR end_date >= start_date)
);

-- B. PATIENTS & INSURANCE
-- 4. PATIENTS
CREATE TABLE patient (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    mrn VARCHAR(30) NOT NULL UNIQUE,
    first_name VARCHAR(80) NOT NULL,
    last_name VARCHAR(80) NOT NULL,
    date_of_birth DATE NOT NULL,
    sex CHAR(1) NOT NULL,
    phone VARCHAR(30),
    email VARCHAR(120),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_patient_sex CHECK (sex IN ('M' , 'F', 'O'))
);
-- 5. INSURANCE PLAN
CREATE TABLE insurance_plan (
    plan_id INT AUTO_INCREMENT PRIMARY KEY,
    payer_name VARCHAR(120) NOT NULL,
    plan_name VARCHAR(120) NOT NULL,
    plan_type VARCHAR(30) NOT NULL,
    UNIQUE (payer_name , plan_name),
    CONSTRAINT ck_plan_type CHECK (plan_type IN ('PUBLIC' , 'PRIVATE', 'SELF_PAY'))
);
-- 6. INSURANCE COVERAGE
CREATE TABLE insurance_coverage (
    patient_id INT NOT NULL,
    plan_id INT NOT NULL,
    member_id VARCHAR(60) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (patient_id , plan_id , member_id , start_date),
    FOREIGN KEY (patient_id)
        REFERENCES patient (patient_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (plan_id)
        REFERENCES insurance_plan (plan_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_coverage_dates CHECK (end_date IS NULL OR end_date >= start_date)
);

-- C. VISITS AND CLINICAL DETAILS
-- 7. CLINICAL VISITS
CREATE TABLE clinical_visit (
    visit_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    provider_id INT NOT NULL,
    department_id INT NOT NULL,
    scheduled_start DATETIME NULL,
    scheduled_end DATETIME NULL,
    visit_start DATETIME NOT NULL,
    visit_end DATETIME NULL,
    visit_type VARCHAR(30) NOT NULL,
    visit_status VARCHAR(20) NOT NULL DEFAULT 'COMPLETED',
    chief_complaint VARCHAR(200),
    notes TEXT,
    FOREIGN KEY (patient_id)
        REFERENCES patient (patient_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (provider_id)
        REFERENCES provider (provider_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (department_id)
        REFERENCES department (department_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_visit_type CHECK (visit_type IN ('OUTPATIENT' , 'EMERGENCY', 'TELEHEALTH')),
    CONSTRAINT ck_visit_status CHECK (visit_status IN ('BOOKED' , 'CANCELLED', 'NO_SHOW', 'IN_PROGRESS', 'COMPLETED')),
    CONSTRAINT ck_visit_time CHECK (visit_end IS NULL OR visit_end >= visit_start),
    CONSTRAINT ck_scheduled_time CHECK ((scheduled_start IS NULL AND scheduled_end IS NULL) OR (scheduled_start IS NOT NULL AND scheduled_end 
    IS NOT NULL AND scheduled_end > scheduled_start))
);
-- 8. VISIT VITALS
CREATE TABLE visit_vitals (
    visit_id INT PRIMARY KEY,
    systolic_bp SMALLINT NULL,
    diastolic_bp SMALLINT NULL,
    heart_rate_bpm SMALLINT NULL,
    recorded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (visit_id) REFERENCES clinical_visit (visit_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ck_bp CHECK ((systolic_bp IS NULL AND diastolic_bp IS NULL) OR (systolic_bp BETWEEN 60 AND 260 AND diastolic_bp BETWEEN 30 AND 160 AND systolic_bp > diastolic_bp)),
    CONSTRAINT ck_hr CHECK (heart_rate_bpm IS NULL OR heart_rate_bpm BETWEEN 20 AND 250)
);

-- 9. DIAGNOSIS
CREATE TABLE diagnosis (
  diagnosis_id INT AUTO_INCREMENT PRIMARY KEY,
  icd10_code   VARCHAR(10) NOT NULL UNIQUE,
  name         VARCHAR(200) NOT NULL);
-- 10. VISIT DIAGNOSIS
CREATE TABLE visit_diagnosis (
  visit_id        INT NOT NULL,
  diagnosis_id    INT NOT NULL,
  diagnosis_role  VARCHAR(20) NOT NULL DEFAULT 'SECONDARY',
  recorded_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (visit_id, diagnosis_id),
  FOREIGN KEY (visit_id) REFERENCES clinical_visit(visit_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (diagnosis_id) REFERENCES diagnosis(diagnosis_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_diagnosis_role CHECK (diagnosis_role IN ('PRIMARY','SECONDARY','RULE_OUT'))
);
-- 11. PROCEDURE MASTER
CREATE TABLE procedure_master (
  procedure_id INT AUTO_INCREMENT PRIMARY KEY,
  proc_code    VARCHAR(12) NOT NULL UNIQUE,
  name         VARCHAR(200) NOT NULL,
  category     VARCHAR(30) NOT NULL,
  base_price   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  CONSTRAINT ck_proc_category CHECK (category IN ('CONSULT','ECG','ECHO','STRESS_TEST','HOLTER','OTHER')),
  CONSTRAINT ck_proc_base_price CHECK (base_price >= 0)
);
-- 12. VISIT PROCEDURE
CREATE TABLE visit_procedure (
  visit_id      INT NOT NULL,
  procedure_id  INT NOT NULL,
  performed_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  quantity      INT NOT NULL DEFAULT 1,
  unit_price    DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (visit_id, procedure_id, performed_at),
  FOREIGN KEY (visit_id) REFERENCES clinical_visit(visit_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (procedure_id) REFERENCES procedure_master(procedure_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_visit_proc_qty CHECK (quantity > 0),
  CONSTRAINT ck_visit_proc_price CHECK (unit_price >= 0));

-- D. BILLING
-- 13. INVOICE BILLIING HEADER
CREATE TABLE invoice (
  invoice_id     INT AUTO_INCREMENT PRIMARY KEY,
  visit_id       INT NOT NULL UNIQUE,
  issued_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  invoice_status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
  total_amount   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  paid_amount     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  paid_at         DATETIME NULL,
  payment_method  VARCHAR(20) NULL,
  payer_type      VARCHAR(20) NULL,
  FOREIGN KEY (visit_id) REFERENCES clinical_visit(visit_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_invoice_status CHECK (invoice_status IN ('OPEN','PARTIALLY_PAID','PAID','VOID')),
  CONSTRAINT ck_invoice_total CHECK (total_amount >= 0),
  CONSTRAINT ck_invoice_paid CHECK (paid_amount >= 0 AND paid_amount <= total_amount),
  CONSTRAINT ck_payment_method CHECK (payment_method IS NULL OR payment_method IN ('CASH','CARD','BANK_TRANSFER','ONLINE')),
  CONSTRAINT ck_payer_type CHECK (payer_type IS NULL OR payer_type IN ('PATIENT','INSURER'))
);

-- 14. INVOICE LINE BILLING LINE ITEMS
CREATE TABLE invoice_line (
  invoice_line_id INT AUTO_INCREMENT PRIMARY KEY,
  invoice_id      INT NOT NULL,
  line_type       VARCHAR(20) NOT NULL DEFAULT 'PROCEDURE',
  description     VARCHAR(200) NOT NULL,
  quantity        INT NOT NULL DEFAULT 1,
  unit_price      DECIMAL(10,2) NOT NULL,
  procedure_id    INT NULL,
  FOREIGN KEY (invoice_id) REFERENCES invoice(invoice_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (procedure_id) REFERENCES procedure_master(procedure_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT ck_line_type CHECK (line_type IN ('PROCEDURE','OTHER')),
  CONSTRAINT ck_line_qty CHECK (quantity > 0),
  CONSTRAINT ck_line_price CHECK (unit_price >= 0)
);

													-- TASK 2 - DATA INSERT AND VIEW CREATIONS
												
-- Inserting Data into the tables created.
-- 1. Department
INSERT INTO department (dept_code, name, phone) VALUES
('BHC-OPD',  'Outpatient Cardiology', '+49 30 1000 1001'),
('BHC-DIAG', 'Cardiac Diagnostics',   '+49 30 1000 1002'),
('BHC-REH',  'Cardiac Rehabilitation','+49 30 1000 1003'),
('BHC-ADM',  'Administration',        '+49 30 1000 1099');
-- 2. Provider
INSERT INTO provider (npi, first_name, last_name, role, phone, email) VALUES
('NPI10001','Hannah','Klein','CARDIOLOGIST','+49 30 2000 1001','h.klein@clinic.example'),
('NPI10002','Markus','Vogel','CARDIOLOGIST','+49 30 2000 1002','m.vogel@clinic.example'),
('NPI20001','Sofia','Weber','NURSE','+49 30 2000 2001','s.weber@clinic.example'),
('NPI30001','Jonas','Richter','TECH','+49 30 2000 3001','j.richter@clinic.example'),
('NPI30002','Lea','Schmidt','TECH','+49 30 2000 3002','l.schmidt@clinic.example'),
('NPI90001','Aylin','Demir','ADMIN','+49 30 2000 9001','a.demir@clinic.example');
-- 3. Staff Assignment
INSERT INTO staff_assignment (provider_id, department_id, start_date) VALUES
(1,1,'2024-01-01'),
(1,2,'2024-01-01'),
(2,1,'2024-03-01'),
(2,2,'2024-03-01'),
(3,1,'2024-01-01'),
(4,2,'2024-01-01'),
(5,2,'2024-06-01'),
(6,4,'2024-01-01'); 
-- 4. Patients
INSERT INTO patient (mrn, first_name, last_name, date_of_birth, sex, phone, email) VALUES
('MRN001','Noah','Meyer','1982-05-14','M','+49 30 3001','noah.m@gmail.com'),
('MRN002','Emma','Fischer','1975-11-02','F','+49 30 3002','emma.f@gmail.com'),
('MRN003','Liam','Wagner','1990-03-22','M','+49 30 3003','liam.w@gmail.com'),
('MRN004','Mia','Becker','1968-07-09','F','+49 30 3004','mia.b@gmail.com'),
('MRN005','Elias','Hoffmann','1959-12-18','M','+49 30 3005','elias.h@gmail.com'),
('MRN006','Sophie','Koch','1987-09-01','F','+49 30 3006','sophie.k@gmail.com'),
('MRN007','Ben','Schulz','1979-01-27','M','+49 30 3007','ben.s@gmail.com'),
('MRN008','Olivia','Neumann','1995-06-30','F','+49 30 3008','olivia.n@gmail.com'),
('MRN009','Paul','Zimmer','1963-02-11','M','+49 30 3009','paul.z@gmail.com'),
('MRN010','Ava','Hartmann','1984-08-25','O','+49 30 3010','ava.h@gmail.com'),
('MRN011','Leo','Brandt','1971-04-03','M','+49 30 3011','leo.b@gmail.com'),
('MRN012','Clara','Seidel','1992-10-12','F','+49 30 3012','clara.s@gmail.com'),
('MRN013','Finn','Lorenz','1980-06-18','M','+49 30 3013','finn.l@gmail.com'),
('MRN014','Nina','Kramer','1965-01-05','F','+49 30 3014','nina.k@gmail.com'),
('MRN015','Tom','Bauer','1957-09-29','M','+49 30 3015','tom.b@gmail.com');

-- 5. Insurance Plan
INSERT INTO insurance_plan (payer_name, plan_name, plan_type) VALUES
('AOK','AOK Basic','PUBLIC'),
('TK','TK Standard','PUBLIC'),
('Barmer','Barmer Classic','PUBLIC'),
('Allianz','Allianz Silver','PRIVATE'),
('AXA','AXA Premium','PRIVATE'),
('Self','Self Pay','SELF_PAY');
-- 6. Insurance Coverage
INSERT INTO insurance_coverage (patient_id, plan_id, member_id, start_date, is_primary) VALUES
(1,1,'AOK-001','2024-01-01',TRUE),
(2,2,'TK-002','2024-01-01',TRUE),
(3,4,'ALZ-003','2024-06-01',TRUE),
(4,3,'BAR-004','2024-01-01',TRUE),
(5,1,'AOK-005','2024-01-01',TRUE),
(6,5,'AXA-006','2025-01-01',TRUE),
(7,2,'TK-007','2024-01-01',TRUE),
(8,6,'SELF-008','2025-01-01',TRUE),
(9,3,'BAR-009','2024-01-01',TRUE),
(10,4,'ALZ-010','2025-02-01',TRUE),
(11,1,'AOK-011','2024-01-01',TRUE),
(12,2,'TK-012','2024-01-01',TRUE),
(13,3,'BAR-013','2024-01-01',TRUE),
(14,5,'AXA-014','2025-01-01',TRUE),
(15,6,'SELF-015','2025-01-01',TRUE);
-- 7. clinical Visit
INSERT INTO clinical_visit
(patient_id, provider_id, department_id, visit_start, visit_end, visit_type, visit_status, chief_complaint)
VALUES
(1,1,1,'2025-06-01 09:00','2025-06-01 09:30','OUTPATIENT','COMPLETED','Chest pain'),
(1,1,2,'2025-08-15 10:00','2025-08-15 10:40','OUTPATIENT','COMPLETED','Follow-up ECG'),
(2,2,1,'2025-06-05 11:00','2025-06-05 11:25','OUTPATIENT','COMPLETED','Palpitations'),
(3,1,2,'2025-07-01 08:30','2025-07-01 09:10','OUTPATIENT','COMPLETED','Shortness of breath'),
(4,2,2,'2025-07-12 11:00','2025-07-12 11:40','OUTPATIENT','COMPLETED','Hypertension'),
(5,1,1,'2025-08-10 09:30','2025-08-10 10:05','OUTPATIENT','COMPLETED','Exertional pain'),
(6,2,1,'2025-09-01 14:00','2025-09-01 14:25','TELEHEALTH','COMPLETED','Medication review'),
(7,1,2,'2025-10-12 10:00','2025-10-12 10:40','OUTPATIENT','COMPLETED','Dizziness'),
(8,2,1,'2025-11-20 09:00','2025-11-20 09:25','OUTPATIENT','COMPLETED','Fast heartbeat'),
(9,1,3,'2025-12-05 15:00','2025-12-05 15:30','OUTPATIENT','COMPLETED','Rehab follow-up'),
(10,2,2,'2026-01-10 12:00','2026-01-10 12:40','OUTPATIENT','COMPLETED','Heart screening'),
(11,1,1,'2025-06-18 09:00','2025-06-18 09:30','OUTPATIENT','COMPLETED','Chest pain'),
(12,2,1,'2025-07-22 10:30','2025-07-22 11:00','OUTPATIENT','COMPLETED','Palpitations'),
(13,1,2,'2025-08-03 08:45','2025-08-03 09:20','OUTPATIENT','COMPLETED','Breathlessness'),
(14,2,2,'2025-09-14 11:00','2025-09-14 11:35','OUTPATIENT','COMPLETED','BP control'),
(15,1,1,'2025-10-05 09:30','2025-10-05 10:00','OUTPATIENT','COMPLETED','Routine review'),
(3,1,1,'2025-11-02 09:15','2025-11-02 09:45','OUTPATIENT','COMPLETED','Follow-up'),
(5,2,2,'2025-12-10 10:00','2025-12-10 10:40','OUTPATIENT','COMPLETED','Stress test'),
(1,1,1,'2026-01-15 09:00','2026-01-15 09:30','OUTPATIENT','COMPLETED','Annual check'),
(8,2,1,'2026-02-01 09:00','2026-02-01 09:25','OUTPATIENT','COMPLETED','Holter review'); 

-- 8. Visit Vitals
INSERT INTO visit_vitals (visit_id, systolic_bp, diastolic_bp, heart_rate_bpm) VALUES
(1,145,95,82),
(2,138,88,78),
(3,128,82,96),
(4,135,85,76),
(5,150,98,72),
(6,125,80,70),
(7,148,92,84),
(8,132,86,90),
(9,120,78,66),
(10,122,80,64),
(11,142,90,80),
(12,130,84,92),
(13,140,88,79),
(14,155,96,75),
(15,118,76,68);
-- 9. Diagnosis
INSERT INTO diagnosis (icd10_code, name) VALUES
('I10','Essential hypertension'),
('I20.9','Angina pectoris'),
('I48.0','Atrial fibrillation'),
('R00.2','Palpitations'),
('R06.02','Shortness of breath'),
('R42','Dizziness'),
('Z13.6','Cardiac screening'),
('Z09','Follow-up after treatment');
-- 10. Visit Diagnosis
INSERT INTO visit_diagnosis (visit_id, diagnosis_id, diagnosis_role) VALUES
(1,2,'PRIMARY'),(1,1,'SECONDARY'),
(2,8,'PRIMARY'),
(3,4,'PRIMARY'),(3,3,'SECONDARY'),
(4,5,'PRIMARY'),
(5,1,'PRIMARY'),
(6,8,'PRIMARY'),
(7,6,'PRIMARY'),
(8,4,'PRIMARY'),
(9,8,'PRIMARY'),
(10,7,'PRIMARY'),
(11,2,'PRIMARY'),
(12,4,'PRIMARY'),
(13,5,'PRIMARY'),
(14,1,'PRIMARY'),
(15,8,'PRIMARY'),
(16,8,'PRIMARY'),
(17,8,'PRIMARY'),
(18,1,'PRIMARY'),
(19,7,'PRIMARY'),
(20,4,'PRIMARY');

-- 11. Procedure Master
INSERT INTO procedure_master (proc_code, name, category, base_price) VALUES
('CONS-001','Cardiology Consultation','CONSULT',120),
('ECG-010','12-Lead ECG','ECG',35),
('ECHO-020','Echocardiogram','ECHO',180),
('STR-030','Stress Test','STRESS_TEST',210),
('HOL-040','Holter Monitoring','HOLTER',160),
('CONS-002','Telehealth Review','CONSULT',80),
('OTR-900','Clinical Report','OTHER',25),
('OTR-910','Rehab Session','OTHER',60);

-- 12. Visit Procedure
INSERT INTO visit_procedure (visit_id, procedure_id, quantity, unit_price) VALUES
(1,1,1,120),
(1,2,1,35),
(2,2,1,35),
(3,1,1,120),
(3,5,1,160),
(4,1,1,120),
(4,3,1,180),
(5,1,1,120),
(6,6,1,80),
(7,1,1,120),
(7,3,1,180),
(8,5,1,160),
(9,8,1,60),
(10,1,1,120),
(11,1,1,120),
(12,5,1,160),
(13,3,1,180),
(14,1,1,120),
(15,1,1,120),
(16,1,1,120),
(17,4,1,210),
(18,1,1,120);

-- 13. Invoice
INSERT INTO invoice
(visit_id, invoice_status, total_amount, paid_amount, payment_method, payer_type)
VALUES
(1,'PAID',155,155,'CARD','PATIENT'),
(2,'PAID',35,35,'CARD','PATIENT'),
(3,'PARTIALLY_PAID',280,80,'CARD','PATIENT'),
(4,'OPEN',300,0,NULL,NULL),
(5,'OPEN',120,0,NULL,NULL),
(7,'OPEN',300,0,NULL,NULL),
(9,'PAID',60,60,'CASH','PATIENT'),
(10,'PAID',120,120,'ONLINE','INSURER'),
(12,'PAID',160,160,'CARD','PATIENT'),
(14,'OPEN',120,0,NULL,NULL),
(17,'OPEN',210,0,NULL,NULL);

-- 14. Invoice Line
INSERT INTO invoice_line
(invoice_id, line_type, description, quantity, unit_price, procedure_id)
VALUES
(1,'PROCEDURE','Consultation',1,120,1),
(1,'PROCEDURE','ECG',1,35,2),
(2,'PROCEDURE','ECG',1,35,2),
(3,'PROCEDURE','Consultation',1,120,1),
(3,'PROCEDURE','Holter Monitoring',1,160,5),
(4,'PROCEDURE','Consultation',1,120,1),
(4,'PROCEDURE','Echocardiogram',1,180,3),
(5,'PROCEDURE','Consultation',1,120,1),
(7,'PROCEDURE','Consultation',1,120,1),
(9,'PROCEDURE','Rehab Session',1,60,8),
(10,'PROCEDURE','Consultation',1,120,1),
(11,'PROCEDURE','Stress Test',1,210,4);


-- View Creation --
-- 1. Monthly Billing Summary by Department

CREATE OR REPLACE VIEW vw_department_monthly_billing AS
SELECT
    d.name AS department_name,
    DATE_FORMAT(v.visit_start, '%Y-%m') AS billing_month,
    COUNT(DISTINCT i.invoice_id) AS total_invoices,
    SUM(i.total_amount) AS total_billed_amount,
    SUM(i.paid_amount) AS total_paid_amount
FROM department d
JOIN clinical_visit v
    ON d.department_id = v.department_id
JOIN invoice i
    ON v.visit_id = i.visit_id
GROUP BY
    d.name,
    DATE_FORMAT(v.visit_start, '%Y-%m')
ORDER BY
    billing_month,
    department_name;
    
SELECT * FROM vw_department_monthly_billing;

-- 2. Patient Blood Pressure Trend Over Time
CREATE OR REPLACE VIEW vw_patient_bp_trend AS
SELECT
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    v.visit_id,
    v.visit_start AS visit_date,
    vt.systolic_bp,
    vt.diastolic_bp
FROM patient p
JOIN clinical_visit v
    ON p.patient_id = v.patient_id
JOIN visit_vitals vt
    ON v.visit_id = vt.visit_id
ORDER BY
    p.patient_id,
    v.visit_start;
    
SELECT * FROM vw_patient_bp_trend;

														-- TASK 3 - ADVANCED SQL QUERIES FOR ANALYTICS
                                                        
-- 1. Department Revenue & Outstanding Risks
SELECT
  d.name AS department_name,
  COUNT(DISTINCT v.visit_id) AS total_visits,
  COUNT(DISTINCT i.invoice_id) AS total_invoices,
  ROUND(SUM(i.total_amount), 2) AS total_billed,
  ROUND(SUM(i.paid_amount), 2) AS total_paid,
  ROUND(SUM(i.total_amount - i.paid_amount), 2) AS total_outstanding,
  CASE
    WHEN SUM(i.total_amount - i.paid_amount) > 200 THEN 'HIGH_OUTSTANDING'
    WHEN SUM(i.total_amount - i.paid_amount) BETWEEN 1 AND 200 THEN 'MEDIUM_OUTSTANDING'
    ELSE 'LOW_OR_NONE'
  END AS outstanding_risk
FROM department d
JOIN clinical_visit v ON v.department_id = d.department_id
LEFT JOIN invoice i ON i.visit_id = v.visit_id
GROUP BY d.name
HAVING COUNT(DISTINCT v.visit_id) >= 2
ORDER BY total_outstanding DESC, total_billed DESC;

-- 2. Patient segmentation by clinical intensity
SELECT
  p.patient_id,
  p.mrn,
  CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
  COUNT(DISTINCT v.visit_id) AS visit_count,
  COUNT(vp.procedure_id) AS procedure_events,
CASE
	WHEN AVG(vt.systolic_bp) IS NULL THEN 'Not recorded'
    ELSE ROUND(AVG(vt.systolic_bp), 0)
END AS avg_sys_bp,
CASE
	WHEN COUNT(DISTINCT v.visit_id) >= 3 OR COUNT(vp.procedure_id) >= 3 THEN 'HIGH_UTILIZATION'
    WHEN COUNT(DISTINCT v.visit_id) = 2 THEN 'MEDIUM_UTILIZATION'
    ELSE 'LOW_UTILIZATION'
END AS utilization_segment
FROM patient p
LEFT JOIN clinical_visit v ON v.patient_id = p.patient_id
LEFT JOIN visit_procedure vp ON vp.visit_id = v.visit_id
LEFT JOIN visit_vitals vt ON vt.visit_id = v.visit_id
GROUP BY p.patient_id, p.mrn, patient_name
ORDER BY visit_count DESC, procedure_events DESC;

-- 3. “Above average” procedure pricing using a subquery
SELECT
  pm.proc_code,
  pm.name AS procedure_name,
  ROUND(AVG(vp.unit_price), 2) AS avg_charged_price,
  pm.base_price,
  CASE
    WHEN AVG(vp.unit_price) > pm.base_price THEN 'ABOVE_BASE'
    WHEN AVG(vp.unit_price) < pm.base_price THEN 'BELOW_BASE'
    ELSE 'AT_BASE'
  END AS pricing_position
FROM procedure_master pm
JOIN visit_procedure vp ON vp.procedure_id = pm.procedure_id
GROUP BY pm.proc_code, pm.name, pm.base_price
HAVING AVG(vp.unit_price) >
(
  SELECT AVG(unit_price) FROM visit_procedure
)
ORDER BY avg_charged_price DESC;

-- 4. Latest diagnosis per patient
SELECT
  p.patient_id,
  p.mrn,
  CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
  d.icd10_code,
  d.name AS diagnosis_name,
  v.visit_start AS diagnosis_date
FROM patient p
JOIN clinical_visit v ON v.patient_id = p.patient_id
JOIN visit_diagnosis vd ON vd.visit_id = v.visit_id
JOIN diagnosis d ON d.diagnosis_id = vd.diagnosis_id
WHERE v.visit_start =
(
  SELECT MAX(v2.visit_start)
  FROM clinical_visit v2
  WHERE v2.patient_id = p.patient_id
)
ORDER BY p.patient_id;

-- 5. Top billed visits per month
SELECT *
FROM (
  SELECT
    DATE_FORMAT(v.visit_start, '%Y-%m') AS visit_month,
    v.visit_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    d.name AS department_name,
    i.total_amount,
    RANK() OVER (PARTITION BY DATE_FORMAT(v.visit_start, '%Y-%m') ORDER BY i.total_amount DESC) AS bill_rank_in_month
  FROM invoice i
  JOIN clinical_visit v ON v.visit_id = i.visit_id
  JOIN patient p ON p.patient_id = v.patient_id
  JOIN department d ON d.department_id = v.department_id
) ranked
WHERE bill_rank_in_month <= 3
ORDER BY visit_month, bill_rank_in_month;

-- Stored Procedure monthly revenue report by department
CALL sp_monthly_department_revenue('2025-06-01', '2026-02-28');


-- Stored Function Patient Age Calculation
-- Single patient
SELECT fn_patient_age_years(1) AS patient_age;
-- How can we use this function in analytics
SELECT
    patient_id,
    mrn,
    fn_patient_age_years(patient_id) AS age_years
FROM patient
ORDER BY age_years DESC;

														-- TASK 5 - QUERY PERFORMANCE AND OPTIMIZATION
-- Before Optimization
EXPLAIN
SELECT
  p.patient_id,
  p.mrn,
  CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
  (
    SELECT SUM(i.total_amount - i.paid_amount)
    FROM invoice i
    JOIN clinical_visit v2 ON v2.visit_id = i.visit_id
    WHERE v2.patient_id = p.patient_id
  ) AS total_outstanding,
  COUNT(DISTINCT v.visit_id) AS visit_count
FROM patient p
LEFT JOIN clinical_visit v ON v.patient_id = p.patient_id
LEFT JOIN visit_diagnosis vd ON vd.visit_id = v.visit_id
LEFT JOIN diagnosis d ON d.diagnosis_id = vd.diagnosis_id
GROUP BY p.patient_id, p.mrn, patient_name
HAVING total_outstanding > 100
ORDER BY total_outstanding DESC;

-- After Optimization
EXPLAIN
SELECT
  p.patient_id,
  p.mrn,
  CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
  COALESCE(o.total_outstanding, 0) AS total_outstanding,
  COUNT(DISTINCT v.visit_id) AS visit_count
FROM patient p
LEFT JOIN clinical_visit v ON v.patient_id = p.patient_id
LEFT JOIN (
  SELECT
    v2.patient_id,
    SUM(i.total_amount - i.paid_amount) AS total_outstanding
  FROM clinical_visit v2
  JOIN invoice i ON i.visit_id = v2.visit_id
  GROUP BY v2.patient_id
) o ON o.patient_id = p.patient_id
GROUP BY p.patient_id, p.mrn, patient_name, o.total_outstanding
HAVING total_outstanding > 100
ORDER BY total_outstanding DESC;
