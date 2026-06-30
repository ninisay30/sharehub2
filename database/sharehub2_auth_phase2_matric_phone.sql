-- ShareHub2 Auth Phase 2 Migration (Matric Number + Phone Number)
-- Safe to run on existing database without affecting existing accounts.
-- Run this on database: sharehub_db

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS matric_no VARCHAR(40) NULL,
    ADD COLUMN IF NOT EXISTS phone_no VARCHAR(30) NULL;

-- Keep email unique at database level (if unique index is not present yet).
SET @schema_name := DATABASE();
SET @has_email_unique := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = @schema_name
      AND table_name = 'users'
      AND index_name = 'uk_users_email'
      AND non_unique = 0
);
SET @email_index_sql := IF(
    @has_email_unique = 0,
    'CREATE UNIQUE INDEX uk_users_email ON users(email)',
    'SELECT ''uk_users_email already exists'' AS status'
);
PREPARE stmt_email FROM @email_index_sql;
EXECUTE stmt_email;
DEALLOCATE PREPARE stmt_email;

-- Enforce unique matric number for new/updated accounts.
-- Multiple NULL values are allowed, so existing old accounts remain compatible.
SET @has_matric_unique := (
    SELECT COUNT(*)
    FROM information_schema.statistics
    WHERE table_schema = @schema_name
      AND table_name = 'users'
      AND index_name = 'uk_users_matric_no'
      AND non_unique = 0
);
SET @matric_index_sql := IF(
    @has_matric_unique = 0,
    'CREATE UNIQUE INDEX uk_users_matric_no ON users(matric_no)',
    'SELECT ''uk_users_matric_no already exists'' AS status'
);
PREPARE stmt_matric FROM @matric_index_sql;
EXECUTE stmt_matric;
DEALLOCATE PREPARE stmt_matric;

