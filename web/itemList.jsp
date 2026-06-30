<%-- 
    Document   : itemList
    Created on : Dec 31, 2025, 5:45:03 PM
    Author     : Asus
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="container">
<h2>Available Items</h2>

<div class="item-card">
    <h3>Buku Novel</h3>
    <p>Status: Available</p>
    <form action="RequestItemServlet" method="post">
        <button type="submit">Request Item</button>
    </form>
</div>

</div>
</body>
</html>
