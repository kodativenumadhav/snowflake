USE SCHEMA bronze_layer_db.bronze_layer_schema;

-- Create a persistent file format for the pipe
CREATE OR REPLACE FILE FORMAT csv_gcs_format
  TYPE = CSV
  FIELD_OPTIONALLY_ENCLOSED_BY = '\"'
  SKIP_HEADER = 1
  ENCODING = 'WINDOWS1252';

-- Create Snowpipe (manual trigger)
CREATE OR REPLACE PIPE employees_pipe
  AUTO_INGEST = FALSE
AS
  COPY INTO employees
  FROM @bronze_sf_gcs_stage
  FILE_FORMAT = csv_gcs_format;


ALTER PIPE employees_pipe REFRESH;

-- Check the pipe status and get the notification channel
SHOW PIPES LIKE 'EMPLOYEES_PIPE';
