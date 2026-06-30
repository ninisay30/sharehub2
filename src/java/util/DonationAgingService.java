package util;

import dao.DBConnection;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;

public class DonationAgingService {

    public static final int INACTIVE_DAYS = 60;
    public static final int GRACE_DAYS = 4;
    private static final String EMAIL_SUBJECT = "ShareHub Reminder: Donation Listing Inactive";
    private static final String ACTIVE_REQUEST_STATUSES =
            "('pending', 'approved', 'pickup scheduled', 'received pending', 'completed')";

    public AgingResult expireInactiveDonations() {
        int checked = 0;
        int remindersSent = 0;
        int expired = 0;

        String reminderSql = "SELECT d.donation_id, d.title, d.category, d.created_at, "
                + "u.user_id AS donor_id, u.name AS donor_name, u.email AS donor_email "
                + "FROM donations d "
                + "JOIN users u ON u.user_id = d.donor_id "
                + "WHERE d.created_at <= (NOW() - INTERVAL " + INACTIVE_DAYS + " DAY) "
                + "AND d.aging_reminder_sent_at IS NULL "
                + "AND LOWER(COALESCE(d.status, '')) IN ('pending', 'available') "
                + noActiveRequestClause("d.donation_id")
                + "ORDER BY d.created_at ASC";

        String expirationSql = "SELECT d.donation_id, d.title, u.user_id AS donor_id "
                + "FROM donations d "
                + "JOIN users u ON u.user_id = d.donor_id "
                + "WHERE d.aging_reminder_sent_at IS NOT NULL "
                + "AND d.aging_reminder_sent_at <= (NOW() - INTERVAL " + GRACE_DAYS + " DAY) "
                + "AND LOWER(COALESCE(d.status, '')) IN ('pending', 'available') "
                + noActiveRequestClause("d.donation_id")
                + "ORDER BY d.aging_reminder_sent_at ASC";

        try (Connection conn = DBConnection.getConnection()) {
            if (conn == null) {
                return new AgingResult(0, 0, 0, false, "Database connection failed.");
            }

            ensureAgingColumn(conn);

            try (PreparedStatement ps = conn.prepareStatement(reminderSql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    checked++;
                    if (sendReminderAndStartGrace(conn, rs)) {
                        remindersSent++;
                    }
                }
            }

            try (PreparedStatement ps = conn.prepareStatement(expirationSql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    checked++;
                    if (expireAfterGrace(conn, rs)) {
                        expired++;
                    }
                }
            }
        } catch (SQLException ex) {
            return new AgingResult(checked, remindersSent, expired, false, "Donation aging check failed.");
        }

        return new AgingResult(checked, remindersSent, expired, true, "Donation aging check completed.");
    }

    private boolean sendReminderAndStartGrace(Connection conn, ResultSet rs) throws SQLException {
        int donationId = rs.getInt("donation_id");
        int donorId = rs.getInt("donor_id");
        String title = safeText(rs.getString("title"), "Donation item");
        String category = safeText(rs.getString("category"), "Others / Miscellaneous");
        Timestamp createdAt = rs.getTimestamp("created_at");
        String donorName = safeText(rs.getString("donor_name"), "there");
        String donorEmail = rs.getString("donor_email");

        String updateSql = "UPDATE donations SET aging_reminder_sent_at = NOW() "
                + "WHERE donation_id = ? "
                + "AND aging_reminder_sent_at IS NULL "
                + "AND LOWER(COALESCE(status, '')) IN ('pending', 'available') "
                + noActiveRequestClause("donations.donation_id");

        try (PreparedStatement updatePs = conn.prepareStatement(updateSql)) {
            updatePs.setInt(1, donationId);
            if (updatePs.executeUpdate() != 1) {
                return false;
            }
        }

        String emailBody = buildReminderEmail(donorName, title, category, createdAt);
        boolean emailQueued = false;
        if (donorEmail != null && donorEmail.trim().length() > 0) {
            EmailUtility.sendNotificationAsync(donorEmail.trim(), EMAIL_SUBJECT, emailBody);
            emailQueued = true;
        }

        NotificationUtil.createNotificationSafely(conn, donorId,
                "Reminder: your donation \"" + title + "\" has been inactive for "
                + INACTIVE_DAYS + " days. Please repost within " + GRACE_DAYS
                + " days if it is still available.",
                "myItems.jsp");

        return emailQueued;
    }

    private boolean expireAfterGrace(Connection conn, ResultSet rs) throws SQLException {
        int donationId = rs.getInt("donation_id");
        int donorId = rs.getInt("donor_id");
        String title = safeText(rs.getString("title"), "Donation item");

        String updateSql = "UPDATE donations SET status = 'Expired' "
                + "WHERE donation_id = ? "
                + "AND aging_reminder_sent_at IS NOT NULL "
                + "AND aging_reminder_sent_at <= (NOW() - INTERVAL " + GRACE_DAYS + " DAY) "
                + "AND LOWER(COALESCE(status, '')) IN ('pending', 'available') "
                + noActiveRequestClause("donations.donation_id");

        try (PreparedStatement updatePs = conn.prepareStatement(updateSql)) {
            updatePs.setInt(1, donationId);
            boolean updated = updatePs.executeUpdate() == 1;
            if (updated) {
                NotificationUtil.createNotificationSafely(conn, donorId,
                        "Your donation \"" + title + "\" has expired after the "
                        + GRACE_DAYS + "-day aging reminder grace period.",
                        "myItems.jsp");
            }
            return updated;
        }
    }

    private void ensureAgingColumn(Connection conn) throws SQLException {
        DatabaseMetaData meta = conn.getMetaData();
        try (ResultSet rs = meta.getColumns(conn.getCatalog(), null, "donations", "aging_reminder_sent_at")) {
            if (rs.next()) {
                return;
            }
        }

        try (PreparedStatement ps = conn.prepareStatement(
                "ALTER TABLE donations ADD COLUMN aging_reminder_sent_at TIMESTAMP NULL")) {
            ps.executeUpdate();
        }
    }

    private String noActiveRequestClause(String donationReference) {
        return "AND NOT EXISTS ("
                + "    SELECT 1 FROM requests r "
                + "    WHERE r.donation_id = " + donationReference + " "
                + "    AND LOWER(COALESCE(r.status, '')) IN " + ACTIVE_REQUEST_STATUSES
                + ") ";
    }

    private String buildReminderEmail(String donorName, String title, String category, Timestamp createdAt) {
        String postedDate = createdAt == null ? "Not available" : new SimpleDateFormat("dd MMM yyyy").format(createdAt);

        return "Hi " + donorName + ",\n\n"
                + "We noticed that your donation item has been inactive for " + INACTIVE_DAYS + " days.\n\n"
                + "Item title: " + title + "\n"
                + "Category: " + category + "\n"
                + "Posted date: " + postedDate + "\n\n"
                + "If you still wish to donate this item, please submit a new donation listing within the next "
                + GRACE_DAYS + " days. This confirms that the item is still available and that the donation "
                + "information remains up to date.\n\n"
                + "If no action is taken within " + GRACE_DAYS + " days, the current donation listing will "
                + "automatically expire and be removed from the public listing. The record will still remain in "
                + "your ShareHub history.\n\n"
                + "Thank you for helping other students reuse useful items and reduce unnecessary waste.\n\n"
                + "Warm regards,\n"
                + "ShareHub Admin";
    }

    private String safeText(String value, String fallback) {
        if (value == null || value.trim().length() == 0) {
            return fallback;
        }
        return value.trim();
    }

    public static final class AgingResult {
        private final int checked;
        private final int remindersSent;
        private final int expired;
        private final boolean success;
        private final String message;

        public AgingResult(int checked, int remindersSent, int expired, boolean success, String message) {
            this.checked = checked;
            this.remindersSent = remindersSent;
            this.expired = expired;
            this.success = success;
            this.message = message;
        }

        public int getChecked() {
            return checked;
        }

        public int getRemindersSent() {
            return remindersSent;
        }

        public int getExpired() {
            return expired;
        }

        public boolean isSuccess() {
            return success;
        }

        public String getMessage() {
            return message;
        }
    }
}
