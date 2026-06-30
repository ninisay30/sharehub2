<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="dao.DBConnection"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.SQLException"%>
<%@page import="java.sql.DatabaseMetaData"%>
<%@page import="java.sql.Timestamp"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.util.ArrayList"%>
<%@page import="java.util.List"%>
<%@page import="java.util.Locale"%>
<%@page import="java.io.File"%>
<!DOCTYPE html>
<html>
<head>
    <title>My Items | ShareHub</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css?v=20260701c">
    <style>
    /* ===== MY ITEMS PAGE ===== */
    .myi-page {
        max-width: 980px;
        margin: 40px auto 64px;
        padding: 0 24px;
    }

    .myi-page h1 {
        font-size: 26px;
        font-weight: 700;
        color: #111827;
        margin: 0 0 4px;
    }

    .myi-subtitle {
        color: #6b7280;
        font-size: 14px;
        margin: 0 0 28px;
    }

    /* Stats */
    .myi-stats {
        display: flex;
        gap: 12px;
        margin-bottom: 28px;
        flex-wrap: wrap;
    }

    .myi-stat {
        flex: 1 1 0;
        min-width: 110px;
        background: #fff;
        border: 1px solid #e5e7eb;
        border-top: 3px solid #e5e7eb;
        border-radius: 12px;
        padding: 14px 18px;
        box-shadow: 0 1px 4px rgba(0,0,0,0.04);
    }

    .myi-stat.st-green  { border-top-color: #2e7d32; }
    .myi-stat.st-amber  { border-top-color: #f59e0b; }
    .myi-stat.st-blue   { border-top-color: #2563eb; }
    .myi-stat.st-slate  { border-top-color: #94a3b8; }

    .myi-stat-value {
        font-size: 28px;
        font-weight: 700;
        color: #111827;
        line-height: 1.1;
    }

    .myi-stat-label {
        font-size: 11px;
        color: #9ca3af;
        margin-top: 4px;
        text-transform: uppercase;
        letter-spacing: 0.6px;
        font-weight: 600;
    }

    /* Flash / info banner */
    .myi-flash {
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

    /* Error */
    .myi-error {
        padding: 12px 16px;
        background: #fef2f2;
        border: 1px solid #fecaca;
        color: #991b1b;
        border-radius: 10px;
        font-size: 14px;
        margin-bottom: 14px;
    }

    /* Empty state */
    .myi-empty {
        text-align: center;
        padding: 64px 32px;
        background: #fff;
        border: 1.5px dashed #86efac;
        border-radius: 18px;
        margin-top: 8px;
    }

    .myi-empty-icon {
        font-size: 52px;
        margin-bottom: 16px;
        display: block;
        line-height: 1;
    }

    .myi-empty h2 {
        font-size: 20px;
        color: #111827;
        margin-bottom: 8px;
    }

    .myi-empty p {
        color: #6b7280;
        font-size: 14px;
        max-width: 360px;
        margin: 0 auto 24px;
        line-height: 1.6;
    }

    .myi-empty-cta {
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

    .myi-empty-cta:hover { background: #256628; }

    /* Grid */
    .myi-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
        gap: 20px;
    }

    /* Card */
    .myi-card {
        background: #fff;
        border-radius: 14px;
        border: 1px solid #e5e7eb;
        box-shadow: 0 2px 8px rgba(0,0,0,0.05);
        overflow: hidden;
        display: flex;
        flex-direction: column;
        transition: box-shadow 0.2s ease, transform 0.2s ease;
    }

    .myi-card:hover {
        box-shadow: 0 8px 24px rgba(0,0,0,0.1);
        transform: translateY(-3px);
    }

    /* Image area */
    .myi-img-wrap {
        position: relative;
        width: 100%;
        height: 180px;
        overflow: hidden;
        background: #f3f4f6;
        flex-shrink: 0;
    }

    .myi-img-btn {
        border: none;
        background: transparent;
        padding: 0;
        width: 100%;
        height: 100%;
        cursor: zoom-in;
        display: block;
    }

    .myi-img {
        width: 100%;
        height: 100%;
        object-fit: cover;
        display: block;
        transition: transform 0.3s ease;
    }

    .myi-card:hover .myi-img {
        transform: scale(1.04);
    }

    /* Status pill overlaid on image */
    .myi-status-overlay {
        position: absolute;
        top: 10px;
        right: 10px;
        display: inline-flex;
        align-items: center;
        gap: 5px;
        padding: 5px 11px;
        border-radius: 999px;
        font-size: 11px;
        font-weight: 700;
        white-space: nowrap;
        backdrop-filter: blur(4px);
    }

    .myi-status-overlay.sp-pending   { background: rgba(254,243,199,0.93); color: #92400e; }
    .myi-status-overlay.sp-available { background: rgba(220,252,231,0.93); color: #15803d; }
    .myi-status-overlay.sp-requested { background: rgba(209,250,229,0.93); color: #065f46; }
    .myi-status-overlay.sp-reserved  { background: rgba(219,234,254,0.93); color: #1d4ed8; }
    .myi-status-overlay.sp-completed { background: rgba(241,245,249,0.93); color: #475569; }
    .myi-status-overlay.sp-rejected  { background: rgba(254,226,226,0.93); color: #991b1b; }
    .myi-status-overlay.sp-expired   { background: rgba(243,244,246,0.93); color: #4b5563; }

    .myi-dot {
        width: 6px;
        height: 6px;
        border-radius: 50%;
        display: inline-block;
        flex-shrink: 0;
    }

    .sp-pending   .myi-dot { background: #d97706; }
    .sp-available .myi-dot { background: #16a34a; }
    .sp-requested .myi-dot { background: #059669; }
    .sp-reserved  .myi-dot { background: #2563eb; }
    .sp-completed .myi-dot { background: #64748b; }
    .sp-rejected  .myi-dot { background: #dc2626; }

    /* Card body */
    .myi-body {
        padding: 16px 18px 18px;
        display: flex;
        flex-direction: column;
        flex: 1;
        gap: 10px;
    }

    .myi-title {
        font-size: 15px;
        font-weight: 700;
        color: #111827;
        margin: 0;
        line-height: 1.3;
        display: -webkit-box;
        -webkit-line-clamp: 2;
        -webkit-box-orient: vertical;
        overflow: hidden;
    }

    /* Badges row */
    .myi-badges {
        display: flex;
        flex-wrap: wrap;
        gap: 6px;
    }

    .myi-badge {
        display: inline-flex;
        align-items: center;
        gap: 4px;
        padding: 3px 9px;
        border-radius: 6px;
        font-size: 11px;
        font-weight: 600;
        background: #f3f4f6;
        color: #374151;
    }

    .myi-badge.badge-category { background: #ecfdf5; color: #065f46; }
    .myi-badge.badge-condition { background: #eff6ff; color: #1e40af; }

    /* Date */
    .myi-date {
        font-size: 12px;
        color: #9ca3af;
        margin: 0;
    }

    /* Description toggle */
    .myi-desc-toggle {
        background: none;
        border: none;
        padding: 0;
        color: #2e7d32;
        font-size: 12px;
        font-weight: 600;
        cursor: pointer;
        text-align: left;
        text-decoration: underline;
        text-underline-offset: 2px;
    }

    .myi-desc-toggle:hover { color: #15803d; }

    .myi-description {
        font-size: 13px;
        color: #6b7280;
        line-height: 1.5;
        margin: 0;
        background: #f9fafb;
        border: 1px solid #e5e7eb;
        border-radius: 8px;
        padding: 10px 12px;
    }

    /* Footer action */
    .myi-footer {
        margin-top: auto;
        padding-top: 4px;
    }

    .myi-view-btn {
        width: 100%;
        padding: 9px 14px;
        border-radius: 8px;
        border: 1px solid #d1d5db;
        background: #fff;
        color: #374151;
        font-size: 13px;
        font-weight: 600;
        cursor: pointer;
        transition: background 0.2s, border-color 0.2s;
    }

    .myi-view-btn:hover {
        background: #f0fdf4;
        border-color: #2e7d32;
        color: #166534;
    }

    @media (max-width: 640px) {
        .myi-grid { grid-template-columns: 1fr; }
        .myi-stat { flex: 1 1 calc(50% - 6px); }
        .myi-stat-value { font-size: 22px; }
        .myi-page { padding: 0 16px; }
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
int statTotal = 0, statPending = 0, statActive = 0, statCompleted = 0;
{
    Connection sc = null; PreparedStatement sp = null; ResultSet sr = null;
    try {
        sc = DBConnection.getConnection();
        if (sc != null) {
            String statSql = "SELECT COUNT(*) AS total, "
                + "SUM(CASE WHEN LOWER(status) = 'pending' THEN 1 ELSE 0 END) AS pending_cnt, "
                + "SUM(CASE WHEN LOWER(status) IN ('available','requested','reserved') THEN 1 ELSE 0 END) AS active_cnt, "
                + "SUM(CASE WHEN LOWER(status) = 'completed' THEN 1 ELSE 0 END) AS completed_cnt "
                + "FROM donations WHERE donor_id = ?";
            sp = sc.prepareStatement(statSql);
            sp.setInt(1, userId);
            sr = sp.executeQuery();
            if (sr.next()) {
                statTotal     = sr.getInt("total");
                statPending   = sr.getInt("pending_cnt");
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

// Main item list
SimpleDateFormat dateFmt = new SimpleDateFormat("d MMM yyyy", Locale.ENGLISH);

// row: [donationId, title, description, category, itemCondition, formattedDate, status, pillClass, pillLabel, imageUrl]
List<Object[]> items = new ArrayList<Object[]>();
String loadError  = null;
String schemaHint = null;

{
    Connection conn = null; PreparedStatement ps = null; ResultSet rs = null;
    ResultSet cr1 = null; ResultSet cr2 = null;
    try {
        conn = DBConnection.getConnection();
        if (conn == null) {
            loadError = "Database connection failed.";
        } else {
            boolean hasCategoryColumn  = false;
            boolean hasConditionColumn = false;
            try {
                DatabaseMetaData meta = conn.getMetaData();
                cr1 = meta.getColumns(conn.getCatalog(), null, "donations", "category");
                hasCategoryColumn = cr1.next();
                cr2 = meta.getColumns(conn.getCatalog(), null, "donations", "item_condition");
                hasConditionColumn = cr2.next();
            } catch (SQLException ign) {
            } finally {
                if (cr1 != null) { try { cr1.close(); } catch (SQLException ign) {} cr1 = null; }
                if (cr2 != null) { try { cr2.close(); } catch (SQLException ign) {} cr2 = null; }
            }

            String sql;
            if (hasCategoryColumn && hasConditionColumn) {
                sql = "SELECT donation_id, title, description, image, "
                    + "COALESCE(NULLIF(TRIM(category),''),'Others / Miscellaneous') AS category, "
                    + "COALESCE(NULLIF(TRIM(item_condition),''),'Good') AS item_condition, "
                    + "status, created_at FROM donations WHERE donor_id = ? ORDER BY created_at DESC";
            } else {
                sql = "SELECT donation_id, title, description, image, "
                    + "'Others / Miscellaneous' AS category, 'Good' AS item_condition, "
                    + "status, created_at FROM donations WHERE donor_id = ? ORDER BY created_at DESC";
                schemaHint = "Category and condition will appear after the database update script is applied.";
            }

            ps = conn.prepareStatement(sql);
            ps.setInt(1, userId);
            rs = ps.executeQuery();
            while (rs.next()) {
                int    donationId    = rs.getInt("donation_id");
                String title         = rs.getString("title");
                String description   = rs.getString("description");
                String category      = rs.getString("category");
                String itemCondition = rs.getString("item_condition");
                String status        = rs.getString("status");
                Timestamp ts         = rs.getTimestamp("created_at");
                String fDate         = ts != null ? dateFmt.format(ts) : "";
                String image         = rs.getString("image");

                // REPLACE WITH:
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
                    if (imagePath.startsWith("/")) { imagePath = imagePath.substring(1); }
                    }
                    boolean isExternal = imagePath.startsWith("http://") || imagePath.startsWith("https://");
                    String imageUrl = isExternal ? imagePath : ctx + "/" + imagePath;

                String pc, pl;
                if ("Available".equalsIgnoreCase(status))       { pc = "sp-available"; pl = "Available"; }
                else if ("Requested".equalsIgnoreCase(status))  { pc = "sp-requested"; pl = "Requested"; }
                else if ("Reserved".equalsIgnoreCase(status))   { pc = "sp-reserved";  pl = "Reserved";  }
                else if ("Completed".equalsIgnoreCase(status))  { pc = "sp-completed"; pl = "Completed"; }
                else if ("Rejected".equalsIgnoreCase(status))   { pc = "sp-rejected";  pl = "Rejected";  }
                else if ("Expired".equalsIgnoreCase(status))    { pc = "sp-expired";   pl = "Expired";   }
                else                                            { pc = "sp-pending";   pl = "Pending";   }

                items.add(new Object[]{ donationId, title, description, category, itemCondition, fDate, status, pc, pl, imageUrl });
            }
        }
    } catch (SQLException e) {
        loadError = "Failed to load your donated items.";
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
                    <a href="<%= ctx %>/myRequest.jsp">My Requests</a>
                    <a href="<%= ctx %>/myItems.jsp" class="active">My Items</a>
                    <a href="<%= ctx %>/pickupSchedule.jsp">Pickup Schedule</a>
                    <a href="<%= ctx %>/profile.jsp?view=profile">My Profile</a>
                    <a href="<%= ctx %>/profile.jsp?view=summary">Account Summary</a>
                    <a href="<%= ctx %>/LogoutServlet">Logout</a>
                </div>
            </details>
        </li>
    </ul>
</nav>

<div class="myi-page">
    <h1>My Donated Items</h1>
    <p class="myi-subtitle">Track all items you have listed for donation and their current status.</p>

    <%-- Stats row --%>
    <div class="myi-stats">
        <div class="myi-stat">
            <div class="myi-stat-value"><%= statTotal %></div>
            <div class="myi-stat-label">Total</div>
        </div>
        <div class="myi-stat st-amber">
            <div class="myi-stat-value"><%= statPending %></div>
            <div class="myi-stat-label">Pending Review</div>
        </div>
        <div class="myi-stat st-green">
            <div class="myi-stat-value"><%= statActive %></div>
            <div class="myi-stat-label">Active</div>
        </div>
        <div class="myi-stat st-slate">
            <div class="myi-stat-value"><%= statCompleted %></div>
            <div class="myi-stat-label">Completed</div>
        </div>
    </div>

    <%-- Flash message --%>
    <%
    String myItemsMessage = (String) session.getAttribute("myItemsMessage");
    if (myItemsMessage != null) {
    %>
    <div class="myi-flash">
        <span>&#10003;</span>
        <%= myItemsMessage %>
    </div>
    <%
        session.removeAttribute("myItemsMessage");
    }
    %>

    <% if (schemaHint != null) { %>
    <div class="myi-flash" style="background:#fff8e1;border-color:#fde68a;color:#92400e;">
        &#9432; <%= schemaHint %>
    </div>
    <% } %>

    <%-- Error --%>
    <% if (loadError != null) { %>
    <div class="myi-error"><%= loadError %></div>
    <% } %>

    <%-- Empty state --%>
    <% if (loadError == null && items.isEmpty()) { %>
    <div class="myi-empty">
        <span class="myi-empty-icon">&#127873;</span>
        <h2>No items donated yet</h2>
        <p>You haven't donated any items. List something you no longer need and help a fellow student.</p>
        <a href="<%= ctx %>/postItem.jsp" class="myi-empty-cta">Donate an Item</a>
    </div>
    <% } %>

    <%-- Item grid --%>
    <% if (!items.isEmpty()) { %>
    <div class="myi-grid">
        <%
        int cardIdx = 0;
        for (Object[] item : items) {
            int    donationId    = (Integer) item[0];
            String title         = (String)  item[1];
            String description   = (String)  item[2];
            String category      = (String)  item[3];
            String itemCondition = (String)  item[4];
            String fDate         = (String)  item[5];
            String status        = (String)  item[6];
            String pc            = (String)  item[7];
            String pl            = (String)  item[8];
            String imageUrl      = (String)  item[9];
            String toggleId = "desc-" + donationId;
            cardIdx++;
        %>
        <div class="myi-card">
            <div class="myi-img-wrap">
                <button type="button"
                        class="myi-img-btn js-myitem-image-open"
                        data-image-url="<%= imageUrl %>"
                        title="Open full image">
                    <img src="<%= imageUrl %>" alt="<%= title %>" class="myi-img">
                </button>
                <span class="myi-status-overlay <%= pc %>">
                    <span class="myi-dot"></span>
                    <%= pl %>
                </span>
            </div>

            <div class="myi-body">
                <h3 class="myi-title"><%= title %></h3>

                <div class="myi-badges">
                    <span class="myi-badge badge-category">&#127807; <%= category %></span>
                    <span class="myi-badge badge-condition">&#9733; <%= itemCondition %></span>
                </div>

                <p class="myi-date">Posted <%= fDate %></p>

                <%
                if (description != null && !description.trim().isEmpty()) {
                %>
                <button type="button"
                        class="myi-desc-toggle"
                        aria-expanded="false"
                        data-target="<%= toggleId %>">
                    Show description
                </button>
                <p id="<%= toggleId %>" class="myi-description" hidden><%= description %></p>
                <%
                }
                %>

                <div class="myi-footer">
                    <button type="button"
                            class="myi-view-btn js-myitem-image-open"
                            data-image-url="<%= imageUrl %>">
                        View Full Image
                    </button>
                </div>
            </div>
        </div>
        <% } %>
    </div>
    <% } %>
</div>

<%-- Image modal --%>
<div id="myItemImageModal" class="image-modal" aria-hidden="true">
    <div class="image-modal-backdrop js-myitem-image-close"></div>
    <div class="image-modal-content" role="dialog" aria-modal="true" aria-label="Full image preview">
        <button type="button" class="image-modal-close js-myitem-image-close" aria-label="Close image">Close</button>
        <img id="myItemImageModalPreview" src="" alt="Full item image" class="image-modal-preview">
    </div>
</div>

<script>
(function () {
    var openButtons = document.querySelectorAll('.js-myitem-image-open');
    var closeButtons = document.querySelectorAll('.js-myitem-image-close');
    var modal = document.getElementById('myItemImageModal');
    var preview = document.getElementById('myItemImageModalPreview');

    if (!modal || !preview || openButtons.length === 0) return;

    function openModal(url) {
        if (!url) return;
        preview.src = url;
        modal.classList.add('open');
        modal.setAttribute('aria-hidden', 'false');
        document.body.classList.add('modal-open');
    }

    function closeModal() {
        modal.classList.remove('open');
        modal.setAttribute('aria-hidden', 'true');
        preview.src = '';
        document.body.classList.remove('modal-open');
    }

    for (var i = 0; i < openButtons.length; i++) {
        openButtons[i].addEventListener('click', function (e) {
            e.preventDefault();
            openModal(this.getAttribute('data-image-url'));
        });
    }

    for (var j = 0; j < closeButtons.length; j++) {
        closeButtons[j].addEventListener('click', closeModal);
    }

    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') closeModal();
    });
})();

(function () {
    var toggles = document.querySelectorAll('.myi-desc-toggle');
    for (var i = 0; i < toggles.length; i++) {
        toggles[i].addEventListener('click', function () {
            var targetId = this.getAttribute('data-target');
            var desc = document.getElementById(targetId);
            if (!desc) return;
            var open = this.getAttribute('aria-expanded') === 'true';
            this.setAttribute('aria-expanded', open ? 'false' : 'true');
            this.textContent = open ? 'Show description' : 'Hide description';
            desc.hidden = open;
        });
    }
})();
</script>

<script src="<%= request.getContextPath() %>/js/logout-confirm.js"></script>
</body>
</html>
