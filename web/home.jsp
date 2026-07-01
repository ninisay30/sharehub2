<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="dao.DBConnection"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.SQLException"%>
<%@page import="java.sql.DatabaseMetaData"%>
<%@page import="java.io.File"%>
<%@page import="java.util.ArrayList"%>
<%@page import="java.util.List"%>
<!DOCTYPE html>
<%!
private String defaultImageForCategory(String category) {
    String normalized = category == null ? "" : category.trim().toLowerCase();
    if (normalized.contains("book") || normalized.contains("study")) {
        return "image/books.jpg";
    }
    if (normalized.contains("clothes") || normalized.contains("accessories")) {
        return "image/bajukurung.jpg";
    }
    if (normalized.contains("electronic") || normalized.contains("gadget")) {
        return "image/calculator.jpg";
    }
    return "image/basikal.jpg";
}

private String resolveDonationImageUrl(String image, String category, String ctx,
        javax.servlet.ServletContext application) {

    String imagePath = (image == null || image.trim().isEmpty())
            ? defaultImageForCategory(category)
            : image.trim().replace('\\', '/');

    if (imagePath.startsWith("http://") || imagePath.startsWith("https://")) {
        return imagePath;
    }

    if (imagePath.matches("^[A-Za-z]:/.*")) {
        imagePath = imagePath.substring(imagePath.lastIndexOf('/') + 1);
    }

    if (!imagePath.startsWith("image/") && !imagePath.startsWith("uploads/")) {
        imagePath = "uploads/" + imagePath;
    }

    if (imagePath.startsWith("/")) {
        imagePath = imagePath.substring(1);
    }

    return ctx + "/" + imagePath;
}
%>
<html>
<head>
    <title>Home | ShareHub</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css?v=20260701b">
    <style>
    /* ===== HOME PAGE IMPROVEMENTS ===== */

    /* Page header */
    .hc-header {
        display: flex;
        justify-content: space-between;
        align-items: flex-end;
        gap: 16px;
        margin-bottom: 22px;
        flex-wrap: wrap;
    }

    .hc-header h1 {
        font-size: 26px;
        font-weight: 700;
        color: #111827;
        margin: 0 0 4px;
    }

    .hc-header p {
        color: #6b7280;
        font-size: 14px;
        margin: 0;
    }

    .hc-donate-cta {
        display: inline-flex;
        align-items: center;
        gap: 7px;
        padding: 10px 20px;
        background: #2e7d32;
        color: #fff;
        border-radius: 10px;
        text-decoration: none;
        font-size: 14px;
        font-weight: 700;
        white-space: nowrap;
        flex-shrink: 0;
        transition: background 0.2s;
    }

    .hc-donate-cta:hover { background: #256628; }

    /* Flash message */
    .hc-flash {
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
        margin-bottom: 20px;
    }

    /* Schema hint */
    .hc-hint {
        display: flex;
        align-items: center;
        gap: 8px;
        padding: 10px 14px;
        background: #fffbeb;
        border: 1px solid #fde68a;
        color: #92400e;
        border-radius: 8px;
        font-size: 13px;
        margin-bottom: 14px;
    }

    /* Error */
    .hc-error {
        padding: 12px 16px;
        background: #fef2f2;
        border: 1px solid #fecaca;
        color: #991b1b;
        border-radius: 10px;
        font-size: 14px;
        margin-bottom: 14px;
    }

    /* Full-page empty state */
    .hc-full-empty {
        text-align: center;
        padding: 64px 32px;
        background: #fff;
        border: 1.5px dashed #86efac;
        border-radius: 18px;
        margin-top: 8px;
    }

    .hc-full-empty-icon {
        font-size: 52px;
        display: block;
        margin-bottom: 16px;
        line-height: 1;
    }

    .hc-full-empty h2 {
        font-size: 20px;
        color: #111827;
        margin-bottom: 8px;
    }

    .hc-full-empty p {
        color: #6b7280;
        font-size: 14px;
        max-width: 380px;
        margin: 0 auto 24px;
        line-height: 1.6;
    }

    .hc-full-empty-actions {
        display: flex;
        gap: 12px;
        justify-content: center;
        flex-wrap: wrap;
    }

    .hc-empty-cta {
        display: inline-flex;
        align-items: center;
        gap: 7px;
        padding: 10px 22px;
        background: #2e7d32;
        color: #fff;
        border-radius: 999px;
        text-decoration: none;
        font-weight: 700;
        font-size: 14px;
        transition: background 0.2s;
    }

    .hc-empty-cta:hover { background: #256628; }

    .hc-empty-reset {
        display: inline-flex;
        align-items: center;
        padding: 10px 22px;
        border: 1px solid #d1d5db;
        background: #fff;
        color: #374151;
        border-radius: 999px;
        text-decoration: none;
        font-weight: 600;
        font-size: 14px;
        transition: background 0.15s;
    }

    .hc-empty-reset:hover { background: #f9fafb; }

    /* Section heading with count badge */
    .hc-section-head {
        display: flex;
        align-items: center;
        gap: 10px;
        margin: 0 0 16px;
        padding-bottom: 12px;
        border-bottom: 2px solid #f3f4f6;
    }

    .hc-section-head h2 {
        font-size: 18px;
        font-weight: 700;
        color: #111827;
        margin: 0;
    }

    .hc-count-badge {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        min-width: 24px;
        height: 24px;
        padding: 0 7px;
        border-radius: 999px;
        background: #e5e7eb;
        color: #374151;
        font-size: 12px;
        font-weight: 700;
    }

    .hc-section-head.avail-head .hc-count-badge {
        background: #dcfce7;
        color: #15803d;
    }

    /* Section-level empty */
    .hc-sect-empty {
        text-align: center;
        padding: 36px 24px;
        background: #fafafa;
        border: 1.5px dashed #e5e7eb;
        border-radius: 14px;
        margin-bottom: 20px;
    }

    .hc-sect-empty p { color: #9ca3af; font-size: 14px; margin: 0; }
    .hc-sect-empty-icon { font-size: 28px; display: block; margin-bottom: 10px; line-height: 1; }

    /* ── CARD OVERRIDES ── */

    /* Reset the 520px min-height from global CSS */
    .home-browse-section .item-card {
        min-height: 0 !important;
        overflow: hidden;
    }

    /* Image wrapper */
    .hc-img-wrap {
        position: relative;
        width: 100%;
        height: 190px;
        overflow: hidden;
        background: #f3f4f6;
        flex-shrink: 0;
    }

    .hc-img-wrap .hc-img-btn {
        width: 100%;
        height: 100%;
        border: none;
        background: transparent;
        padding: 0;
        cursor: zoom-in;
        display: block;
    }

    /* Override the 180px height rule from global CSS */
    .home-browse-section .hc-img-wrap img {
        width: 100%;
        height: 100% !important;
        object-fit: cover;
        display: block;
        transition: transform 0.3s ease;
    }

    .home-browse-section .item-card:hover .hc-img-wrap img {
        transform: scale(1.04);
    }

    /* Status overlay on image */
    .hc-status-overlay {
        position: absolute;
        top: 10px;
        right: 10px;
        display: inline-flex;
        align-items: center;
        gap: 5px;
        padding: 4px 10px;
        border-radius: 999px;
        font-size: 11px;
        font-weight: 700;
        white-space: nowrap;
        pointer-events: none;
    }

    .hso-available { background: rgba(220,252,231,0.92); color: #15803d; }
    .hso-requested { background: rgba(209,250,229,0.92); color: #065f46; }
    .hso-reserved  { background: rgba(219,234,254,0.92); color: #1d4ed8; }
    .hso-pending   { background: rgba(254,243,199,0.92); color: #92400e; }

    .hc-sdot {
        width: 6px;
        height: 6px;
        border-radius: 50%;
        display: inline-block;
        flex-shrink: 0;
    }

    .hso-available .hc-sdot { background: #16a34a; }
    .hso-requested .hc-sdot { background: #059669; }
    .hso-reserved  .hc-sdot { background: #2563eb; }
    .hso-pending   .hc-sdot { background: #d97706; }

    /* Card body */
    .hc-body {
        padding: 14px 16px 18px;
        display: flex;
        flex-direction: column;
        gap: 9px;
        flex: 1;
    }

    .hc-title {
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

    /* Category + condition badges */
    .hc-badges {
        display: flex;
        flex-wrap: wrap;
        gap: 5px;
    }

    .hc-badge {
        display: inline-flex;
        align-items: center;
        padding: 3px 8px;
        border-radius: 6px;
        font-size: 11px;
        font-weight: 600;
        line-height: 1.4;
    }

    .hc-badge-cat  { background: #ecfdf5; color: #065f46; }
    .hc-badge-cond { background: #eff6ff; color: #1e40af; }

    /* Description toggle */
    .hc-desc-toggle {
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
        align-self: flex-start;
    }

    .hc-desc-toggle:hover { color: #15803d; }

    /* Override existing item-description for new layout */
    .home-browse-section .item-description {
        font-size: 13px;
        color: #6b7280;
        background: #f9fafb;
        border: 1px solid #e5e7eb;
        border-radius: 8px;
        padding: 10px 12px;
        margin: 0;
        line-height: 1.5;
        max-height: none;
        display: block;
        -webkit-line-clamp: unset;
        overflow: visible;
        text-overflow: clip;
    }

    .home-browse-section .item-description[hidden] {
        display: none !important;
    }

    /* Action buttons — two per row */
    .hc-actions {
        margin-top: auto;
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 8px;
        padding-top: 2px;
    }

    .hc-view-btn {
        padding: 9px 8px;
        border: 1px solid #d1d5db;
        border-radius: 8px;
        background: #fff;
        color: #374151;
        font-size: 12px;
        font-weight: 600;
        cursor: pointer;
        text-align: center;
        transition: background 0.15s, border-color 0.15s;
        width: 100%;
    }

    .hc-view-btn:hover { background: #f9fafb; border-color: #9ca3af; }

    .hc-req-form { margin: 0; }

    .hc-req-btn {
        width: 100%;
        padding: 9px 8px;
        border: 1px solid #2e7d32;
        border-radius: 8px;
        background: #2e7d32;
        color: #fff;
        font-size: 12px;
        font-weight: 700;
        cursor: pointer;
        text-align: center;
        transition: background 0.15s;
    }

    .hc-req-btn:hover { background: #256628; }

    .hc-unavail-btn {
        padding: 9px 8px;
        border: 1px solid #e5e7eb;
        border-radius: 8px;
        background: #f9fafb;
        color: #9ca3af;
        font-size: 12px;
        font-weight: 600;
        cursor: not-allowed;
        text-align: center;
        width: 100%;
    }

    @media (max-width: 700px) {
        .hc-header { align-items: flex-start; flex-direction: column; gap: 12px; }
        .hc-actions { grid-template-columns: 1fr; }
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
%>

<nav class="navbar">
    <div class="nav-logo">ShareHub</div>
    <ul class="nav-links">
        <li><a href="<%= ctx %>/home.jsp" class="active">Home</a></li>
        <li><a href="<%= ctx %>/postItem.jsp">Donate</a></li>
        <li><a href="<%= ctx %>/activity.jsp">Activity</a></li>
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

<%
String searchTerm     = request.getParameter("search")    == null ? "" : request.getParameter("search").trim();
String categoryFilter = request.getParameter("category")  == null ? "" : request.getParameter("category").trim();
String conditionFilter= request.getParameter("condition") == null ? "" : request.getParameter("condition").trim();

List<Object[]> availableItems   = new ArrayList<Object[]>();
String loadError  = null;
String schemaHint = null;
boolean supportsCategoryCondition = false;

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
                DatabaseMetaData metaData = conn.getMetaData();
                cr1 = metaData.getColumns(conn.getCatalog(), null, "donations", "category");
                hasCategoryColumn = cr1.next();
                cr2 = metaData.getColumns(conn.getCatalog(), null, "donations", "item_condition");
                hasConditionColumn = cr2.next();
            } catch (SQLException ign) {
            } finally {
                if (cr1 != null) { try { cr1.close(); } catch (SQLException ign) {} cr1 = null; }
                if (cr2 != null) { try { cr2.close(); } catch (SQLException ign) {} cr2 = null; }
            }

            supportsCategoryCondition = hasCategoryColumn && hasConditionColumn;

            StringBuilder sqlBuilder = new StringBuilder();
            sqlBuilder.append("SELECT donation_id, title, description, image, ")
                      .append("CASE WHEN EXISTS (SELECT 1 FROM requests r ")
                      .append("WHERE r.donation_id = donations.donation_id ")
                      .append("AND LOWER(r.status) IN ('pending', 'approved', 'pickup scheduled', 'received pending')) ")
                      .append("THEN 'Requested' ELSE status END AS status, ");
            if (supportsCategoryCondition) {
                sqlBuilder.append("COALESCE(NULLIF(TRIM(category), ''), 'Others / Miscellaneous') AS category, ")
                          .append("COALESCE(NULLIF(TRIM(item_condition), ''), 'Good') AS item_condition ");
            } else {
                sqlBuilder.append("'Others / Miscellaneous' AS category, 'Good' AS item_condition ");
                schemaHint = "Category and condition filters will work after the database update script is applied.";
            }
            sqlBuilder.append("FROM donations WHERE donor_id <> ? ")
                      .append("AND LOWER(COALESCE(status, '')) = 'available' ")
                      .append("AND NOT EXISTS (SELECT 1 FROM requests r ")
                      .append("WHERE r.donation_id = donations.donation_id ")
                      .append("AND LOWER(r.status) IN ('pending', 'approved', 'pickup scheduled', 'received pending', 'completed')) ");

            List<String> queryValues = new ArrayList<String>();
            if (!searchTerm.isEmpty()) {
                if (supportsCategoryCondition) {
                    sqlBuilder.append("AND (LOWER(COALESCE(title, '')) LIKE ? ")
                              .append("OR LOWER(COALESCE(description, '')) LIKE ? ")
                              .append("OR LOWER(COALESCE(category, '')) LIKE ? ")
                              .append("OR LOWER(COALESCE(item_condition, '')) LIKE ?) ");
                    String t = "%" + searchTerm.toLowerCase() + "%";
                    queryValues.add(t); queryValues.add(t); queryValues.add(t); queryValues.add(t);
                } else {
                    sqlBuilder.append("AND (LOWER(COALESCE(title, '')) LIKE ? ")
                              .append("OR LOWER(COALESCE(description, '')) LIKE ?) ");
                    String t = "%" + searchTerm.toLowerCase() + "%";
                    queryValues.add(t); queryValues.add(t);
                }
            }
            if (supportsCategoryCondition) {
                if (!categoryFilter.isEmpty() && !"All".equalsIgnoreCase(categoryFilter)) {
                    sqlBuilder.append("AND COALESCE(NULLIF(TRIM(category), ''), 'Others / Miscellaneous') = ? ");
                    queryValues.add(categoryFilter);
                }
                if (!conditionFilter.isEmpty() && !"All".equalsIgnoreCase(conditionFilter)) {
                    sqlBuilder.append("AND COALESCE(NULLIF(TRIM(item_condition), ''), 'Good') = ? ");
                    queryValues.add(conditionFilter);
                }
            }
            sqlBuilder.append("ORDER BY created_at DESC");

            ps = conn.prepareStatement(sqlBuilder.toString());
            int bindIndex = 1;
            ps.setInt(bindIndex++, userId);
            for (String v : queryValues) ps.setString(bindIndex++, v);
            rs = ps.executeQuery();
            while (rs.next()) {
                int    donationId    = rs.getInt("donation_id");
                String title         = rs.getString("title");
                String description   = rs.getString("description");
                String status        = rs.getString("status");
                String category      = rs.getString("category");
                String itemCondition = rs.getString("item_condition");
                String image         = rs.getString("image");

                String imageUrl = resolveDonationImageUrl(image, category, ctx, application);

                String normalizedStatus = status == null ? "" : status.trim();
                String statusClass, statusLabel;
                if ("Available".equalsIgnoreCase(normalizedStatus)) {
                    statusClass = "available"; statusLabel = "Available";
                } else if ("Requested".equalsIgnoreCase(normalizedStatus)) {
                    statusClass = "requested"; statusLabel = "Requested";
                } else if ("Reserved".equalsIgnoreCase(normalizedStatus)) {
                    statusClass = "reserved";  statusLabel = "Reserved";
                } else {
                    statusClass = "pending";   statusLabel = "Pending";
                }

                Object[] item = new Object[]{ donationId, title, description, imageUrl, category, itemCondition, statusLabel, statusClass };
                availableItems.add(item);
            }
        }
    } catch (SQLException e) {
        loadError = "Failed to load items.";
    } finally {
        if (rs != null) { try { rs.close(); } catch (SQLException ign) {} }
        if (ps != null) { try { ps.close(); } catch (SQLException ign) {} }
        if (conn != null) { try { conn.close(); } catch (SQLException ign) {} }
    }
}

boolean hasFilters = !searchTerm.isEmpty() || !categoryFilter.isEmpty() || !conditionFilter.isEmpty();
%>

<div class="page-container home-listing-page">

    <%-- Page header --%>
    <div class="hc-header">
        <div>
            <h1>Browse Donations</h1>
            <p>Discover items shared by UMT students &mdash; request what you need.</p>
        </div>
    </div>

    <%-- Flash --%>
    <%
    String requestMessage = (String) session.getAttribute("requestMessage");
    if (requestMessage != null) {
    %>
    <div class="hc-flash">&#10003; <%= requestMessage %></div>
    <%
        session.removeAttribute("requestMessage");
    }
    %>

    <%-- Error --%>
    <% if (loadError != null) { %>
    <div class="hc-error">&#9888; <%= loadError %></div>
    <% } %>

    <%-- Schema hint --%>
    <% if (schemaHint != null) { %>
    <div class="hc-hint">&#9432; <%= schemaHint %></div>
    <% } %>

    <% if (loadError == null) { %>

    <%-- Filter form (always visible) --%>
    <form action="<%= ctx %>/home.jsp" method="get" class="browse-filter-form">
        <div class="browse-filter-controls">
            <input type="text" name="search" value="<%= searchTerm %>"
                   placeholder="Search by name, description, category..."
                   class="browse-filter-input">
            <select name="category" class="browse-filter-select">
                <option value="">All Categories</option>
                <option value="Books & Study Materials"  <%= "Books & Study Materials".equals(categoryFilter)  ? "selected" : "" %>>Books &amp; Study Materials</option>
                <option value="Clothes & Accessories"    <%= "Clothes & Accessories".equals(categoryFilter)    ? "selected" : "" %>>Clothes &amp; Accessories</option>
                <option value="Household & Hostel Items" <%= "Household & Hostel Items".equals(categoryFilter) ? "selected" : "" %>>Household &amp; Hostel Items</option>
                <option value="Electronics & Gadgets"    <%= "Electronics & Gadgets".equals(categoryFilter)    ? "selected" : "" %>>Electronics &amp; Gadgets</option>
                <option value="Others / Miscellaneous"   <%= "Others / Miscellaneous".equals(categoryFilter)   ? "selected" : "" %>>Others / Miscellaneous</option>
            </select>
            <select name="condition" class="browse-filter-select">
                <option value="">All Conditions</option>
                <option value="New"      <%= "New".equals(conditionFilter)      ? "selected" : "" %>>New</option>
                <option value="Like New" <%= "Like New".equals(conditionFilter) ? "selected" : "" %>>Like New</option>
                <option value="Good"     <%= "Good".equals(conditionFilter)     ? "selected" : "" %>>Good</option>
                <option value="Fair"     <%= "Fair".equals(conditionFilter)     ? "selected" : "" %>>Fair</option>
            </select>
        </div>
        <div class="browse-filter-actions">
            <button type="submit" class="primary-btn browse-filter-apply-btn">Apply Filters</button>
            <a href="<%= ctx %>/home.jsp" class="secondary-inline-link browse-filter-reset-link">Reset</a>
        </div>
    </form>

    <%-- Full-page empty state --%>
    <% if (availableItems.isEmpty()) { %>
    <div class="hc-full-empty">
        <span class="hc-full-empty-icon">&#128269;</span>
        <% if (hasFilters) { %>
        <h2>No items match your filters</h2>
        <p>Try adjusting your search terms or removing a filter to see more results.</p>
        <div class="hc-full-empty-actions">
            <a href="<%= ctx %>/home.jsp" class="hc-empty-reset">Clear Filters</a>
            <a href="<%= ctx %>/postItem.jsp" class="hc-empty-cta">Donate an Item</a>
        </div>
        <% } else { %>
        <h2>No items yet</h2>
        <p>No one has donated items for you to browse yet. Be the first to donate something!</p>
        <% } %>
    </div>
    <% } else { %>

    <%-- ===== AVAILABLE SECTION ===== --%>
    <div class="home-browse-section">
        <div class="hc-section-head avail-head home-section-heading">
            <h2>Available Now</h2>
            <span class="hc-count-badge"><%= availableItems.size() %></span>
        </div>
        <% if (availableItems.isEmpty()) { %>
        <div class="hc-sect-empty">
            <span class="hc-sect-empty-icon">&#10003;</span>
            <p>No available items right now &mdash; check back soon or try a different filter.</p>
        </div>
        <% } else { %>
        <div class="item-grid">
            <%
            for (Object[] item : availableItems) {
                int    donationId    = ((Integer) item[0]).intValue();
                String title         = item[1] == null ? "" : item[1].toString();
                String description   = item[2] == null ? "" : item[2].toString();
                String imageUrl      = item[3] == null ? "" : item[3].toString();
                String category      = item[4] == null ? "Others / Miscellaneous" : item[4].toString();
                String itemCondition = item[5] == null ? "Good" : item[5].toString();
                String statusLabel   = item[6] == null ? "" : item[6].toString();
                String statusClass   = item[7] == null ? "pending" : item[7].toString();
                String hso = "hso-" + statusClass;
            %>
            <div class="item-card">
                <div class="hc-img-wrap">
                    <button type="button" class="hc-img-btn js-home-image-open"
                            data-image-url="<%= imageUrl %>" title="View full image">
                        <img src="<%= imageUrl %>" alt="<%= title %>">
                    </button>
                    <span class="hc-status-overlay <%= hso %>">
                        <span class="hc-sdot"></span>
                        <%= statusLabel %>
                    </span>
                </div>
                <div class="hc-body">
                    <h3 class="hc-title"><%= title %></h3>
                    <div class="hc-badges">
                        <span class="hc-badge hc-badge-cat">&#127807; <%= category %></span>
                        <span class="hc-badge hc-badge-cond">&#9733; <%= itemCondition %></span>
                    </div>
                    <% if (description != null && !description.trim().isEmpty()) { %>
                    <button type="button" class="hc-desc-toggle js-description-toggle" aria-expanded="false">
                        Show description
                    </button>
                    <p class="item-description" hidden><%= description %></p>
                    <% } %>
                    <div class="hc-actions">
                        <button type="button" class="hc-view-btn js-home-image-open"
                                data-image-url="<%= imageUrl %>">View Photo</button>
                        <form action="RequestItemServlet" method="post" class="hc-req-form">
                            <input type="hidden" name="donationId" value="<%= donationId %>">
                            <button type="submit" class="hc-req-btn">Request Item</button>
                        </form>
                    </div>
                </div>
            </div>
            <% } %>
        </div>
        <% } %>
    </div>

    <% } /* end has items */ %>
    <% } /* end no loadError */ %>

</div>

<%-- Image modal --%>
<div id="homeImageModal" class="image-modal" aria-hidden="true">
    <div class="image-modal-backdrop js-home-image-close"></div>
    <div class="image-modal-content" role="dialog" aria-modal="true" aria-label="Full image preview">
        <button type="button" class="image-modal-close js-home-image-close" aria-label="Close image">Close</button>
        <img id="homeImageModalPreview" src="" alt="Full donation image" class="image-modal-preview">
    </div>
</div>

<script>
(function () {
    var toggles = document.querySelectorAll('.js-description-toggle');
    for (var d = 0; d < toggles.length; d++) {
        toggles[d].addEventListener('click', function () {
            var desc = this.nextElementSibling;
            if (!desc) return;
            var isOpen = this.getAttribute('aria-expanded') === 'true';
            this.setAttribute('aria-expanded', isOpen ? 'false' : 'true');
            this.textContent = isOpen ? 'Show description' : 'Hide description';
            desc.hidden = isOpen;
        });
    }
})();

(function () {
    var openBtns  = document.querySelectorAll('.js-home-image-open');
    var closeBtns = document.querySelectorAll('.js-home-image-close');
    var modal   = document.getElementById('homeImageModal');
    var preview = document.getElementById('homeImageModalPreview');
    if (!modal || !preview || !openBtns.length) return;

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

    for (var i = 0; i < openBtns.length; i++) {
        openBtns[i].addEventListener('click', function (e) {
            e.preventDefault();
            openModal(this.getAttribute('data-image-url'));
        });
    }
    for (var j = 0; j < closeBtns.length; j++) {
        closeBtns[j].addEventListener('click', closeModal);
    }
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape') closeModal(); });
})();
</script>

<script src="<%= request.getContextPath() %>/js/logout-confirm.js"></script>
</body>
</html>
