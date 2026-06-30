package controller;

import dao.DBConnection;
import util.EmailUtility;
import util.NotificationUtil;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/PickupScheduleServlet")
public class PickupScheduleServlet extends HttpServlet {

    private static final String EMAIL_CLOSING = "\n\nWarm regards,\nAinin Sofia\n(ShareHub Admin)";

    private static final Set<String> ALLOWED_LOCATIONS = new HashSet<String>(Arrays.asList(
            "Kompleks Kuliah",
            "PSNZ",
            "Kompleks Siswa",
            "Kolej Kediaman"
    ));

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        int donorId = resolveUserId(session, -1);
        if (donorId <= 0) {
            session.setAttribute("pickupMessage", "Invalid session. Please login again.");
            response.sendRedirect("login.jsp");
            return;
        }

        int requestId = parseInt(request.getParameter("requestId"), -1);
        String location = request.getParameter("location") == null ? "" : request.getParameter("location").trim();
        String pickupDateTime = request.getParameter("pickupDateTime") == null
                ? "" : request.getParameter("pickupDateTime").trim();
        if (pickupDateTime.isEmpty()) {
            String pickupDate = request.getParameter("pickupDate") == null
                    ? "" : request.getParameter("pickupDate").trim();
            String pickupTime = request.getParameter("pickupTime") == null
                    ? "" : request.getParameter("pickupTime").trim();
            if (!pickupDate.isEmpty() && !pickupTime.isEmpty()) {
                pickupDateTime = pickupDate + "T" + pickupTime;
            }
        }

        if (requestId <= 0) {
            session.setAttribute("pickupMessage", "Invalid request selected.");
            response.sendRedirect("pickupSchedule.jsp");
            return;
        }

        if (!ALLOWED_LOCATIONS.contains(location)) {
            session.setAttribute("pickupMessage", "Please choose a valid UMT pickup location.");
            response.sendRedirect("pickupSchedule.jsp");
            return;
        }

        Timestamp pickupTimestamp = parseTimestamp(pickupDateTime);
        if (pickupTimestamp == null) {
            session.setAttribute("pickupMessage", "Please choose a valid pickup date and time.");
            response.sendRedirect("pickupSchedule.jsp");
            return;
        }

        String verifySql = "SELECT r.request_id, r.user_id AS requester_id, d.title, "
                + "requester.email AS requester_email, donor.email AS donor_email, "
                + "CASE WHEN EXISTS (SELECT 1 FROM pickup_schedule ps WHERE ps.request_id = r.request_id) "
                + "THEN 1 ELSE 0 END AS has_schedule "
                + "FROM requests r "
                + "JOIN donations d ON d.donation_id = r.donation_id "
                + "JOIN users requester ON requester.user_id = r.user_id "
                + "JOIN users donor ON donor.user_id = d.donor_id "
                + "WHERE r.request_id = ? AND d.donor_id = ? "
                + "AND LOWER(r.status) IN ('approved', 'pickup scheduled') LIMIT 1";

        String upsertSql = "INSERT INTO pickup_schedule (request_id, donor_id, location, pickup_time) "
                + "VALUES (?, ?, ?, ?) "
                + "ON DUPLICATE KEY UPDATE donor_id = VALUES(donor_id), location = VALUES(location), "
                + "pickup_time = VALUES(pickup_time), updated_at = CURRENT_TIMESTAMP";

        String updateStatusSql = "UPDATE requests SET status = 'Pickup Scheduled' WHERE request_id = ?";

        try (Connection conn = DBConnection.getConnection()) {
            if (conn == null) {
                session.setAttribute("pickupMessage", "Database connection failed.");
                response.sendRedirect("pickupSchedule.jsp");
                return;
            }

            boolean eligibleRequest = false;
            int requesterId = -1;
            String donationTitle = "item";
            boolean hadSchedule = false;
            String requesterEmail = null;
            String donorEmail = null;
            try (PreparedStatement ps = conn.prepareStatement(verifySql)) {
                ps.setInt(1, requestId);
                ps.setInt(2, donorId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        eligibleRequest = true;
                        requesterId = rs.getInt("requester_id");
                        String dbTitle = rs.getString("title");
                        if (dbTitle != null && !dbTitle.trim().isEmpty()) {
                            donationTitle = dbTitle.trim();
                        }
                        requesterEmail = rs.getString("requester_email");
                        donorEmail = rs.getString("donor_email");
                        hadSchedule = rs.getInt("has_schedule") == 1;
                    }
                }
            }

            if (!eligibleRequest) {
                session.setAttribute("pickupMessage", "This request is not ready for pickup scheduling.");
                response.sendRedirect("pickupSchedule.jsp");
                return;
            }

            try (PreparedStatement ps = conn.prepareStatement(upsertSql)) {
                ps.setInt(1, requestId);
                ps.setInt(2, donorId);
                ps.setString(3, location);
                ps.setTimestamp(4, pickupTimestamp);
                ps.executeUpdate();
            }

            try (PreparedStatement ps = conn.prepareStatement(updateStatusSql)) {
                ps.setInt(1, requestId);
                ps.executeUpdate();
            }

            String pickupActionWord = hadSchedule ? "updated" : "scheduled";
            NotificationUtil.createNotificationSafely(conn, requesterId,
                    "Pickup " + pickupActionWord + " for \"" + donationTitle + "\" at "
                    + location + " on " + pickupTimestamp + ".",
                    "myRequest.jsp");

            String emailActionWord = hadSchedule ? "updated" : "scheduled";
            if (requesterEmail != null && !requesterEmail.trim().isEmpty()) {
                EmailUtility.sendNotificationAsync(
                        requesterEmail.trim(),
                        "ShareHub Update: Pickup " + (hadSchedule ? "Updated" : "Scheduled"),
                        "Hello,\n\nYour pickup schedule has been successfully " + emailActionWord + " for \"" + donationTitle + "\"."
                        + "\n\nPickup details:"
                        + "\nLocation: " + location
                        + "\nTime: " + pickupTimestamp
                        + "\n\nPlease attend the pickup at the agreed time and location. If anything changes, kindly inform the other user through ShareHub."
                        + EMAIL_CLOSING);
            }
            if (donorEmail != null && !donorEmail.trim().isEmpty()) {
                EmailUtility.sendNotificationAsync(
                        donorEmail.trim(),
                        "ShareHub Update: Pickup " + (hadSchedule ? "Updated" : "Scheduled"),
                        "Hello,\n\nYou have successfully " + emailActionWord + " the pickup schedule for \"" + donationTitle + "\"."
                        + "\n\nPickup details:"
                        + "\nLocation: " + location
                        + "\nTime: " + pickupTimestamp
                        + "\n\nThank you for coordinating the handover and supporting the ShareHub community."
                        + EMAIL_CLOSING);
            }

            session.setAttribute("pickupMessage", "Pickup details saved. Request status is now Pickup Scheduled.");
            response.sendRedirect("pickupSchedule.jsp");
        } catch (SQLException e) {
            session.setAttribute("pickupMessage", "Failed to save pickup details due to server error.");
            response.sendRedirect("pickupSchedule.jsp");
        }
    }

    private Timestamp parseTimestamp(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        try {
            LocalDateTime localDateTime = LocalDateTime.parse(value);
            return Timestamp.valueOf(localDateTime);
        } catch (DateTimeParseException ex) {
            return null;
        }
    }

    private int resolveUserId(HttpSession session, int fallback) {
        Object userIdObj = session.getAttribute("userId");
        if (userIdObj instanceof Integer) {
            return ((Integer) userIdObj).intValue();
        }
        if (userIdObj != null) {
            try {
                return Integer.parseInt(userIdObj.toString());
            } catch (NumberFormatException ignored) {
                return fallback;
            }
        }
        return fallback;
    }

    private int parseInt(String value, int fallback) {
        if (value == null) {
            return fallback;
        }
        try {
            return Integer.parseInt(value.trim());
        } catch (NumberFormatException ex) {
            return fallback;
        }
    }
}
