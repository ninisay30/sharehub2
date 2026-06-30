<%--
    Document   : register
    Created on : Dec 31, 2025, 5:47:02 PM
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
    <title>Register | ShareHub</title>
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
    <h1>Create Account</h1>
    <p class="auth-subtitle">Join ShareHub and start donating or requesting items</p>

    <%
    String nameValue = (String) request.getAttribute("nameValue");
    String matricNoValue = (String) request.getAttribute("matricNoValue");
    String emailValue = (String) request.getAttribute("emailValue");
    String phoneNoValue = (String) request.getAttribute("phoneNoValue");

    String nameError = (String) request.getAttribute("nameError");
    String matricNoError = (String) request.getAttribute("matricNoError");
    String emailError = (String) request.getAttribute("emailError");
    String passwordError = (String) request.getAttribute("passwordError");
    String phoneNoError = (String) request.getAttribute("phoneNoError");
    %>

    <form action="RegisterServlet" method="post" class="auth-form" novalidate>

        <div class="auth-field">
            <label for="nameInput">Full Name <span class="required-indicator">*</span></label>
            <input id="nameInput" type="text" name="name" placeholder="Full name"
                   value="<%= esc(nameValue) %>" class="<%= nameError != null ? "input-error" : "" %>" required>
            <p class="field-error <%= nameError != null ? "show" : "" %>"><%= nameError != null ? esc(nameError) : "" %></p>
        </div>

        <div class="auth-field">
            <label for="matricInput">Matric Number <span class="required-indicator">*</span></label>
            <input id="matricInput" type="text" name="matricNo" placeholder="Matric number"
                   value="<%= esc(matricNoValue) %>" class="<%= matricNoError != null ? "input-error" : "" %>" required>
            <p class="field-error <%= matricNoError != null ? "show" : "" %>"><%= matricNoError != null ? esc(matricNoError) : "" %></p>
        </div>

        <div class="auth-field">
            <label for="emailInput">Email Address <span class="required-indicator">*</span></label>
            <input id="emailInput" type="email" name="email" placeholder="Email address"
                   value="<%= esc(emailValue) %>" class="<%= emailError != null ? "input-error" : "" %>" required>
            <p class="field-error <%= emailError != null ? "show" : "" %>"><%= emailError != null ? esc(emailError) : "" %></p>
        </div>

        <div class="auth-field">
            <label for="passwordInput">Password <span class="required-indicator">*</span></label>
            <input id="passwordInput" type="password" name="password" placeholder="Password"
                   class="<%= passwordError != null ? "input-error" : "" %>" required>
            <p class="field-error <%= passwordError != null ? "show" : "" %>"><%= passwordError != null ? esc(passwordError) : "" %></p>
        </div>

        <div class="auth-field">
            <label for="phoneInput">Phone Number (Optional)</label>
            <input id="phoneInput" type="text" name="phoneNo" placeholder="Phone number (optional)"
                   value="<%= esc(phoneNoValue) %>" class="<%= phoneNoError != null ? "input-error" : "" %>">
            <p class="field-error <%= phoneNoError != null ? "show" : "" %>"><%= phoneNoError != null ? esc(phoneNoError) : "" %></p>
        </div>

        <button type="submit" class="primary-btn">Register</button>
    </form>

    <p class="auth-footer">
        Already have an account?
        <a href="login.jsp">Login here</a>
    </p>
</div>

</body>
</html>

