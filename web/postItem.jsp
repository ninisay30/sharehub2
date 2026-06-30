<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="dao.DBConnection"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.SQLException"%>
<!DOCTYPE html>
<html>
<head>
    <title>Donate Item | ShareHub</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css?v=20260701b">
    <style>
    /* ===== POST ITEM PAGE ===== */
    .pi-page {
        max-width: 1020px;
        margin: 40px auto 64px;
        padding: 0 24px;
    }

    .pi-page-header {
        margin-bottom: 28px;
    }

    .pi-page-header h1 {
        font-size: 26px;
        font-weight: 700;
        color: #111827;
        margin: 0 0 4px;
    }

    .pi-page-header p {
        color: #6b7280;
        font-size: 14px;
        margin: 0;
    }

    /* Two-column layout */
    .pi-layout {
        display: grid;
        grid-template-columns: minmax(0, 1.65fr) minmax(0, 1fr);
        gap: 24px;
        align-items: start;
    }

    /* Form card */
    .pi-form-card {
        background: #fff;
        border-radius: 16px;
        border: 1px solid #e5e7eb;
        box-shadow: 0 2px 10px rgba(0,0,0,0.05);
        padding: 28px 30px;
    }

    /* Side panel */
    .pi-side {
        display: flex;
        flex-direction: column;
        gap: 16px;
        position: sticky;
        top: 24px;
    }

    .pi-side-card {
        background: #fff;
        border-radius: 14px;
        border: 1px solid #e5e7eb;
        padding: 20px 22px;
        box-shadow: 0 1px 6px rgba(0,0,0,0.04);
    }

    .pi-side-card h3 {
        font-size: 13px;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.6px;
        color: #9ca3af;
        margin: 0 0 14px;
    }

    .pi-guideline-list {
        list-style: none;
        padding: 0;
        margin: 0;
        display: flex;
        flex-direction: column;
        gap: 10px;
    }

    .pi-guideline-list li {
        display: flex;
        align-items: flex-start;
        gap: 9px;
        font-size: 13px;
        color: #374151;
        line-height: 1.45;
    }

    .pi-gl-icon {
        width: 20px;
        height: 20px;
        border-radius: 50%;
        background: #dcfce7;
        color: #15803d;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        font-size: 11px;
        font-weight: 700;
        flex-shrink: 0;
        margin-top: 1px;
    }

    .pi-flow {
        display: flex;
        flex-direction: column;
        gap: 10px;
    }

    .pi-flow-step {
        display: flex;
        align-items: flex-start;
        gap: 11px;
        font-size: 13px;
        color: #374151;
        line-height: 1.4;
    }

    .pi-step-num {
        width: 22px;
        height: 22px;
        border-radius: 50%;
        background: #2e7d32;
        color: #fff;
        font-size: 11px;
        font-weight: 700;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
        margin-top: 1px;
    }

    .pi-status-note {
        display: flex;
        align-items: center;
        gap: 8px;
        padding: 10px 14px;
        background: #fef9ec;
        border: 1px solid #fde68a;
        border-radius: 8px;
        font-size: 13px;
        color: #92400e;
    }

    /* Form fields */
    .pi-field {
        margin-bottom: 20px;
    }

    .pi-label {
        display: block;
        font-size: 13px;
        font-weight: 700;
        color: #374151;
        margin-bottom: 6px;
    }

    .pi-required {
        color: #dc2626;
        margin-left: 2px;
    }

    .pi-input,
    .pi-textarea,
    .pi-select {
        width: 100%;
        padding: 10px 12px;
        border: 1px solid #d1d5db;
        border-radius: 8px;
        font-size: 14px;
        color: #111827;
        background: #fff;
        font-family: inherit;
        transition: border-color 0.15s ease, box-shadow 0.15s ease;
    }

    .pi-textarea { resize: vertical; min-height: 100px; }

    .pi-input:focus,
    .pi-textarea:focus,
    .pi-select:focus {
        outline: none;
        border-color: #2e7d32;
        box-shadow: 0 0 0 3px rgba(46, 125, 50, 0.12);
    }

    /* Condition chips */
    .pi-chips {
        display: flex;
        gap: 8px;
        flex-wrap: wrap;
    }

    .pi-chip {
        position: relative;
    }

    .pi-chip input[type="radio"] {
        position: absolute;
        opacity: 0;
        width: 0;
        height: 0;
    }

    .pi-chip-label {
        display: inline-flex;
        flex-direction: column;
        align-items: center;
        padding: 9px 18px;
        border: 1.5px solid #d1d5db;
        border-radius: 8px;
        font-size: 13px;
        font-weight: 600;
        color: #6b7280;
        cursor: pointer;
        transition: border-color 0.15s, background 0.15s, color 0.15s;
        background: #fff;
        line-height: 1.2;
        user-select: none;
    }

    .pi-chip-hint {
        font-size: 10px;
        font-weight: 400;
        color: #9ca3af;
        margin-top: 2px;
    }

    .pi-chip input:checked + .pi-chip-label {
        border-color: #2e7d32;
        background: #f0fdf4;
        color: #15803d;
    }

    .pi-chip input:checked + .pi-chip-label .pi-chip-hint {
        color: #4ade80;
    }

    .pi-chip-label:hover {
        border-color: #9ca3af;
        color: #374151;
    }

    .pi-chip input:focus-visible + .pi-chip-label {
        outline: 2px solid #2e7d32;
        outline-offset: 2px;
    }

    /* Image upload area */
    .pi-upload-area {
        position: relative;
        border: 2px dashed #d1d5db;
        border-radius: 12px;
        padding: 28px 20px;
        text-align: center;
        cursor: pointer;
        background: #fafafa;
        transition: border-color 0.15s, background 0.15s;
    }

    .pi-upload-area:hover {
        border-color: #2e7d32;
        background: #f0fdf4;
    }

    .pi-upload-area.has-file {
        border-color: #86efac;
        background: #f0fdf4;
    }

    .pi-upload-area input[type="file"] {
        position: absolute;
        inset: 0;
        opacity: 0;
        cursor: pointer;
        width: 100%;
        height: 100%;
        font-size: 0;
    }

    .pi-upload-icon {
        font-size: 30px;
        display: block;
        margin-bottom: 8px;
        line-height: 1;
    }

    .pi-upload-text {
        font-size: 14px;
        color: #6b7280;
        margin: 0;
    }

    .pi-upload-text strong { color: #2e7d32; }

    .pi-upload-hint {
        font-size: 12px;
        color: #9ca3af;
        margin: 4px 0 0;
    }

    /* Image preview */
    .pi-preview {
        display: none;
        margin-top: 14px;
        text-align: left;
    }

    .pi-preview.show { display: block; }

    .pi-preview-inner {
        display: flex;
        align-items: center;
        gap: 12px;
        padding: 10px 12px;
        background: #f9fafb;
        border: 1px solid #e5e7eb;
        border-radius: 10px;
    }

    .pi-preview-img {
        width: 56px;
        height: 56px;
        object-fit: cover;
        border-radius: 8px;
        border: 1px solid #e5e7eb;
        flex-shrink: 0;
    }

    .pi-preview-name {
        font-size: 13px;
        color: #374151;
        font-weight: 600;
        word-break: break-all;
    }

    .pi-preview-size {
        font-size: 12px;
        color: #9ca3af;
        margin-top: 2px;
    }

    /* Error banner */
    .pi-error {
        display: flex;
        align-items: center;
        gap: 10px;
        padding: 12px 16px;
        border-radius: 10px;
        background: #fef2f2;
        border: 1px solid #fecaca;
        color: #991b1b;
        font-size: 14px;
        font-weight: 500;
        margin-bottom: 22px;
    }

    /* Submit row */
    .pi-submit-row {
        display: flex;
        align-items: center;
        gap: 16px;
        margin-top: 8px;
        flex-wrap: wrap;
    }

    .pi-submit-btn {
        flex: 1 1 auto;
        padding: 12px 24px;
        background: #2e7d32;
        color: #fff;
        border: none;
        border-radius: 10px;
        font-size: 15px;
        font-weight: 700;
        cursor: pointer;
        transition: background 0.2s;
    }

    .pi-submit-btn:hover { background: #256628; }

    .pi-cancel-link {
        color: #6b7280;
        font-size: 14px;
        text-decoration: none;
        font-weight: 500;
        white-space: nowrap;
    }

    .pi-cancel-link:hover { color: #374151; text-decoration: underline; }

    /* Divider inside form card */
    .pi-divider {
        border: none;
        border-top: 1px solid #f3f4f6;
        margin: 22px 0;
    }

    @media (max-width: 820px) {
        .pi-layout {
            grid-template-columns: 1fr;
        }

        .pi-side {
            position: static;
            order: -1;
        }

        .pi-side {
            display: grid;
            grid-template-columns: 1fr 1fr;
        }
    }

    @media (max-width: 560px) {
        .pi-page { padding: 0 16px; }
        .pi-form-card { padding: 20px 18px; }
        .pi-side { grid-template-columns: 1fr; }
        .pi-chips { gap: 6px; }
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
        <li><a href="<%= ctx %>/home.jsp">Home</a></li>
        <li><a href="<%= ctx %>/postItem.jsp" class="active">Donate</a></li>
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

<div class="pi-page">
    <div class="pi-page-header">
        <h1>Post a Donation</h1>
        <p>Share items you no longer need with other UMT students.</p>
    </div>

    <div class="pi-layout">

        <%-- ===== FORM CARD ===== --%>
        <div class="pi-form-card">

            <%-- Error message --%>
            <%
            String postItemMessage = (String) session.getAttribute("postItemMessage");
            if (postItemMessage != null) {
            %>
            <div class="pi-error">
                <span>&#9888;</span>
                <%= postItemMessage %>
            </div>
            <%
                session.removeAttribute("postItemMessage");
            }
            %>

            <form action="PostItemServlet" method="post" enctype="multipart/form-data" id="postItemForm" novalidate>

                <%-- Title --%>
                <div class="pi-field">
                    <label class="pi-label" for="pi-title">
                        Item Title <span class="pi-required">*</span>
                    </label>
                    <input id="pi-title" class="pi-input" type="text" name="title"
                           placeholder="e.g. Engineering Textbook, Baju Kurung, Mini Fan"
                           required maxlength="200">
                </div>

                <%-- Description --%>
                <div class="pi-field">
                    <label class="pi-label" for="pi-desc">
                        Description <span class="pi-required">*</span>
                    </label>
                    <textarea id="pi-desc" class="pi-textarea" name="description"
                              placeholder="Describe the item — size, colour, brand, any defects, reason for donating..."
                              rows="4" required maxlength="1000"></textarea>
                </div>

                <%-- Category --%>
                <div class="pi-field">
                    <label class="pi-label" for="pi-category">
                        Category <span class="pi-required">*</span>
                    </label>
                    <select id="pi-category" class="pi-select" name="category" required>
                        <option value="">Select a category</option>
                        <option value="Books & Study Materials">&#128218; Books &amp; Study Materials</option>
                        <option value="Clothes & Accessories">&#128084; Clothes &amp; Accessories</option>
                        <option value="Household & Hostel Items">&#127968; Household &amp; Hostel Items</option>
                        <option value="Electronics & Gadgets">&#128187; Electronics &amp; Gadgets</option>
                        <option value="Others / Miscellaneous">&#128230; Others / Miscellaneous</option>
                    </select>
                </div>

                <%-- Condition chips --%>
                <div class="pi-field">
                    <label class="pi-label">
                        Item Condition <span class="pi-required">*</span>
                    </label>
                    <div class="pi-chips">
                        <label class="pi-chip">
                            <input type="radio" name="itemCondition" value="New" required>
                            <span class="pi-chip-label">
                                New
                                <span class="pi-chip-hint">Never used</span>
                            </span>
                        </label>
                        <label class="pi-chip">
                            <input type="radio" name="itemCondition" value="Like New">
                            <span class="pi-chip-label">
                                Like New
                                <span class="pi-chip-hint">Barely used</span>
                            </span>
                        </label>
                        <label class="pi-chip">
                            <input type="radio" name="itemCondition" value="Good">
                            <span class="pi-chip-label">
                                Good
                                <span class="pi-chip-hint">Some wear</span>
                            </span>
                        </label>
                        <label class="pi-chip">
                            <input type="radio" name="itemCondition" value="Fair">
                            <span class="pi-chip-label">
                                Fair
                                <span class="pi-chip-hint">Visible wear</span>
                            </span>
                        </label>
                    </div>
                </div>

                <hr class="pi-divider">

                <%-- Image upload --%>
                <div class="pi-field">
                    <label class="pi-label">
                        Photo <span class="pi-required">*</span>
                    </label>
                    <div class="pi-upload-area" id="piUploadArea">
                        <input type="file" name="image" id="piImageInput"
                               accept="image/*" required
                               aria-label="Upload item photo">
                        <span class="pi-upload-icon">&#128247;</span>
                        <p class="pi-upload-text">
                            <strong>Click to upload</strong> or drag and drop
                        </p>
                        <p class="pi-upload-hint">JPG, PNG, WEBP &mdash; clear, well-lit photo preferred</p>
                    </div>
                    <div class="pi-preview" id="piPreview">
                        <div class="pi-preview-inner">
                            <img id="piPreviewImg" class="pi-preview-img" src="" alt="Preview">
                            <div>
                                <p class="pi-preview-name" id="piPreviewName"></p>
                                <p class="pi-preview-size" id="piPreviewSize"></p>
                            </div>
                        </div>
                    </div>
                </div>

                <%-- Status note --%>
                <div class="pi-status-note">
                    <span>&#9432;</span>
                    Your item will be listed as <strong>Pending</strong> until reviewed and approved by an admin.
                </div>

                <%-- Submit --%>
                <div class="pi-submit-row" style="margin-top:22px;">
                    <button type="submit" class="pi-submit-btn">Submit Donation</button>
                    <a href="<%= ctx %>/home.jsp" class="pi-cancel-link">Cancel</a>
                </div>

            </form>
        </div>

        <%-- ===== SIDE PANEL ===== --%>
        <div class="pi-side">

            <div class="pi-side-card">
                <h3>Donation Guidelines</h3>
                <ul class="pi-guideline-list">
                    <li>
                        <span class="pi-gl-icon">&#10003;</span>
                        Items must be clean and in usable condition.
                    </li>
                    <li>
                        <span class="pi-gl-icon">&#10003;</span>
                        Be honest in your description &mdash; include any faults or wear.
                    </li>
                    <li>
                        <span class="pi-gl-icon">&#10003;</span>
                        Upload a clear, well-lit photo of the actual item.
                    </li>
                    <li>
                        <span class="pi-gl-icon">&#10003;</span>
                        Do not post damaged, broken, or inappropriate items.
                    </li>
                    <li>
                        <span class="pi-gl-icon">&#10003;</span>
                        One photo per listing &mdash; make it count.
                    </li>
                </ul>
            </div>

            <div class="pi-side-card">
                <h3>What Happens Next?</h3>
                <div class="pi-flow">
                    <div class="pi-flow-step">
                        <span class="pi-step-num">1</span>
                        <span>You submit the item &mdash; it goes into <strong>Pending</strong> review.</span>
                    </div>
                    <div class="pi-flow-step">
                        <span class="pi-step-num">2</span>
                        <span>An admin reviews and <strong>approves</strong> or rejects the listing.</span>
                    </div>
                    <div class="pi-flow-step">
                        <span class="pi-step-num">3</span>
                        <span>Once approved, your item goes <strong>live</strong> for students to request.</span>
                    </div>
                    <div class="pi-flow-step">
                        <span class="pi-step-num">4</span>
                        <span>You <strong>schedule pickup</strong> with the approved requester.</span>
                    </div>
                </div>
            </div>

        </div>
        <%-- end side --%>

    </div>
    <%-- end layout --%>
</div>

<script>
(function () {
    var input      = document.getElementById('piImageInput');
    var area       = document.getElementById('piUploadArea');
    var preview    = document.getElementById('piPreview');
    var previewImg = document.getElementById('piPreviewImg');
    var previewName = document.getElementById('piPreviewName');
    var previewSize = document.getElementById('piPreviewSize');

    if (!input || !area || !preview) return;

    function formatBytes(bytes) {
        if (bytes < 1024) return bytes + ' B';
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
        return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
    }

    function showPreview(file) {
        if (!file || !file.type.startsWith('image/')) return;
        var reader = new FileReader();
        reader.onload = function (e) {
            previewImg.src = e.target.result;
            previewName.textContent = file.name;
            previewSize.textContent = formatBytes(file.size);
            preview.classList.add('show');
            area.classList.add('has-file');
        };
        reader.readAsDataURL(file);
    }

    input.addEventListener('change', function () {
        if (this.files && this.files[0]) {
            showPreview(this.files[0]);
        }
    });

    area.addEventListener('dragover', function (e) {
        e.preventDefault();
        this.classList.add('has-file');
    });

    area.addEventListener('dragleave', function () {
        if (!input.files || !input.files[0]) {
            this.classList.remove('has-file');
        }
    });

    area.addEventListener('drop', function (e) {
        e.preventDefault();
        var files = e.dataTransfer.files;
        if (files && files[0]) {
            input.files = files;
            showPreview(files[0]);
        }
    });
})();
</script>

<script src="<%= request.getContextPath() %>/js/logout-confirm.js"></script>
</body>
</html>
