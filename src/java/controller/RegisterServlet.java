/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package controller;

import dao.DBConnection;
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
import java.util.regex.Pattern;
import javax.servlet.RequestDispatcher;
import javax.servlet.http.HttpSession;
import util.EmailUtility;
import util.PasswordUtil;


/**
 *
 * @author Asus
 */

@WebServlet("/RegisterServlet")
public class RegisterServlet extends HttpServlet {

    private static final Pattern EMAIL_PATTERN = Pattern.compile("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");
    private static final Pattern PASSWORD_HAS_LETTER = Pattern.compile(".*[A-Za-z].*");
    private static final Pattern PASSWORD_HAS_DIGIT = Pattern.compile(".*\\d.*");
    private static final Pattern PHONE_PATTERN = Pattern.compile("^[0-9+()\\-\\s]{7,20}$");

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        String name = req.getParameter("name") == null ? "" : req.getParameter("name").trim();
        String matricNo = req.getParameter("matricNo") == null ? "" : req.getParameter("matricNo").trim();
        String email = req.getParameter("email") == null ? "" : req.getParameter("email").trim();
        String password = req.getParameter("password") == null ? "" : req.getParameter("password").trim();
        String phoneNo = req.getParameter("phoneNo") == null ? "" : req.getParameter("phoneNo").trim();
        setFormValues(req, name, matricNo, email, phoneNo);

        if (name.isEmpty()) {
            req.setAttribute("nameError", "Please enter your full name.");
            forwardRegister(req, res);
            return;
        }

        String normalizedEmail = email.toLowerCase();
        req.setAttribute("emailValue", normalizedEmail);
        if (normalizedEmail.isEmpty()) {
            req.setAttribute("emailError", "Please enter your email address.");
            forwardRegister(req, res);
            return;
        }

        if (!EMAIL_PATTERN.matcher(normalizedEmail).matches()) {
            req.setAttribute("emailError", "Please enter a valid email address (example: name@email.com).");
            forwardRegister(req, res);
            return;
        }

        if (password.isEmpty()) {
            req.setAttribute("passwordError", "Please enter a password.");
            forwardRegister(req, res);
            return;
        }

        if (password.length() < 8) {
            req.setAttribute("passwordError", "Password must be at least 8 characters long.");
            forwardRegister(req, res);
            return;
        }

        if (!PASSWORD_HAS_LETTER.matcher(password).matches() || !PASSWORD_HAS_DIGIT.matcher(password).matches()) {
            req.setAttribute("passwordError", "Password must contain both letters and numbers.");
            forwardRegister(req, res);
            return;
        }

        if (matricNo.isEmpty()) {
            req.setAttribute("matricNoError", "Please enter your matric number.");
            forwardRegister(req, res);
            return;
        }

        String normalizedMatricNo = matricNo.toUpperCase();
        req.setAttribute("matricNoValue", normalizedMatricNo);

        if (!phoneNo.isEmpty() && !PHONE_PATTERN.matcher(phoneNo).matches()) {
            req.setAttribute("phoneNoError", "Please enter a valid phone number (digits and + - ( ) only).");
            forwardRegister(req, res);
            return;
        }

        // Security: hash password before database insert (never store plaintext for new accounts).
        String hashedPassword = PasswordUtil.hashPassword(password);
        String insertSql = "INSERT INTO users (name, matric_no, phone_no, email, password, role) VALUES (?, ?, ?, ?, ?, ?)";
        String duplicateCheckSql = "SELECT user_id, email, matric_no FROM users "
                + "WHERE LOWER(email)=LOWER(?) OR matric_no=? LIMIT 1";

        try (Connection conn = DBConnection.getConnection()) {
            if (conn == null) {
                req.setAttribute("emailError", "Unable to connect to database. Please try again.");
                forwardRegister(req, res);
                return;
            }

            // Validate uniqueness first so users get a clear message for email/matric conflicts.
            try (PreparedStatement checkPs = conn.prepareStatement(duplicateCheckSql)) {
                checkPs.setString(1, normalizedEmail);
                checkPs.setString(2, normalizedMatricNo);
                try (ResultSet checkRs = checkPs.executeQuery()) {
                    if (checkRs.next()) {
                        String existingEmail = checkRs.getString("email");
                        String existingMatricNo = checkRs.getString("matric_no");
                        if (existingEmail != null && existingEmail.equalsIgnoreCase(normalizedEmail)) {
                            req.setAttribute("emailError", "This email is already registered.");
                        } else if (existingMatricNo != null && existingMatricNo.equalsIgnoreCase(normalizedMatricNo)) {
                            req.setAttribute("matricNoError", "This matric number is already registered.");
                        } else {
                            req.setAttribute("emailError", "This account is already registered.");
                        }
                        forwardRegister(req, res);
                        return;
                    }
                }
            }

            try (PreparedStatement ps = conn.prepareStatement(insertSql, PreparedStatement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, name);
                ps.setString(2, normalizedMatricNo);
                if (phoneNo.isEmpty()) {
                    ps.setNull(3, java.sql.Types.VARCHAR);
                } else {
                    ps.setString(3, phoneNo);
                }
                ps.setString(4, normalizedEmail);
                ps.setString(5, hashedPassword);
                ps.setString(6, "User");
                ps.executeUpdate();

                int userId = 0;
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) {
                        userId = rs.getInt(1);
                    }
                }

                HttpSession session = req.getSession();
                session.setAttribute("username", name);
                session.setAttribute("userId", Integer.valueOf(userId));
                session.setAttribute("role", "User");
                session.setAttribute("email", normalizedEmail);
                EmailUtility.sendWelcomeEmailAsync(normalizedEmail, name);
                res.sendRedirect("home.jsp");
                return;
            }
        } catch (SQLException e) {
            String sqlState = e.getSQLState();
            if ("23000".equals(sqlState)) {
                req.setAttribute("emailError", "Email or matric number is already registered.");
            } else {
                req.setAttribute("emailError", "Registration failed due to server error. Please try again.");
            }
            forwardRegister(req, res);
        }
    }

    private void setFormValues(HttpServletRequest req, String name, String matricNo, String email, String phoneNo) {
        req.setAttribute("nameValue", name);
        req.setAttribute("matricNoValue", matricNo);
        req.setAttribute("emailValue", email);
        req.setAttribute("phoneNoValue", phoneNo);
    }

    private void forwardRegister(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        RequestDispatcher rd = req.getRequestDispatcher("register.jsp");
        rd.forward(req, res);
    }
}

