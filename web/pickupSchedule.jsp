<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="dao.DBConnection"%>
<%@page import="java.io.File"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.SQLException"%>
<%@page import="java.sql.Timestamp"%>
<!DOCTYPE html>
<html>
<head>
    <title>Pickup Module | ShareHub</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css?v=20260701b">
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

    private String safeText(String value, String fallback) {
        return value == null || value.trim().isEmpty() ? fallback : value.trim();
    }

    private String selected(String current, String option) {
        return option.equals(current) ? "selected" : "";
    }

    private String pickupStatusLabel(String status) {
        if ("Approved".equalsIgnoreCase(status)) {
            return "Awaiting Schedule";
        }
        if ("Pickup Scheduled".equalsIgnoreCase(status)) {
            return "Scheduled";
        }
        if ("Received Pending".equalsIgnoreCase(status)) {
            return "Pending Handover Confirmation";
        }
        if ("Completed".equalsIgnoreCase(status)) {
            return "Completed";
        }
        return safeText(status, "Pending");
    }

    private String pickupStatusClass(String status) {
        if ("Approved".equalsIgnoreCase(status)) {
            return "awaiting";
        }
        if ("Pickup Scheduled".equalsIgnoreCase(status)) {
            return "scheduled";
        }
        if ("Received Pending".equalsIgnoreCase(status)) {
            return "handover";
        }
        if ("Completed".equalsIgnoreCase(status)) {
            return "completed";
        }
        return "pending";
    }

    private String pickupDateValue(Timestamp pickupTime) {
        if (pickupTime == null) {
            return "";
        }
        String value = pickupTime.toLocalDateTime().toLocalDate().toString();
        return value.length() > 10 ? value.substring(0, 10) : value;
    }

    private String pickupTimeValue(Timestamp pickupTime) {
        if (pickupTime == null) {
            return "";
        }
        String value = pickupTime.toLocalDateTime().toLocalTime().withSecond(0).withNano(0).toString();
        return value.length() > 5 ? value.substring(0, 5) : value;
    }

    private String displayPickupDate(Timestamp pickupTime) {
        if (pickupTime == null) {
            return "Not set";
        }
        return pickupDateValue(pickupTime);
    }

    private String displayPickupTime(Timestamp pickupTime) {
        if (pickupTime == null) {
            return "Not set";
        }
        return pickupTimeValue(pickupTime);
    }

    // REPLACE WITH:
private String imageUrl(String image, String ctx, javax.servlet.ServletContext application) {
    String imagePath;
    if (image == null || image.trim().isEmpty()) {
        imagePath = "image/books.jpg";
    } else {
        imagePath = image.trim().replace('\\', '/');
        if (imagePath.matches("^[A-Za-z]:/.*")) {
            imagePath = imagePath.substring(imagePath.lastIndexOf('/') + 1);
        }
        if (!(imagePath.startsWith("http://") || imagePath.startsWith("https://")
                || imagePath.startsWith("image/") || imagePath.startsWith("uploads/"))) {
            imagePath = "uploads/" + imagePath;
        }
        if (imagePath.startsWith("/")) {
            imagePath = imagePath.substring(1);
        }
    }
    boolean external = imagePath.startsWith("http://") || imagePath.startsWith("https://");
    return external ? imagePath : ctx + "/" + imagePath;
}
%>
<%
String ctx = request.getContextPath();
String role = (String) session.getAttribute("role");
String normalizedRole = role == null ? "" : role.trim();
if (normalizedRole.toLowerCase().contains("admin")) {
    session.setAttribute("adminMessage", "Pickup scheduling is for donors/users, not admin moderation.");
    response.sendRedirect("adminDashboard.jsp");
    return;
}

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
                    <a href="<%= ctx %>/pickupSchedule.jsp" class="active">Pickup Schedule</a>
                    <a href="<%= ctx %>/profile.jsp?view=profile">My Profile</a>
                    <a href="<%= ctx %>/profile.jsp?view=summary">Account Summary</a>
                    <a href="<%= ctx %>/LogoutServlet">Logout</a>
                </div>
            </details>
        </li>
    </ul>
</nav>

<div class="page-container pickup-page">
    <h1>Pickup Scheduling</h1>
    <p class="page-subtitle">
        Manage pickup details for your donations and view pickups scheduled for your requests.
    </p>

    <div class="location-chip-row" aria-label="Allowed pickup locations">
        <span class="location-chip">📍 Kompleks Kuliah</span>
        <span class="location-chip">📍 PSNZ</span>
        <span class="location-chip">📍 Kompleks Siswa</span>
        <span class="location-chip">📍 Kolej Kediaman</span>
    </div>

    <%
    String pickupMessage = (String) session.getAttribute("pickupMessage");
    if (pickupMessage != null) {
    %>
    <p class="info-banner"><%= esc(pickupMessage) %></p>
    <%
        session.removeAttribute("pickupMessage");
    }
    %>

    <%
    String pendingSql = "SELECT r.request_id, r.user_id, r.status, d.title, d.image, "
            + "COALESCE(NULLIF(TRIM(d.category), ''), 'Others / Miscellaneous') AS category, "
            + "u.name AS requester_name, ps.location, ps.pickup_time "
            + "FROM requests r "
            + "JOIN donations d ON d.donation_id = r.donation_id "
            + "LEFT JOIN users u ON u.user_id = r.user_id "
            + "LEFT JOIN pickup_schedule ps ON ps.request_id = r.request_id "
            + "WHERE d.donor_id = ? AND LOWER(r.status) IN ('approved', 'pickup scheduled', 'received pending') "
            + "ORDER BY CASE "
            + "WHEN LOWER(r.status) = 'received pending' THEN 1 "
            + "WHEN LOWER(r.status) = 'approved' THEN 2 "
            + "ELSE 3 END, r.created_at DESC";

    String completedSql = "SELECT r.request_id, r.user_id, r.status, d.title, d.image, "
            + "COALESCE(NULLIF(TRIM(d.category), ''), 'Others / Miscellaneous') AS category, "
            + "u.name AS requester_name, ps.location, ps.pickup_time "
            + "FROM requests r "
            + "JOIN donations d ON d.donation_id = r.donation_id "
            + "LEFT JOIN users u ON u.user_id = r.user_id "
            + "LEFT JOIN pickup_schedule ps ON ps.request_id = r.request_id "
            + "WHERE d.donor_id = ? AND LOWER(r.status) = 'completed' "
            + "ORDER BY r.created_at DESC";

    String requesterPickupSql = "SELECT r.request_id, r.status, d.title, d.image, "
            + "COALESCE(NULLIF(TRIM(d.category), ''), 'Others / Miscellaneous') AS category, "
            + "donor.name AS donor_name, ps.location, ps.pickup_time "
            + "FROM requests r "
            + "JOIN donations d ON d.donation_id = r.donation_id "
            + "LEFT JOIN users donor ON donor.user_id = d.donor_id "
            + "JOIN pickup_schedule ps ON ps.request_id = r.request_id "
            + "WHERE r.user_id = ? AND LOWER(r.status) IN ('approved', 'pickup scheduled', 'received pending', 'completed') "
            + "ORDER BY CASE "
            + "WHEN LOWER(r.status) = 'pickup scheduled' THEN 1 "
            + "WHEN LOWER(r.status) = 'received pending' THEN 2 "
            + "ELSE 3 END, ps.pickup_time DESC";

    boolean hasPendingRows = false;
    boolean hasCompletedRows = false;
    boolean hasRequesterRows = false;
    boolean loadFailed = false;

    try (Connection conn = DBConnection.getConnection()) {
        if (conn == null) {
            loadFailed = true;
    %>
    <p class="error-banner">Database connection failed.</p>
    <%
        } else {
            boolean hasAnyPickupRows = false;
            String countPickupSql = "SELECT COUNT(*) FROM requests r "
                    + "JOIN donations d ON d.donation_id = r.donation_id "
                    + "WHERE d.donor_id = ? "
                    + "AND LOWER(r.status) IN ('approved', 'pickup scheduled', 'received pending', 'completed') "
                    + "UNION ALL "
                    + "SELECT COUNT(*) FROM requests r "
                    + "JOIN pickup_schedule ps ON ps.request_id = r.request_id "
                    + "WHERE r.user_id = ? "
                    + "AND LOWER(r.status) IN ('approved', 'pickup scheduled', 'received pending', 'completed')";
            try (PreparedStatement countPs = conn.prepareStatement(countPickupSql)) {
                countPs.setInt(1, userId);
                countPs.setInt(2, userId);
                try (ResultSet countRs = countPs.executeQuery()) {
                    while (countRs.next()) {
                        if (countRs.getInt(1) > 0) {
                            hasAnyPickupRows = true;
                        }
                    }
                }
            }

            if (hasAnyPickupRows) {
    %>
    <section class="pickup-section">
        <h2>My Scheduled Pickups</h2>
        <%
            try (PreparedStatement ps = conn.prepareStatement(requesterPickupSql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        hasRequesterRows = true;
                        int requestId = rs.getInt("request_id");
                        String title = safeText(rs.getString("title"), "Donation item");
                        String donorName = safeText(rs.getString("donor_name"), "Donor");
                        String status = safeText(rs.getString("status"), "Pickup Scheduled");
                        if ("Approved".equalsIgnoreCase(status)) {
                            status = "Pickup Scheduled";
                        }
                        String location = safeText(rs.getString("location"), "Not set");
                        Timestamp pickupTime = rs.getTimestamp("pickup_time");
                        String category = safeText(rs.getString("category"), "Others / Miscellaneous");
                        String thumbnailUrl = imageUrl(rs.getString("image"), ctx, application);
        %>
        <article class="pickup-card">
            <div class="pickup-card-header">
                <div class="pickup-item-block">
                    <img src="<%= thumbnailUrl %>" alt="<%= esc(title) %>" class="pickup-thumb">
                    <div>
                        <h3><%= esc(title) %></h3>
                        <p><strong>Category:</strong> <%= esc(category) %></p>
                    </div>
                </div>
                <span class="status <%= pickupStatusClass(status) %>"><%= pickupStatusLabel(status) %></span>
            </div>

            <div class="pickup-detail-grid">
                <p><strong>Donor:</strong> <%= esc(donorName) %></p>
                <p><strong>Pickup location:</strong> <%= esc(location) %></p>
                <p><strong>Date:</strong> <%= displayPickupDate(pickupTime) %></p>
                <p><strong>Time:</strong> <%= displayPickupTime(pickupTime) %></p>
            </div>

            <% if ("Pickup Scheduled".equalsIgnoreCase(status)) { %>
            <div class="pickup-confirm-panel">
                <p>Attend the pickup at the scheduled location and time. After receiving the item, mark it as received.</p>
                <form action="ConfirmReceivedServlet" method="post">
                    <input type="hidden" name="requestId" value="<%= requestId %>">
                    <button type="submit" class="primary-btn pickup-confirm-btn">Mark as Received</button>
                </form>
            </div>
            <% } else if ("Received Pending".equalsIgnoreCase(status)) { %>
            <div class="pickup-confirm-panel">
                <p>You marked this item as received. Waiting for the donor to confirm handover.</p>
            </div>
            <% } %>
        </article>
        <%
                    }
                }
            }

            if (!hasRequesterRows) {
        %>
        <p class="page-subtitle">No scheduled pickups for your requests yet.</p>
        <%
            }
        %>
    </section>

    <section class="pickup-section">
        <h2>Pickups to Manage</h2>
        <%
            try (PreparedStatement ps = conn.prepareStatement(pendingSql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        hasPendingRows = true;
                        int requestId = rs.getInt("request_id");
                        String title = safeText(rs.getString("title"), "Donation item");
                        String requesterName = safeText(rs.getString("requester_name"), "User #" + rs.getInt("user_id"));
                        String status = safeText(rs.getString("status"), "Pending");
                        String location = rs.getString("location");
                        Timestamp pickupTime = rs.getTimestamp("pickup_time");
                        String category = safeText(rs.getString("category"), "Others / Miscellaneous");
                        String thumbnailUrl = imageUrl(rs.getString("image"), ctx, application);
                        String preferredLocation = location == null || location.trim().isEmpty() ? "To be arranged" : location.trim();
        %>
        <article class="pickup-card">
            <div class="pickup-card-header">
                <div class="pickup-item-block">
                    <img src="<%= thumbnailUrl %>" alt="<%= esc(title) %>" class="pickup-thumb">
                    <div>
                        <h3><%= esc(title) %></h3>
                        <p><strong>Category:</strong> <%= esc(category) %></p>
                    </div>
                </div>
                <span class="status <%= pickupStatusClass(status) %>"><%= pickupStatusLabel(status) %></span>
            </div>

            <div class="pickup-detail-grid">
                <p><strong>Requester:</strong> <%= esc(requesterName) %></p>
                <p><strong>Preferred pickup:</strong> <%= esc(preferredLocation) %></p>
                <p><strong>Date:</strong> <%= displayPickupDate(pickupTime) %></p>
                <p><strong>Time:</strong> <%= displayPickupTime(pickupTime) %></p>
            </div>

            <% if ("Approved".equalsIgnoreCase(status) || "Pickup Scheduled".equalsIgnoreCase(status)) { %>
            <form action="PickupScheduleServlet" method="post" class="pickup-schedule-form">
                <input type="hidden" name="requestId" value="<%= requestId %>">

                <label>
                    Location
                    <select name="location" required>
                        <option value="">Select location</option>
                        <option value="Kompleks Kuliah" <%= selected(location, "Kompleks Kuliah") %>>Kompleks Kuliah</option>
                        <option value="PSNZ" <%= selected(location, "PSNZ") %>>PSNZ</option>
                        <option value="Kompleks Siswa" <%= selected(location, "Kompleks Siswa") %>>Kompleks Siswa</option>
                        <option value="Kolej Kediaman" <%= selected(location, "Kolej Kediaman") %>>Kolej Kediaman</option>
                    </select>
                </label>

                <label>
                    Date
                    <input type="date" name="pickupDate" value="<%= pickupDateValue(pickupTime) %>" required>
                </label>

                <label>
                    Time
                    <input type="time" name="pickupTime" value="<%= pickupTimeValue(pickupTime) %>" required>
                </label>

                <button type="submit" class="primary-btn pickup-update-btn">Update Schedule</button>
            </form>
            <% } else if ("Received Pending".equalsIgnoreCase(status)) { %>
            <div class="pickup-confirm-panel">
                <p>Requester has marked this item as received. Please confirm the handover to complete the donation.</p>
                <form action="ConfirmHandoverServlet" method="post">
                    <input type="hidden" name="requestId" value="<%= requestId %>">
                    <button type="submit" class="primary-btn pickup-confirm-btn">Confirm Handover</button>
                </form>
            </div>
            <% } %>
        </article>
        <%
                    }
                }
            }

            if (!hasPendingRows) {
        %>
        <p class="page-subtitle">No donor pickups need action right now.</p>
        <%
            }
        %>
    </section>

    <section class="pickup-section">
        <h2>Completed Handovers</h2>
        <%
            try (PreparedStatement ps = conn.prepareStatement(completedSql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        hasCompletedRows = true;
                        String title = safeText(rs.getString("title"), "Donation item");
                        String requesterName = safeText(rs.getString("requester_name"), "User #" + rs.getInt("user_id"));
                        String status = safeText(rs.getString("status"), "Completed");
                        String location = safeText(rs.getString("location"), "Not set");
                        Timestamp pickupTime = rs.getTimestamp("pickup_time");
                        String category = safeText(rs.getString("category"), "Others / Miscellaneous");
                        String thumbnailUrl = imageUrl(rs.getString("image"), ctx, application);
        %>
        <article class="pickup-card pickup-card-completed">
            <div class="pickup-card-header">
                <div class="pickup-item-block">
                    <img src="<%= thumbnailUrl %>" alt="<%= esc(title) %>" class="pickup-thumb">
                    <div>
                        <h3><%= esc(title) %></h3>
                        <p><strong>Category:</strong> <%= esc(category) %></p>
                    </div>
                </div>
                <span class="status <%= pickupStatusClass(status) %>"><%= pickupStatusLabel(status) %></span>
            </div>
            <div class="pickup-detail-grid">
                <p><strong>Requester:</strong> <%= esc(requesterName) %></p>
                <p><strong>Pickup location:</strong> <%= esc(location) %></p>
                <p><strong>Date:</strong> <%= displayPickupDate(pickupTime) %></p>
                <p><strong>Time:</strong> <%= displayPickupTime(pickupTime) %></p>
            </div>
        </article>
        <%
                    }
                }
            }

            if (!hasCompletedRows) {
        %>
        <p class="page-subtitle">Completed handovers will appear here after donor confirmation.</p>
        <%
            }
        %>
    </section>
    <%
            }
        }
    } catch (SQLException e) {
        loadFailed = true;
    %>
    <p class="error-banner">Failed to load pickup requests.</p>
    <%
    }

    if (!loadFailed && !hasPendingRows && !hasCompletedRows && !hasRequesterRows) {
    %>
    <section class="pickup-empty-card" aria-label="No pickup schedules yet">
        <div class="pickup-empty-icon" aria-hidden="true">📦</div>
        <h2>No pickups scheduled yet</h2>
        <p>
            Pickup schedules for your requests and donations will appear here after they are arranged.
        </p>

        <div class="pickup-mini-flow" aria-label="Pickup flow">
            <div class="pickup-flow-step">
                <span class="pickup-flow-icon">🎁</span>
                <span>Donate an item</span>
            </div>
            <div class="pickup-flow-step">
                <span class="pickup-flow-icon">🙋</span>
                <span>Someone requests it</span>
            </div>
            <div class="pickup-flow-step">
                <span class="pickup-flow-icon">🗓️</span>
                <span>Schedule pickup here</span>
            </div>
            <div class="pickup-flow-step">
                <span class="pickup-flow-icon">✅</span>
                <span>Confirm handover</span>
            </div>
        </div>

        <a href="<%= ctx %>/home.jsp" class="pickup-empty-cta">Browse Items to Donate</a>
    </section>
    <%
    }
    %>
</div>

<script src="<%= request.getContextPath() %>/js/logout-confirm.js"></script>
</body>
</html>
