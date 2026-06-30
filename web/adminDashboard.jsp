<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="dao.DBConnection"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.SQLException"%>
<%@page import="java.util.ArrayList"%>
<%@page import="java.util.List"%>
<!DOCTYPE html>
<html>
<head>
    <title>Admin Dashboard | ShareHub</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css?v=20260701c">
</head>
<body>
<%
String ctx = request.getContextPath();
String role = (String) session.getAttribute("role");
String normalizedRole = role == null ? "" : role.trim();
if (!normalizedRole.toLowerCase().contains("admin")) {
    response.sendRedirect("home.jsp");
    return;
}

String adminMessage = (String) session.getAttribute("adminMessage");
if (adminMessage != null) {
    session.removeAttribute("adminMessage");
}

int pendingDonations = 0;
int pendingRequests = 0;
int pickupScheduled = 0;
int approvedToday = 0;
int rejectedToday = 0;
int monthlyCompletedDonations = 0;
int monthlyFulfilledRequests = 0;
int totalItemsReused = 0;
boolean activityLogEnabled = true;

List<String[]> recentActivity = new ArrayList<String[]>();
List<String[]> stalePickupAlerts = new ArrayList<String[]>();

String countDonationSql = "SELECT COUNT(*) FROM donations WHERE LOWER(status)='pending'";
String countRequestSql = "SELECT COUNT(*) FROM requests WHERE LOWER(status)='pending'";
String countPickupScheduledSql = "SELECT COUNT(*) FROM requests WHERE LOWER(status)='pickup scheduled'";
String countMonthlyCompletedDonationsSql = "SELECT COUNT(*) FROM donations "
        + "WHERE LOWER(status)='completed' AND YEAR(created_at)=YEAR(CURDATE()) AND MONTH(created_at)=MONTH(CURDATE())";
String countMonthlyFulfilledRequestsSql = "SELECT COUNT(*) FROM requests "
        + "WHERE LOWER(status)='completed' AND YEAR(created_at)=YEAR(CURDATE()) AND MONTH(created_at)=MONTH(CURDATE())";
String countTotalReusedSql = "SELECT COUNT(*) FROM donations WHERE LOWER(status)='completed'";
String countApprovedTodaySql = "SELECT COUNT(*) FROM admin_activity_log "
        + "WHERE action_type='approve' AND DATE(created_at)=CURDATE()";
String countRejectedTodaySql = "SELECT COUNT(*) FROM admin_activity_log "
        + "WHERE action_type='reject' AND DATE(created_at)=CURDATE()";

String recentActivitySql = "SELECT l.admin_name, l.action_type, l.entity_type, l.entity_id, l.details, l.created_at, "
        + "COALESCE(d_direct.title, d_request.title, 'Donation item') AS item_title "
        + "FROM admin_activity_log l "
        + "LEFT JOIN donations d_direct ON l.entity_type='donation' AND d_direct.donation_id = l.entity_id "
        + "LEFT JOIN requests r ON l.entity_type='request' AND r.request_id = l.entity_id "
        + "LEFT JOIN donations d_request ON d_request.donation_id = r.donation_id "
        + "ORDER BY l.created_at DESC LIMIT 8";

String staleApprovedNoPickupSql = "SELECT r.request_id, d.title, "
        + "COALESCE(reqUser.name, 'Unknown requester') AS requester_name, "
        + "COALESCE(donorUser.name, 'Unknown donor') AS donor_name, l.created_at AS approved_at "
        + "FROM requests r "
        + "JOIN donations d ON d.donation_id = r.donation_id "
        + "LEFT JOIN users reqUser ON reqUser.user_id = r.user_id "
        + "LEFT JOIN users donorUser ON donorUser.user_id = d.donor_id "
        + "LEFT JOIN pickup_schedule ps ON ps.request_id = r.request_id "
        + "JOIN admin_activity_log l ON l.entity_type='request' AND l.entity_id = r.request_id AND l.action_type='approve' "
        + "WHERE LOWER(r.status)='approved' AND ps.request_id IS NULL "
        + "AND l.created_at = (SELECT MAX(l2.created_at) FROM admin_activity_log l2 "
        + "WHERE l2.entity_type='request' AND l2.entity_id = r.request_id AND l2.action_type='approve') "
        + "AND l.created_at <= (NOW() - INTERVAL 24 HOUR) "
        + "ORDER BY l.created_at ASC LIMIT 10";

try (Connection conn = DBConnection.getConnection()) {
    if (conn != null) {
        try (PreparedStatement ps = conn.prepareStatement(countDonationSql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                pendingDonations = rs.getInt(1);
            }
        }
        try (PreparedStatement ps = conn.prepareStatement(countRequestSql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                pendingRequests = rs.getInt(1);
            }
        }
        try (PreparedStatement ps = conn.prepareStatement(countPickupScheduledSql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                pickupScheduled = rs.getInt(1);
            }
        }
        try (PreparedStatement ps = conn.prepareStatement(countMonthlyCompletedDonationsSql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                monthlyCompletedDonations = rs.getInt(1);
            }
        }
        try (PreparedStatement ps = conn.prepareStatement(countMonthlyFulfilledRequestsSql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                monthlyFulfilledRequests = rs.getInt(1);
            }
        }
        try (PreparedStatement ps = conn.prepareStatement(countTotalReusedSql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                totalItemsReused = rs.getInt(1);
            }
        }

        try {
            try (PreparedStatement ps = conn.prepareStatement(countApprovedTodaySql);
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    approvedToday = rs.getInt(1);
                }
            }

            try (PreparedStatement ps = conn.prepareStatement(countRejectedTodaySql);
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    rejectedToday = rs.getInt(1);
                }
            }

            try (PreparedStatement ps = conn.prepareStatement(recentActivitySql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    recentActivity.add(new String[] {
                        rs.getString("created_at"),
                        rs.getString("admin_name"),
                        rs.getString("action_type"),
                        rs.getString("entity_type"),
                        String.valueOf(rs.getInt("entity_id")),
                        rs.getString("details"),
                        String.valueOf(rs.getTimestamp("created_at").getTime()),
                        rs.getString("item_title")
                    });
                }
            }

            try (PreparedStatement ps = conn.prepareStatement(staleApprovedNoPickupSql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    stalePickupAlerts.add(new String[] {
                        String.valueOf(rs.getInt("request_id")),
                        rs.getString("title"),
                        rs.getString("requester_name"),
                        rs.getString("donor_name"),
                        rs.getString("approved_at"),
                        String.valueOf(rs.getTimestamp("approved_at").getTime())
                    });
                }
            }
        } catch (SQLException e) {
            activityLogEnabled = false;
        }
    }
} catch (SQLException e) {
    adminMessage = "Failed to load admin dashboard data.";
}
%>

<nav class="navbar">
    <div class="nav-logo">ShareHub Admin</div>
    <ul class="nav-links">
        <li><a href="<%= ctx %>/adminDashboard.jsp" class="active">Admin</a></li>
        <li><a href="<%= ctx %>/adminPendingDonations.jsp">Pending Donations</a></li>
        <li><a href="<%= ctx %>/adminPendingRequests.jsp">Pending Requests</a></li>
        <li><a href="<%= ctx %>/adminActivity.jsp">Activity</a></li>
        <li><a href="<%= ctx %>/LogoutServlet">Logout</a></li>
    </ul>
</nav>

<div class="page-container admin-dashboard-page">
    <section class="admin-hero">
        <div>
            <p class="admin-kicker">ShareHub moderation</p>
            <h1>Admin Dashboard</h1>
            <p class="page-subtitle">Review pending work, monitor pickup risks, and track reuse impact from one place.</p>
        </div>
        <div class="admin-hero-actions">
            <a href="<%= ctx %>/adminPendingDonations.jsp" class="admin-hero-btn primary">Review donations</a>
            <a href="<%= ctx %>/adminPendingRequests.jsp" class="admin-hero-btn">Review requests</a>
        </div>
    </section>

    <% if (adminMessage != null) { %>
    <p class="info-banner"><%= adminMessage %></p>
    <% } %>

    <div class="admin-metric-grid">
        <a href="<%= ctx %>/adminPendingDonations.jsp" class="admin-metric-card urgent">
            <span class="admin-metric-label">Pending donations</span>
            <strong><%= pendingDonations %></strong>
            <span class="admin-metric-note">Items waiting for approval</span>
        </a>

        <a href="<%= ctx %>/adminPendingRequests.jsp" class="admin-metric-card urgent">
            <span class="admin-metric-label">Pending requests</span>
            <strong><%= pendingRequests %></strong>
            <span class="admin-metric-note">Student requests to review</span>
        </a>

        <div class="admin-metric-card success">
            <span class="admin-metric-label">Approved today</span>
            <strong><%= approvedToday %></strong>
            <span class="admin-metric-note">Positive decisions logged</span>
        </div>

        <div class="admin-metric-card danger">
            <span class="admin-metric-label">Rejected today</span>
            <strong><%= rejectedToday %></strong>
            <span class="admin-metric-note">Declined submissions</span>
        </div>

        <div class="admin-metric-card info">
            <span class="admin-metric-label">Pickup scheduled</span>
            <strong><%= pickupScheduled %></strong>
            <span class="admin-metric-note">Active handovers</span>
        </div>

        <div class="admin-metric-card neutral">
            <span class="admin-metric-label">Donated this month</span>
            <strong><%= monthlyCompletedDonations %></strong>
            <span class="admin-metric-note">Completed donations</span>
        </div>

        <div class="admin-metric-card neutral">
            <span class="admin-metric-label">Fulfilled requests</span>
            <strong><%= monthlyFulfilledRequests %></strong>
            <span class="admin-metric-note">Completed this month</span>
        </div>
    </div>

    <div class="admin-dashboard-layout">
        <section class="admin-section-card admin-activity-panel">
            <div class="admin-section-header">
                <div>
                    <p class="admin-section-eyebrow">Audit trail</p>
                    <h2>Recent activity</h2>
                    <p class="section-subtitle">Latest moderation decisions across donations and requests.</p>
                </div>
                <% if (activityLogEnabled && !recentActivity.isEmpty()) { %>
                <span class="admin-count-pill"><%= recentActivity.size() %> latest</span>
                <% } %>
            </div>
            <%
            if (!activityLogEnabled) {
            %>
            <div class="admin-empty-state">
                <strong>Activity log unavailable</strong>
                <span>Run database/sharehub2_admin_activity_module.sql to enable this view.</span>
            </div>
            <%
            } else if (recentActivity.isEmpty()) {
            %>
            <div class="admin-empty-state">
                <strong>No recent activity</strong>
                <span>Approvals and rejections will appear here after moderation starts.</span>
            </div>
            <%
            } else {
            %>
            <div class="admin-activity-list">
                <%
                for (String[] row : recentActivity) {
                    String actionType = row[2] == null ? "" : row[2].trim().toLowerCase();
                    String entityType = row[3] == null ? "" : row[3].trim().toLowerCase();
                    String actionLabel;
                    String actionClass;
                    if ("approve".equals(actionType)) {
                        actionLabel = "Approved";
                        actionClass = "approved";
                    } else if ("reject".equals(actionType)) {
                        actionLabel = "Rejected";
                        actionClass = "rejected";
                    } else {
                        actionLabel = actionType.length() == 0 ? "Updated" : actionType.substring(0, 1).toUpperCase() + actionType.substring(1);
                        actionClass = "reserved";
                    }
                    String targetLabel = ("donation".equals(entityType) ? "Donation #" : "Request #") + row[4];
                    String targetHref = "donation".equals(entityType) ? ctx + "/adminPendingDonations.jsp" : ctx + "/adminPendingRequests.jsp";
                    String itemTitle = (row[7] == null || row[7].trim().isEmpty()) ? "Donation item" : row[7].trim();
                    String detailText = (row[5] == null || row[5].trim().isEmpty()) ? "No extra details recorded." : row[5];
                    long activityAgeMs = new java.util.Date().getTime() - Long.parseLong(row[6]);
                    long activityAgeMinutes = Math.max(1, activityAgeMs / (60L * 1000L));
                    String relativeTime;
                    if (activityAgeMinutes < 60L) {
                        relativeTime = activityAgeMinutes + " min ago";
                    } else if (activityAgeMinutes < 1440L) {
                        long hours = Math.max(1, activityAgeMinutes / 60L);
                        relativeTime = hours + "h ago";
                    } else {
                        long days = Math.max(1, activityAgeMinutes / 1440L);
                        relativeTime = days + "d ago";
                    }
                %>
                <div class="admin-activity-item">
                    <span class="admin-action-dot <%= actionClass %>"></span>
                    <div class="admin-activity-body">
                        <div class="admin-activity-line">
                            <strong class="admin-activity-action <%= actionClass %>"><%= actionLabel %></strong>
                            <a class="admin-activity-title" href="<%= targetHref %>"><%= itemTitle %></a>
                            <span class="admin-activity-target"><%= targetLabel %></span>
                        </div>
                        <div class="admin-activity-meta">
                            <span>by <%= row[1] %></span>
                            <span><%= relativeTime %></span>
                        </div>
                        <p><%= detailText %></p>
                    </div>
                </div>
                <%
                }
                %>
            </div>
            <a class="admin-view-more" href="<%= ctx %>/adminActivity.jsp">View full activity</a>
            <%
            }
            %>
        </section>

        <aside class="admin-side-column">
            <section class="admin-section-card admin-alert-panel">
                <div class="admin-section-header">
                    <div>
                        <p class="admin-section-eyebrow">Pickup follow-up</p>
                        <h2>Pickup alerts</h2>
                        <p class="section-subtitle">Approved requests without a pickup schedule for more than 24 hours.</p>
                    </div>
                    <% if (activityLogEnabled) { %>
                    <span class="admin-count-pill alert"><%= stalePickupAlerts.size() %></span>
                    <% } %>
                </div>
                <%
                if (!activityLogEnabled) {
                %>
                <div class="admin-empty-state">
                    <strong>Pickup timing unavailable</strong>
                    <span>Enable activity log data before checking overdue scheduling.</span>
                </div>
                <%
                } else if (stalePickupAlerts.isEmpty()) {
                %>
                <div class="admin-empty-state success">
                    <strong>No overdue pickups</strong>
                    <span>All approved requests are currently within the scheduling window.</span>
                </div>
                <%
                } else {
                %>
                <div class="admin-alert-list">
                    <%
                    int alertIndex = 0;
                    for (String[] alert : stalePickupAlerts) {
                        long overdueMs = new java.util.Date().getTime() - Long.parseLong(alert[5]);
                        long overdueHours = Math.max(25, overdueMs / (60L * 60L * 1000L));
                        String alertTone = (alertIndex % 2 == 0) ? "critical" : "warning";
                        alertIndex++;
                    %>
                    <div class="admin-alert-item <%= alertTone %>">
                        <div>
                            <div class="admin-alert-title">
                                <strong><%= alert[1] %></strong>
                                <span>Request #<%= alert[0] %></span>
                            </div>
                            <div class="admin-alert-meta">
                                Requester: <%= alert[2] %><br>
                                Donor: <%= alert[3] %>
                            </div>
                        </div>
                        <span class="admin-overdue-pill"><%= overdueHours %>h overdue</span>
                    </div>
                    <%
                    }
                    %>
                </div>
                <%
                }
                %>
            </section>

            <section class="admin-section-card admin-impact-card">
                <p class="admin-section-eyebrow">Reuse impact</p>
                <h2><%= totalItemsReused %> items reused</h2>
                <p class="section-subtitle">Every completed donation keeps useful items circulating in the student community.</p>
            </section>

            <section class="admin-section-card admin-aging-card">
                <p class="admin-section-eyebrow">Donation aging</p>
                <h2>Run aging check</h2>
                <p class="section-subtitle">Send 60-day inactivity reminders and expire listings whose 4-day grace period has ended.</p>
                <form action="<%= ctx %>/DonationAgingServlet" method="post">
                    <button type="submit" class="primary-btn admin-aging-btn">Run Aging Check</button>
                </form>
            </section>

            <section class="admin-section-card admin-report-card">
                <p class="admin-section-eyebrow">Reporting</p>
                <h2>Monthly report</h2>
                <p class="section-subtitle">Generate a PDF for donation, request, reuse, and category statistics.</p>
                <form action="<%= ctx %>/MonthlyReportServlet" method="get" class="admin-report-form">
                    <label for="adminReportMonth">
                        Month
                        <select id="adminReportMonth" name="month" required>
                            <%
                            int currentMonth = java.util.Calendar.getInstance().get(java.util.Calendar.MONTH) + 1;
                            String[] monthNames = new java.text.DateFormatSymbols().getMonths();
                            for (int m = 1; m <= 12; m++) {
                            %>
                            <option value="<%= m %>" <%= m == currentMonth ? "selected" : "" %>><%= monthNames[m - 1] %></option>
                            <% } %>
                        </select>
                    </label>
                    <label for="adminReportYear">
                        Year
                        <select id="adminReportYear" name="year" required>
                            <%
                            int currentYear = java.util.Calendar.getInstance().get(java.util.Calendar.YEAR);
                            for (int y = currentYear - 2; y <= currentYear + 1; y++) {
                            %>
                            <option value="<%= y %>" <%= y == currentYear ? "selected" : "" %>><%= y %></option>
                            <% } %>
                        </select>
                    </label>
                    <button type="submit" class="primary-btn">Generate report</button>
                </form>
            </section>
        </aside>
    </div>
</div>

<script src="<%= request.getContextPath() %>/js/logout-confirm.js"></script>
</body>
</html>

