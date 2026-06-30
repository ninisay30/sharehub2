package util;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

public final class NotificationUtil {

    private NotificationUtil() {
    }

    public static void createNotification(Connection conn, int userId, String message, String targetPath)
            throws SQLException {
        if (conn == null || userId <= 0 || message == null || message.trim().isEmpty()) {
            return;
        }

        String normalizedMessage = message.trim();
        if (normalizedMessage.length() > 255) {
            normalizedMessage = normalizedMessage.substring(0, 252) + "...";
        }
        String normalizedTarget = targetPath == null ? "" : targetPath.trim();
        String insertSql = "INSERT INTO notifications (user_id, message, target_path, is_read) "
                + "VALUES (?, ?, ?, 0)";

        try (PreparedStatement ps = conn.prepareStatement(insertSql)) {
            ps.setInt(1, userId);
            ps.setString(2, normalizedMessage);
            ps.setString(3, normalizedTarget);
            ps.executeUpdate();
        }
    }

    public static void createNotificationSafely(Connection conn, int userId, String message, String targetPath) {
        try {
            createNotification(conn, userId, message, targetPath);
        } catch (SQLException ignored) {
            // Notification failures should not break core flow.
        }
    }
}
