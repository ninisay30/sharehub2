package controller;

import dao.DBConnection;
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

@WebServlet("/ConfirmReceivedServlet")
public class ConfirmReceivedServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        int requesterId = resolveUserId(session, -1);
        if (requesterId <= 0) {
            session.setAttribute("requestMessage", "Invalid session. Please login again.");
            response.sendRedirect("login.jsp");
            return;
        }

        int requestId = parseInt(request.getParameter("requestId"), -1);
        if (requestId <= 0) {
            session.setAttribute("requestMessage", "Invalid request selected.");
            response.sendRedirect("myRequest.jsp");
            return;
        }

        String findSql = "SELECT r.request_id, r.donation_id, d.donor_id, d.title "
                + "FROM requests r "
                + "JOIN donations d ON d.donation_id = r.donation_id "
                + "WHERE r.request_id = ? AND r.user_id = ? "
                + "AND LOWER(r.status) = 'pickup scheduled' LIMIT 1";

        String completeRequestSql = "UPDATE requests SET status = 'Received Pending' "
                + "WHERE request_id = ? AND user_id = ? AND LOWER(status) = 'pickup scheduled'";

        try (Connection conn = DBConnection.getConnection()) {
            if (conn == null) {
                session.setAttribute("requestMessage", "Database connection failed.");
                response.sendRedirect("myRequest.jsp");
                return;
            }

            conn.setAutoCommit(false);
            try {
                int donorId = -1;
                String donationTitle = "item";

                try (PreparedStatement ps = conn.prepareStatement(findSql)) {
                    ps.setInt(1, requestId);
                    ps.setInt(2, requesterId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            donorId = rs.getInt("donor_id");
                            String dbTitle = rs.getString("title");
                            if (dbTitle != null && !dbTitle.trim().isEmpty()) {
                                donationTitle = dbTitle.trim();
                            }
                        }
                    }
                }

                if (donorId <= 0) {
                    conn.rollback();
                    session.setAttribute("requestMessage", "This request is not ready for receive confirmation.");
                    response.sendRedirect("myRequest.jsp");
                    return;
                }

                int requestUpdated;
                try (PreparedStatement ps = conn.prepareStatement(completeRequestSql)) {
                    ps.setInt(1, requestId);
                    ps.setInt(2, requesterId);
                    requestUpdated = ps.executeUpdate();
                }

                if (requestUpdated == 0) {
                    conn.rollback();
                    session.setAttribute("requestMessage", "Unable to mark item as received.");
                    response.sendRedirect("myRequest.jsp");
                    return;
                }

                NotificationUtil.createNotificationSafely(conn, requesterId,
                        "You marked \"" + donationTitle + "\" as received. Waiting donor confirmation.",
                        "myRequest.jsp");
                NotificationUtil.createNotificationSafely(conn, donorId,
                        "Requester marked \"" + donationTitle + "\" as received. Please confirm handover.",
                        "pickupSchedule.jsp");

                conn.commit();
                session.setAttribute("requestMessage", "Marked as received. Waiting donor confirmation.");
                response.sendRedirect("myRequest.jsp");
            } catch (SQLException ex) {
                conn.rollback();
                session.setAttribute("requestMessage", "Failed to confirm received status due to server error.");
                response.sendRedirect("myRequest.jsp");
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (SQLException e) {
            session.setAttribute("requestMessage", "Failed to confirm received status due to server error.");
            response.sendRedirect("myRequest.jsp");
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
