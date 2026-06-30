/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package controller;

import dao.DBConnection;
import util.NotificationUtil;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import javax.servlet.http.HttpSession;

/**
 *
 * @author Asus
 */
@WebServlet("/RequestItemServlet")
public class RequestItemServlet extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            res.sendRedirect("login.jsp");
            return;
        }

        int userId;
        Object userIdObj = session.getAttribute("userId");
        try {
            userId = (userIdObj instanceof Integer)
                    ? ((Integer) userIdObj).intValue()
                    : Integer.parseInt(userIdObj.toString());
        } catch (NumberFormatException ex) {
            session.setAttribute("requestMessage", "Invalid session. Please login again.");
            res.sendRedirect("login.jsp");
            return;
        }

        String donationIdParam = req.getParameter("donationId");
        if (donationIdParam == null || donationIdParam.trim().isEmpty()) {
            session.setAttribute("requestMessage", "Invalid item request.");
            res.sendRedirect("home.jsp");
            return;
        }

        int donationId;
        try {
            donationId = Integer.parseInt(donationIdParam.trim());
        } catch (NumberFormatException ex) {
            session.setAttribute("requestMessage", "Invalid item request.");
            res.sendRedirect("home.jsp");
            return;
        }

        String findDonationSql = "SELECT status, donor_id, title FROM donations WHERE donation_id = ?";
        String activeRequestSql = "SELECT user_id FROM requests WHERE donation_id = ? "
                + "AND LOWER(status) IN ('pending', 'approved', 'pickup scheduled', 'received pending') LIMIT 1";
        String insertSql = "INSERT INTO requests (donation_id, user_id, status) VALUES (?, ?, 'Pending')";
        String markRequestedSql = "UPDATE donations SET status = 'Requested' "
                + "WHERE donation_id = ? AND LOWER(status) = 'available'";

        try (Connection conn = DBConnection.getConnection()) {
            if (conn == null) {
                session.setAttribute("requestMessage", "Database connection failed.");
                res.sendRedirect("home.jsp");
                return;
            }

            conn.setAutoCommit(false);
            try {
                String donationStatus = null;
                int donorId = -1;
                String donationTitle = "item";
                try (PreparedStatement ps = conn.prepareStatement(findDonationSql)) {
                    ps.setInt(1, donationId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            donationStatus = rs.getString("status");
                            donorId = rs.getInt("donor_id");
                            String titleFromDb = rs.getString("title");
                            if (titleFromDb != null && !titleFromDb.trim().isEmpty()) {
                                donationTitle = titleFromDb.trim();
                            }
                        }
                    }
                }

                if (donationStatus == null) {
                    conn.rollback();
                    session.setAttribute("requestMessage", "Item not found.");
                    res.sendRedirect("home.jsp");
                    return;
                }

                if (!"Available".equalsIgnoreCase(donationStatus)) {
                    conn.rollback();
                    session.setAttribute("requestMessage", "Item is not available for request.");
                    res.sendRedirect("home.jsp");
                    return;
                }

                try (PreparedStatement ps = conn.prepareStatement(activeRequestSql)) {
                    ps.setInt(1, donationId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            conn.rollback();
                            int requesterId = rs.getInt("user_id");
                            session.setAttribute("requestMessage",
                                    requesterId == userId
                                            ? "You already requested this item."
                                            : "Item already has a pending request.");
                            res.sendRedirect(requesterId == userId ? "myRequest.jsp" : "home.jsp");
                            return;
                        }
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(insertSql)) {
                    ps.setInt(1, donationId);
                    ps.setInt(2, userId);
                    ps.executeUpdate();
                }

                try (PreparedStatement ps = conn.prepareStatement(markRequestedSql)) {
                    ps.setInt(1, donationId);
                    ps.executeUpdate();
                }

                String requesterName = session.getAttribute("username") == null
                        ? "A user" : session.getAttribute("username").toString().trim();
                if (requesterName.isEmpty()) {
                    requesterName = "A user";
                }

                NotificationUtil.createNotificationSafely(conn, userId,
                        "You requested \"" + donationTitle + "\". Status: Pending admin review.",
                        "myRequest.jsp");

                if (donorId > 0 && donorId != userId) {
                    NotificationUtil.createNotificationSafely(conn, donorId,
                            requesterName + " requested your item \"" + donationTitle + "\".",
                            "myItems.jsp");
                }

                conn.commit();
                session.setAttribute("requestMessage", "Request submitted successfully (Pending).");
                res.sendRedirect("myRequest.jsp");
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (SQLException e) {
            session.setAttribute("requestMessage", "Failed to submit request due to server error.");
            res.sendRedirect("home.jsp");
        }
    }
}
