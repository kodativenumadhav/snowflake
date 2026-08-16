-- ============================================
-- DYNAMIC TABLES: Full Pipeline (Bronze → Silver → Gold)
-- ============================================

USE SCHEMA bronze_layer_db.bronze_layer_schema;

-- ============================================
-- DYNAMIC TABLE 2: Gold Layer
-- Refreshes automatically from silver (chained)
-- Filters to employee 3029 only
-- ============================================
CREATE OR REPLACE DYNAMIC TABLE dt_gold_employees
  TARGET_LAG = '1 MINUTE'
  WAREHOUSE = COMPUTE_WH
AS
  SELECT *
  FROM dt_silver_employees
  WHERE "Employee Number" = 3029;

-- ============================================
-- DYNAMIC TABLE 1: Silver Layer
-- Refreshes automatically from employees (bronze)
-- ============================================
CREATE OR REPLACE DYNAMIC TABLE dt_silver_employees
  TARGET_LAG = '1 MINUTE'
  WAREHOUSE = COMPUTE_WH
AS
  SELECT
    "Employee Number",
    SALESPERSON,
    QUANTITY_INVOICED,
    UNITSELLINGPRICE,
    "Sale Line",
    "Sale Item Qty",
    INV_AMT,
    FLOW_STATUS_CODE,
    "MONTH"
  FROM employees;



-- ============================================
-- VERIFY
-- ============================================
SHOW DYNAMIC TABLES IN SCHEMA bronze_layer_db.bronze_layer_schema;

-- Check refresh status
SELECT *
FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLES())
WHERE SCHEMA_NAME = 'BRONZE_LAYER_SCHEMA';

-- Query the dynamic tables
SELECT * FROM dt_silver_employees;
SELECT * FROM dt_gold_employees;