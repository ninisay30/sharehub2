package controller;

import dao.DBConnection;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.regex.Pattern;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/ProfileUpdateServlet")
public class ProfileUpdateServlet extends HttpServlet {

    private static final Pattern PHONE_PATTERN = Pattern.compile("^[0-9+()\\-\\s]{7,20}$");

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        Object roleObj = session.getAttribute("role");
        String role = roleObj == null ? "" : roleObj.toString().trim();
        if (role.toLowerCase().contains("admin")) {
            response.sendRedirect("adminDashboard.jsp");
            return;
        }

        int userId;
        Object userIdObj = session.getAttribute("userId");
        try {
            userId = (userIdObj instanceof Integer)
                    ? ((Integer) userIdObj).intValue()
                    : Integer.parseInt(userIdObj.toString());
        } catch (NumberFormatException ex) {
            response.sendRedirect("login.jsp");
            return;
        }

        String phoneNo = request.getParameter("phoneNo") == null ? "" : request.getParameter("phoneNo").trim();
        if (!phoneNo.isEmpty() && !PHONE_PATTERN.matcher(phoneNo).matches()) {
            session.setAttribute("profileError", "Please enter a valid phone number (digits and + - ( ) only).");
            response.sendRedirect("profile.jsp#my-profile");
            return;
        }

        String sql = "UPDATE users SET phone_no = ? WHERE user_id = ?";
        try (Connection conn = DBConnection.getConnection()) {
            if (conn == null) {
                session.setAttribute("profileError", "Database connection failed.");
                response.sendRedirect("profile.jsp#my-profile");
                return;
            }

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                if (phoneNo.isEmpty()) {
                    ps.setNull(1, java.sql.Types.VARCHAR);
                } else {
                    ps.setString(1, phoneNo);
                }
                ps.setInt(2, userId);
                ps.executeUpdate();
            }

            session.setAttribute("profileMessage", "Phone number updated successfully.");
            response.sendRedirect("profile.jsp#my-profile");
        } catch (SQLException ex) {
            session.setAttribute("profileError", "Failed to update profile due to server error.");
            response.sendRedirect("profile.jsp#my-profile");
        }
    }
}
