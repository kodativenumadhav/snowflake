
USE DATABASE bronze_layer_db;
USE SCHEMA bronze_layer_db.bronze_layer_schema;

-- drop table gold_employees

-- Task that refreshes gold table from silver with filter
CREATE OR REPLACE TASK gold_employees_task
  WAREHOUSE = COMPUTE_WH
  SCHEDULE = '1 MINUTE'
AS
  CREATE OR REPLACE TABLE gold_employees AS
    SELECT *
    FROM silver_employees
    WHERE "Employee Number" = 3029;

-- Resume the task
ALTER TASK gold_employees_task RESUME;

ALTER TASK gold_employees_task suspend;

-- SELECT * FROM gold_employees;