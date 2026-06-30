<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="dao.DBConnection"%>
<%@page import="java.sql.Connection"%>
<%@page import="java.sql.PreparedStatement"%>
<%@page import="java.sql.ResultSet"%>
<%@page import="java.sql.SQLException"%>
<%@page import="java.io.File"%>
<!DOCTYPE html>
<html>
<head>
    <title>Pending Requests | ShareHub Admin</title>
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
%>

<nav class="navbar">
    <div class="nav-logo">ShareHub Admin</div>
    <ul class="nav-links">
        <li><a href="<%= ctx %>/adminDashboard.jsp">Admin</a></li>
        <li><a href="<%= ctx %>/adminPendingDonations.jsp">Pending Donations</a></li>
        <li><a href="<%= ctx %>/adminPendingRequests.jsp" class="active">Pending Requests</a></li>
        <li><a href="<%= ctx %>/adminActivity.jsp">Activity</a></li>
        <li><a href="<%= ctx %>/LogoutServlet">Logout</a></li>
    </ul>
</nav>

<div class="page-container">
    <h1>Pending Item Requests</h1>
    <p class="page-subtitle">Approve or reject each request.</p>

    <%
    String adminMessage = (String) session.getAttribute("adminMessage");
    if (adminMessage != null) {
    %>
    <p class="info-banner"><%= adminMessage %></p>
    <%
        session.removeAttribute("adminMessage");
    }

    String pendingRequestsSql = "SELECT r.request_id, r.created_at, d.title, d.image, u.name AS requester_name "
            + "FROM requests r "
            + "JOIN donations d ON d.donation_id = r.donation_id "
            + "LEFT JOIN users u ON u.user_id = r.user_id "
            + "WHERE LOWER(r.status)='pending' ORDER BY r.created_at ASC";
    boolean hasPendingRequests = false;

    try (Connection conn = DBConnection.getConnection()) {
        if (conn == null) {
    %>
    <p style="color:red;">Database connection failed.</p>
    <%
        } else {
            try (PreparedStatement ps = conn.prepareStatement(pendingRequestsSql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    hasPendingRequests = true;
                    int requestId = rs.getInt("request_id");
                    String requesterName = rs.getString("requester_name");
                    if (requesterName == null || requesterName.trim().isEmpty()) {
                        requesterName = "Unknown requester";
                    }

                    String image = rs.getString("image");
                    String imagePath = (image == null || image.trim().isEmpty()) ? "image/books.jpg" : image.trim();
                    imagePath = imagePath.replace('\\', '/');
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

                    boolean isExternalImage = imagePath.startsWith("http://")
                            || imagePath.startsWith("https://");
                    String imageUrl = isExternalImage ? imagePath : ctx + "/" + imagePath;
    %>
    <div class="request-card" style="display:block;">
        <div class="admin-review-layout">
            <div class="admin-review-image-wrap">
                <button type="button" class="admin-review-image-link js-image-open" data-image-url="<%= imageUrl %>" title="Open full image">
                    <img src="<%= imageUrl %>" alt="Requested item image" class="admin-review-image">
                </button>
            </div>
            <div class="admin-review-content">
                <div class="request-info">
                    <h3>Request #<%= requestId %>: <%= rs.getString("title") %></h3>
                    <p>Requester: <%= requesterName %></p>
                    <p>Requested on: <%= rs.getString("created_at") %></p>
                </div>

                <div class="admin-action-row">
                    <button type="button" class="view-image-btn js-image-open" data-image-url="<%= imageUrl %>">View Full Image</button>

                    <form action="AdminActionServlet" method="post">
                        <input type="hidden" name="entity" value="request">
                        <input type="hidden" name="decision" value="approve">
                        <input type="hidden" name="id" value="<%= requestId %>">
                        <input type="hidden" name="returnPage" value="adminPendingRequests.jsp">
                        <button type="submit" class="primary-btn small-btn action-btn">Approve</button>
                    </form>
                    <form action="AdminActionServlet" method="post">
                        <input type="hidden" name="entity" value="request">
                        <input type="hidden" name="decision" value="reject">
                        <input type="hidden" name="id" value="<%= requestId %>">
                        <input type="hidden" name="returnPage" value="adminPendingRequests.jsp">
                        <button type="submit" class="danger-btn action-btn">Reject</button>
                    </form>
                </div>
            </div>
        </div>
    </div>
    <%
                }
            }
        }
    } catch (SQLException e) {
    %>
    <p style="color:red;">Failed to load pending requests.</p>
    <%
    }

    if (!hasPendingRequests) {
    %>
    <p>No pending item requests.</p>
    <%
    }
    %>
</div>

<div id="imageModal" class="image-modal" aria-hidden="true">
    <div class="image-modal-backdrop js-image-close"></div>
    <div class="image-modal-content" role="dialog" aria-modal="true" aria-label="Full image preview">
        <button type="button" class="image-modal-close js-image-close" aria-label="Close image">Close</button>
        <img id="imageModalPreview" src="" alt="Full request image" class="image-modal-preview">
    </div>
</div>

<script>
(function () {
    var openButtons = document.querySelectorAll('.js-image-open');
    var closeButtons = document.querySelectorAll('.js-image-close');
    var modal = document.getElementById('imageModal');
    var preview = document.getElementById('imageModalPreview');

    if (!modal || !preview || openButtons.length === 0) {
        return;
    }

    function openModal(url) {
        if (!url) {
            return;
        }
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
        openButtons[i].addEventListener('click', function (event) {
            event.preventDefault();
            var url = this.getAttribute('data-image-url');
            openModal(url);
        });
    }

    for (var j = 0; j < closeButtons.length; j++) {
        closeButtons[j].addEventListener('click', function () {
            closeModal();
        });
    }

    document.addEventListener('keydown', function (event) {
        if (event.key === 'Escape') {
            closeModal();
        }
    });
})();
</script>

<script src="<%= request.getContextPath() %>/js/logout-confirm.js"></script>
</body>
</html>

