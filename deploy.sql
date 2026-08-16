-- ============================================
-- PARAMETERIZED DEPLOYMENT SCRIPT
-- Set env = 'DEV' or 'PROD' — all other params auto-resolve
-- ============================================

-- >>>>>> SET ENVIRONMENT HERE <<<<<<
SET env = 'DEV';  -- Change to 'PROD' for production deployment

-- Auto-resolve parameters based on environment
SET db_name = CASE WHEN $env = 'PROD' THEN 'PROD_BRONZE_DB' ELSE 'BRONZE_LAYER_DB' END;
SET schema_name = CASE WHEN $env = 'PROD' THEN 'PROD_BRONZE_SCHEMA' ELSE 'BRONZE_LAYER_SCHEMA' END;
SET warehouse = CASE WHEN $env = 'PROD' THEN 'PROD_WH' ELSE 'COMPUTE_WH' END;
SET stage_url = CASE WHEN $env = 'PROD' THEN 'gcs://prod_bronze_snowflake/' ELSE 'gcs://bronze_snowflake/' END;
SET integration_name = CASE WHEN $env = 'PROD' THEN 'PROD_GCS_INTEGRATION' ELSE 'GCS_INTEGRATION' END;
SET task_schedule = CASE WHEN $env = 'PROD' THEN '5 MINUTE' ELSE '5 MINUTE' END;
SET gold_employee_filter = 3029;

-- Display resolved config
SELECT $env AS ENVIRONMENT,
       $db_name AS DATABASE_NAME,
       $schema_name AS SCHEMA_NAME,
       $warehouse AS WAREHOUSE,
       $stage_url AS STAGE_URL,
       $integration_name AS INTEGRATION,
       $task_schedule AS TASK_SCHEDULE;

-- ============================================
-- STEP 1: DATABASE & SCHEMA
-- ============================================
CREATE DATABASE IF NOT EXISTS IDENTIFIER($db_name);
USE DATABASE IDENTIFIER($db_name);

CREATE SCHEMA IF NOT EXISTS IDENTIFIER($schema_name);
USE SCHEMA IDENTIFIER($schema_name);

-- ============================================
-- STEP 2: STORAGE INTEGRATION (run once, requires ACCOUNTADMIN)
-- ============================================
-- NOTE: Storage integrations are account-level objects.
-- Uncomment and run only if it doesn't exist yet.

-- CREATE STORAGE INTEGRATION IF NOT EXISTS IDENTIFIER($integration_name)
--   TYPE = EXTERNAL_STAGE
--   STORAGE_PROVIDER = GCS
--   ENABLED = TRUE
--   STORAGE_ALLOWED_LOCATIONS = ($stage_url);

-- ============================================
-- STEP 3: FILE FORMAT
-- ============================================
CREATE OR REPLACE FILE FORMAT csv_gcs_format
  TYPE = CSV
  FIELD_OPTIONALLY_ENCLOSED_BY = '\"'
  SKIP_HEADER = 1
  ENCODING = 'WINDOWS1252';

-- ============================================
-- STEP 4: STAGE
-- ============================================
CREATE STAGE IF NOT EXISTS bronze_sf_gcs_stage
  STORAGE_INTEGRATION = GCS_INTEGRATION
  URL = $stage_url;

-- ============================================
-- STEP 5: TABLES
-- ============================================
CREATE TABLE IF NOT EXISTS employees (
  "Employee Number" INT,
  SALESPERSON STRING,
  QUANTITY_INVOICED STRING,
  UNITSELLINGPRICE INT,
  "Sale Line" INT,
  "Sale Item Qty" INT,
  INV_AMT INT,
  FLOW_STATUS_CODE STRING,
  "MONTH" STRING
);

CREATE TABLE IF NOT EXISTS silver_employees (
  "Employee Number" NUMBER(38,0),
  SALESPERSON VARCHAR,
  QUANTITY_INVOICED VARCHAR,
  UNITSELLINGPRICE NUMBER(38,0),
  "Sale Line" NUMBER(38,0),
  "Sale Item Qty" NUMBER(38,0),
  INV_AMT NUMBER(38,0),
  FLOW_STATUS_CODE VARCHAR,
  "MONTH" VARCHAR
);

CREATE TABLE IF NOT EXISTS gold_employees (
  "Employee Number" NUMBER(38,0),
  SALESPERSON VARCHAR,
  QUANTITY_INVOICED VARCHAR,
  UNITSELLINGPRICE NUMBER(38,0),
  "Sale Line" NUMBER(38,0),
  "Sale Item Qty" NUMBER(38,0),
  INV_AMT NUMBER(38,0),
  FLOW_STATUS_CODE VARCHAR,
  "MONTH" VARCHAR
);

-- ============================================
-- STEP 6: LOAD DATA
-- ============================================
COPY INTO employees
FROM @bronze_sf_gcs_stage
FILE_FORMAT = csv_gcs_format;

-- ============================================
-- STEP 7: STREAM (CDC)
-- ============================================
CREATE OR REPLACE STREAM employees_stream ON TABLE employees;

-- ============================================
-- STEP 8: SNOWPIPE
-- ============================================
CREATE OR REPLACE PIPE employees_pipe
  AUTO_INGEST = FALSE
AS
  COPY INTO employees
  FROM @bronze_sf_gcs_stage
  FILE_FORMAT = csv_gcs_format;

-- ============================================
-- STEP 9: TASKS
-- ============================================

-- Task: Silver layer (merge from stream)
CREATE OR REPLACE TASK silver_employees_task
  WAREHOUSE = $warehouse
  SCHEDULE = $task_schedule
  WHEN SYSTEM$STREAM_HAS_DATA('employees_stream')
AS
  MERGE INTO silver_employees AS tgt
  USING (
    SELECT * FROM employees_stream WHERE METADATA$ACTION = 'INSERT'
  ) AS src
  ON tgt."Employee Number" = src."Employee Number"
     AND tgt."Sale Line" = src."Sale Line"
     AND tgt."MONTH" = src."MONTH"
  WHEN MATCHED THEN UPDATE SET
    tgt.SALESPERSON = src.SALESPERSON,
    tgt.QUANTITY_INVOICED = src.QUANTITY_INVOICED,
    tgt.UNITSELLINGPRICE = src.UNITSELLINGPRICE,
    tgt."Sale Item Qty" = src."Sale Item Qty",
    tgt.INV_AMT = src.INV_AMT,
    tgt.FLOW_STATUS_CODE = src.FLOW_STATUS_CODE
  WHEN NOT MATCHED THEN INSERT (
    "Employee Number", SALESPERSON, QUANTITY_INVOICED, UNITSELLINGPRICE,
    "Sale Line", "Sale Item Qty", INV_AMT, FLOW_STATUS_CODE, "MONTH"
  ) VALUES (
    src."Employee Number", src.SALESPERSON, src.QUANTITY_INVOICED, src.UNITSELLINGPRICE,
    src."Sale Line", src."Sale Item Qty", src.INV_AMT, src.FLOW_STATUS_CODE, src."MONTH"
  );

-- Task: Gold layer (filtered refresh)
CREATE OR REPLACE TASK gold_employees_task
  WAREHOUSE = $warehouse
  SCHEDULE = $task_schedule
AS
  INSERT OVERWRITE INTO gold_employees
  SELECT *
  FROM silver_employees
  WHERE "Employee Number" = $gold_employee_filter;

-- ============================================
-- STEP 10: RESUME TASKS
-- ============================================
ALTER TASK silver_employees_task RESUME;
ALTER TASK gold_employees_task RESUME;

-- ============================================
-- VERIFICATION
-- ============================================
SHOW TABLES IN SCHEMA IDENTIFIER($schema_name);
SHOW STREAMS IN SCHEMA IDENTIFIER($schema_name);
SHOW TASKS IN SCHEMA IDENTIFIER($schema_name);
SHOW PIPES IN SCHEMA IDENTIFIER($schema_name);
