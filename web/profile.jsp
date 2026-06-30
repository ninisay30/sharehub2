<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="dao.DBConnection"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.SQLException"%>
<!DOCTYPE html>
<html>
<head>
    <title>My Profile | ShareHub</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css?v=20260701b">
    <style>
    .impact-hero {
        background: #ffffff;
        border: 1px solid #dfe7df;
        border-left: 5px solid #2e7d32;
        border-radius: 12px;
        padding: 22px 24px;
        margin-bottom: 22px;
        box-shadow: 0 8px 20px rgba(0,0,0,0.05);
    }
    .impact-hero h2 {
        margin: 0 0 8px;
        color: #1f2937;
        font-size: 21px;
    }
    .impact-hero p {
        margin: 0;
        color: #64748b;
        line-height: 1.6;
        font-size: 14px;
    }
    .summary-card .summary-label {
        color: #64748b;
        font-size: 12px;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.4px;
    }
    .summary-card .summary-value {
        color: #111827;
        font-size: 30px;
        font-weight: 800;
        margin-top: 8px;
    }
    .impact-panel,
    .monthly-report-panel {
        background: #fff;
        border: 1px solid #e5e7eb;
        border-radius: 12px;
        padding: 22px 24px;
        margin-top: 20px;
        box-shadow: 0 4px 14px rgba(0,0,0,0.04);
    }
    .impact-panel h2,
    .monthly-report-panel h2 {
        margin: 0 0 12px;
        font-size: 19px;
        color: #111827;
    }
    .impact-list,
    .month-list {
        margin: 10px 0 14px;
        padding-left: 20px;
        color: #374151;
        line-height: 1.7;
    }
    .impact-thanks {
        color: #4b5563;
        line-height: 1.6;
        margin: 0;
    }
    .month-strip {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
        gap: 12px;
        margin-top: 12px;
    }
    .month-mini-card {
        background: #f8fafc;
        border: 1px solid #e5e7eb;
        border-radius: 10px;
        padding: 14px;
    }
    .month-mini-card strong {
        display: block;
        font-size: 22px;
        color: #2e7d32;
        margin-bottom: 4px;
    }
    .month-mini-card span {
        color: #64748b;
        font-size: 13px;
    }
    .report-form {
        display: grid;
        grid-template-columns: minmax(150px, 1fr) minmax(120px, 0.8fr) auto;
        gap: 12px;
        align-items: end;
        margin-top: 16px;
    }
    .report-form label {
        display: block;
        color: #374151;
        font-size: 13px;
        font-weight: 700;
        margin-bottom: 6px;
    }
    .report-form select {
        width: 100%;
        border: 1px solid #d1d5db;
        border-radius: 8px;
        padding: 10px 12px;
        background: #fff;
        font-size: 14px;
    }
    .report-form .primary-btn {
        min-height: 40px;
        padding: 10px 18px;
    }
    @media (max-width: 680px) {
        .report-form {
            grid-template-columns: 1fr;
        }
    }
    </style>
</head>
<body>
<%!
    private String esc(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#39;");
    }
%>
<%
String ctx = request.getContextPath();
Object userIdObj = session.getAttribute("userId");
if (userIdObj == null) {
    response.sendRedirect("login.jsp");
    return;
}

int userId;
try {
    userId = (userIdObj instanceof Integer)
            ? ((Integer) userIdObj).intValue()
            : Integer.parseInt(userIdObj.toString());
} catch (NumberFormatException ex) {
    response.sendRedirect("login.jsp");
    return;
}

String role = (String) session.getAttribute("role");
String normalizedRole = role == null ? "" : role.trim();
if (normalizedRole.toLowerCase().contains("admin")) {
    response.sendRedirect("adminDashboard.jsp");
    return;
}

String navUsername = (String) session.getAttribute("username");
if (navUsername == null || navUsername.trim().isEmpty()) {
    navUsername = "Account";
}
String navInitial = navUsername.substring(0, 1).toUpperCase();

int unreadNotificationCount = 0;
String unreadCountSql = "SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = 0";
try (Connection navConn = DBConnection.getConnection()) {
    if (navConn != null) {
        try (PreparedStatement navPs = navConn.prepareStatement(unreadCountSql)) {
            navPs.setInt(1, userId);
            try (ResultSet navRs = navPs.executeQuery()) {
                if (navRs.next()) {
                    unreadNotificationCount = navRs.getInt(1);
                }
            }
        }
    }
} catch (SQLException ignored) {
    unreadNotificationCount = 0;
}

String fullName = "";
String email = "";
String matricNo = "";
String phoneNo = "";
int totalItemsPosted = 0;
int totalSuccessfulDonations = 0;
int totalItemsReceived = 0;
int totalCompletedPickups = 0;
int monthDonationsPosted = 0;
int monthRequestsMade = 0;
int monthCompletedDonations = 0;
String loadError = null;

try (Connection conn = DBConnection.getConnection()) {
    if (conn == null) {
        loadError = "Database connection failed.";
    } else {
        String profileSql = "SELECT name, email, matric_no, phone_no FROM users WHERE user_id = ? LIMIT 1";
        try (PreparedStatement ps = conn.prepareStatement(profileSql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    fullName = rs.getString("name");
                    email = rs.getString("email");
                    matricNo = rs.getString("matric_no");
                    phoneNo = rs.getString("phone_no");
                }
            }
        }

        String postedSql = "SELECT COUNT(*) FROM donations WHERE donor_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(postedSql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    totalItemsPosted = rs.getInt(1);
                }
            }
        }

        String successSql = "SELECT COUNT(*) FROM requests r "
                + "JOIN donations d ON d.donation_id = r.donation_id "
                + "WHERE d.donor_id = ? AND LOWER(COALESCE(r.status, '')) = 'completed'";
        try (PreparedStatement ps = conn.prepareStatement(successSql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    totalSuccessfulDonations = rs.getInt(1);
                }
            }
        }

        String receivedSql = "SELECT COUNT(*) FROM requests "
                + "WHERE user_id = ? AND LOWER(COALESCE(status, '')) = 'completed'";
        try (PreparedStatement ps = conn.prepareStatement(receivedSql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    totalItemsReceived = rs.getInt(1);
                }
            }
        }

        String monthPostedSql = "SELECT COUNT(*) FROM donations "
                + "WHERE donor_id = ? AND YEAR(created_at)=YEAR(CURDATE()) AND MONTH(created_at)=MONTH(CURDATE())";
        try (PreparedStatement ps = conn.prepareStatement(monthPostedSql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    monthDonationsPosted = rs.getInt(1);
                }
            }
        }

        String monthRequestsSql = "SELECT COUNT(*) FROM requests "
                + "WHERE user_id = ? AND YEAR(created_at)=YEAR(CURDATE()) AND MONTH(created_at)=MONTH(CURDATE())";
        try (PreparedStatement ps = conn.prepareStatement(monthRequestsSql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    monthRequestsMade = rs.getInt(1);
                }
            }
        }

        String monthCompletedSql = "SELECT COUNT(*) FROM requests r "
                + "JOIN donations d ON d.donation_id = r.donation_id "
                + "WHERE d.donor_id = ? AND LOWER(COALESCE(r.status, '')) = 'completed' "
                + "AND YEAR(r.created_at)=YEAR(CURDATE()) AND MONTH(r.created_at)=MONTH(CURDATE())";
        try (PreparedStatement ps = conn.prepareStatement(monthCompletedSql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    monthCompletedDonations = rs.getInt(1);
                }
            }
        }

        String pickupsSql = "SELECT COUNT(*) FROM requests r "
                + "JOIN donations d ON d.donation_id = r.donation_id "
                + "WHERE LOWER(COALESCE(r.status, '')) = 'completed' "
                + "AND (r.user_id = ? OR d.donor_id = ?)";
        try (PreparedStatement ps = conn.prepareStatement(pickupsSql)) {
            ps.setInt(1, userId);
            ps.setInt(2, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    totalCompletedPickups = rs.getInt(1);
                }
            }
        }
    }
} catch (SQLException ex) {
    loadError = "Failed to load account details.";
}

String profileMessage = (String) session.getAttribute("profileMessage");
String profileError = (String) session.getAttribute("profileError");
String passwordMessage = (String) session.getAttribute("passwordMessage");
String passwordError = (String) session.getAttribute("passwordError");
String viewParam = request.getParameter("view");
String activeView = "summary".equalsIgnoreCase(viewParam) ? "summary" : "profile";
boolean showSummaryOnly = "summary".equals(activeView);
session.removeAttribute("profileMessage");
session.removeAttribute("profileError");
session.removeAttribute("passwordMessage");
session.removeAttribute("passwordError");
%>

<nav class="navbar">
    <div class="nav-logo">ShareHub</div>
    <ul class="nav-links">
        <li><a href="<%= ctx %>/home.jsp">Home</a></li>
        <li><a href="<%= ctx %>/postItem.jsp">Donate</a></li>
        <li><a href="<%= ctx %>/activity.jsp">Activity</a></li>
        <li class="profile-menu-item">
            <details class="profile-dropdown">
                <summary class="profile-trigger active" aria-label="Open account menu">
                    <span class="profile-avatar-icon" aria-hidden="true"></span>
                </summary>
                <div class="profile-dropdown-menu">
                    <a href="<%= ctx %>/myRequest.jsp">My Requests</a>
                    <a href="<%= ctx %>/myItems.jsp">My Items</a>
                    <a href="<%= ctx %>/pickupSchedule.jsp">Pickup Schedule</a>
                    <a href="<%= ctx %>/profile.jsp?view=profile" class="<%= "profile".equals(activeView) ? "active" : "" %>">My Profile</a>
                    <a href="<%= ctx %>/profile.jsp?view=summary" class="<%= "summary".equals(activeView) ? "active" : "" %>">Account Summary</a>
                    <a href="<%= ctx %>/LogoutServlet">Logout</a>
                </div>
            </details>
        </li>
    </ul>
</nav>

<div class="page-container account-page">
    <h1><%= showSummaryOnly ? "Account Summary" : "My Profile" %></h1>
    <p class="page-subtitle"><%= showSummaryOnly
            ? "View your account activity and sharing impact at a glance."
            : "Manage your profile details, phone number, and password settings." %></p>

    <% if (loadError != null) { %>
    <p style="color:red;"><%= esc(loadError) %></p>
    <% } %>

    <% if (!showSummaryOnly) { %>
    <section id="my-profile" class="account-section">
        <h2>Profile Details</h2>

        <% if (profileMessage != null) { %>
        <p class="info-banner"><%= esc(profileMessage) %></p>
        <% } %>
        <% if (profileError != null) { %>
        <p class="error-banner"><%= esc(profileError) %></p>
        <% } %>

        <form class="post-form account-form" action="ProfileUpdateServlet" method="post">
            <label>Full Name</label>
            <input type="text" value="<%= esc(fullName) %>" readonly>

            <label>Email Address</label>
            <input type="text" value="<%= esc(email) %>" readonly>

            <label>Matric Number</label>
            <input type="text" value="<%= esc(matricNo) %>" readonly>
            <p class="form-subtitle" style="margin-top:-10px; margin-bottom:16px;">
                Email address and matric number cannot be changed because they are used as core account identity and authentication records.
            </p>

            <label>Phone Number (Optional)</label>
            <input type="text" name="phoneNo" value="<%= esc(phoneNo) %>" placeholder="Phone number (optional)">

            <button type="submit" class="primary-btn">Update Phone Number</button>
        </form>
    </section>
    <% } %>

    <% if (showSummaryOnly) { %>
    <section id="account-summary" class="account-section">
        <div class="impact-hero">
            <h2>Your ShareHub Impact</h2>
            <p>
                This summary focuses on how your sharing activity supports reuse, reduces unnecessary waste,
                and helps other UMT students access useful items.
            </p>
        </div>

        <div class="summary-grid">
            <div class="summary-card">
                <p class="summary-label">Items Posted</p>
                <p class="summary-value"><%= totalItemsPosted %></p>
            </div>
            <div class="summary-card">
                <p class="summary-label">Items Received</p>
                <p class="summary-value"><%= totalItemsReceived %></p>
            </div>
            <div class="summary-card">
                <p class="summary-label">Successful Donations</p>
                <p class="summary-value"><%= totalSuccessfulDonations %></p>
            </div>
            <div class="summary-card">
                <p class="summary-label">Completed Pickups</p>
                <p class="summary-value"><%= totalCompletedPickups %></p>
            </div>
        </div>

        <div class="impact-panel">
            <h2>&#127793; Sustainability Impact</h2>
            <p>You have contributed:</p>
            <ul class="impact-list">
                <li><strong><%= totalItemsPosted %></strong> donated items</li>
                <li><strong><%= totalItemsReceived %></strong> received items</li>
                <li><strong><%= totalSuccessfulDonations %></strong> successful donation</li>
            </ul>
            <p class="impact-thanks">
                Thank you for supporting reuse and reducing waste within the UMT community through ShareHub.
            </p>
        </div>

        <div class="impact-panel">
            <h2>This Month</h2>
            <div class="month-strip">
                <div class="month-mini-card">
                    <strong><%= monthDonationsPosted %></strong>
                    <span>Donations Posted</span>
                </div>
                <div class="month-mini-card">
                    <strong><%= monthRequestsMade %></strong>
                    <span>Requests Made</span>
                </div>
                <div class="month-mini-card">
                    <strong><%= monthCompletedDonations %></strong>
                    <span>Completed Donations</span>
                </div>
            </div>
        </div>

        <div class="monthly-report-panel">
            <h2>Monthly PDF Report</h2>
            <p class="impact-thanks">
                Generate a clean monthly sustainability report with donation, request, reuse, and category statistics.
            </p>
            <form action="<%= ctx %>/MonthlyReportServlet" method="get" class="report-form">
                <div>
                    <label for="reportMonth">Month</label>
                    <select id="reportMonth" name="month" required>
                        <%
                        int currentMonth = java.util.Calendar.getInstance().get(java.util.Calendar.MONTH) + 1;
                        String[] monthNames = new java.text.DateFormatSymbols().getMonths();
                        for (int m = 1; m <= 12; m++) {
                        %>
                        <option value="<%= m %>" <%= m == currentMonth ? "selected" : "" %>><%= monthNames[m - 1] %></option>
                        <% } %>
                    </select>
                </div>
                <div>
                    <label for="reportYear">Year</label>
                    <select id="reportYear" name="year" required>
                        <%
                        int currentYear = java.util.Calendar.getInstance().get(java.util.Calendar.YEAR);
                        for (int y = currentYear - 2; y <= currentYear + 1; y++) {
                        %>
                        <option value="<%= y %>" <%= y == currentYear ? "selected" : "" %>><%= y %></option>
                        <% } %>
                    </select>
                </div>
                <button type="submit" class="primary-btn">Generate Monthly Report</button>
            </form>
        </div>
    </section>
    <% } %>

    <% if (!showSummaryOnly) { %>
    <section id="change-password" class="account-section">
        <h2>Change Password</h2>

        <% if (passwordMessage != null) { %>
        <p class="info-banner"><%= esc(passwordMessage) %></p>
        <% } %>
        <% if (passwordError != null) { %>
        <p class="error-banner"><%= esc(passwordError) %></p>
        <% } %>

        <form class="post-form account-form" action="ChangePasswordServlet" method="post">
            <label>Current Password</label>
            <input type="password" name="currentPassword" required>

            <label>New Password</label>
            <input type="password" name="newPassword" required>

            <label>Confirm New Password</label>
            <input type="password" name="confirmPassword" required>

            <button type="submit" class="primary-btn">Update Password</button>
        </form>
    </section>
    <% } %>
</div>

<script src="<%= request.getContextPath() %>/js/logout-confirm.js"></script>
</body>
</html>



