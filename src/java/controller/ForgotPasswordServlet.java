package controller;

import dao.DBConnection;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.regex.Pattern;
import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import util.EmailUtility;
import util.PasswordUtil;
import util.TemporaryPasswordUtil;

@WebServlet("/ForgotPasswordServlet")
public class ForgotPasswordServlet extends HttpServlet {

    private static final Pattern EMAIL_PATTERN = Pattern.compile("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String email = request.getParameter("email") == null ? "" : request.getParameter("email").trim().toLowerCase();
        request.setAttribute("emailValue", email);

        if (email.isEmpty()) {
            request.setAttribute("emailError", "Please enter your registered email address.");
            forwardForgotPassword(request, response);
            return;
        }

        if (!EMAIL_PATTERN.matcher(email).matches()) {
            request.setAttribute("emailError", "Please enter a valid email address (example: name@email.com).");
            forwardForgotPassword(request, response);
            return;
        }

        String findUserSql = "SELECT user_id, name, email FROM users WHERE LOWER(email)=LOWER(?) LIMIT 1";
        String updatePasswordSql = "UPDATE users SET password = ? WHERE user_id = ?";

        try (Connection conn = DBConnection.getConnection()) {
            if (conn == null) {
                request.setAttribute("emailError", "Unable to process your request right now. Please try again later.");
                forwardForgotPassword(request, response);
                return;
            }

            int userId = 0;
            String fullName = "";
            String storedEmail = "";
            try (PreparedStatement ps = conn.prepareStatement(findUserSql)) {
                ps.setString(1, email);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        userId = rs.getInt("user_id");
                        fullName = rs.getString("name");
                        storedEmail = rs.getString("email");
                    }
                }
            }

            if (userId <= 0) {
                request.setAttribute("emailError", "No ShareHub account was found for that email address.");
                forwardForgotPassword(request, response);
                return;
            }

            conn.setAutoCommit(false);
            try {
                String temporaryPassword = TemporaryPasswordUtil.generate();
                String temporaryPasswordHash = PasswordUtil.hashPassword(temporaryPassword);
                try (PreparedStatement updatePs = conn.prepareStatement(updatePasswordSql)) {
                    updatePs.setString(1, temporaryPasswordHash);
                    updatePs.setInt(2, userId);
                    if (updatePs.executeUpdate() != 1) {
                        conn.rollback();
                        request.setAttribute("emailError",
                                "We could not complete the password reset right now. Please try again later.");
                        forwardForgotPassword(request, response);
                        return;
                    }
                }

                String emailBody = buildEmailBody(fullName, temporaryPassword);
                boolean emailSent = EmailUtility.sendNotification(
                        storedEmail,
                        "ShareHub Temporary Password",
                        emailBody);

                if (!emailSent) {
                    conn.rollback();
                    request.setAttribute("emailError",
                            "We could not send the temporary password right now. Please try again later.");
                    forwardForgotPassword(request, response);
                    return;
                }

                conn.commit();
            } catch (SQLException ex) {
                conn.rollback();
                throw ex;
            }

            request.setAttribute("successMessage",
                    "A temporary password has been emailed to you. Please login and change it from My Profile.");
            forwardForgotPassword(request, response);
        } catch (SQLException ex) {
            request.setAttribute("emailError", "Unable to process your request right now. Please try again later.");
            forwardForgotPassword(request, response);
        }
    }

    private String buildEmailBody(String fullName, String temporaryPassword) {
        String greetingName = fullName == null || fullName.trim().isEmpty() ? "there" : fullName.trim();
        String body = "Hi " + greetingName + ",\n\n"
                + "We received a password reset request for your ShareHub account. "
                + "A temporary password has been generated for you.\n\n"
                + "Temporary password: " + temporaryPassword + "\n\n"
                + "Please login using the temporary password above and change your password "
                + "after logging in for better account security.\n\n"
                + "If you did not request this, please contact the ShareHub administrator.";
        return EmailUtility.withFooter(body);
    }

    private void forwardForgotPassword(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        RequestDispatcher rd = request.getRequestDispatcher("forgotPassword.jsp");
        rd.forward(request, response);
    }
}
