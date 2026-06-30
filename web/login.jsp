<%-- 
    Document   : login
    Created on : Dec 31, 2025, 5:45:29 PM
    Author     : Asus
--%>

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
    <title>Login | ShareHub</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css?v=20260521a">
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
        .auth-container .auth-form .required-indicator {
            color: #c62828;
            margin-left: 2px;
            font-weight: 600;
        }
        .auth-container .auth-form .auth-field input {
            margin-bottom: 4px;
        }
        .auth-container .auth-form .field-error {
            min-height: 16px;
            margin: 0 0 2px 0;
            color: #d32f2f;
            font-size: 12px;
            line-height: 1.3;
            text-align: left !important;
            visibility: hidden;
        }
        .auth-container .auth-form .field-error.show {
            visibility: visible;
        }
        .auth-container .auth-form .input-error {
            border-color: #d32f2f !important;
            background-color: #fff8f8;
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
    <h1>Welcome Back</h1>
    <p class="auth-subtitle">
        Log in to continue your sharing journey with ShareHub.
    </p>

    <%
    String emailValue = (String) request.getAttribute("emailValue");
    String emailError = (String) request.getAttribute("emailError");
    String passwordError = (String) request.getAttribute("passwordError");
    %>

    <form action="LoginServlet" method="post" class="auth-form login-form" novalidate>

        <div class="auth-field">
            <label for="emailInput" class="auth-input-label">Email Address <span class="required-indicator">*</span></label>
            <input id="emailInput" type="email" name="email" placeholder="Email address"
                   value="<%= esc(emailValue) %>" class="<%= emailError != null ? "input-error" : "" %>" required>
            <p class="field-error <%= emailError != null ? "show" : "" %>"><%= emailError != null ? esc(emailError) : "" %></p>
        </div>

        <div class="auth-field">
            <label for="passwordInput" class="auth-input-label">Password <span class="required-indicator">*</span></label>
            <input id="passwordInput" type="password" name="password" placeholder="Password"
                   class="<%= passwordError != null ? "input-error" : "" %>" required>
            <p class="field-error <%= passwordError != null ? "show" : "" %>"><%= passwordError != null ? esc(passwordError) : "" %></p>
        </div>

        <button type="submit" class="primary-btn">Login</button>

    </form>

    <p class="auth-footer" style="margin-top:12px;">
        <a href="forgotPassword.jsp">Forgot Password?</a>
    </p>

    <p class="auth-footer">
        Don't have an account?
        <a href="register.jsp">Register here</a>
    </p>
</div>

</body>
</html>

