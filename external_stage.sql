CREATE DATABASE bronze_layer_db;
USE DATABASE bronze_layer_db;

CREATE SCHEMA bronze_layer_schema;
USE SCHEMA bronze_layer_db.bronze_layer_schema;

CREATE or replace  TABLE employees (
  "Employee Number" INT,
  Salesperson STRING,
  Quantity_Invoiced STRING,
  UnitSellingPrice INT,
  "Sale Line" INT,
  "Sale Item Qty" INT,
  Inv_Amt INT,
  Flow_Status_Code STRING,
  "MONTH" STRING
);

CREATE STAGE bronze_sf_gcs_stage
  STORAGE_INTEGRATION = gcs_integration
  URL = 'gcs://bronze_snowflake/';







