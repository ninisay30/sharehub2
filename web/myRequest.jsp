<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="dao.DBConnection"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.SQLException"%>
<%@page import="java.sql.Timestamp"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.util.ArrayList"%>
<%@page import="java.util.List"%>
<%@page import="java.util.Locale"%>
<!DOCTYPE html>
<html>
<head>
    <title>My Requests | ShareHub</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css?v=20260701b">
    <style>
    /* ===== MY REQUESTS PAGE ===== */
    .myr-page {
        max-width: 860px;
        margin: 40px auto 64px;
        padding: 0 24px;
    }

    .myr-page h1 {
        font-size: 26px;
        font-weight: 700;
        color: #111827;
        margin: 0 0 4px;
    }

    .myr-subtitle {
        color: #6b7280;
        font-size: 14px;
        margin: 0 0 28px;
    }

    /* Stats row */
    .myr-stats {
        display: flex;
        gap: 12px;
        margin-bottom: 28px;
        flex-wrap: wrap;
    }

    .myr-stat {
        flex: 1 1 0;
        min-width: 110px;
        background: #fff;
        border: 1px solid #e5e7eb;
        border-top: 3px solid #e5e7eb;
        border-radius: 12px;
        padding: 14px 18px;
        box-shadow: 0 1px 4px rgba(0,0,0,0.04);
    }

    .myr-stat.st-green  { border-top-color: #2e7d32; }
    .myr-stat.st-amber  { border-top-color: #f59e0b; }
    .myr-stat.st-slate  { border-top-color: #94a3b8; }

    .myr-stat-value {
        font-size: 28px;
        font-weight: 700;
        color: #111827;
        line-height: 1.1;
    }

    .myr-stat-label {
        font-size: 11px;
        color: #9ca3af;
        margin-top: 4px;
        text-transform: uppercase;
        letter-spacing: 0.6px;
        font-weight: 600;
    }

    /* Flash message */
    .myr-flash {
        display: flex;
        align-items: center;
        gap: 10px;
        padding: 12px 16px;
        border-radius: 10px;
        background: #f0fdf4;
        border: 1px solid #86efac;
        color: #166534;
        font-size: 14px;
        font-weight: 500;
        margin-bottom: 22px;
    }

    /* Error banner */
    .myr-error {
        padding: 12px 16px;
        background: #fef2f2;
        border: 1px solid #fecaca;
        color: #991b1b;
        border-radius: 10px;
        font-size: 14px;
        margin-bottom: 14px;
    }

    /* Empty state */
    .myr-empty {
        text-align: center;
        padding: 64px 32px;
        background: #fff;
        border: 1.5px dashed #86efac;
        border-radius: 18px;
        margin-top: 8px;
    }

    .myr-empty-icon {
        font-size: 52px;
        margin-bottom: 16px;
        display: block;
        line-height: 1;
    }

    .myr-empty h2 {
        font-size: 20px;
        color: #111827;
        margin-bottom: 8px;
    }

    .myr-empty p {
        color: #6b7280;
        font-size: 14px;
        max-width: 360px;
        margin: 0 auto 24px;
        line-height: 1.6;
    }

    .myr-empty-cta {
        display: inline-flex;
        align-items: center;
        gap: 7px;
        padding: 11px 26px;
        background: #2e7d32;
        color: #fff;
        border-radius: 999px;
        text-decoration: none;
        font-weight: 700;
        font-size: 14px;
        transition: background 0.2s;
    }

    .myr-empty-cta:hover { background: #256628; }

    /* Request card */
    .myr-card {
        background: #fff;
        border-radius: 14px;
        border: 1px solid #e5e7eb;
        border-left: 4px solid #2e7d32;
        box-shadow: 0 2px 8px rgba(0,0,0,0.05);
        padding: 20px 22px;
        margin-bottom: 14px;
        transition: box-shadow 0.2s ease, transform 0.2s ease;
    }

    .myr-card:hover {
        box-shadow: 0 6px 22px rgba(0,0,0,0.09);
        transform: translateY(-2px);
    }

    .myr-card.sl-pending   { border-left-color: #f59e0b; }
    .myr-card.sl-approved  { border-left-color: #2e7d32; }
    .myr-card.sl-pickup    { border-left-color: #2563eb; }
    .myr-card.sl-received  { border-left-color: #0d9488; }
    .myr-card.sl-completed { border-left-color: #94a3b8; }
    .myr-card.sl-rejected  { border-left-color: #dc2626; }
    .myr-card.sl-requested { border-left-color: #059669; }

    /* Card top row */
    .myr-card-top {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        gap: 12px;
        margin-bottom: 4px;
    }

    .myr-item-name {
        font-size: 16px;
        font-weight: 700;
        color: #111827;
        margin: 0;
        line-height: 1.3;
    }

    .myr-requested-on {
        font-size: 12px;
        color: #9ca3af;
        margin: 5px 0 0;
    }

    /* Status pill */
    .myr-pill {
        display: inline-flex;
        align-items: center;
        gap: 5px;
        padding: 5px 12px;
        border-radius: 999px;
        font-size: 12px;
        font-weight: 700;
        white-space: nowrap;
        flex-shrink: 0;
    }

    .myr-pill.p-pending   { background: #fef3c7; color: #92400e; }
    .myr-pill.p-approved  { background: #dcfce7; color: #15803d; }
    .myr-pill.p-pickup    { background: #dbeafe; color: #1d4ed8; }
    .myr-pill.p-received  { background: #ccfbf1; color: #115e59; }
    .myr-pill.p-completed { background: #f1f5f9; color: #475569; }
    .myr-pill.p-rejected  { background: #fee2e2; color: #991b1b; }
    .myr-pill.p-requested { background: #d1fae5; color: #065f46; }

    .myr-dot {
        width: 6px;
        height: 6px;
        border-radius: 50%;
        display: inline-block;
        flex-shrink: 0;
    }

    .p-pending   .myr-dot { background: #d97706; }
    .p-approved  .myr-dot { background: #16a34a; }
    .p-pickup    .myr-dot { background: #2563eb; }
    .p-received  .myr-dot { background: #0d9488; }
    .p-completed .myr-dot { background: #64748b; }
    .p-rejected  .myr-dot { background: #dc2626; }
    .p-requested .myr-dot { background: #059669; }

    /* Info block */
    .myr-info {
        margin-top: 12px;
        background: #f9fafb;
        border: 1px solid #e5e7eb;
        border-radius: 10px;
        padding: 12px 14px;
        font-size: 13px;
        color: #374151;
    }

    .myr-info.info-pickup   { background: #eff6ff; border-color: #bfdbfe; }
    .myr-info.info-approved { background: #f0fdf4; border-color: #bbf7d0; color: #15803d; }
    .myr-info.info-received { background: #f0fdfa; border-color: #99f6e4; color: #0f766e; }
    .myr-info.info-done     { background: #f8fafc; border-color: #e2e8f0; color: #475569; }
    .myr-info.info-rejected { background: #fef2f2; border-color: #fecaca; color: #991b1b; }

    .myr-info-row {
        display: flex;
        align-items: flex-start;
        gap: 9px;
        line-height: 1.5;
    }

    .myr-info-row + .myr-info-row { margin-top: 8px; }

    .myr-info-row .ico {
        font-style: normal;
        font-size: 14px;
        flex-shrink: 0;
        width: 20px;
        text-align: center;
        margin-top: 1px;
    }

    .myr-info-divider {
        border: none;
        border-top: 1px solid #e5e7eb;
        margin: 10px 0;
    }

    /* Action area */
    .myr-action { margin-top: 14px; }

    .myr-btn-confirm {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        padding: 10px 22px;
        background: #2e7d32;
        color: #fff;
        border: none;
        border-radius: 8px;
        font-size: 13px;
        font-weight: 700;
        cursor: pointer;
        transition: background 0.2s;
    }

    .myr-btn-confirm:hover { background: #256628; }

    @media (max-width: 600px) {
        .myr-page { padding: 0 16px; }
        .myr-card { padding: 16px; }
        .myr-card-top { flex-direction: column-reverse; gap: 8px; }
        .myr-stat { flex: 1 1 calc(50% - 6px); }
        .myr-stat-value { font-size: 22px; }
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

int unreadNotificationCount = 0;
{
    Connection navConn = null; PreparedStatement navPs = null; ResultSet navRs = null;
    try {
        navConn = DBConnection.getConnection();
        if (navConn != null) {
            navPs = navConn.prepareStatement("SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = 0");
            navPs.setInt(1, userId);
            navRs = navPs.executeQuery();
            if (navRs.next()) { unreadNotificationCount = navRs.getInt(1); }
        }
    } catch (SQLException ign) {
    } finally {
        if (navRs != null) { try { navRs.close(); } catch (SQLException ign) {} }
        if (navPs != null) { try { navPs.close(); } catch (SQLException ign) {} }
        if (navConn != null) { try { navConn.close(); } catch (SQLException ign) {} }
    }
}

// Stats
int statTotal = 0, statActive = 0, statCompleted = 0;
{
    Connection sc = null; PreparedStatement sp = null; ResultSet sr = null;
    try {
        sc = DBConnection.getConnection();
        if (sc != null) {
            String statSql = "SELECT COUNT(*) AS total, "
                + "SUM(CASE WHEN LOWER(status) NOT IN ('completed','rejected') THEN 1 ELSE 0 END) AS active_cnt, "
                + "SUM(CASE WHEN LOWER(status) = 'completed' THEN 1 ELSE 0 END) AS completed_cnt "
                + "FROM requests WHERE user_id = ?";
            sp = sc.prepareStatement(statSql);
            sp.setInt(1, userId);
            sr = sp.executeQuery();
            if (sr.next()) {
                statTotal     = sr.getInt("total");
                statActive    = sr.getInt("active_cnt");
                statCompleted = sr.getInt("completed_cnt");
            }
        }
    } catch (SQLException ign) {
    } finally {
        if (sr != null) { try { sr.close(); } catch (SQLException ign) {} }
        if (sp != null) { try { sp.close(); } catch (SQLException ign) {} }
        if (sc != null) { try { sc.close(); } catch (SQLException ign) {} }
    }
}

// Main request list
SimpleDateFormat dateFmt   = new SimpleDateFormat("d MMM yyyy", Locale.ENGLISH);
SimpleDateFormat timeFmt   = new SimpleDateFormat("EEE, d MMM yyyy 'at' h:mm a", Locale.ENGLISH);

// row: [request_id, title, formattedDate, status, sidelineClass, pillClass, pillLabel, location, formattedPickupTime]
List<Object[]> rows = new ArrayList<Object[]>();
String loadError = null;

String sql = "SELECT r.request_id, d.title, r.created_at, r.status, "
           + "ps.location, ps.pickup_time "
           + "FROM requests r "
           + "JOIN donations d ON d.donation_id = r.donation_id "
           + "LEFT JOIN pickup_schedule ps ON ps.request_id = r.request_id "
           + "WHERE r.user_id = ? ORDER BY r.created_at DESC";

{
    Connection conn = null; PreparedStatement ps = null; ResultSet rs = null;
    try {
        conn = DBConnection.getConnection();
        if (conn == null) {
            loadError = "Database connection failed.";
        } else {
            ps = conn.prepareStatement(sql);
            ps.setInt(1, userId);
            rs = ps.executeQuery();
            while (rs.next()) {
                int reqId       = rs.getInt("request_id");
                String title    = rs.getString("title");
                Timestamp ts    = rs.getTimestamp("created_at");
                String fDate    = ts != null ? dateFmt.format(ts) : "";
                String status   = rs.getString("status");
                String location = rs.getString("location");
                Timestamp pt    = rs.getTimestamp("pickup_time");
                String fPickup  = pt != null ? timeFmt.format(pt) : null;
                if (location != null && !location.trim().isEmpty() && pt != null
                        && "Approved".equalsIgnoreCase(status)) {
                    status = "Pickup Scheduled";
                }

                String sl, pc, pl;
                if ("Approved".equalsIgnoreCase(status)) {
                    sl = "sl-approved"; pc = "p-approved"; pl = "Approved";
                } else if ("Pickup Scheduled".equalsIgnoreCase(status)) {
                    sl = "sl-pickup";   pc = "p-pickup";   pl = "Pickup Scheduled";
                } else if ("Received Pending".equalsIgnoreCase(status)) {
                    sl = "sl-received"; pc = "p-received"; pl = "Received Pending";
                } else if ("Completed".equalsIgnoreCase(status)) {
                    sl = "sl-completed"; pc = "p-completed"; pl = "Completed";
                } else if ("Rejected".equalsIgnoreCase(status)) {
                    sl = "sl-rejected"; pc = "p-rejected"; pl = "Rejected";
                } else if ("Requested".equalsIgnoreCase(status)) {
                    sl = "sl-requested"; pc = "p-requested"; pl = "Requested";
                } else {
                    sl = "sl-pending"; pc = "p-pending"; pl = "Pending";
                }

                rows.add(new Object[]{ reqId, title, fDate, status, sl, pc, pl, location, fPickup });
            }
        }
    } catch (SQLException e) {
        loadError = "Failed to load requests.";
    } finally {
        if (rs != null) { try { rs.close(); } catch (SQLException ign) {} }
        if (ps != null) { try { ps.close(); } catch (SQLException ign) {} }
        if (conn != null) { try { conn.close(); } catch (SQLException ign) {} }
    }
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
                    <a href="<%= ctx %>/myRequest.jsp" class="active">My Requests</a>
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

<div class="myr-page">
    <h1>My Requests</h1>
    <p class="myr-subtitle">Track the status of items you have requested from other students.</p>

    <%-- Stats row --%>
    <div class="myr-stats">
        <div class="myr-stat">
            <div class="myr-stat-value"><%= statTotal %></div>
            <div class="myr-stat-label">Total</div>
        </div>
        <div class="myr-stat st-amber">
            <div class="myr-stat-value"><%= statActive %></div>
            <div class="myr-stat-label">In Progress</div>
        </div>
        <div class="myr-stat st-slate">
            <div class="myr-stat-value"><%= statCompleted %></div>
            <div class="myr-stat-label">Completed</div>
        </div>
    </div>

    <%-- Flash message --%>
    <%
    String requestMessage = (String) session.getAttribute("requestMessage");
    if (requestMessage != null) {
    %>
    <div class="myr-flash">
        <span>&#10003;</span>
        <%= requestMessage %>
    </div>
    <%
        session.removeAttribute("requestMessage");
    }
    %>

    <%-- Error state --%>
    <% if (loadError != null) { %>
    <div class="myr-error"><%= loadError %></div>
    <% } %>

    <%-- Empty state --%>
    <% if (loadError == null && rows.isEmpty()) { %>
    <div class="myr-empty">
        <span class="myr-empty-icon">&#128203;</span>
        <h2>No requests yet</h2>
        <p>You haven't requested any items yet. Browse available donations and request something you need.</p>
        <a href="<%= ctx %>/home.jsp" class="myr-empty-cta">Browse Donations</a>
    </div>
    <% } %>

    <%-- Request cards --%>
    <%
    for (Object[] row : rows) {
        int    reqId    = (Integer) row[0];
        String title    = (String)  row[1];
        String fDate    = (String)  row[2];
        String status   = (String)  row[3];
        String sl       = (String)  row[4];
        String pc       = (String)  row[5];
        String pl       = (String)  row[6];
        String location = (String)  row[7];
        String fPickup  = (String)  row[8];

        boolean hasPickup   = fPickup != null && location != null;
        boolean isPickupSch = "Pickup Scheduled".equalsIgnoreCase(status);
        boolean isReceived  = "Received Pending".equalsIgnoreCase(status);
        boolean isCompleted = "Completed".equalsIgnoreCase(status);
        boolean isApproved  = "Approved".equalsIgnoreCase(status);
        boolean isRejected  = "Rejected".equalsIgnoreCase(status);
    %>
    <div class="myr-card <%= sl %>">
        <div class="myr-card-top">
            <div>
                <h3 class="myr-item-name"><%= title %></h3>
                <p class="myr-requested-on">Requested on <%= fDate %></p>
            </div>
            <span class="myr-pill <%= pc %>">
                <span class="myr-dot"></span>
                <%= pl %>
            </span>
        </div>

        <%-- Pickup details block --%>
        <% if (hasPickup) { %>
        <div class="myr-info info-pickup">
            <div class="myr-info-row">
                <i class="ico">&#128205;</i>
                <span><strong>Location:</strong> <%= location %></span>
            </div>
            <div class="myr-info-row">
                <i class="ico">&#128337;</i>
                <span><strong>Pickup time:</strong> <%= fPickup %></span>
            </div>
        </div>
        <% } else if (isApproved) { %>
        <div class="myr-info info-approved">
            <div class="myr-info-row">
                <i class="ico">&#9201;</i>
                <span>Your request was approved. Waiting for the donor to schedule a pickup location and time.</span>
            </div>
        </div>
        <% } else if (isRejected) { %>
        <div class="myr-info info-rejected">
            <div class="myr-info-row">
                <i class="ico">&#10060;</i>
                <span>This request was not approved. Browse other available items on the home page.</span>
            </div>
        </div>
        <% } else if (isCompleted) { %>
        <div class="myr-info info-done">
            <div class="myr-info-row">
                <i class="ico">&#10003;</i>
                <span>Handover completed. Thank you for confirming receipt.</span>
            </div>
        </div>
        <% } %>

        <%-- Status context for received pending when location exists --%>
        <% if (isReceived && hasPickup) { %>
        <div class="myr-info info-received" style="margin-top:10px;">
            <div class="myr-info-row">
                <i class="ico">&#128338;</i>
                <span>You confirmed receipt. Waiting for the donor to confirm handover.</span>
            </div>
        </div>
        <% } else if (isCompleted && hasPickup) { %>
        <%-- already shown above --%>
        <% } %>

        <%-- Mark as Received action --%>
        <% if (isPickupSch) { %>
        <div class="myr-action">
            <form action="ConfirmReceivedServlet" method="post">
                <input type="hidden" name="requestId" value="<%= reqId %>">
                <button type="submit" class="myr-btn-confirm">
                    &#10003; Mark as Received
                </button>
            </form>
        </div>
        <% } %>
    </div>
    <% } %>

</div>

<script src="<%= request.getContextPath() %>/js/logout-confirm.js"></script>
</body>
</html>
