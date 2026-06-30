-- ShareHub2 Notifications Module Migration
-- Run this on database: sharehub_db

CREATE TABLE IF NOT EXISTS notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    message VARCHAR(255) NOT NULL,
    target_path VARCHAR(120) NULL,
    is_read TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE INDEX idx_notifications_user_time ON notifications(user_id, created_at);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read);
