-- ShareHub2 Donation Enhancements Migration
-- Run this on database: sharehub_db

ALTER TABLE donations
    ADD COLUMN IF NOT EXISTS category VARCHAR(60) NULL,
    ADD COLUMN IF NOT EXISTS item_condition VARCHAR(20) NULL;

UPDATE donations
SET category = 'Others / Miscellaneous'
WHERE category IS NULL OR TRIM(category) = '';

UPDATE donations
SET category = 'Household & Hostel Items'
WHERE category IN ('Household Items', 'Hostel Essentials');

UPDATE donations
SET category = 'Others / Miscellaneous'
WHERE category IN ('Food & Beverages', 'Others');

UPDATE donations
SET category = 'Others / Miscellaneous'
WHERE category NOT IN (
    'Books & Study Materials',
    'Clothes & Accessories',
    'Household & Hostel Items',
    'Electronics & Gadgets',
    'Others / Miscellaneous'
);

UPDATE donations
SET item_condition = 'Good'
WHERE item_condition IS NULL OR TRIM(item_condition) = '';

CREATE INDEX idx_donations_category ON donations(category);
CREATE INDEX idx_donations_condition ON donations(item_condition);
