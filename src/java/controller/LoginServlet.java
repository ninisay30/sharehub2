/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package controller;

import dao.DBConnection;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.regex.Pattern;
import javax.servlet.RequestDispatcher;
import javax.servlet.http.HttpSession;
import javax.servlet.annotation.WebServlet;
import util.PasswordUtil;
/**
 *
 * @author Asus
 */
@WebServlet("/LoginServlet")
public class LoginServlet extends HttpServlet {

    private static final Pattern EMAIL_PATTERN = Pattern.compile("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String email = request.getParameter("email") == null ? "" : request.getParameter("email").trim();
        String password = request.getParameter("password") == null ? "" : request.getParameter("password").trim();
        String normalizedEmail = email.toLowerCase();
        setFormValues(request, normalizedEmail);

        boolean hasError = false;
        if (normalizedEmail.isEmpty()) {
            request.setAttribute("emailError", "Please enter your email address.");
            hasError = true;
        } else if (!EMAIL_PATTERN.matcher(normalizedEmail).matches()) {
            request.setAttribute("emailError", "Please enter a valid email address (example: name@email.com).");
            hasError = true;
        }

        if (password.isEmpty()) {
            request.setAttribute("passwordError", "Please enter your password.");
            hasError = true;
        }

        if (hasError) {
            forwardLogin(request, response);
            return;
        }

        String sql = "SELECT user_id, name, role, email, password FROM users WHERE LOWER(email)=LOWER(?) LIMIT 1";
        String updatePasswordSql = "UPDATE users SET password=? WHERE user_id=?";

        try (Connection conn = DBConnection.getConnection()) {
            if (conn == null) {
                request.setAttribute("passwordError", "Unable to connect to database. Please try again.");
                forwardLogin(request, response);
                return;
            }

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, normalizedEmail);

                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        String storedPassword = rs.getString("password");
                        // Security: verify using BCrypt hash when present.
                        // Migration: legacy plaintext accounts still login, then get upgraded to BCrypt.
                        boolean authenticated = PasswordUtil.verifyPassword(password, storedPassword);
                        if (!authenticated) {
                            request.setAttribute("passwordError", "Invalid email or password.");
                            forwardLogin(request, response);
                            return;
                        }

                        if (!PasswordUtil.isBcryptHash(storedPassword)) {
                            String upgradedHash = PasswordUtil.hashPassword(password);
                            try (PreparedStatement updatePs = conn.prepareStatement(updatePasswordSql)) {
                                updatePs.setString(1, upgradedHash);
                                updatePs.setInt(2, rs.getInt("user_id"));
                                updatePs.executeUpdate();
                            }
                        }

                        String role = rs.getString("role");
                        String normalizedRole = role == null ? "" : role.trim();
                        String storedEmail = rs.getString("email");
                        // Security: invalidate any existing session before creating a new authenticated session.
                        HttpSession oldSession = request.getSession(false);
                        if (oldSession != null) {
                            oldSession.invalidate();
                        }

                        // Security: create a fresh session for this successful login.
                        HttpSession session = request.getSession(true);
                        session.setAttribute("username", rs.getString("name"));
                        session.setAttribute("userId", Integer.valueOf(rs.getInt("user_id")));
                        session.setAttribute("role", normalizedRole);
                        session.setAttribute("email", storedEmail == null ? normalizedEmail : storedEmail);
                        if (normalizedRole.toLowerCase().contains("admin")) {
                            response.sendRedirect("adminDashboard.jsp");
                        } else {
                            response.sendRedirect("home.jsp");
                        }
                        return;
                    }
                }
            }

            request.setAttribute("passwordError", "Invalid email or password.");
            forwardLogin(request, response);
        } catch (SQLException e) {
            request.setAttribute("passwordError", "Login failed due to server error. Please try again.");
            forwardLogin(request, response);
        }
    }

    private void setFormValues(HttpServletRequest request, String email) {
        request.setAttribute("emailValue", email);
    }

    private void forwardLogin(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        RequestDispatcher rd = request.getRequestDispatcher("login.jsp");
        rd.forward(request, response);
    }
}

