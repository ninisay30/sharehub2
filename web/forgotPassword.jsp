<%@page contentType="text/html" pageEncoding="UTF-8"%>
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
<!DOCTYPE html>
<html>
<head>
    <title>Forgot Password | ShareHub</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css?v=20260605a">
    <style>
        .auth-container .auth-form {
            text-align: left !important;
        }
        .auth-container .auth-form .auth-field {
            margin-bottom: 10px;
            text-align: left !important;
        }
        .auth-container .auth-form .auth-field label {
            display: block;
            margin-bottom: 6px;
            text-align: left !important;
            font-weight: 600;
        }
        .auth-container .auth-form .auth-field input {
            margin-bottom: 4px;
        }
    </style>
</head>
<body>

<nav class="navbar" aria-label="Guest navigation">
    <div class="nav-logo">ShareHub</div>
    <ul class="nav-links">
        <li><a href="<%= request.getContextPath() %>/index.jsp">Home</a></li>
    </ul>
</nav>

<div class="auth-container">
    <h1>Forgot Password</h1>
    <p class="auth-subtitle">
        Enter your registered email address and ShareHub will send you a temporary password.
    </p>

    <%
        String emailValue = (String) request.getAttribute("emailValue");
        String emailError = (String) request.getAttribute("emailError");
        String successMessage = (String) request.getAttribute("successMessage");
    %>

    <% if (successMessage != null) { %>
    <p class="info-banner"><%= esc(successMessage) %></p>
    <% } %>

    <form action="ForgotPasswordServlet" method="post" class="auth-form forgot-password-form" novalidate>
        <div class="auth-field">
            <label for="emailInput">Registered Email Address <span class="required-indicator">*</span></label>
            <input id="emailInput" type="email" name="email" placeholder="Email address"
                   value="<%= esc(emailValue) %>" class="<%= emailError != null ? "input-error" : "" %>" required>
            <p class="field-error <%= emailError != null ? "show" : "" %>"><%= emailError != null ? esc(emailError) : "" %></p>
        </div>

        <button type="submit" class="primary-btn">Send Temporary Password</button>
    </form>

    <p class="auth-footer">
        Remember your password?
        <a href="login.jsp">Login here</a>
    </p>
</div>

</body>
</html>
