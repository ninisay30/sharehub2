-- ShareHub Donation Aging Module
-- No permanent deletion is used. Old inactive items are archived using status = 'Expired'.
-- aging_reminder_sent_at stores the start of the 4-day grace period after the 60-day reminder.

SET @has_aging_reminder_column := (
    SELECT COUNT(1)
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'donations'
      AND column_name = 'aging_reminder_sent_at'
);

SET @aging_reminder_column_sql := IF(
    @has_aging_reminder_column = 0,
    'ALTER TABLE donations ADD COLUMN aging_reminder_sent_at TIMESTAMP NULL',
    'SELECT ''aging_reminder_sent_at already exists'' AS status'
);

PREPARE stmt_aging_reminder_column FROM @aging_reminder_column_sql;
EXECUTE stmt_aging_reminder_column;
DEALLOCATE PREPARE stmt_aging_reminder_column;

-- Optional helper index for the daily aging check.
SET @has_donation_aging_index := (
    SELECT COUNT(1)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'donations'
      AND index_name = 'idx_donations_status_created_at'
);

SET @donation_aging_index_sql := IF(
    @has_donation_aging_index = 0,
    'CREATE INDEX idx_donations_status_created_at ON donations(status, created_at)',
    'SELECT ''idx_donations_status_created_at already exists'' AS status'
);

PREPARE stmt_donation_aging_index FROM @donation_aging_index_sql;
EXECUTE stmt_donation_aging_index;
DEALLOCATE PREPARE stmt_donation_aging_index;

-- Expired items remain in donations for donor/admin history, but should be excluded from public listings.
