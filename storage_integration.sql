CREATE or replace STORAGE INTEGRATION gcs_integration
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = GCS
  ENABLED = TRUE
  STORAGE_ALLOWED_LOCATIONS = ('gcs://bronze_snowflake/');

DESC STORAGE INTEGRATION gcs_integration;





-- -- 1. Create a secret for authentication (if private repo)
-- CREATE OR REPLACE SECRET git_secret
--   TYPE = PASSWORD
--   USERNAME = 'kodativenumadhav'
--   PASSWORD = 'your-personal-access-token';

-- -- 2. Create an API integration for Git
-- CREATE OR REPLACE API INTEGRATION git_api_integration
--   API_PROVIDER = GIT_HTTPS_API
--   API_ALLOWED_PREFIXES = ('https://github.com/your-org')
--   ALLOWED_AUTHENTICATION_SECRETS = (git_secret)
--   ENABLED = TRUE;

-- -- 3. Create the Git repository object
-- CREATE OR REPLACE GIT REPOSITORY my_repo
--   API_INTEGRATION = git_api_integration
--   GIT_CREDENTIALS = git_secret
--   ORIGIN = 'https://github.com/your-org/your-repo.git';

-- -- 4. Fetch latest
-- ALTER GIT REPOSITORY my_repo FETCH;

-- -- 5. List files
-- LS @my_repo/branches/main;






