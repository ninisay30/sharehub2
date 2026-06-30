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
    <title>Admin Activity | ShareHub</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css?v=20260701b">
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

boolean activityLogEnabled = true;
String loadError = null;
List<String[]> activityRows = new ArrayList<String[]>();

String activitySql = "SELECT l.admin_name, l.action_type, l.entity_type, l.entity_id, l.details, l.created_at, "
        + "COALESCE(d_direct.title, d_request.title, 'Donation item') AS item_title "
        + "FROM admin_activity_log l "
        + "LEFT JOIN donations d_direct ON l.entity_type='donation' AND d_direct.donation_id = l.entity_id "
        + "LEFT JOIN requests r ON l.entity_type='request' AND r.request_id = l.entity_id "
        + "LEFT JOIN donations d_request ON d_request.donation_id = r.donation_id "
        + "ORDER BY l.created_at DESC LIMIT 100";

try (Connection conn = DBConnection.getConnection()) {
    if (conn != null) {
        try (PreparedStatement ps = conn.prepareStatement(activitySql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                activityRows.add(new String[] {
                    rs.getString("admin_name"),
                    rs.getString("action_type"),
                    rs.getString("entity_type"),
                    String.valueOf(rs.getInt("entity_id")),
                    rs.getString("details"),
                    rs.getString("created_at"),
                    String.valueOf(rs.getTimestamp("created_at").getTime()),
                    rs.getString("item_title")
                });
            }
        }
    }
} catch (SQLException e) {
    activityLogEnabled = false;
    loadError = "Activity log unavailable. Run database/sharehub2_admin_activity_module.sql to enable this view.";
}
%>

<nav class="navbar">
    <div class="nav-logo">ShareHub Admin</div>
    <ul class="nav-links">
        <li><a href="<%= ctx %>/adminDashboard.jsp">Admin</a></li>
        <li><a href="<%= ctx %>/adminPendingDonations.jsp">Pending Donations</a></li>
        <li><a href="<%= ctx %>/adminPendingRequests.jsp">Pending Requests</a></li>
        <li><a href="<%= ctx %>/adminActivity.jsp" class="active">Activity</a></li>
        <li><a href="<%= ctx %>/LogoutServlet">Logout</a></li>
    </ul>
</nav>

<div class="page-container admin-dashboard-page">
    <section class="admin-hero admin-activity-hero">
        <div>
            <p class="admin-kicker">Admin audit trail</p>
            <h1>Full Activity</h1>
            <p class="page-subtitle">A complete view of recent admin approvals, rejections, and moderation decisions.</p>
        </div>
        <div class="admin-hero-actions">
            <a href="<%= ctx %>/adminDashboard.jsp" class="admin-hero-btn">Back to dashboard</a>
        </div>
    </section>

    <section class="admin-section-card admin-activity-full-card">
        <div class="admin-section-header">
            <div>
                <p class="admin-section-eyebrow">Latest records</p>
                <h2>Admin activity</h2>
                <p class="section-subtitle">Showing up to 100 latest actions.</p>
            </div>
            <% if (activityLogEnabled) { %>
            <span class="admin-count-pill"><%= activityRows.size() %> records</span>
            <% } %>
        </div>

        <% if (!activityLogEnabled) { %>
        <div class="admin-empty-state">
            <strong>Activity log unavailable</strong>
            <span><%= loadError %></span>
        </div>
        <% } else if (activityRows.isEmpty()) { %>
        <div class="admin-empty-state">
            <strong>No admin activity yet</strong>
            <span>Approvals and rejections will appear here after moderation starts.</span>
        </div>
        <% } else { %>
        <div class="admin-activity-list admin-activity-list-full">
            <%
            for (String[] row : activityRows) {
                String adminName = (row[0] == null || row[0].trim().isEmpty()) ? "Admin" : row[0].trim();
                String actionType = row[1] == null ? "" : row[1].trim().toLowerCase();
                String entityType = row[2] == null ? "" : row[2].trim().toLowerCase();
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
                String targetLabel = ("donation".equals(entityType) ? "Donation #" : "Request #") + row[3];
                String targetHref = "donation".equals(entityType) ? ctx + "/adminPendingDonations.jsp" : ctx + "/adminPendingRequests.jsp";
                String detailText = (row[4] == null || row[4].trim().isEmpty()) ? "No extra details recorded." : row[4];
                String absoluteTime = (row[5] == null || row[5].trim().isEmpty()) ? "" : row[5];
                String itemTitle = (row[7] == null || row[7].trim().isEmpty()) ? "Donation item" : row[7].trim();
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
                        <span>by <%= adminName %></span>
                        <span><%= relativeTime %></span>
                        <% if (!absoluteTime.isEmpty()) { %><span><%= absoluteTime %></span><% } %>
                    </div>
                    <p><%= detailText %></p>
                </div>
            </div>
            <%
            }
            %>
        </div>
        <% } %>
    </section>
</div>

<script src="<%= request.getContextPath() %>/js/logout-confirm.js"></script>
</body>
</html>
