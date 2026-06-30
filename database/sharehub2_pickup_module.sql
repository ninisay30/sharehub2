-- ShareHub2 Pickup Module Migration
-- Run this on database: sharehub_db

CREATE TABLE IF NOT EXISTS pickup_schedule (
    schedule_id INT AUTO_INCREMENT PRIMARY KEY,
    request_id INT NOT NULL,
    donor_id INT NOT NULL,
    location VARCHAR(80) NOT NULL,
    pickup_time DATETIME NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_pickup_schedule_request UNIQUE (request_id),
    CONSTRAINT fk_pickup_request FOREIGN KEY (request_id) REFERENCES requests(request_id),
    CONSTRAINT fk_pickup_donor FOREIGN KEY (donor_id) REFERENCES users(user_id)
);

-- Optional index for faster donor listing
CREATE INDEX idx_pickup_donor_time ON pickup_schedule(donor_id, pickup_time);
