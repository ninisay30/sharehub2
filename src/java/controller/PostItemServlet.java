/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package controller;

import dao.DBConnection;
import java.io.File;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;
import util.EmailUtility;

/**
 *
 * @author Asus
 */
@WebServlet("/PostItemServlet")
@MultipartConfig
public class PostItemServlet extends HttpServlet {

    private static final Set<String> ALLOWED_CATEGORIES = new HashSet<String>(Arrays.asList(
            "Books & Study Materials",
            "Clothes & Accessories",
            "Household & Hostel Items",
            "Electronics & Gadgets",
            "Others / Miscellaneous"
    ));

    private static final Set<String> ALLOWED_CONDITIONS = new HashSet<String>(Arrays.asList(
            "New",
            "Like New",
            "Good",
            "Fair"
    ));

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        int donorId = resolveUserId(session, -1);
        if (donorId <= 0) {
            session.setAttribute("postItemMessage", "Invalid session. Please login again.");
            response.sendRedirect("login.jsp");
            return;
        }

        String title = request.getParameter("title") == null ? "" : request.getParameter("title").trim();
        String description = request.getParameter("description") == null ? "" : request.getParameter("description").trim();
        String category = request.getParameter("category") == null ? "" : request.getParameter("category").trim();
        String itemCondition = request.getParameter("itemCondition") == null ? "" : request.getParameter("itemCondition").trim();
        if (title.isEmpty() || description.isEmpty() || category.isEmpty() || itemCondition.isEmpty()) {
            session.setAttribute("postItemMessage", "Title, description, category, and condition are required.");
            response.sendRedirect("postItem.jsp");
            return;
        }

        if (!ALLOWED_CATEGORIES.contains(category)) {
            session.setAttribute("postItemMessage", "Please choose a valid category.");
            response.sendRedirect("postItem.jsp");
            return;
        }

        if (!ALLOWED_CONDITIONS.contains(itemCondition)) {
            session.setAttribute("postItemMessage", "Please choose a valid item condition.");
            response.sendRedirect("postItem.jsp");
            return;
        }

        Part imagePart = request.getPart("image");
        String storedImagePath = null;

        if (imagePart != null && imagePart.getSize() > 0) {
            String submittedName = imagePart.getSubmittedFileName();
            String safeName = sanitizeSubmittedFileName(submittedName);
            String storedFileName = System.currentTimeMillis() + "_" + safeName;

        String uploadPath = ImageServlet.getUploadBaseDir(getServletContext());
        File uploadDir = new File(uploadPath);
        if (!uploadDir.exists()) {
            uploadDir.mkdirs();
        }

        String filePath = uploadPath + File.separator + storedFileName;
        imagePart.write(filePath);
        storedImagePath = "uploads/" + storedFileName;
        }

        try (Connection conn = DBConnection.getConnection()) {
            if (conn == null) {
                session.setAttribute("postItemMessage", "Database connection failed.");
                response.sendRedirect("postItem.jsp");
                return;
            }

            boolean hasCategoryColumn = hasColumn(conn, "donations", "category");
            boolean hasConditionColumn = hasColumn(conn, "donations", "item_condition");

            if (hasCategoryColumn && hasConditionColumn) {
                String sql = "INSERT INTO donations (donor_id, title, description, image, category, item_condition, status) "
                        + "VALUES (?, ?, ?, ?, ?, ?, 'Pending')";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, donorId);
                    ps.setString(2, title);
                    ps.setString(3, description);
                    ps.setString(4, storedImagePath);
                    ps.setString(5, category);
                    ps.setString(6, itemCondition);
                    ps.executeUpdate();
                }
            } else {
                String sql = "INSERT INTO donations (donor_id, title, description, image, status) "
                        + "VALUES (?, ?, ?, ?, 'Pending')";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, donorId);
                    ps.setString(2, title);
                    ps.setString(3, description);
                    ps.setString(4, storedImagePath);
                    ps.executeUpdate();
                }
            }

            session.setAttribute("myItemsMessage", "Item submitted successfully. Status: Pending.");
            EmailUtility.sendDonationSubmittedEmailAsync(resolveEmail(session), resolveName(session), title);
            response.sendRedirect("myItems.jsp");
        } catch (SQLException e) {
            session.setAttribute("postItemMessage", "Failed to submit item due to server error.");
            response.sendRedirect("postItem.jsp");
        }
    }

    private int resolveUserId(HttpSession session, int fallback) {
        Object userIdObj = session.getAttribute("userId");
        if (userIdObj instanceof Integer) {
            return ((Integer) userIdObj).intValue();
        }
        if (userIdObj != null) {
            try {
                return Integer.parseInt(userIdObj.toString());
            } catch (NumberFormatException ignored) {
                return fallback;
            }
        }
        return fallback;
    }

    private String resolveEmail(HttpSession session) {
        Object emailObj = session.getAttribute("email");
        return emailObj == null ? "" : emailObj.toString();
    }

    private String resolveName(HttpSession session) {
        Object usernameObj = session.getAttribute("username");
        return usernameObj == null ? "" : usernameObj.toString();
    }

    private boolean hasColumn(Connection conn, String tableName, String columnName) {
        if (conn == null || tableName == null || columnName == null) {
            return false;
        }
        try {
            DatabaseMetaData meta = conn.getMetaData();
            try (ResultSet rs = meta.getColumns(conn.getCatalog(), null, tableName, columnName)) {
                return rs.next();
            }
        } catch (SQLException ex) {
            return false;
        }
    }

    private String sanitizeSubmittedFileName(String submittedName) {
        String fileName = submittedName == null ? "item.jpg" : new File(submittedName).getName();
        int dotIndex = fileName.lastIndexOf('.');
        String baseName = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
        String extension = dotIndex > 0 ? fileName.substring(dotIndex).toLowerCase() : ".jpg";

        if (!isAllowedImageExtension(extension)) {
            extension = ".jpg";
        }

        baseName = baseName.replaceAll("[^A-Za-z0-9_-]+", "_");
        baseName = baseName.replaceAll("_+", "_");
        baseName = baseName.replaceAll("^_+|_+$", "");

        if (baseName.isEmpty()) {
            baseName = "item";
        }
        if (baseName.length() > 80) {
            baseName = baseName.substring(0, 80);
        }

        return baseName + extension;
    }

    private boolean isAllowedImageExtension(String extension) {
        return ".jpg".equals(extension)
                || ".jpeg".equals(extension)
                || ".png".equals(extension)
                || ".webp".equals(extension)
                || ".gif".equals(extension);
    }
}
