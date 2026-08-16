-- ============================================
-- ALL TYPES OF TIME TRAVEL IN SNOWFLAKE
-- ============================================

USE SCHEMA bronze_layer_db.bronze_layer_schema;

-- ============================================
-- TYPE 1: AT(OFFSET => -seconds)
-- Query data as it existed N seconds ago
-- ============================================
SELECT * FROM employees AT(OFFSET => -60) LIMIT 5;         -- 1 minute ago
SELECT * FROM employees AT(OFFSET => -300) LIMIT 5;        -- 5 minutes ago
SELECT * FROM employees AT(OFFSET => -3600) LIMIT 5;       -- 1 hour ago
SELECT * FROM employees AT(OFFSET => -86400) LIMIT 5;      -- 24 hours ago (max for Standard)

-- ============================================
-- TYPE 2: AT(TIMESTAMP => 'value')
-- Query data at an exact point in time
-- ============================================
SELECT * FROM employees AT(TIMESTAMP => CURRENT_TIMESTAMP() - INTERVAL '30 minutes') LIMIT 5;
SELECT * FROM employees AT(TIMESTAMP => '2026-08-16 01:00:00'::TIMESTAMP_LTZ) LIMIT 5;

-- ============================================
-- TYPE 3: BEFORE(TIMESTAMP => 'value')
-- Query data just BEFORE a specific timestamp
-- ============================================
SELECT * FROM employees BEFORE(TIMESTAMP => CURRENT_TIMESTAMP() - INTERVAL '10 minutes') LIMIT 5;

-- ============================================
-- TYPE 4: AT(STATEMENT => 'query_id')
-- Query data at the point when a specific query started
-- ============================================
-- First, make a change and note the query ID
UPDATE employees SET SALESPERSON = 'UNKNOWN' WHERE "Employee Number" = 3029;
-- Find the query ID from QUERY_HISTORY
SELECT QUERY_ID, QUERY_TEXT, START_TIME
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())
WHERE QUERY_TEXT ILIKE '%UPDATE%UNKNOWN%'
ORDER BY START_TIME DESC LIMIT 1;

-- Use the query ID (replace with actual value)
SELECT * FROM employees AT(STATEMENT => '01c66c8d-0002-51fc-0001-e65a002702fe') LIMIT 5;

-- ============================================
-- TYPE 5: BEFORE(STATEMENT => 'query_id')
-- Query data just BEFORE a specific query executed
-- ============================================
SELECT * FROM employees BEFORE(STATEMENT => '01c66c8d-0002-51fc-0001-e65a002702fe') LIMIT 5;

-- ============================================
-- TYPE 6: CLONE with Time Travel
-- Create a full copy of a table at a past point
-- ============================================
-- Clone using offset
CREATE OR REPLACE TABLE employees_clone_offset
  CLONE employees AT(OFFSET => -60);

-- Clone using timestamp
CREATE OR REPLACE TABLE employees_clone_ts
  CLONE employees AT(TIMESTAMP => CURRENT_TIMESTAMP() - INTERVAL '30 minutes');

-- Clone using statement ID
CREATE OR REPLACE TABLE employees_clone_stmt
CLONE employees BEFORE(STATEMENT => '01c66c8d-0002-51fc-0001-e65a002702fe');


-- ============================================
-- DROP and UNDROP examples
-- ============================================

-- Table
DROP TABLE employees;
UNDROP TABLE employees;

-- Schema
DROP SCHEMA bronze_layer_schema;
UNDROP SCHEMA bronze_layer_schema;

-- Database
DROP DATABASE bronze_layer_db;
UNDROP DATABASE bronze_layer_db;


-- Drop a table
SELECT * FROM employees;
DROP TABLE employees;
-- Try to query it (this will fail)
SELECT * FROM employees;
-- Bring it back with UNDROP
UNDROP TABLE employees;
-- Confirm it's back
SELECT * FROM employees LIMIT 5;

-- Drop and recover a schema
DROP SCHEMA bronze_layer_schema;
USE SCHEMA bronze_layer_db.bronze_layer_schema;
UNDROP SCHEMA bronze_layer_schema;
USE SCHEMA bronze_layer_db.bronze_layer_schema;

-- Drop and recover a database
use bronze_layer_db;
DROP DATABASE bronze_layer_db;
use bronze_layer_db;
UNDROP DATABASE bronze_layer_db;
use bronze_layer_db;


-- ============================================
-- DATA RETENTION AT ALL LEVELS
-- ============================================
-- account is on the Standard edition, which limits DATA_RETENTION_TIME_IN_DAYS to a maximum of 1 day. Setting 7, 14, or 30 days is only available on Enterprise edition or higher.

-- Database level (applies to all schemas/tables unless overridden)
ALTER DATABASE bronze_layer_db SET DATA_RETENTION_TIME_IN_DAYS = 7;
ALTER DATABASE bronze_layer_db SET DATA_RETENTION_TIME_IN_DAYS = 1;

-- Schema level (overrides database setting for this schema)
ALTER SCHEMA bronze_layer_db.bronze_layer_schema SET DATA_RETENTION_TIME_IN_DAYS = 14;
ALTER SCHEMA bronze_layer_db.bronze_layer_schema SET DATA_RETENTION_TIME_IN_DAYS = 1;

-- Table level (overrides schema setting for this table)
ALTER TABLE employees SET DATA_RETENTION_TIME_IN_DAYS = 30;
ALTER TABLE employees SET DATA_RETENTION_TIME_IN_DAYS = 1;

-- Verify retention at each level
SHOW DATABASES LIKE 'BRONZE_LAYER_DB';
SHOW SCHEMAS LIKE 'BRONZE_LAYER_SCHEMA' IN DATABASE BRONZE_LAYER_DB;
SHOW TABLES LIKE 'EMPLOYEES' IN SCHEMA BRONZE_LAYER_DB.BRONZE_LAYER_SCHEMA;