
USE SCHEMA bronze_layer_db.bronze_layer_schema;

CREATE OR REPLACE STREAM employees_stream ON TABLE employees;

-- Silver-layer target table
CREATE OR REPLACE TABLE silver_employees (
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


INSERT INTO silver_employees
SELECT "Employee Number", SALESPERSON, QUANTITY_INVOICED, UNITSELLINGPRICE,
       "Sale Line", "Sale Item Qty", INV_AMT, FLOW_STATUS_CODE, "MONTH"
FROM employees;


-- -- Now update a row to test the stream/task pipeline
UPDATE employees
SET INV_AMT = 50000, FLOW_STATUS_CODE = 'CLOSED'
WHERE "Employee Number" = 1854
  AND "Sale Line" = 2
  AND "MONTH" = 'Apr-19';

-- -- Verify the stream captured the change
SELECT * FROM employees_stream;


