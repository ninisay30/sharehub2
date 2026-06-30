package controller;

import dao.DBConnection;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.regex.Pattern;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import util.PasswordUtil;

@WebServlet("/ChangePasswordServlet")
public class ChangePasswordServlet extends HttpServlet {

    private static final Pattern PASSWORD_HAS_LETTER = Pattern.compile(".*[A-Za-z].*");
    private static final Pattern PASSWORD_HAS_DIGIT = Pattern.compile(".*\\d.*");

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

        String currentPassword = request.getParameter("currentPassword") == null
                ? "" : request.getParameter("currentPassword").trim();
        String newPassword = request.getParameter("newPassword") == null
                ? "" : request.getParameter("newPassword").trim();
        String confirmPassword = request.getParameter("confirmPassword") == null
                ? "" : request.getParameter("confirmPassword").trim();

        if (currentPassword.isEmpty()) {
            session.setAttribute("passwordError", "Please enter your current password.");
            response.sendRedirect("profile.jsp#change-password");
            return;
        }
        if (newPassword.isEmpty()) {
            session.setAttribute("passwordError", "Please enter a new password.");
            response.sendRedirect("profile.jsp#change-password");
            return;
        }
        if (newPassword.length() < 8) {
            session.setAttribute("passwordError", "New password must be at least 8 characters.");
            response.sendRedirect("profile.jsp#change-password");
            return;
        }
        if (!PASSWORD_HAS_LETTER.matcher(newPassword).matches()
                || !PASSWORD_HAS_DIGIT.matcher(newPassword).matches()) {
            session.setAttribute("passwordError", "New password must include letters and numbers.");
            response.sendRedirect("profile.jsp#change-password");
            return;
        }
        if (!newPassword.equals(confirmPassword)) {
            session.setAttribute("passwordError", "New password and confirm password do not match.");
            response.sendRedirect("profile.jsp#change-password");
            return;
        }

        String selectSql = "SELECT password FROM users WHERE user_id = ? LIMIT 1";
        String updateSql = "UPDATE users SET password = ? WHERE user_id = ?";

        try (Connection conn = DBConnection.getConnection()) {
            if (conn == null) {
                session.setAttribute("passwordError", "Database connection failed.");
                response.sendRedirect("profile.jsp#change-password");
                return;
            }

            String storedPassword = null;
            try (PreparedStatement ps = conn.prepareStatement(selectSql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        storedPassword = rs.getString("password");
                    }
                }
            }

            if (storedPassword == null || !PasswordUtil.verifyPassword(currentPassword, storedPassword)) {
                session.setAttribute("passwordError", "Current password is incorrect.");
                response.sendRedirect("profile.jsp#change-password");
                return;
            }

            if (PasswordUtil.verifyPassword(newPassword, storedPassword)) {
                session.setAttribute("passwordError", "New password must be different from current password.");
                response.sendRedirect("profile.jsp#change-password");
                return;
            }

            // Security: always store a BCrypt hash (never plaintext).
            String hashedNewPassword = PasswordUtil.hashPassword(newPassword);
            try (PreparedStatement ps = conn.prepareStatement(updateSql)) {
                ps.setString(1, hashedNewPassword);
                ps.setInt(2, userId);
                ps.executeUpdate();
            }

            session.setAttribute("passwordMessage", "Password changed successfully.");
            response.sendRedirect("profile.jsp#change-password");
        } catch (SQLException ex) {
            session.setAttribute("passwordError", "Failed to change password due to server error.");
            response.sendRedirect("profile.jsp#change-password");
        }
    }
}
