package controller;

import dao.DBConnection;
import util.EmailUtility;
import util.NotificationUtil;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/AdminActionServlet")
public class AdminActionServlet extends HttpServlet {

    private static final String EMAIL_CLOSING = "\n\nWarm regards,\nAinin Sofia\n(ShareHub Admin)";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        String returnPage = resolveReturnPage(request.getParameter("returnPage"));
        if (session == null || !isAdmin(session)) {
            response.sendRedirect("login.jsp");
            return;
        }

        String entity = request.getParameter("entity") == null ? "" : request.getParameter("entity").trim();
        String decision = request.getParameter("decision") == null ? "" : request.getParameter("decision").trim();
        int id = parseInt(request.getParameter("id"), -1);

        if (id <= 0 || (!"donation".equalsIgnoreCase(entity) && !"request".equalsIgnoreCase(entity))
                || (!"approve".equalsIgnoreCase(decision) && !"reject".equalsIgnoreCase(decision))) {
            session.setAttribute("adminMessage", "Invalid admin action.");
            response.sendRedirect(returnPage);
            return;
        }

        boolean approve = "approve".equalsIgnoreCase(decision);
        boolean success;

        try (Connection conn = DBConnection.getConnection()) {
            if (conn == null) {
                session.setAttribute("adminMessage", "Database connection failed.");
                response.sendRedirect(returnPage);
                return;
            }

            if ("donation".equalsIgnoreCase(entity)) {
                success = processDonation(conn, id, approve);
            } else {
                success = processRequest(conn, id, approve);
            }
        } catch (SQLException e) {
            session.setAttribute("adminMessage", "Admin action failed due to server error.");
            response.sendRedirect(returnPage);
            return;
        }

        if (success) {
            String actionWord = approve ? "approved" : "rejected";
            session.setAttribute("adminMessage",
                    ("donation".equalsIgnoreCase(entity) ? "Donation #" : "Request #") + id + " " + actionWord + ".");
            logAdminActionSafely(session, entity, id, decision);
        } else {
            session.setAttribute("adminMessage", "Action not applied. Record may have been processed already.");
        }
        response.sendRedirect(returnPage);
    }

    private boolean processDonation(Connection conn, int donationId, boolean approve) throws SQLException {
        String findDonationSql = "SELECT d.donor_id, d.title, u.email AS donor_email "
                + "FROM donations d "
                + "JOIN users u ON u.user_id = d.donor_id "
                + "WHERE d.donation_id = ? AND LOWER(d.status) = 'pending' LIMIT 1";
        String updateSql = "UPDATE donations SET status = ? WHERE donation_id = ? AND LOWER(status) = 'pending'";
        String pendingRequesterSql = "SELECT user_id FROM requests "
                + "WHERE donation_id = ? AND LOWER(status) = 'pending'";

        conn.setAutoCommit(false);
        try {
            int donorId = -1;
            String donationTitle = "item";
            String donorEmail = null;
            try (PreparedStatement ps = conn.prepareStatement(findDonationSql)) {
                ps.setInt(1, donationId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        donorId = rs.getInt("donor_id");
                        donorEmail = rs.getString("donor_email");
                        String dbTitle = rs.getString("title");
                        if (dbTitle != null && !dbTitle.trim().isEmpty()) {
                            donationTitle = dbTitle.trim();
                        }
                    } else {
                        conn.rollback();
                        return false;
                    }
                }
            }

            int updatedRows;
            try (PreparedStatement ps = conn.prepareStatement(updateSql)) {
                ps.setString(1, approve ? "Available" : "Rejected");
                ps.setInt(2, donationId);
                updatedRows = ps.executeUpdate();
            }

            if (updatedRows == 0) {
                conn.rollback();
                return false;
            }

            NotificationUtil.createNotificationSafely(conn, donorId,
                    approve
                            ? "Your donation \"" + donationTitle + "\" was approved and is now available."
                            : "Your donation \"" + donationTitle + "\" was rejected by admin.",
                    "myItems.jsp");

            if (!approve) {
                List<Integer> impactedRequesterIds = new ArrayList<Integer>();
                try (PreparedStatement ps = conn.prepareStatement(pendingRequesterSql)) {
                    ps.setInt(1, donationId);
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            impactedRequesterIds.add(Integer.valueOf(rs.getInt("user_id")));
                        }
                    }
                }

                String rejectPendingRequestsSql = "UPDATE requests SET status = 'Rejected' "
                        + "WHERE donation_id = ? AND LOWER(status) = 'pending'";
                try (PreparedStatement ps = conn.prepareStatement(rejectPendingRequestsSql)) {
                    ps.setInt(1, donationId);
                    ps.executeUpdate();
                }

                for (Integer requesterId : impactedRequesterIds) {
                    NotificationUtil.createNotificationSafely(conn, requesterId.intValue(),
                            "Your request for \"" + donationTitle + "\" was rejected because the donation was not approved.",
                            "myRequest.jsp");
                }
            }

            conn.commit();
            if (donorEmail != null && !donorEmail.trim().isEmpty()) {
                if (approve) {
                    EmailUtility.sendNotificationAsync(
                            donorEmail.trim(),
                            "ShareHub Update: Donation Approved",
                            "Hello,\n\nGood news. Your donation item \"" + donationTitle
                            + "\" has been approved and is now available on ShareHub for other students to request."
                            + "\n\nThank you for contributing to our sharing community and supporting sustainable reuse among UMT students."
                            + EMAIL_CLOSING);
                } else {
                    EmailUtility.sendNotificationAsync(
                            donorEmail.trim(),
                            "ShareHub Update: Donation Not Approved",
                            "Hello,\n\nThank you for submitting your donation item \"" + donationTitle + "\"."
                            + "\n\nAt this time, it could not be approved for listing."
                            + "\nYou may review your item details and submit again when ready."
                            + "\n\nWe appreciate your willingness to support fellow students."
                            + EMAIL_CLOSING);
                }
            }
            return true;
        } catch (SQLException e) {
            conn.rollback();
            throw e;
        } finally {
            conn.setAutoCommit(true);
        }
    }

    private boolean processRequest(Connection conn, int requestId, boolean approve) throws SQLException {
        conn.setAutoCommit(false);
        try {
            int donationId = -1;
            int requesterId = -1;
            int donorId = -1;
            String requesterEmail = null;
            String donorEmail = null;
            String donationTitle = "item";
            String findSql = "SELECT r.donation_id, r.user_id AS requester_id, d.donor_id, d.title, "
                    + "requester.email AS requester_email, donor.email AS donor_email "
                    + "FROM requests r "
                    + "JOIN donations d ON d.donation_id = r.donation_id "
                    + "JOIN users requester ON requester.user_id = r.user_id "
                    + "JOIN users donor ON donor.user_id = d.donor_id "
                    + "WHERE r.request_id = ? AND LOWER(r.status) = 'pending' LIMIT 1";
            try (PreparedStatement ps = conn.prepareStatement(findSql)) {
                ps.setInt(1, requestId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        donationId = rs.getInt("donation_id");
                        requesterId = rs.getInt("requester_id");
                        donorId = rs.getInt("donor_id");
                        requesterEmail = rs.getString("requester_email");
                        donorEmail = rs.getString("donor_email");
                        String dbTitle = rs.getString("title");
                        if (dbTitle != null && !dbTitle.trim().isEmpty()) {
                            donationTitle = dbTitle.trim();
                        }
                    }
                }
            }

            if (donationId <= 0) {
                conn.rollback();
                return false;
            }

            if (!approve) {
                String rejectSql = "UPDATE requests SET status = 'Rejected' "
                        + "WHERE request_id = ? AND LOWER(status) = 'pending'";
                try (PreparedStatement ps = conn.prepareStatement(rejectSql)) {
                    ps.setInt(1, requestId);
                    if (ps.executeUpdate() == 0) {
                        conn.rollback();
                        return false;
                    }
                }

                String restoreDonationSql = "UPDATE donations SET status = 'Available' "
                        + "WHERE donation_id = ? "
                        + "AND NOT EXISTS (SELECT 1 FROM requests r "
                        + "WHERE r.donation_id = donations.donation_id "
                        + "AND LOWER(r.status) IN ('pending', 'approved', 'pickup scheduled', 'received pending'))";
                try (PreparedStatement ps = conn.prepareStatement(restoreDonationSql)) {
                    ps.setInt(1, donationId);
                    ps.executeUpdate();
                }

                NotificationUtil.createNotificationSafely(conn, requesterId,
                        "Your request for \"" + donationTitle + "\" was rejected by admin.",
                        "myRequest.jsp");

                conn.commit();
                if (requesterEmail != null && !requesterEmail.trim().isEmpty()) {
                    EmailUtility.sendNotificationAsync(
                            requesterEmail.trim(),
                            "ShareHub Update: Request Not Approved",
                            "Hello,\n\nUnfortunately, your request for \"" + donationTitle
                            + "\" could not be approved at this time."
                            + "\n\nPlease review the item information and feel free to try again in the future."
                            + "\n\nThank you for using ShareHub."
                            + EMAIL_CLOSING);
                }
                return true;
            }

            String approveSql = "UPDATE requests SET status = 'Approved' "
                    + "WHERE request_id = ? AND LOWER(status) = 'pending'";
            int updatedRows;
            try (PreparedStatement ps = conn.prepareStatement(approveSql)) {
                ps.setInt(1, requestId);
                updatedRows = ps.executeUpdate();
            }

            if (updatedRows == 0) {
                conn.rollback();
                return false;
            }

            List<Integer> otherRequesterIds = new ArrayList<Integer>();
            String otherPendingSql = "SELECT user_id FROM requests "
                    + "WHERE donation_id = ? AND request_id <> ? AND LOWER(status) = 'pending'";
            try (PreparedStatement ps = conn.prepareStatement(otherPendingSql)) {
                ps.setInt(1, donationId);
                ps.setInt(2, requestId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        otherRequesterIds.add(Integer.valueOf(rs.getInt("user_id")));
                    }
                }
            }

            String rejectOtherPendingSql = "UPDATE requests SET status = 'Rejected' "
                    + "WHERE donation_id = ? AND request_id <> ? AND LOWER(status) = 'pending'";
            try (PreparedStatement ps = conn.prepareStatement(rejectOtherPendingSql)) {
                ps.setInt(1, donationId);
                ps.setInt(2, requestId);
                ps.executeUpdate();
            }

            String reserveDonationSql = "UPDATE donations SET status = 'Reserved' WHERE donation_id = ?";
            try (PreparedStatement ps = conn.prepareStatement(reserveDonationSql)) {
                ps.setInt(1, donationId);
                ps.executeUpdate();
            }

            NotificationUtil.createNotificationSafely(conn, requesterId,
                    "Your request for \"" + donationTitle + "\" was approved. Please wait for donor pickup details.",
                    "myRequest.jsp");

            NotificationUtil.createNotificationSafely(conn, donorId,
                    "A request for your item \"" + donationTitle + "\" was approved. Please schedule pickup.",
                    "pickupSchedule.jsp");

            for (Integer otherRequesterId : otherRequesterIds) {
                NotificationUtil.createNotificationSafely(conn, otherRequesterId.intValue(),
                        "Your request for \"" + donationTitle + "\" was not selected.",
                        "myRequest.jsp");
            }

            conn.commit();
            if (requesterEmail != null && !requesterEmail.trim().isEmpty()) {
                EmailUtility.sendNotificationAsync(
                        requesterEmail.trim(),
                        "ShareHub Update: Request Approved",
                        "Hello,\n\nGood news. Your request for \"" + donationTitle + "\" has been approved."
                        + "\n\nPlease wait for pickup details from the donor. You will receive another notification once pickup is scheduled."
                        + "\n\nThank you for being part of the ShareHub community."
                        + EMAIL_CLOSING);
            }
            if (donorEmail != null && !donorEmail.trim().isEmpty()) {
                EmailUtility.sendNotificationAsync(
                        donorEmail.trim(),
                        "ShareHub Update: Request Approved",
                        "Hello,\n\nA request for your donation item \"" + donationTitle + "\" has been approved."
                        + "\n\nPlease schedule pickup details for the requester at your earliest convenience."
                        + "\n\nThank you for helping fellow students through ShareHub."
                        + EMAIL_CLOSING);
            }
            return true;
        } catch (SQLException e) {
            conn.rollback();
            throw e;
        } finally {
            conn.setAutoCommit(true);
        }
    }

    private boolean isAdmin(HttpSession session) {
        Object roleObj = session.getAttribute("role");
        String role = roleObj == null ? "" : roleObj.toString().trim();
        return role.toLowerCase().contains("admin");
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

    private String resolveReturnPage(String returnPage) {
        if ("adminPendingDonations.jsp".equals(returnPage)
                || "adminPendingRequests.jsp".equals(returnPage)
                || "adminDashboard.jsp".equals(returnPage)) {
            return returnPage;
        }
        return "adminDashboard.jsp";
    }

    private void logAdminActionSafely(HttpSession session, String entity, int entityId, String decision) {
        if (session == null) {
            return;
        }

        String actionType = decision == null ? "" : decision.trim().toLowerCase(Locale.ENGLISH);
        String entityType = entity == null ? "" : entity.trim().toLowerCase(Locale.ENGLISH);
        if (!("approve".equals(actionType) || "reject".equals(actionType))
                || !("donation".equals(entityType) || "request".equals(entityType))) {
            return;
        }

        int adminUserId = resolveUserId(session, -1);
        String adminName = safeText(session.getAttribute("username"), "Admin");
        String adminEmail = safeText(session.getAttribute("email"), null);
        String details = ("donation".equals(entityType) ? "Donation #" : "Request #")
                + entityId + " " + ("approve".equals(actionType) ? "approved" : "rejected");

        String insertSql = "INSERT INTO admin_activity_log "
                + "(admin_user_id, admin_name, admin_email, action_type, entity_type, entity_id, details) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?)";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn == null ? null : conn.prepareStatement(insertSql)) {
            if (conn == null || ps == null) {
                return;
            }
            if (adminUserId > 0) {
                ps.setInt(1, adminUserId);
            } else {
                ps.setNull(1, java.sql.Types.INTEGER);
            }
            ps.setString(2, adminName);
            ps.setString(3, adminEmail);
            ps.setString(4, actionType);
            ps.setString(5, entityType);
            ps.setInt(6, entityId);
            ps.setString(7, details);
            ps.executeUpdate();
        } catch (SQLException ignored) {
            // Logging must never break moderation flow.
        }
    }

    private int resolveUserId(HttpSession session, int fallback) {
        Object userIdObj = session.getAttribute("userId");
        if (userIdObj instanceof Integer) {
            return ((Integer) userIdObj).intValue();
        }
        if (userIdObj != null) {
            try {
                return Integer.parseInt(userIdObj.toString().trim());
            } catch (NumberFormatException ex) {
                return fallback;
            }
        }
        return fallback;
    }

    private String safeText(Object value, String fallback) {
        if (value == null) {
            return fallback;
        }
        String normalized = value.toString().trim();
        return normalized.isEmpty() ? fallback : normalized;
    }
}
