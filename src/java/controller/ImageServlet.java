/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package controller;

/**
 *
 * @author Asus
 */
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/uploads/*")
public class ImageServlet extends HttpServlet {

    public static String getUploadBaseDir(javax.servlet.ServletContext ctx) {
        String envParam = System.getenv("SHAREHUB_UPLOAD_DIR");
        if (envParam != null && !envParam.trim().isEmpty()) {
            return envParam.trim();
        }

        String propertyParam = System.getProperty("sharehub.upload.dir");
        if (propertyParam != null && !propertyParam.trim().isEmpty()) {
            return propertyParam.trim();
        }

        String ctxParam = ctx.getInitParameter("uploadBaseDir");
        if (ctxParam != null && !ctxParam.trim().isEmpty()) {
            return ctxParam.trim();
        }
        return new File(System.getProperty("user.home"), "sharehub_uploads").getAbsolutePath();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String pathInfo = request.getPathInfo();
        if (pathInfo == null || pathInfo.equals("/") || pathInfo.isEmpty()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "No image specified.");
            return;
        }

        String fileName = pathInfo.substring(1);
        if (fileName.contains("..") || fileName.contains("/") || fileName.contains("\\")) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid filename.");
            return;
        }

        String baseDir = getUploadBaseDir(getServletContext());
        File imageFile = new File(baseDir, fileName);

        if (!imageFile.exists() || !imageFile.isFile()) {
            String deployedUploadPath = getServletContext().getRealPath("/uploads/" + fileName);
            File deployedUploadFile = deployedUploadPath == null ? null : new File(deployedUploadPath);
            if (deployedUploadFile != null && deployedUploadFile.exists() && deployedUploadFile.isFile()) {
                imageFile = deployedUploadFile;
            } else {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Image not found.");
                return;
            }
        }

        String lowerName = fileName.toLowerCase();
        String contentType;
        if (lowerName.endsWith(".jpg") || lowerName.endsWith(".jpeg")) {
            contentType = "image/jpeg";
        } else if (lowerName.endsWith(".png")) {
            contentType = "image/png";
        } else if (lowerName.endsWith(".webp")) {
            contentType = "image/webp";
        } else {
            contentType = "image/gif";
        }

        response.setContentType(contentType);
        response.setContentLengthLong(imageFile.length());
        response.setHeader("Cache-Control", "public, max-age=3600");

        try (FileInputStream in = new FileInputStream(imageFile);
             OutputStream out = response.getOutputStream()) {
            byte[] buffer = new byte[8192];
            int bytesRead;
            while ((bytesRead = in.read(buffer)) != -1) {
                out.write(buffer, 0, bytesRead);
            }
        }
    }
}
