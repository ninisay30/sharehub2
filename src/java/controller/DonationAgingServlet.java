package controller;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import util.DonationAgingService;

@WebServlet("/DonationAgingServlet")
public class DonationAgingServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || !isAdmin(session)) {
            response.sendRedirect("login.jsp");
            return;
        }

        DonationAgingService.AgingResult result = new DonationAgingService().expireInactiveDonations();
        if (result.isSuccess()) {
            session.setAttribute("adminMessage",
                    "Donation aging check completed. Processed " + result.getChecked()
                    + " donation item(s), sent " + result.getRemindersSent()
                    + " reminder email(s), expired " + result.getExpired() + " item(s).");
        } else {
            session.setAttribute("adminMessage", result.getMessage());
        }

        response.sendRedirect("adminDashboard.jsp");
    }

    private boolean isAdmin(HttpSession session) {
        Object roleObj = session.getAttribute("role");
        String role = roleObj == null ? "" : roleObj.toString().trim();
        return role.toLowerCase().contains("admin");
    }
}
