<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="dao.DBConnection"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.DatabaseMetaData"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.SQLException"%>
<%@page import="java.sql.Timestamp"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.util.ArrayList"%>
<%@page import="java.util.Calendar"%>
<%@page import="java.util.List"%>
<%@page import="java.util.Locale"%>
<!DOCTYPE html>
<html>
<head>
    <title>Activity | ShareHub</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css?v=20260701b">
    <style>
    /* ===== ACTIVITY PAGE ===== */
    .notif-page {
        max-width: 760px;
        margin: 40px auto 64px;
        padding: 0 24px;
    }

    .notif-page h1 {
        font-size: 26px;
        font-weight: 700;
        color: #111827;
        margin: 0 0 4px;
    }

    .notif-subtitle {
        color: #6b7280;
        font-size: 14px;
        margin: 0 0 24px;
    }

    /* New activity banner */
    .notif-new-banner {
        display: flex;
        align-items: center;
        gap: 10px;
        padding: 11px 16px;
        border-radius: 10px;
        background: #f0fdf4;
        border: 1px solid #86efac;
        color: #166534;
        font-size: 14px;
        font-weight: 500;
        margin-bottom: 22px;
    }

    .notif-new-dot {
        width: 8px;
        height: 8px;
        border-radius: 50%;
        background: #16a34a;
        flex-shrink: 0;
    }

    /* Error */
    .notif-error {
        padding: 12px 16px;
        background: #fef2f2;
        border: 1px solid #fecaca;
        color: #991b1b;
        border-radius: 10px;
        font-size: 14px;
        margin-bottom: 14px;
    }

    /* Empty state */
    .notif-empty {
        text-align: center;
        padding: 64px 32px;
        background: #fff;
        border: 1.5px dashed #86efac;
        border-radius: 18px;
    }

    .notif-empty-icon {
        font-size: 52px;
        margin-bottom: 16px;
        display: block;
        line-height: 1;
    }

    .notif-empty h2 {
        font-size: 20px;
        color: #111827;
        margin-bottom: 8px;
    }

    .notif-empty p {
        color: #6b7280;
        font-size: 14px;
        max-width: 340px;
        margin: 0 auto;
        line-height: 1.6;
    }

    /* Section heading (Today / Yesterday / Earlier) */
    .notif-section-label {
        font-size: 11px;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.7px;
        color: #9ca3af;
        margin: 24px 0 10px;
        padding-left: 2px;
    }

    .notif-section-label:first-child {
        margin-top: 0;
    }

    /* Notification card */
    .notif-card {
        display: flex;
        align-items: flex-start;
        gap: 14px;
        background: #fff;
        border: 1px solid #e5e7eb;
        border-radius: 12px;
        padding: 14px 16px;
        margin-bottom: 8px;
        transition: box-shadow 0.15s ease, transform 0.15s ease;
    }

    .notif-card:hover {
        box-shadow: 0 4px 14px rgba(0,0,0,0.07);
        transform: translateY(-1px);
    }

    /* Icon circle */
    .notif-icon {
        width: 38px;
        height: 38px;
        border-radius: 50%;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        font-size: 15px;
        font-style: normal;
        flex-shrink: 0;
        margin-top: 1px;
    }

    .ni-check   { background: #dcfce7; color: #15803d; }
    .ni-cross   { background: #fee2e2; color: #dc2626; }
    .ni-pickup  { background: #dbeafe; color: #1d4ed8; }
    .ni-request { background: #d1fae5; color: #065f46; }
    .ni-warn    { background: #fef3c7; color: #b45309; }
    .ni-info    { background: #f3f4f6; color: #6b7280; }

    /* Card body */
    .notif-body {
        flex: 1;
        min-width: 0;
    }

    .notif-message {
        font-size: 14px;
        color: #1f2937;
        line-height: 1.5;
        margin: 0 0 4px;
    }

    .notif-time {
        font-size: 12px;
        color: #9ca3af;
        margin: 0;
    }

    /* Open link */
    .notif-open-link {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        padding: 6px 14px;
        background: #fff;
        border: 1px solid #d1d5db;
        border-radius: 8px;
        color: #374151;
        text-decoration: none;
        font-size: 12px;
        font-weight: 600;
        white-space: nowrap;
        flex-shrink: 0;
        align-self: center;
        transition: background 0.15s, border-color 0.15s, color 0.15s;
    }

    .notif-open-link:hover {
        background: #f0fdf4;
        border-color: #2e7d32;
        color: #166534;
    }

    @media (max-width: 560px) {
        .notif-page { padding: 0 16px; }
        .notif-card { gap: 10px; padding: 12px 13px; }
        .notif-icon { width: 32px; height: 32px; font-size: 13px; }
        .notif-open-link { padding: 5px 10px; }
    }
    </style>
</head>
<body>

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

String navUsername = (String) session.getAttribute("username");
if (navUsername == null || navUsername.trim().isEmpty()) {
    navUsername = "Account";
}

// ── Unread count (captured BEFORE mark-read) ────────────────────────────────
int unreadNotificationCount = 0;
{
    Connection navConn = null;
    PreparedStatement navPs = null;
    ResultSet navRs = null;
    ResultSet navMc = null;
    try {
        navConn = DBConnection.getConnection();
        if (navConn != null) {
            boolean navHasIsRead = false;
            try {
                navMc = navConn.getMetaData().getColumns(navConn.getCatalog(), null, "notifications", "is_read");
                navHasIsRead = navMc.next();
            } catch (SQLException ign) {
            } finally {
                if (navMc != null) { try { navMc.close(); } catch (SQLException ign) {} navMc = null; }
            }
            if (navHasIsRead) {
                navPs = navConn.prepareStatement("SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = 0");
                navPs.setInt(1, userId);
                navRs = navPs.executeQuery();
                if (navRs.next()) { unreadNotificationCount = navRs.getInt(1); }
            }
        }
    } catch (SQLException ign) {
    } finally {
        if (navRs   != null) { try { navRs.close();   } catch (SQLException ign) {} }
        if (navPs   != null) { try { navPs.close();   } catch (SQLException ign) {} }
        if (navConn != null) { try { navConn.close(); } catch (SQLException ign) {} }
    }
}

int newCount = unreadNotificationCount;

// ── Data collections ─────────────────────────────────────────────────────────
List<Object[]> todayRows     = new ArrayList<Object[]>();
List<Object[]> yesterdayRows = new ArrayList<Object[]>();
List<Object[]> earlierRows   = new ArrayList<Object[]>();
String loadError = null;

SimpleDateFormat dateFmt = new SimpleDateFormat("d MMM yyyy", Locale.ENGLISH);

Calendar cal = Calendar.getInstance();
cal.set(Calendar.HOUR_OF_DAY, 0);
cal.set(Calendar.MINUTE, 0);
cal.set(Calendar.SECOND, 0);
cal.set(Calendar.MILLISECOND, 0);
long todayStart = cal.getTimeInMillis();
cal.add(Calendar.DAY_OF_MONTH, -1);
long yesterdayStart = cal.getTimeInMillis();

// ── Main DB query ─────────────────────────────────────────────────────────────
{
    Connection conn   = null;
    PreparedStatement markPs = null;
    PreparedStatement selPs  = null;
    ResultSet selRs   = null;
    ResultSet mc1     = null;
    ResultSet mc2     = null;
    try {
        conn = DBConnection.getConnection();
        if (conn == null) {
            loadError = "Database connection failed.";
        } else {
            boolean hasTargetPath = false;
            boolean hasIsRead     = false;
            try {
                DatabaseMetaData meta = conn.getMetaData();
                mc1 = meta.getColumns(conn.getCatalog(), null, "notifications", "target_path");
                hasTargetPath = mc1.next();
                mc2 = meta.getColumns(conn.getCatalog(), null, "notifications", "is_read");
                hasIsRead = mc2.next();
            } catch (SQLException ign) {
            } finally {
                if (mc1 != null) { try { mc1.close(); } catch (SQLException ign) {} mc1 = null; }
                if (mc2 != null) { try { mc2.close(); } catch (SQLException ign) {} mc2 = null; }
            }

            if (hasIsRead) {
                try {
                    markPs = conn.prepareStatement("UPDATE notifications SET is_read = 1 WHERE user_id = ? AND is_read = 0");
                    markPs.setInt(1, userId);
                    markPs.executeUpdate();
                } catch (SQLException ign) {
                } finally {
                    if (markPs != null) { try { markPs.close(); } catch (SQLException ign) {} markPs = null; }
                }
            }

            String selectSql = "SELECT notification_id, message, "
                    + (hasTargetPath ? "target_path" : "'' AS target_path")
                    + ", created_at FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 100";

            selPs = conn.prepareStatement(selectSql);
            selPs.setInt(1, userId);
            selRs = selPs.executeQuery();

            long now = Calendar.getInstance().getTimeInMillis();

            while (selRs.next()) {
                String message    = selRs.getString("message");
                String targetPath = selRs.getString("target_path");
                Timestamp ts      = selRs.getTimestamp("created_at");

                if (message == null) message = "";
                String targetUrl = (targetPath == null || targetPath.trim().isEmpty())
                        ? "" : ctx + "/" + targetPath.trim();

                String relTime;
                long notifMillis = (ts != null) ? ts.getTime() : 0L;
                if (notifMillis > 0) {
                    long diff = now - notifMillis;
                    if (diff < 60000L) {
                        relTime = "Just now";
                    } else if (diff < 3600000L) {
                        relTime = (diff / 60000L) + "m ago";
                    } else if (diff < 86400000L) {
                        relTime = (diff / 3600000L) + "h ago";
                    } else if (diff < 604800000L) {
                        relTime = (diff / 86400000L) + "d ago";
                    } else {
                        relTime = dateFmt.format(ts);
                    }
                } else {
                    relTime = "";
                }

                String msgLower = message.toLowerCase(Locale.ENGLISH);
                String iconClass, iconChar;
                if (msgLower.contains("approved") || msgLower.contains("completed")
                        || msgLower.contains("confirmed") || msgLower.contains("received")) {
                    iconClass = "ni-check";   iconChar = "&#10003;";
                } else if (msgLower.contains("rejected") || msgLower.contains("not approved")
                        || msgLower.contains("could not") || msgLower.contains("not selected")) {
                    iconClass = "ni-cross";   iconChar = "&#10007;";
                } else if (msgLower.contains("pickup") || msgLower.contains("schedule")
                        || msgLower.contains("handover") || msgLower.contains("place and time")) {
                    iconClass = "ni-pickup";  iconChar = "&#128337;";
                } else if (msgLower.contains("request")) {
                    iconClass = "ni-request"; iconChar = "&#128203;";
                } else if (msgLower.contains("reminder") || msgLower.contains("expir")
                        || msgLower.contains("aging") || msgLower.contains("soon")) {
                    iconClass = "ni-warn";    iconChar = "&#9888;";
                } else {
                    iconClass = "ni-info";    iconChar = "&#8226;";
                }

                Object[] row = new Object[]{ message, targetUrl, relTime, iconClass, iconChar };

                if (notifMillis >= todayStart) {
                    todayRows.add(row);
                } else if (notifMillis >= yesterdayStart) {
                    yesterdayRows.add(row);
                } else {
                    earlierRows.add(row);
                }
            }
        }
    } catch (SQLException e) {
        loadError = "Failed to load activity.";
    } finally {
        if (selRs != null) { try { selRs.close();   } catch (SQLException ign) {} }
        if (selPs != null) { try { selPs.close();   } catch (SQLException ign) {} }
        if (conn  != null) { try { conn.close();    } catch (SQLException ign) {} }
    }
}

boolean hasAny = !todayRows.isEmpty() || !yesterdayRows.isEmpty() || !earlierRows.isEmpty();
%>

<nav class="navbar">
    <div class="nav-logo">ShareHub</div>
    <ul class="nav-links">
        <li><a href="<%= ctx %>/home.jsp">Home</a></li>
        <li><a href="<%= ctx %>/postItem.jsp">Donate</a></li>
        <li><a href="<%= ctx %>/activity.jsp" class="active">Activity</a></li>
        <li class="profile-menu-item">
            <details class="profile-dropdown">
                <summary class="profile-trigger" aria-label="Open account menu">
                    <span class="profile-avatar-icon" aria-hidden="true"></span>
                </summary>
                <div class="profile-dropdown-menu">
                    <a href="<%= ctx %>/myRequest.jsp">My Requests</a>
                    <a href="<%= ctx %>/myItems.jsp">My Items</a>
                    <a href="<%= ctx %>/pickupSchedule.jsp">Pickup Schedule</a>
                    <a href="<%= ctx %>/profile.jsp?view=profile">My Profile</a>
                    <a href="<%= ctx %>/profile.jsp?view=summary">Account Summary</a>
                    <a href="<%= ctx %>/LogoutServlet">Logout</a>
                </div>
            </details>
        </li>
    </ul>
</nav>

<div class="notif-page">
    <h1>Activity</h1>
    <p class="notif-subtitle">A recent history of your donation approvals, requests, pickup updates, and completed handovers.</p>

    <%-- New activity banner --%>
    <% if (newCount > 0) { %>
    <div class="notif-new-banner">
        <span class="notif-new-dot"></span>
        <%= newCount %> new activity update<%= newCount == 1 ? "" : "s" %> since your last visit
    </div>
    <% } %>

    <%-- Error --%>
    <% if (loadError != null) { %>
    <div class="notif-error"><%= loadError %></div>
    <% } %>

    <%-- Empty state --%>
    <% if (loadError == null && !hasAny) { %>
    <div class="notif-empty">
        <span class="notif-empty-icon">&#128276;</span>
        <h2>No activity yet</h2>
        <p>Your donation approvals, requests, pickup schedules, completed handovers, and future item aging updates will appear here.</p>
    </div>
    <% } %>

    <%-- Today --%>
    <% if (!todayRows.isEmpty()) { %>
    <p class="notif-section-label">Today</p>
    <%
    for (Object[] row : todayRows) {
        String message   = (String) row[0];
        String targetUrl = (String) row[1];
        String relTime   = (String) row[2];
        String iconClass = (String) row[3];
        String iconChar  = (String) row[4];
    %>
    <div class="notif-card">
        <i class="notif-icon <%= iconClass %>"><%= iconChar %></i>
        <div class="notif-body">
            <p class="notif-message"><%= message %></p>
            <% if (!relTime.isEmpty()) { %><p class="notif-time"><%= relTime %></p><% } %>
        </div>
        <% if (!targetUrl.isEmpty()) { %>
        <a href="<%= targetUrl %>" class="notif-open-link">View &#8599;</a>
        <% } %>
    </div>
    <% } %>
    <% } %>

    <%-- Yesterday --%>
    <% if (!yesterdayRows.isEmpty()) { %>
    <p class="notif-section-label">Yesterday</p>
    <%
    for (Object[] row : yesterdayRows) {
        String message   = (String) row[0];
        String targetUrl = (String) row[1];
        String relTime   = (String) row[2];
        String iconClass = (String) row[3];
        String iconChar  = (String) row[4];
    %>
    <div class="notif-card">
        <i class="notif-icon <%= iconClass %>"><%= iconChar %></i>
        <div class="notif-body">
            <p class="notif-message"><%= message %></p>
            <% if (!relTime.isEmpty()) { %><p class="notif-time"><%= relTime %></p><% } %>
        </div>
        <% if (!targetUrl.isEmpty()) { %>
        <a href="<%= targetUrl %>" class="notif-open-link">View &#8599;</a>
        <% } %>
    </div>
    <% } %>
    <% } %>

    <%-- Earlier --%>
    <% if (!earlierRows.isEmpty()) { %>
    <p class="notif-section-label">Earlier</p>
    <%
    for (Object[] row : earlierRows) {
        String message   = (String) row[0];
        String targetUrl = (String) row[1];
        String relTime   = (String) row[2];
        String iconClass = (String) row[3];
        String iconChar  = (String) row[4];
    %>
    <div class="notif-card">
        <i class="notif-icon <%= iconClass %>"><%= iconChar %></i>
        <div class="notif-body">
            <p class="notif-message"><%= message %></p>
            <% if (!relTime.isEmpty()) { %><p class="notif-time"><%= relTime %></p><% } %>
        </div>
        <% if (!targetUrl.isEmpty()) { %>
        <a href="<%= targetUrl %>" class="notif-open-link">View &#8599;</a>
        <% } %>
    </div>
    <% } %>
    <% } %>

</div>

<script src="<%= request.getContextPath() %>/js/logout-confirm.js"></script>
</body>
</html>
