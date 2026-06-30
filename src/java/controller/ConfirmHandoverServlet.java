package controller;

import dao.DBConnection;
import util.EmailUtility;
import util.NotificationUtil;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/ConfirmHandoverServlet")
public class ConfirmHandoverServlet extends HttpServlet {

    private static final String EMAIL_CLOSING = "\n\nWarm regards,\nAinin Sofia\n(ShareHub Admin)";

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
        if (requestId <= 0) {
            session.setAttribute("pickupMessage", "Invalid request selected.");
            response.sendRedirect("pickupSchedule.jsp");
            return;
        }

        String findSql = "SELECT r.user_id AS requester_id, r.donation_id, d.title, "
                + "requester.email AS requester_email, donor.email AS donor_email "
                + "FROM requests r "
                + "JOIN donations d ON d.donation_id = r.donation_id "
                + "JOIN users requester ON requester.user_id = r.user_id "
                + "JOIN users donor ON donor.user_id = d.donor_id "
                + "WHERE r.request_id = ? AND d.donor_id = ? "
                + "AND LOWER(r.status) = 'received pending' LIMIT 1";

        String updateRequestSql = "UPDATE requests SET status = 'Completed' "
                + "WHERE request_id = ? AND LOWER(status) = 'received pending'";

        String updateDonationSql = "UPDATE donations SET status = 'Completed' WHERE donation_id = ?";

        try (Connection conn = DBConnection.getConnection()) {
            if (conn == null) {
                session.setAttribute("pickupMessage", "Database connection failed.");
                response.sendRedirect("pickupSchedule.jsp");
                return;
            }

            conn.setAutoCommit(false);
            try {
                int requesterId = -1;
                int donationId = -1;
                String donationTitle = "item";
                String requesterEmail = null;
                String donorEmail = null;

                try (PreparedStatement ps = conn.prepareStatement(findSql)) {
                    ps.setInt(1, requestId);
                    ps.setInt(2, donorId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            requesterId = rs.getInt("requester_id");
                            donationId = rs.getInt("donation_id");
                            String dbTitle = rs.getString("title");
                            if (dbTitle != null && !dbTitle.trim().isEmpty()) {
                                donationTitle = dbTitle.trim();
                            }
                            requesterEmail = rs.getString("requester_email");
                            donorEmail = rs.getString("donor_email");
                        }
                    }
                }

                if (requesterId <= 0 || donationId <= 0) {
                    conn.rollback();
                    session.setAttribute("pickupMessage", "This request is not ready for handover confirmation.");
                    response.sendRedirect("pickupSchedule.jsp");
                    return;
                }

                int requestUpdated;
                try (PreparedStatement ps = conn.prepareStatement(updateRequestSql)) {
                    ps.setInt(1, requestId);
                    requestUpdated = ps.executeUpdate();
                }

                if (requestUpdated == 0) {
                    conn.rollback();
                    session.setAttribute("pickupMessage", "Unable to confirm handover.");
                    response.sendRedirect("pickupSchedule.jsp");
                    return;
                }

                try (PreparedStatement ps = conn.prepareStatement(updateDonationSql)) {
                    ps.setInt(1, donationId);
                    ps.executeUpdate();
                }

                NotificationUtil.createNotificationSafely(conn, donorId,
                        "You confirmed handover for \"" + donationTitle + "\". Donation completed.",
                        "myItems.jsp");
                NotificationUtil.createNotificationSafely(conn, requesterId,
                        "Donor confirmed handover for \"" + donationTitle + "\". Request completed.",
                        "myRequest.jsp");

                conn.commit();
                if (donorEmail != null && !donorEmail.trim().isEmpty()) {
                    EmailUtility.sendNotificationAsync(
                            donorEmail.trim(),
                            "ShareHub Update: Donation Completed",
                            "Hello,\n\nYour donation \"" + donationTitle + "\" has been successfully completed."
                            + "\n\nThank you for your kindness and for supporting sustainable sharing among UMT students."
                            + EMAIL_CLOSING);
                }
                if (requesterEmail != null && !requesterEmail.trim().isEmpty()) {
                    EmailUtility.sendNotificationAsync(
                            requesterEmail.trim(),
                            "ShareHub Update: Request Completed",
                            "Hello,\n\nYour request for \"" + donationTitle + "\" has been successfully completed."
                            + "\n\nThank you for using ShareHub and being part of our student sharing community."
                            + EMAIL_CLOSING);
                }
                session.setAttribute("pickupMessage", "Handover confirmed. Request marked as Completed.");
                response.sendRedirect("pickupSchedule.jsp");
            } catch (SQLException ex) {
                conn.rollback();
                session.setAttribute("pickupMessage", "Failed to confirm handover due to server error.");
                response.sendRedirect("pickupSchedule.jsp");
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (SQLException e) {
            session.setAttribute("pickupMessage", "Failed to confirm handover due to server error.");
            response.sendRedirect("pickupSchedule.jsp");
        }
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
}
