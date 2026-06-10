-- ==============================================================
--   SERVICE MANAGEMENT DATABASE
--   Complete SQL Script
-- ==============================================================
--
--   CONTENTS
--   ─────────────────────────────────────────────────────────
--   SECTION 1  Database + Schema (CREATE TABLE)
--   SECTION 2  Sample Data      (INSERT)
--   SECTION 3  CRUD Queries
--              3A  CREATE   — INSERT
--              3B  READ     — SELECT (simple → complex)
--              3C  UPDATE
--              3D  DELETE
--   SECTION 4  Stored Procedures
--   SECTION 5  Views
--   SECTION 6  Indexes  (Query Optimisation)
--
--   HOW TO RUN
--   ─────────────────────────────────────────────────────────
--   Option A — MySQL Workbench:
--       File → Open SQL Script → select this file → Run (Ctrl+Shift+Enter)
--
--   Option B — Command line:
--       mysql -u root -p < service_management.sql
--
--   Compatible with: MySQL 8.0+
-- ==============================================================


-- ==============================================================
--   SECTION 1 :  DATABASE + SCHEMA
-- ==============================================================

-- ──────────────────────────────────────────────────────────────
--   WHAT IS A DATABASE?
--   A database is an organised collection of structured data
--   stored and accessed electronically. A relational database
--   organises data into TABLES (rows and columns) and links
--   them using KEYS.
-- ──────────────────────────────────────────────────────────────

-- Drop existing database and start fresh (safe for development)
DROP DATABASE IF EXISTS service_management;

-- Create the database with UTF-8 encoding
-- utf8mb4     = full Unicode support (handles all languages + emoji)
-- unicode_ci  = case-insensitive string comparison (ABC = abc)
CREATE DATABASE service_management
    CHARACTER SET  utf8mb4
    COLLATE        utf8mb4_unicode_ci;

USE service_management;


-- ══════════════════════════════════════════════════════════════
--   NORMALIZATION — WHY THIS SCHEMA IS IN 3NF
-- ══════════════════════════════════════════════════════════════
--
--   Normalization is the process of structuring a database to
--   reduce redundancy and prevent data anomalies.
--
--   ─────────────────────────────────────────────────────────
--   1NF (First Normal Form)
--   ─────────────────────────────────────────────────────────
--   Rule: Every column holds ONE atomic (indivisible) value.
--         No arrays, no comma-separated lists in a single cell.
--
--   What we did:
--   • Each column holds exactly one value per row
--   • failure_category = 'Electrical'  NOT  'Electrical, Hydraulic'
--   • Every table has a Primary Key
--
--   ─────────────────────────────────────────────────────────
--   2NF (Second Normal Form)
--   ─────────────────────────────────────────────────────────
--   Rule: Every non-key column must depend on the ENTIRE
--         primary key (no partial dependencies).
--         Mainly matters when you have composite (multi-column) PKs.
--
--   What we avoided:
--   BAD design — one big table with composite PK (sr_id, technician_id):
--       customer_name depends only on sr_id  ← partial dependency
--       technician_phone depends only on technician_id  ← partial dependency
--
--   What we did instead:
--   • customer details  → their own customers table
--   • technician details → their own technicians table
--   • the relationship between SR and technician → work_orders table
--
--   ─────────────────────────────────────────────────────────
--   3NF (Third Normal Form)
--   ─────────────────────────────────────────────────────────
--   Rule: Every non-key column must depend DIRECTLY on the
--         primary key — not on another non-key column.
--         (No transitive dependencies)
--
--   Example of what we avoided:
--       service_requests.customer_name → depends on customer_id
--       If we stored customer_name inside service_requests,
--       changing the name means updating EVERY row — an update anomaly.
--
--   What we did instead:
--   • Only store customer_id (FK) in service_requests
--   • Look up the actual name via JOIN when needed
--   • The name lives ONCE in the customers table
--
--   ─────────────────────────────────────────────────────────
--   THE THREE ANOMALIES NORMALIZATION PREVENTS
--   ─────────────────────────────────────────────────────────
--   Update anomaly : Without normalization, changing a customer's
--       name requires updating 500 rows. With normalization: 1 row.
--
--   Insertion anomaly : Without normalization, you can't add a
--       customer without also adding a service request. Solved by
--       keeping customers as an independent table.
--
--   Deletion anomaly : Without normalization, deleting the last
--       service request for a customer also deletes the customer.
--       Solved by ON DELETE RESTRICT on foreign keys.
-- ══════════════════════════════════════════════════════════════


-- ──────────────────────────────────────────────────────────────
--   TABLE 1 :  customers
-- ──────────────────────────────────────────────────────────────
--   Who raises service requests.
--
--   KEY CONCEPTS:
--   • INT AUTO_INCREMENT  = database generates IDs automatically (1, 2, 3…)
--   • NOT NULL            = this field MUST have a value — never empty
--   • UNIQUE              = no two rows can have the same value in this column
--   • PRIMARY KEY         = uniquely identifies every row; cannot be NULL
--   • DEFAULT CURRENT_TIMESTAMP = auto-fills with the current date/time
--
--   Why no foreign keys here?
--   customers is a ROOT table — it doesn't depend on any other table.
--   Other tables (assets, service_requests) depend on it.
-- ──────────────────────────────────────────────────────────────
CREATE TABLE customers (
    customer_id     INT           NOT NULL  AUTO_INCREMENT,
    customer_name   VARCHAR(150)  NOT NULL,
    contact_person  VARCHAR(100)  NOT NULL,
    email           VARCHAR(150)  NOT NULL  UNIQUE,
    phone           VARCHAR(20)   NOT NULL,
    address         TEXT,
    city            VARCHAR(80),
    created_at      DATETIME      NOT NULL  DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_customers  PRIMARY KEY (customer_id)
);


-- ──────────────────────────────────────────────────────────────
--   TABLE 2 :  technicians
-- ──────────────────────────────────────────────────────────────
--   The engineers who perform repairs.
--
--   KEY CONCEPTS:
--   • TINYINT UNSIGNED = stores 0–255; perfect for experience_years
--     (uses 1 byte instead of 4 bytes for INT — space optimisation)
--   • BOOLEAN          = stores TRUE / FALSE; internally stored as TINYINT(1)
--   • is_active        = used for SOFT DELETE — instead of removing a
--     technician's record (which would break historical work order data),
--     we mark them inactive. This preserves audit history.
-- ──────────────────────────────────────────────────────────────
CREATE TABLE technicians (
    technician_id     INT           NOT NULL  AUTO_INCREMENT,
    full_name         VARCHAR(100)  NOT NULL,
    email             VARCHAR(150)  NOT NULL  UNIQUE,
    phone             VARCHAR(20),
    specialization    VARCHAR(100),
    experience_years  TINYINT       UNSIGNED  DEFAULT 0,
    is_active         BOOLEAN       NOT NULL  DEFAULT TRUE,
    hire_date         DATE,

    CONSTRAINT pk_technicians  PRIMARY KEY (technician_id)
);


-- ──────────────────────────────────────────────────────────────
--   TABLE 3 :  assets
-- ──────────────────────────────────────────────────────────────
--   Physical machines owned by customers.
--
--   KEY CONCEPTS:
--   • FOREIGN KEY        = links this table to another table's PK
--   • REFERENCES         = specifies which table and column to link to
--   • ON DELETE RESTRICT = prevents deleting a customer who still has assets
--     (protects referential integrity — no orphaned records)
--   • ON UPDATE CASCADE  = if customer_id changes in customers table,
--     automatically update it here too
--
--   REFERENTIAL INTEGRITY:
--   You CANNOT insert an asset with customer_id = 999 unless customer 999
--   exists in the customers table. MySQL rejects the INSERT automatically.
--   This is the database enforcing data consistency for us.
-- ──────────────────────────────────────────────────────────────
CREATE TABLE assets (
    asset_id         INT           NOT NULL  AUTO_INCREMENT,
    customer_id      INT           NOT NULL,
    asset_code       VARCHAR(20)   NOT NULL  UNIQUE,
    machine_type     VARCHAR(100)  NOT NULL,
    model            VARCHAR(100),
    serial_number    VARCHAR(100)  UNIQUE,
    location         VARCHAR(150),
    purchase_date    DATE,
    warranty_expiry  DATE,

    CONSTRAINT pk_assets  PRIMARY KEY (asset_id),

    CONSTRAINT fk_assets_customer
        FOREIGN KEY  (customer_id)
        REFERENCES    customers (customer_id)
        ON DELETE     RESTRICT
        ON UPDATE     CASCADE
);


-- ──────────────────────────────────────────────────────────────
--   TABLE 4 :  service_requests
-- ──────────────────────────────────────────────────────────────
--   A ticket raised when a machine has a problem.
--   The central table — links customers AND assets.
--
--   KEY CONCEPTS:
--   • ENUM = a column type that only accepts values from a fixed list
--     MySQL stores it as a tiny integer internally → space efficient
--     Acts as a built-in validation — INSERT 'Urgent' into an
--     ENUM('High','Medium','Low') column and MySQL throws an error
--     This is called a DOMAIN CONSTRAINT
--
--   CARDINALITY:
--   • customers → service_requests  :  1 : N
--     (one customer can have many requests, each request has one customer)
--   • assets → service_requests     :  1 : N
--     (one asset can have many incidents over time)
-- ──────────────────────────────────────────────────────────────
CREATE TABLE service_requests (
    sr_id              INT          NOT NULL  AUTO_INCREMENT,
    customer_id        INT          NOT NULL,
    asset_id           INT          NOT NULL,
    sr_code            VARCHAR(20)  NOT NULL  UNIQUE,
    reported_date      DATETIME     NOT NULL  DEFAULT CURRENT_TIMESTAMP,
    priority           ENUM('High','Medium','Low')
                                    NOT NULL  DEFAULT 'Medium',
    status             ENUM('Open','In Progress','Completed','Cancelled')
                                    NOT NULL  DEFAULT 'Open',
    failure_category   VARCHAR(80),
    description        TEXT,
    closed_at          DATETIME,

    CONSTRAINT pk_service_requests  PRIMARY KEY (sr_id),

    CONSTRAINT fk_sr_customer
        FOREIGN KEY  (customer_id)
        REFERENCES    customers (customer_id)
        ON DELETE     RESTRICT
        ON UPDATE     CASCADE,

    CONSTRAINT fk_sr_asset
        FOREIGN KEY  (asset_id)
        REFERENCES    assets (asset_id)
        ON DELETE     RESTRICT
        ON UPDATE     CASCADE
);


-- ──────────────────────────────────────────────────────────────
--   TABLE 5 :  work_orders
-- ──────────────────────────────────────────────────────────────
--   The assignment of a technician to fix a service request.
--
--   WHY A SEPARATE TABLE FROM service_requests?
--   A service request captures the PROBLEM (what broke, when, priority).
--   A work order captures the RESPONSE (who fixed it, how long it took).
--   Mixing them would create a wide, sparse table full of NULLs for
--   all the unassigned requests. Separation is cleaner and follows 3NF.
--
--   One SR can have MULTIPLE work orders:
--   e.g., if the first fix attempt fails, a second work order is raised.
--
--   DECIMAL(6,2):
--   Stores numbers like 14.50 (6 total digits, 2 after decimal point).
--   Better than INT for hours — a job can take 2.5 hours, not just 2 or 3.
-- ──────────────────────────────────────────────────────────────
CREATE TABLE work_orders (
    wo_id                   INT           NOT NULL  AUTO_INCREMENT,
    sr_id                   INT           NOT NULL,
    technician_id           INT           NOT NULL,
    wo_code                 VARCHAR(20)   NOT NULL  UNIQUE,
    assigned_date           DATETIME      NOT NULL  DEFAULT CURRENT_TIMESTAMP,
    scheduled_date          DATETIME,
    completed_date          DATETIME,
    resolution_notes        TEXT,
    resolution_time_hours   DECIMAL(6,2)  UNSIGNED,
    status                  ENUM('Pending','In Progress','Completed','On Hold')
                                          NOT NULL  DEFAULT 'Pending',

    CONSTRAINT pk_work_orders  PRIMARY KEY (wo_id),

    CONSTRAINT fk_wo_sr
        FOREIGN KEY  (sr_id)
        REFERENCES    service_requests (sr_id)
        ON DELETE     RESTRICT
        ON UPDATE     CASCADE,

    CONSTRAINT fk_wo_technician
        FOREIGN KEY  (technician_id)
        REFERENCES    technicians (technician_id)
        ON DELETE     RESTRICT
        ON UPDATE     CASCADE
);


-- ==============================================================
--   SECTION 2 :  SAMPLE DATA   (INSERT)
-- ==============================================================
--   INSERT ORDER MATTERS.
--   You must insert parent tables BEFORE child tables because of
--   foreign key constraints.
--
--   Correct order:
--       customers  (no dependencies)
--       technicians (no dependencies)
--       assets      (depends on customers)
--       service_requests (depends on customers + assets)
--       work_orders (depends on service_requests + technicians)
--
--   Inserting in the wrong order will cause:
--   ERROR 1452: Cannot add or update a child row:
--   a foreign key constraint fails
-- ==============================================================


-- ── Customers ────────────────────────────────────────────────
INSERT INTO customers
    (customer_name,              contact_person,    email,                    phone,        city)
VALUES
    ('ABC Manufacturing Pvt Ltd', 'Ramesh Gupta',   'ramesh@abcmfg.com',     '9812345678', 'Bangalore'),
    ('XYZ Industries',            'Sunita Joshi',   'sunita@xyzind.com',     '9823456789', 'Mumbai'),
    ('Delta Corp',                'Arjun Mehta',    'arjun@deltacorp.com',   '9834567890', 'Chennai'),
    ('Sigma Fabricators',         'Kavitha Nair',   'kavitha@sigmafab.com',  '9845678901', 'Pune'),
    ('Nexus Engineering',         'Vikram Reddy',   'vikram@nexuseng.com',   '9856789012', 'Hyderabad'),
    ('Apex Systems',              'Priya Sharma',   'priya@apexsys.com',     '9867890123', 'Delhi'),
    ('Orion Works',               'Manoj Patel',    'manoj@orionworks.com',  '9878901234', 'Ahmedabad'),
    ('Titan Tech',                'Anita Singh',    'anita@titantech.com',   '9889012345', 'Kolkata');


-- ── Technicians ──────────────────────────────────────────────
INSERT INTO technicians
    (full_name,       email,                         phone,        specialization,   experience_years, hire_date)
VALUES
    ('Raj Kumar',     'raj.kumar@service.com',       '9001234567', 'Electrical',     8,  '2016-03-15'),
    ('Anita Sharma',  'anita.sharma@service.com',    '9002345678', 'Hydraulic',      5,  '2019-07-20'),
    ('Vikram Patel',  'vikram.patel@service.com',    '9003456789', 'Mechanical',     12, '2012-01-10'),
    ('Sunita Rao',    'sunita.rao@service.com',      '9004567890', 'Software',       4,  '2020-09-05'),
    ('Manoj Singh',   'manoj.singh@service.com',     '9005678901', 'Electrical',     7,  '2017-11-22'),
    ('Priya Nair',    'priya.nair@service.com',      '9006789012', 'Pneumatic',      3,  '2021-04-18'),
    ('Arjun Reddy',   'arjun.reddy@service.com',     '9007890123', 'Mechanical',     9,  '2015-06-30'),
    ('Kavitha Menon', 'kavitha.menon@service.com',   '9008901234', 'Sensor',         6,  '2018-02-14');


-- ── Assets ───────────────────────────────────────────────────
INSERT INTO assets
    (customer_id, asset_code, machine_type,       model,             serial_number,    location,        purchase_date, warranty_expiry)
VALUES
    (1, 'AST001', 'CNC Machine',       'Haas VF-2',       'HVF2-20230101',  'Plant A Bay 1', '2023-01-15', '2026-01-15'),
    (1, 'AST002', 'Lathe Machine',     'Okuma LB-3000',   'OLB3-20220601',  'Plant A Bay 2', '2022-06-01', '2025-06-01'),
    (2, 'AST003', 'Hydraulic Press',   'Rexroth HP-50',   'RHP50-2021',     'Floor 2',       '2021-09-10', '2024-09-10'),
    (3, 'AST004', 'Conveyor Belt',     'Dorner 2200',     'D2200-2022',     'Line 3',        '2022-03-20', '2025-03-20'),
    (4, 'AST005', 'Robotic Arm',       'KUKA KR-10',      'KKR10-2023',     'Assembly Area', '2023-05-01', '2026-05-01'),
    (5, 'AST006', 'Welding Machine',   'Lincoln EW-400',  'LEW400-2020',    'Workshop',      '2020-11-15', '2023-11-15'),
    (6, 'AST007', 'Milling Machine',   'DMG DMU 50',      'DDMU50-2022',    'Bay 7',         '2022-07-08', '2025-07-08'),
    (7, 'AST008', 'Drilling Machine',  'Radial RD-200',   'RRD200-2021',    'Section B',     '2021-04-25', '2024-04-25'),
    (8, 'AST009', 'CNC Machine',       'Fanuc 0i-MF',     'F0IMF-2023',     'Hall C',        '2023-02-14', '2026-02-14'),
    (2, 'AST010', 'Lathe Machine',     'Ace Jobber XL',   'AJXL-2022',      'Floor 3',       '2022-08-30', '2025-08-30');


-- ── Service Requests ─────────────────────────────────────────
INSERT INTO service_requests
    (customer_id, asset_id, sr_code, reported_date,          priority,  status,        failure_category, description)
VALUES
    (1, 1,  'SR001', '2024-01-10 09:00:00', 'High',   'Completed',    'Electrical',  'Machine not powering on after weekend shutdown'),
    (1, 2,  'SR002', '2024-01-15 11:30:00', 'Medium', 'Completed',    'Mechanical',  'Unusual grinding noise during operation'),
    (2, 3,  'SR003', '2024-02-05 08:45:00', 'High',   'In Progress',  'Hydraulic',   'Hydraulic fluid leak detected near main cylinder'),
    (3, 4,  'SR004', '2024-02-20 14:00:00', 'Low',    'Open',         'Sensor',      'Belt speed sensor giving erratic readings'),
    (4, 5,  'SR005', '2024-03-01 10:15:00', 'High',   'Completed',    'Software',    'Robot arm losing calibration after reboot'),
    (5, 6,  'SR006', '2024-03-12 13:30:00', 'Medium', 'Open',         'Electrical',  'Welding arc unstable, voltage fluctuation'),
    (6, 7,  'SR007', '2024-03-25 09:00:00', 'High',   'Completed',    'Mechanical',  'Spindle vibration exceeding safe threshold'),
    (7, 8,  'SR008', '2024-04-03 16:00:00', 'Medium', 'In Progress',  'Lubrication', 'Drill head overheating due to lubrication failure'),
    (8, 9,  'SR009', '2024-04-15 08:00:00', 'Low',    'Open',         'Software',    'CNC program upload failing intermittently'),
    (1, 1,  'SR010', '2024-05-02 11:00:00', 'High',   'Open',         'Electrical',  'Power surge caused controller board failure'),
    (2, 10, 'SR011', '2024-05-10 09:30:00', 'Medium', 'Completed',    'Mechanical',  'Tailstock misalignment after heavy use'),
    (3, 4,  'SR012', '2024-05-18 14:45:00', 'High',   'Open',         'Structural',  'Conveyor frame showing stress fractures');


-- ── Work Orders ──────────────────────────────────────────────
INSERT INTO work_orders
    (sr_id, technician_id, wo_code, assigned_date,           scheduled_date,          completed_date,          resolution_notes,                                                                           resolution_time_hours, status)
VALUES
    (1,  1, 'WO001', '2024-01-10 10:00:00', '2024-01-11 09:00:00', '2024-01-11 15:30:00', 'Replaced faulty contactor and power relay. Tested under load — all normal.',          6.50,  'Completed'),
    (2,  3, 'WO002', '2024-01-15 13:00:00', '2024-01-16 09:00:00', '2024-01-16 17:00:00', 'Replaced worn spindle bearings and recalibrated feed rate.',                          8.00,  'Completed'),
    (3,  2, 'WO003', '2024-02-05 10:00:00', '2024-02-06 09:00:00', NULL,                  'Seal kit ordered. Temporary clamp applied to reduce leak.',                           NULL,  'In Progress'),
    (4,  8, 'WO004', '2024-02-20 15:00:00', '2024-02-22 10:00:00', NULL,                  NULL,                                                                                  NULL,  'Pending'),
    (5,  4, 'WO005', '2024-03-01 11:00:00', '2024-03-02 09:00:00', '2024-03-02 13:00:00', 'Recalibrated robot arm using OEM software. Updated firmware to v3.2.1.',             4.00,  'Completed'),
    (6,  1, 'WO006', '2024-03-12 14:00:00', '2024-03-14 09:00:00', NULL,                  'Awaiting spare voltage regulator from supplier.',                                     NULL,  'Pending'),
    (7,  7, 'WO007', '2024-03-25 10:00:00', '2024-03-26 09:00:00', '2024-03-26 14:30:00', 'Balanced spindle, replaced worn collet. Vibration now within spec.',                  5.50,  'Completed'),
    (8,  3, 'WO008', '2024-04-03 17:00:00', '2024-04-05 09:00:00', NULL,                  'Flushed old lubricant, refilled with ISO 46. Cooling check in progress.',             NULL,  'In Progress'),
    (9,  4, 'WO009', '2024-04-15 09:00:00', '2024-04-17 09:00:00', NULL,                  NULL,                                                                                  NULL,  'Pending'),
    (11, 3, 'WO010', '2024-05-10 10:00:00', '2024-05-11 09:00:00', '2024-05-11 12:30:00', 'Realigned tailstock using dial indicator. Within 0.02mm tolerance.',                  3.50,  'Completed');


-- ==============================================================
--   SECTION 3 :  CRUD QUERIES
-- ==============================================================
--
--   CRUD = Create · Read · Update · Delete
--   These are the FOUR fundamental database operations.
--   Every database-backed application performs exactly these four.
--
--   Create → INSERT
--   Read   → SELECT
--   Update → UPDATE
--   Delete → DELETE
-- ==============================================================


-- ════════════════════════════════════════════════════════════
--   3A : CREATE  (INSERT)
-- ════════════════════════════════════════════════════════════

-- ── Insert a new customer ────────────────────────────────────
-- Only required (NOT NULL) fields specified.
-- customer_id fills automatically via AUTO_INCREMENT.
-- created_at fills automatically via DEFAULT CURRENT_TIMESTAMP.
INSERT INTO customers (customer_name, contact_person, email, phone, city)
VALUES ('Vega Industries', 'Rohit Bansal', 'rohit@vega.com', '9900112233', 'Indore');


-- ── Insert a new technician ──────────────────────────────────
INSERT INTO technicians (full_name, email, phone, specialization, experience_years, hire_date)
VALUES ('Deepa Krishnan', 'deepa.k@service.com', '9011223344', 'Hydraulic', 6, '2022-01-15');


-- ── Insert a new asset linked to an existing customer ────────
-- customer_id = 1 must exist in the customers table.
-- If it doesn't exist, MySQL raises: ERROR 1452 (foreign key constraint fails)
INSERT INTO assets (customer_id, asset_code, machine_type, model, serial_number, location, purchase_date)
VALUES (1, 'AST011', 'Grinding Machine', 'Studer S33', 'SS33-2024', 'Plant B', '2024-01-20');


-- ── Raise a new service request ──────────────────────────────
INSERT INTO service_requests (customer_id, asset_id, sr_code, priority, failure_category, description)
VALUES (1, 1, 'SR013', 'High', 'Electrical', 'Encoder feedback signal lost on X-axis');


-- ── Assign a work order using a subquery ─────────────────────
-- We use a subquery to look up sr_id from sr_code
-- so the calling code doesn't need to know internal IDs
INSERT INTO work_orders (sr_id, technician_id, wo_code, scheduled_date, status)
VALUES (
    (SELECT sr_id FROM service_requests WHERE sr_code = 'SR013'),
    1,
    'WO011',
    DATE_ADD(NOW(), INTERVAL 1 DAY),   -- schedule for tomorrow
    'Pending'
);


-- ════════════════════════════════════════════════════════════
--   3B : READ  (SELECT)
-- ════════════════════════════════════════════════════════════
--
--   SELECT queries range from simple single-table reads
--   to complex multi-table JOINs with aggregations.
--   We go from simple to complex below.
-- ════════════════════════════════════════════════════════════


-- ── SIMPLE SELECTs ───────────────────────────────────────────

-- All customers (every column, every row)
SELECT * FROM customers;

-- Specific columns only (best practice — avoid SELECT * in production)
SELECT customer_id, customer_name, city
FROM   customers
ORDER BY city;

-- All open service requests, most urgent first
-- ORDER BY with FIELD() defines a custom sort order for the ENUM values
SELECT sr_code, reported_date, priority, failure_category, description
FROM   service_requests
WHERE  status = 'Open'
ORDER BY FIELD(priority, 'High', 'Medium', 'Low'),
         reported_date ASC;

-- All active technicians, most experienced first
SELECT full_name, specialization, experience_years, hire_date
FROM   technicians
WHERE  is_active = TRUE
ORDER BY experience_years DESC;


-- ── JOIN QUERIES ─────────────────────────────────────────────
--
--   A JOIN combines rows from two or more tables based on a
--   matching column value — usually a primary key / foreign key pair.
--
--   INNER JOIN : Returns only rows that have a match in BOTH tables.
--               Rows with no match are excluded.
--
--   LEFT JOIN  : Returns ALL rows from the LEFT table.
--               If no match exists in the right table, columns from
--               the right table are filled with NULL.
--               Used when: "give me everything from A, plus any B that exists"
--
--   Example to remember:
--       INNER JOIN customers + assets  →  only customers who have assets
--       LEFT  JOIN customers + assets  →  ALL customers, even those with no assets yet


-- Service requests with customer name and asset details
-- Three tables joined: service_requests → customers, service_requests → assets
SELECT
    sr.sr_code,
    c.customer_name,
    c.city,
    a.asset_code,
    a.machine_type,
    sr.priority,
    sr.status,
    sr.failure_category,
    sr.reported_date
FROM       service_requests  sr
INNER JOIN customers          c   ON  sr.customer_id = c.customer_id
INNER JOIN assets             a   ON  sr.asset_id    = a.asset_id
ORDER BY   sr.reported_date DESC;


-- Work orders with technician and service request details
SELECT
    wo.wo_code,
    sr.sr_code,
    c.customer_name,
    a.machine_type,
    t.full_name              AS technician,
    t.specialization,
    wo.status                AS wo_status,
    wo.scheduled_date,
    wo.completed_date,
    wo.resolution_time_hours
FROM       work_orders        wo
INNER JOIN service_requests   sr  ON  wo.sr_id           = sr.sr_id
INNER JOIN customers          c   ON  sr.customer_id     = c.customer_id
INNER JOIN assets             a   ON  sr.asset_id        = a.asset_id
INNER JOIN technicians        t   ON  wo.technician_id   = t.technician_id
ORDER BY   wo.assigned_date DESC;


-- Full 5-table join: all entities in one result
-- Uses LEFT JOIN for work_orders/technicians because some SRs
-- may not have been assigned to a work order yet
SELECT
    c.customer_name,
    a.machine_type,
    sr.sr_code,
    sr.priority,
    sr.failure_category,
    sr.status              AS sr_status,
    wo.wo_code,
    t.full_name            AS assigned_technician,
    wo.status              AS wo_status,
    wo.resolution_time_hours
FROM        service_requests  sr
INNER JOIN  customers          c   ON  sr.customer_id    = c.customer_id
INNER JOIN  assets             a   ON  sr.asset_id       = a.asset_id
LEFT  JOIN  work_orders        wo  ON  wo.sr_id          = sr.sr_id
LEFT  JOIN  technicians        t   ON  wo.technician_id  = t.technician_id
ORDER BY    FIELD(sr.priority, 'High', 'Medium', 'Low'),
            sr.reported_date;


-- ── AGGREGATE QUERIES ────────────────────────────────────────
--
--   Aggregate functions collapse many rows into a single summary value.
--   They are always used with GROUP BY (unless aggregating the entire table).
--
--   COUNT(*)        = total rows in group
--   COUNT(column)   = total non-NULL values in column
--   AVG(column)     = arithmetic mean
--   SUM(column)     = total
--   MIN / MAX       = smallest / largest value
--
--   HAVING vs WHERE:
--   WHERE  filters BEFORE grouping  (filters individual rows)
--   HAVING filters AFTER  grouping  (filters entire groups)


-- Service request count by status
SELECT
    status,
    COUNT(*) AS total_requests
FROM    service_requests
GROUP BY status
ORDER BY total_requests DESC;


-- Service request count by priority
SELECT
    priority,
    COUNT(*) AS total_requests
FROM    service_requests
GROUP BY priority
ORDER BY FIELD(priority, 'High', 'Medium', 'Low');


-- Top 5 failure categories
SELECT
    failure_category,
    COUNT(*) AS occurrences
FROM    service_requests
GROUP BY failure_category
ORDER BY occurrences DESC
LIMIT 5;


-- Technician performance: completed jobs + time statistics
SELECT
    t.full_name,
    t.specialization,
    COUNT(wo.wo_id)                           AS completed_jobs,
    ROUND(AVG(wo.resolution_time_hours), 2)   AS avg_hours,
    MIN(wo.resolution_time_hours)             AS fastest_job_hrs,
    MAX(wo.resolution_time_hours)             AS slowest_job_hrs
FROM       technicians   t
INNER JOIN work_orders   wo  ON  wo.technician_id = t.technician_id
WHERE      wo.status = 'Completed'
GROUP BY   t.technician_id, t.full_name, t.specialization
ORDER BY   avg_hours ASC;   -- fastest average first


-- Customers with the most service requests (HAVING example)
-- HAVING COUNT(*) > 1 means: only show customers with MORE THAN 1 request
SELECT
    c.customer_name,
    COUNT(sr.sr_id)                                              AS total_requests,
    SUM(CASE WHEN sr.priority = 'High'  THEN 1 ELSE 0 END)      AS high_priority,
    SUM(CASE WHEN sr.status   = 'Open'  THEN 1 ELSE 0 END)      AS still_open
FROM       customers          c
INNER JOIN service_requests   sr  ON  sr.customer_id = c.customer_id
GROUP BY   c.customer_id, c.customer_name
HAVING     COUNT(sr.sr_id) > 1       -- HAVING filters after grouping
ORDER BY   total_requests DESC;


-- Assets with the most failures (maintenance hot-spots)
SELECT
    a.asset_code,
    a.machine_type,
    c.customer_name,
    COUNT(sr.sr_id)  AS total_failures
FROM       assets              a
INNER JOIN customers           c   ON  a.customer_id  = c.customer_id
INNER JOIN service_requests    sr  ON  sr.asset_id    = a.asset_id
GROUP BY   a.asset_id, a.asset_code, a.machine_type, c.customer_name
ORDER BY   total_failures DESC;


-- Service requests with NO work order assigned yet (LEFT JOIN + IS NULL trick)
-- This is the standard SQL pattern for finding "missing" related rows.
-- LEFT JOIN brings in work_orders columns.
-- WHERE wo.wo_id IS NULL keeps only rows where no WO exists.
SELECT
    sr.sr_code,
    c.customer_name,
    a.machine_type,
    sr.priority,
    sr.reported_date,
    DATEDIFF(NOW(), sr.reported_date)  AS days_unassigned
FROM       service_requests   sr
INNER JOIN customers           c   ON  sr.customer_id  = c.customer_id
INNER JOIN assets              a   ON  sr.asset_id     = a.asset_id
LEFT  JOIN work_orders         wo  ON  wo.sr_id        = sr.sr_id
WHERE      wo.wo_id IS NULL
ORDER BY   FIELD(sr.priority, 'High', 'Medium', 'Low'),
           sr.reported_date;


-- ════════════════════════════════════════════════════════════
--   3C : UPDATE
-- ════════════════════════════════════════════════════════════
--
--   UPDATE modifies existing rows.
--   ALWAYS include a WHERE clause — without it, ALL rows are updated.
--   Best practice: run the equivalent SELECT first to verify the rows
--   you're about to change.


-- Mark a service request as Completed
UPDATE service_requests
SET    status    = 'Completed',
       closed_at = NOW()
WHERE  sr_code   = 'SR003';


-- Record completion of a work order
UPDATE work_orders
SET    status                = 'Completed',
       completed_date        = NOW(),
       resolution_time_hours = 7.25,
       resolution_notes      = 'Replaced hydraulic seal kit PN:RX-448. Pressure tested at 250 bar. No leaks.'
WHERE  wo_code = 'WO003';


-- Escalate all High priority Open requests older than 7 days (bulk update)
-- DATE_SUB(NOW(), INTERVAL 7 DAY) = "7 days ago"
-- CONCAT prepends a warning tag to the existing description
UPDATE service_requests
SET    description = CONCAT('[!! ESCALATED !!] ', description)
WHERE  priority      = 'High'
  AND  status        = 'Open'
  AND  reported_date < DATE_SUB(NOW(), INTERVAL 7 DAY);


-- Soft delete: deactivate a technician who has left
-- PREFERRED over hard DELETE — preserves historical work order records
UPDATE technicians
SET    is_active = FALSE
WHERE  technician_id = 8;


-- Update customer contact details
UPDATE customers
SET    contact_person = 'Neha Gupta',
       email          = 'neha.gupta@abcmfg.com',
       phone          = '9812399999'
WHERE  customer_id = 1;


-- ════════════════════════════════════════════════════════════
--   3D : DELETE
-- ════════════════════════════════════════════════════════════
--
--   DELETE removes rows permanently.
--
--   IMPORTANT — Production databases rarely use hard DELETE.
--   They use soft delete (is_active = FALSE, status = 'Cancelled')
--   to preserve audit history.
--
--   FOREIGN KEY PROTECTION:
--   ON DELETE RESTRICT means: if you try to delete a customer
--   who still has assets or service requests, MySQL will REJECT
--   the DELETE with an error. This prevents orphaned records —
--   a serious data integrity problem.


-- Delete a specific work order (safe — nothing points to work_orders)
DELETE FROM work_orders
WHERE  wo_code = 'WO009';


-- Delete a service request
-- Only works if no work orders reference this SR (FK constraint protects us)
DELETE FROM service_requests
WHERE  sr_code = 'SR013';


-- Archive cleanup: delete cancelled SRs older than 1 year
DELETE FROM service_requests
WHERE  status        = 'Cancelled'
  AND  reported_date < DATE_SUB(NOW(), INTERVAL 1 YEAR);


-- ==============================================================
--   SECTION 4 :  STORED PROCEDURES
-- ==============================================================
--
--   WHAT IS A STORED PROCEDURE?
--   ────────────────────────────
--   A stored procedure is a named block of SQL code saved permanently
--   inside the database. You call it by name and pass parameters,
--   just like calling a function in Python.
--
--   BENEFITS:
--   • Reusability   — write once, call from any application
--   • Security      — users can EXECUTE a procedure without direct
--                     table access (principle of least privilege)
--   • Performance   — MySQL pre-compiles the execution plan
--   • Consistency   — business logic lives in the database, not
--                     scattered across multiple application files
--   • Atomicity     — multiple SQL statements execute as one unit
--
--   KEY SYNTAX:
--   • DELIMITER //   — changes the statement terminator from ; to //
--                     because the procedure body itself contains ; characters
--                     and MySQL needs a different outer terminator
--   • IN parameter   — value passed INTO the procedure by the caller
--   • OUT parameter  — value the procedure sends BACK to the caller
--   • DECLARE        — creates a local variable (exists only during the call)
--   • IF/THEN/ELSE   — conditional logic inside SQL
--   • SIGNAL SQLSTATE — raises an error (like raise Exception in Python)
-- ==============================================================

DELIMITER //


-- ── Procedure 1 :  raise_service_request ─────────────────────────────────────
--
--   Purpose  : Validates and creates a new service request.
--   Why useful: Enforces business rules at the database level:
--               1. Asset must belong to the given customer
--               2. Auto-generates the SR code (SR001, SR002…)
--               3. Returns the new SR code to the caller
-- ─────────────────────────────────────────────────────────────────────────────
CREATE PROCEDURE raise_service_request (
    IN  p_customer_id       INT,           -- which customer is raising the request
    IN  p_asset_id          INT,           -- which machine has the problem
    IN  p_priority          VARCHAR(10),   -- High / Medium / Low
    IN  p_failure_category  VARCHAR(80),   -- Electrical / Mechanical / etc.
    IN  p_description       TEXT,          -- free-text problem description
    OUT p_new_sr_code       VARCHAR(20)    -- the procedure sends back the generated code
)
BEGIN
    -- Local variables — exist only for the duration of this procedure call
    DECLARE v_asset_belongs_to_customer  INT;
    DECLARE v_next_id                    INT;

    -- ── Validation: does this asset actually belong to this customer? ──────
    -- A customer should not be able to raise a request against someone else's asset.
    -- COUNT(*) returns 0 if no matching row exists, 1 if it does.
    SELECT COUNT(*)
    INTO   v_asset_belongs_to_customer
    FROM   assets
    WHERE  asset_id = p_asset_id
      AND  customer_id = p_customer_id;

    -- IF this is 0, the asset doesn't belong to this customer → raise an error
    IF v_asset_belongs_to_customer = 0 THEN
        -- SIGNAL SQLSTATE '45000' is the standard way to raise a custom error in MySQL
        -- This rolls back any partial changes and sends the message to the caller
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Validation failed: Asset does not belong to this customer';
    END IF;

    -- ── Generate next SR code ──────────────────────────────────────────────
    -- Find the current highest sr_id, add 1, and format as SR001 / SR002 etc.
    -- IFNULL handles empty table edge case (returns 0 when table is empty)
    -- LPAD pads with leading zeros: LPAD(3, 3, '0') → '003'
    SELECT IFNULL(MAX(sr_id), 0) + 1
    INTO   v_next_id
    FROM   service_requests;

    SET p_new_sr_code = CONCAT('SR', LPAD(v_next_id, 3, '0'));

    -- ── Insert the service request ────────────────────────────────────────
    INSERT INTO service_requests
        (customer_id, asset_id, sr_code, priority, failure_category, description)
    VALUES
        (p_customer_id, p_asset_id, p_new_sr_code, p_priority, p_failure_category, p_description);

END //


-- ── Procedure 2 :  assign_work_order ─────────────────────────────────────────
--
--   Purpose  : Automatically finds the best-matched technician and
--              creates a work order for an open service request.
--
--   Business logic:
--   1. Validate the SR exists and is Open
--   2. Find an active technician whose specialization matches failure_category
--   3. Among matching technicians, pick the one with the FEWEST active jobs
--      (least busy = best candidate for a new assignment)
--   4. If no specialist exists, fall back to any active technician
--   5. Create the work order, update the SR status to In Progress
-- ─────────────────────────────────────────────────────────────────────────────
CREATE PROCEDURE assign_work_order (
    IN  p_sr_code      VARCHAR(20),
    OUT p_wo_code      VARCHAR(20),
    OUT p_tech_name    VARCHAR(100)
)
BEGIN
    DECLARE v_sr_id        INT;
    DECLARE v_failure_cat  VARCHAR(80);
    DECLARE v_tech_id      INT;
    DECLARE v_next_wo_id   INT;

    -- ── Step 1: Get SR details ────────────────────────────────────────────
    SELECT sr_id, failure_category
    INTO   v_sr_id, v_failure_cat
    FROM   service_requests
    WHERE  sr_code = p_sr_code
      AND  status  = 'Open';

    -- If no SR found, raise an error
    IF v_sr_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Service request not found or is not in Open status';
    END IF;

    -- ── Step 2: Find the best matching active technician ──────────────────
    -- LEFT JOIN + GROUP BY + COUNT counts active work orders per technician
    -- ORDER BY COUNT ASC → least busy technician comes first
    -- LIMIT 1 → take only the best one
    SELECT t.technician_id, t.full_name
    INTO   v_tech_id, p_tech_name
    FROM   technicians t
    LEFT JOIN work_orders wo
           ON  wo.technician_id = t.technician_id
          AND  wo.status NOT IN ('Completed')          -- count only ACTIVE jobs
    WHERE  t.is_active      = TRUE
      AND  t.specialization = v_failure_cat            -- match by specialization
    GROUP BY t.technician_id, t.full_name
    ORDER BY COUNT(wo.wo_id) ASC                       -- least busy first
    LIMIT 1;

    -- ── Step 3: Fallback — if no specialist, pick any available technician ─
    IF v_tech_id IS NULL THEN
        SELECT t.technician_id, t.full_name
        INTO   v_tech_id, p_tech_name
        FROM   technicians t
        LEFT JOIN work_orders wo
               ON  wo.technician_id = t.technician_id
              AND  wo.status NOT IN ('Completed')
        WHERE  t.is_active = TRUE
        GROUP BY t.technician_id, t.full_name
        ORDER BY COUNT(wo.wo_id) ASC
        LIMIT 1;
    END IF;

    -- ── Step 4: Generate WO code ──────────────────────────────────────────
    SELECT IFNULL(MAX(wo_id), 0) + 1
    INTO   v_next_wo_id
    FROM   work_orders;

    SET p_wo_code = CONCAT('WO', LPAD(v_next_wo_id, 3, '0'));

    -- ── Step 5: Create the work order ────────────────────────────────────
    INSERT INTO work_orders (sr_id, technician_id, wo_code, scheduled_date, status)
    VALUES (
        v_sr_id,
        v_tech_id,
        p_wo_code,
        DATE_ADD(NOW(), INTERVAL 1 DAY),   -- schedule for next business day
        'Pending'
    );

    -- ── Step 6: Update the SR to In Progress ─────────────────────────────
    UPDATE service_requests
    SET    status = 'In Progress'
    WHERE  sr_id  = v_sr_id;

END //


-- ── Procedure 3 :  complete_work_order ───────────────────────────────────────
--
--   Purpose  : Closes a work order and auto-closes the parent SR
--              if all associated work orders are now complete.
--
--   Why check the parent SR?
--   A single SR can have multiple work orders (e.g., first fix failed).
--   We should only mark the SR as Completed when EVERY work order is done.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE PROCEDURE complete_work_order (
    IN  p_wo_code              VARCHAR(20),
    IN  p_resolution_notes     TEXT,
    IN  p_resolution_time_hrs  DECIMAL(6,2)
)
BEGIN
    DECLARE v_sr_id           INT;
    DECLARE v_remaining_open  INT;

    -- ── Step 1: Close the work order ─────────────────────────────────────
    UPDATE work_orders
    SET    status                = 'Completed',
           completed_date        = NOW(),
           resolution_notes      = p_resolution_notes,
           resolution_time_hours = p_resolution_time_hrs
    WHERE  wo_code = p_wo_code;

    -- ── Step 2: Get the parent SR id ─────────────────────────────────────
    SELECT sr_id
    INTO   v_sr_id
    FROM   work_orders
    WHERE  wo_code = p_wo_code;

    -- ── Step 3: Count remaining non-completed work orders for this SR ─────
    SELECT COUNT(*)
    INTO   v_remaining_open
    FROM   work_orders
    WHERE  sr_id   = v_sr_id
      AND  status <> 'Completed';

    -- ── Step 4: If all work orders are done, close the SR too ────────────
    IF v_remaining_open = 0 THEN
        UPDATE service_requests
        SET    status    = 'Completed',
               closed_at = NOW()
        WHERE  sr_id = v_sr_id;
    END IF;

END //


-- ── Procedure 4 :  get_technician_performance ────────────────────────────────
--
--   Purpose  : Generate a performance summary for all technicians
--              within a given date range. Used for monthly reviews.
--
--   COALESCE(value, fallback):
--   Returns the first non-NULL value. If avg is NULL (no completed jobs),
--   return 0 instead of NULL — cleaner for reports.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE PROCEDURE get_technician_performance (
    IN p_start_date  DATE,
    IN p_end_date    DATE
)
BEGIN
    SELECT
        t.full_name,
        t.specialization,
        t.experience_years,
        COUNT(wo.wo_id)                                               AS total_assigned,
        SUM(CASE WHEN wo.status = 'Completed'  THEN 1 ELSE 0 END)    AS completed_jobs,
        COALESCE(ROUND(AVG(
            CASE WHEN wo.status = 'Completed'
                 THEN wo.resolution_time_hours END
        ), 2), 0)                                                     AS avg_resolution_hrs,
        COALESCE(MIN(wo.resolution_time_hours), 0)                    AS fastest_hrs,
        COALESCE(MAX(wo.resolution_time_hours), 0)                    AS slowest_hrs
    FROM       technicians  t
    LEFT JOIN  work_orders  wo
           ON  wo.technician_id = t.technician_id
          AND  wo.assigned_date BETWEEN p_start_date AND p_end_date
    WHERE  t.is_active = TRUE
    GROUP BY t.technician_id, t.full_name, t.specialization, t.experience_years
    ORDER BY completed_jobs DESC;
END //


-- ── Procedure 5 :  get_sla_dashboard ─────────────────────────────────────────
--
--   Purpose  : Show all open requests with their SLA breach status.
--
--   SLA = Service Level Agreement
--   A commitment to respond/resolve within a given time window.
--   Here: High = 1 day, Medium = 3 days, Low = 7 days.
--
--   CASE WHEN: SQL's version of if/elif/else.
--   DATEDIFF(date1, date2): returns integer number of days between two dates.
--   COALESCE(t.full_name, 'UNASSIGNED'): if no technician assigned, show label.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE PROCEDURE get_sla_dashboard ()
BEGIN
    SELECT
        c.customer_name,
        sr.sr_code,
        a.machine_type,
        sr.priority,
        sr.failure_category,
        sr.reported_date,
        DATEDIFF(NOW(), sr.reported_date)    AS age_days,

        -- CASE WHEN = if/elif/else inside SQL
        CASE
            WHEN sr.priority = 'High'   AND DATEDIFF(NOW(), sr.reported_date) > 1  THEN '!! BREACHED !!'
            WHEN sr.priority = 'Medium' AND DATEDIFF(NOW(), sr.reported_date) > 3  THEN '!! BREACHED !!'
            WHEN sr.priority = 'Low'    AND DATEDIFF(NOW(), sr.reported_date) > 7  THEN '!! BREACHED !!'
            ELSE 'Within SLA'
        END                                  AS sla_status,

        COALESCE(t.full_name, 'UNASSIGNED')  AS assigned_technician

    FROM       service_requests   sr
    INNER JOIN customers           c   ON  sr.customer_id    = c.customer_id
    INNER JOIN assets              a   ON  sr.asset_id       = a.asset_id
    LEFT  JOIN work_orders         wo  ON  wo.sr_id          = sr.sr_id
                                      AND  wo.status <> 'Completed'
    LEFT  JOIN technicians         t   ON  wo.technician_id  = t.technician_id
    WHERE  sr.status IN ('Open', 'In Progress')
    ORDER BY
        FIELD(sr.priority, 'High', 'Medium', 'Low'),
        age_days DESC;
END //


DELIMITER ;


-- ── How to CALL the procedures ────────────────────────────────────────────────

-- Step 1: Raise a new service request
SET @new_sr = '';
CALL raise_service_request(2, 3, 'High', 'Hydraulic', 'Pump failure on press line 2', @new_sr);
SELECT @new_sr AS generated_sr_code;

-- Step 2: Assign a technician → creates work order automatically
SET @wo = '';
SET @tech = '';
CALL assign_work_order(@new_sr, @wo, @tech);
SELECT @wo AS work_order_code, @tech AS assigned_to;

-- Step 3: Mark the work order complete
CALL complete_work_order(@wo, 'Replaced hydraulic pump seal. Pressure tested OK.', 5.50);

-- Step 4: Get technician performance for Q1 2024
CALL get_technician_performance('2024-01-01', '2024-03-31');

-- Step 5: View the live SLA dashboard
CALL get_sla_dashboard();


-- ==============================================================
--   SECTION 5 :  VIEWS
-- ==============================================================
--
--   WHAT IS A VIEW?
--   ────────────────
--   A view is a saved SELECT query stored in the database as a
--   named object. When you query a view, MySQL runs the underlying
--   SELECT and returns the result — like a virtual table.
--
--   Views DO NOT store data (unlike tables).
--   They compute results fresh on every query.
--
--   BENEFITS:
--   • Simplicity  — hide complex 5-table JOINs behind one simple name
--   • Security    — expose only certain columns to certain users
--   • Consistency — one definition, referenced everywhere
-- ==============================================================

-- View 1: All open and in-progress requests with full context
CREATE OR REPLACE VIEW v_open_requests AS
SELECT
    sr.sr_code,
    c.customer_name,
    c.city,
    a.machine_type,
    a.asset_code,
    sr.priority,
    sr.status,
    sr.failure_category,
    sr.reported_date,
    DATEDIFF(NOW(), sr.reported_date)       AS days_open,
    COALESCE(t.full_name, 'Unassigned')     AS technician,
    COALESCE(wo.status, 'No WO yet')        AS wo_status
FROM       service_requests   sr
INNER JOIN customers           c   ON  sr.customer_id    = c.customer_id
INNER JOIN assets              a   ON  sr.asset_id       = a.asset_id
LEFT  JOIN work_orders         wo  ON  wo.sr_id          = sr.sr_id
LEFT  JOIN technicians         t   ON  wo.technician_id  = t.technician_id
WHERE  sr.status IN ('Open', 'In Progress');


-- View 2: Technician workload (useful for capacity planning)
CREATE OR REPLACE VIEW v_technician_workload AS
SELECT
    t.full_name,
    t.specialization,
    t.experience_years,
    COUNT(wo.wo_id)                                               AS total_assigned,
    SUM(CASE WHEN wo.status = 'Completed'   THEN 1 ELSE 0 END)   AS completed,
    SUM(CASE WHEN wo.status = 'In Progress' THEN 1 ELSE 0 END)   AS in_progress,
    SUM(CASE WHEN wo.status = 'Pending'     THEN 1 ELSE 0 END)   AS pending
FROM       technicians   t
LEFT JOIN  work_orders   wo  ON  wo.technician_id = t.technician_id
WHERE      t.is_active = TRUE
GROUP BY   t.technician_id, t.full_name, t.specialization, t.experience_years;


-- Query the views just like tables
SELECT * FROM v_open_requests      ORDER BY priority, days_open DESC;
SELECT * FROM v_technician_workload ORDER BY in_progress DESC;


-- ==============================================================
--   SECTION 6 :  INDEXES  (Query Optimisation)
-- ==============================================================
--
--   WHAT IS AN INDEX?
--   ──────────────────
--   An index is a separate data structure (B-tree) that MySQL maintains
--   alongside your table. It maps column values → row locations, so MySQL
--   can find rows WITHOUT scanning every row in the table.
--
--   ANALOGY:
--   Without index: you read every page of a 500-page textbook looking
--                  for the word "Hydraulic" (FULL TABLE SCAN)
--   With index:    you check the index at the back, jump directly to
--                  page 142 (INDEX LOOKUP)
--
--   WHEN TO ADD AN INDEX:
--   • Columns used in WHERE clauses frequently
--   • Columns used in JOIN ON conditions (MySQL auto-indexes FKs but adding
--     explicit indexes is still good practice)
--   • Columns used in ORDER BY or GROUP BY
--
--   COST vs BENEFIT:
--   Benefit: SELECT queries run much faster
--   Cost:    INSERT / UPDATE / DELETE are slightly slower (index must be updated)
--            Indexes consume disk space
--   Rule:    Index columns you read often; be conservative on write-heavy columns
--
--   COMPOSITE INDEX:
--   An index on TWO columns together: (status, priority)
--   Useful when queries filter BOTH columns simultaneously.
--   More efficient than two separate single-column indexes for combined filters.
-- ==============================================================

-- Index on status — most WHERE clauses filter by status
CREATE INDEX idx_sr_status
    ON service_requests (status);

-- Index on priority — used in ORDER BY and WHERE
CREATE INDEX idx_sr_priority
    ON service_requests (priority);

-- Composite index on (status, priority) — for queries filtering both columns
-- EXPLAIN will show "Using index" for: WHERE status = 'Open' AND priority = 'High'
CREATE INDEX idx_sr_status_priority
    ON service_requests (status, priority);

-- Index on reported_date — for date range queries and SLA age calculations
CREATE INDEX idx_sr_reported_date
    ON service_requests (reported_date);

-- Index on work_orders.status — frequently filtered
CREATE INDEX idx_wo_status
    ON work_orders (status);

-- Index on machine_type — frequently grouped and filtered
CREATE INDEX idx_assets_machine_type
    ON assets (machine_type);


-- ── EXPLAIN: see if MySQL is using your index ─────────────────────────────────
--
--   EXPLAIN shows the query execution plan.
--   Key fields to look at:
--   type  = ALL   → full table scan (bad for large tables)
--   type  = ref   → index used (good)
--   type  = range → index used for range scan (good)
--   rows  = estimated number of rows MySQL will examine
--   key   = which index is being used (NULL = no index)

EXPLAIN
SELECT sr_code, priority, status, failure_category
FROM   service_requests
WHERE  status   = 'Open'
  AND  priority = 'High';
-- Expected: key = idx_sr_status_priority, type = ref, rows = small number
