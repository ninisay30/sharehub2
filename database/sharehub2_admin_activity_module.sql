-- ShareHub2 Admin Activity Module Migration
-- Run this on database: sharehub_db

CREATE TABLE IF NOT EXISTS admin_activity_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    admin_user_id INT NULL,
    admin_name VARCHAR(120) NOT NULL,
    admin_email VARCHAR(150) NULL,
    action_type VARCHAR(20) NOT NULL,
    entity_type VARCHAR(20) NOT NULL,
    entity_id INT NOT NULL,
    details VARCHAR(255) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_admin_activity_created_at ON admin_activity_log(created_at);
CREATE INDEX idx_admin_activity_target ON admin_activity_log(entity_type, entity_id);
CREATE INDEX idx_admin_activity_action_time ON admin_activity_log(action_type, created_at);
