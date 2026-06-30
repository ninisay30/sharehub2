package controller;

import com.lowagie.text.Chunk;
import com.lowagie.text.Document;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.FontFactory;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.Rectangle;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import dao.DBConnection;
import java.awt.Color;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.text.DateFormatSymbols;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/MonthlyReportServlet")
public class MonthlyReportServlet extends HttpServlet {

    private static final Color GREEN = new Color(46, 125, 50);
    private static final Color LIGHT_GREEN = new Color(232, 245, 233);
    private static final Color LIGHT_GRAY = new Color(245, 247, 250);
    private static final Color TEXT_DARK = new Color(17, 24, 39);
    private static final Color TEXT_MUTED = new Color(85, 99, 116);

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        int userId = parseInt(String.valueOf(session.getAttribute("userId")), -1);
        if (userId <= 0) {
            response.sendRedirect("login.jsp");
            return;
        }

        int month = parseInt(request.getParameter("month"), -1);
        int year = parseInt(request.getParameter("year"), -1);
        if (month < 1 || month > 12 || year < 2020 || year > 2100) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid report month or year.");
            return;
        }

        boolean adminReport = isAdmin(session);
        String preparedFor = resolvePreparedFor(session, adminReport);
        ReportStats stats;
        try (Connection conn = DBConnection.getConnection()) {
            if (conn == null) {
                response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Database connection failed.");
                return;
            }
            stats = loadReportStats(conn, month, year, adminReport, userId);
        } catch (SQLException ex) {
            throw new ServletException("Failed to generate monthly report.", ex);
        }

        String monthName = new DateFormatSymbols().getMonths()[month - 1];
        String filename = "ShareHub_Monthly_Sustainability_Report_" + year + "_"
                + twoDigits(month) + ".pdf";

        response.setContentType("application/pdf");
        response.setHeader("Content-Disposition", "attachment; filename=\"" + filename + "\"");

        ServletOutputStream out = response.getOutputStream();
        try {
            writePdf(out, stats, monthName, year, preparedFor, adminReport);
        } catch (DocumentException ex) {
            throw new ServletException("Failed to write PDF report.", ex);
        } finally {
            out.flush();
        }
    }

    private ReportStats loadReportStats(Connection conn, int month, int year,
            boolean adminReport, int userId) throws SQLException {

        Calendar cal = Calendar.getInstance();
        cal.clear();
        cal.set(Calendar.YEAR, year);
        cal.set(Calendar.MONTH, month - 1);
        cal.set(Calendar.DAY_OF_MONTH, 1);
        Timestamp start = new Timestamp(cal.getTimeInMillis());
        cal.add(Calendar.MONTH, 1);
        Timestamp end = new Timestamp(cal.getTimeInMillis());

        ReportStats stats = new ReportStats();

        String donationScope = adminReport ? "" : " AND donor_id = ?";
        String requestScope = adminReport ? "" : " AND user_id = ?";

        stats.totalDonationsSubmitted = count(conn,
                "SELECT COUNT(*) FROM donations WHERE created_at >= ? AND created_at < ?" + donationScope,
                start, end, userId, adminReport);
        stats.approvedDonations = count(conn,
                "SELECT COUNT(*) FROM donations WHERE created_at >= ? AND created_at < ? "
                + "AND LOWER(COALESCE(status,'')) IN ('available','reserved','completed')" + donationScope,
                start, end, userId, adminReport);
        stats.rejectedDonations = count(conn,
                "SELECT COUNT(*) FROM donations WHERE created_at >= ? AND created_at < ? "
                + "AND LOWER(COALESCE(status,'')) = 'rejected'" + donationScope,
                start, end, userId, adminReport);
        stats.completedDonations = count(conn,
                "SELECT COUNT(*) FROM donations WHERE created_at >= ? AND created_at < ? "
                + "AND LOWER(COALESCE(status,'')) = 'completed'" + donationScope,
                start, end, userId, adminReport);
        stats.activeDonations = count(conn,
                "SELECT COUNT(*) FROM donations WHERE created_at >= ? AND created_at < ? "
                + "AND LOWER(COALESCE(status,'')) IN ('available','reserved')" + donationScope,
                start, end, userId, adminReport);
        stats.expiredDonations = count(conn,
                "SELECT COUNT(*) FROM donations WHERE created_at >= ? AND created_at < ? "
                + "AND LOWER(COALESCE(status,'')) = 'expired'" + donationScope,
                start, end, userId, adminReport);

        stats.totalRequestsSubmitted = count(conn,
                "SELECT COUNT(*) FROM requests WHERE created_at >= ? AND created_at < ?" + requestScope,
                start, end, userId, adminReport);
        stats.approvedRequests = count(conn,
                "SELECT COUNT(*) FROM requests WHERE created_at >= ? AND created_at < ? "
                + "AND LOWER(COALESCE(status,'')) IN ('approved','received pending','completed')" + requestScope,
                start, end, userId, adminReport);
        stats.rejectedRequests = count(conn,
                "SELECT COUNT(*) FROM requests WHERE created_at >= ? AND created_at < ? "
                + "AND LOWER(COALESCE(status,'')) = 'rejected'" + requestScope,
                start, end, userId, adminReport);
        stats.completedRequests = count(conn,
                "SELECT COUNT(*) FROM requests WHERE created_at >= ? AND created_at < ? "
                + "AND LOWER(COALESCE(status,'')) = 'completed'" + requestScope,
                start, end, userId, adminReport);

        if (adminReport) {
            stats.completedDonationTransactions = countCompletedTransactions(conn, start, end);
        } else {
            stats.completedDonationTransactions = countCompletedTransactionsForUser(conn, start, end, userId);
        }
        stats.itemsSuccessfullyReused = stats.completedDonationTransactions;

        stats.books = categoryCount(conn, start, end, adminReport, userId, "Books & Study Materials");
        stats.electronics = categoryCount(conn, start, end, adminReport, userId, "Electronics & Gadgets");
        stats.clothes = categoryCount(conn, start, end, adminReport, userId, "Clothes & Accessories");
        stats.household = categoryCount(conn, start, end, adminReport, userId, "Household & Hostel Items");
        stats.others = categoryCount(conn, start, end, adminReport, userId, "Others / Miscellaneous");

        return stats;
    }

    private int count(Connection conn, String sql, Timestamp start, Timestamp end,
            int userId, boolean adminReport) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setTimestamp(1, start);
            ps.setTimestamp(2, end);
            if (!adminReport) {
                ps.setInt(3, userId);
            }
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    private int countCompletedTransactions(Connection conn, Timestamp start, Timestamp end)
            throws SQLException {
        String sql = "SELECT COUNT(*) FROM requests r "
                + "JOIN donations d ON d.donation_id = r.donation_id "
                + "WHERE r.created_at >= ? AND r.created_at < ? "
                + "AND LOWER(COALESCE(r.status,'')) = 'completed'";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setTimestamp(1, start);
            ps.setTimestamp(2, end);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    private int countCompletedTransactionsForUser(Connection conn, Timestamp start,
            Timestamp end, int userId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM requests r "
                + "JOIN donations d ON d.donation_id = r.donation_id "
                + "WHERE r.created_at >= ? AND r.created_at < ? "
                + "AND LOWER(COALESCE(r.status,'')) = 'completed' "
                + "AND (r.user_id = ? OR d.donor_id = ?)";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setTimestamp(1, start);
            ps.setTimestamp(2, end);
            ps.setInt(3, userId);
            ps.setInt(4, userId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    private int categoryCount(Connection conn, Timestamp start, Timestamp end,
            boolean adminReport, int userId, String category) throws SQLException {
        String scope = adminReport ? "" : " AND donor_id = ?";
        String sql = "SELECT COUNT(*) FROM donations WHERE created_at >= ? AND created_at < ? "
                + "AND COALESCE(NULLIF(TRIM(category),''),'Others / Miscellaneous') = ?" + scope;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setTimestamp(1, start);
            ps.setTimestamp(2, end);
            ps.setString(3, category);
            if (!adminReport) {
                ps.setInt(4, userId);
            }
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    private void writePdf(ServletOutputStream out, ReportStats stats, String monthName,
            int year, String preparedFor, boolean adminReport)
            throws DocumentException {

        Document document = new Document(PageSize.A4, 42, 42, 42, 42);
        PdfWriter.getInstance(document, out);
        document.open();

        Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 18, TEXT_DARK);
        Font subFont = FontFactory.getFont(FontFactory.HELVETICA, 10, TEXT_MUTED);
        Font sectionFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 12, GREEN);

        Paragraph title = new Paragraph("ShareHub Monthly Sustainability Report", titleFont);
        title.setAlignment(Element.ALIGN_CENTER);
        title.setSpacingAfter(8);
        document.add(title);

        Paragraph meta = new Paragraph(monthName + " " + year + " | "
                + (adminReport ? "Platform-wide report" : "Personal contribution report")
                + " | Prepared for: " + preparedFor, subFont);
        meta.setAlignment(Element.ALIGN_CENTER);
        meta.setSpacingAfter(16);
        document.add(meta);

        addImpactBanner(document, stats);

        addSection(document, "A. Donation Statistics", sectionFont);
        addStatsTable(document, new String[][]{
            {"Total Donations Submitted", String.valueOf(stats.totalDonationsSubmitted)},
            {"Approved Donations", String.valueOf(stats.approvedDonations)},
            {"Rejected Donations", String.valueOf(stats.rejectedDonations)},
            {"Completed Donations", String.valueOf(stats.completedDonations)},
            {"Active Donations", String.valueOf(stats.activeDonations)},
            {"Expired Donations", String.valueOf(stats.expiredDonations)}
        });

        addSection(document, "B. Request Statistics", sectionFont);
        addStatsTable(document, new String[][]{
            {"Total Requests Submitted", String.valueOf(stats.totalRequestsSubmitted)},
            {"Approved Requests", String.valueOf(stats.approvedRequests)},
            {"Rejected Requests", String.valueOf(stats.rejectedRequests)},
            {"Completed Requests", String.valueOf(stats.completedRequests)}
        });

        addSection(document, "C. Sustainability Impact", sectionFont);
        addStatsTable(document, new String[][]{
            {"Items Successfully Reused", String.valueOf(stats.itemsSuccessfullyReused)},
            {"Completed Donation Transactions", String.valueOf(stats.completedDonationTransactions)}
        });

        addSection(document, "D. Category Breakdown", sectionFont);
        addStatsTable(document, new String[][]{
            {"Books & Study Materials", String.valueOf(stats.books)},
            {"Electronics", String.valueOf(stats.electronics)},
            {"Clothes & Accessories", String.valueOf(stats.clothes)},
            {"Household & Hostel Items", String.valueOf(stats.household)},
            {"Others", String.valueOf(stats.others)}
        });

        addSection(document, "E. Monthly Summary Statement", sectionFont);
        Paragraph summary = new Paragraph(buildSummaryStatement(stats, monthName, year, adminReport),
                FontFactory.getFont(FontFactory.HELVETICA, 10, TEXT_DARK));
        summary.setLeading(15);
        summary.setSpacingAfter(16);
        document.add(summary);

        Paragraph footer = new Paragraph("Generated by ShareHub on "
                + new SimpleDateFormat("dd MMM yyyy, h:mm a").format(new Date()),
                FontFactory.getFont(FontFactory.HELVETICA_OBLIQUE, 9, TEXT_MUTED));
        footer.setAlignment(Element.ALIGN_RIGHT);
        document.add(footer);

        document.close();
    }

    private void addImpactBanner(Document document, ReportStats stats)
            throws DocumentException {
        PdfPTable table = new PdfPTable(3);
        table.setWidthPercentage(100);
        table.setWidths(new float[]{1f, 1f, 1f});
        table.setSpacingAfter(14);
        addBannerCell(table, "Donations Submitted", stats.totalDonationsSubmitted);
        addBannerCell(table, "Requests Submitted", stats.totalRequestsSubmitted);
        addBannerCell(table, "Items Reused", stats.itemsSuccessfullyReused);
        document.add(table);
    }

    private void addBannerCell(PdfPTable table, String label, int value) {
        Font numberFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 17, GREEN);
        Font labelFont = FontFactory.getFont(FontFactory.HELVETICA, 9, TEXT_MUTED);
        Paragraph p = new Paragraph();
        p.add(new Chunk(String.valueOf(value), numberFont));
        p.add(Chunk.NEWLINE);
        p.add(new Chunk(label, labelFont));
        PdfPCell cell = new PdfPCell(p);
        cell.setBackgroundColor(LIGHT_GREEN);
        cell.setBorderColor(new Color(190, 224, 194));
        cell.setPadding(12);
        cell.setHorizontalAlignment(Element.ALIGN_CENTER);
        table.addCell(cell);
    }

    private void addSection(Document document, String heading, Font font)
            throws DocumentException {
        Paragraph p = new Paragraph(heading, font);
        p.setSpacingBefore(8);
        p.setSpacingAfter(6);
        document.add(p);
    }

    private void addStatsTable(Document document, String[][] rows)
            throws DocumentException {
        PdfPTable table = new PdfPTable(2);
        table.setWidthPercentage(100);
        table.setWidths(new float[]{3.2f, 1f});
        table.setSpacingAfter(8);
        for (int i = 0; i < rows.length; i++) {
            addTableCell(table, rows[i][0], false);
            addTableCell(table, rows[i][1], true);
        }
        document.add(table);
    }

    private void addTableCell(PdfPTable table, String text, boolean valueCell) {
        Font font = FontFactory.getFont(valueCell ? FontFactory.HELVETICA_BOLD : FontFactory.HELVETICA,
                10, TEXT_DARK);
        PdfPCell cell = new PdfPCell(new Phrase(text, font));
        cell.setPadding(8);
        cell.setBorder(Rectangle.BOTTOM);
        cell.setBorderColor(new Color(225, 230, 235));
        cell.setBackgroundColor(valueCell ? Color.WHITE : LIGHT_GRAY);
        cell.setHorizontalAlignment(valueCell ? Element.ALIGN_CENTER : Element.ALIGN_LEFT);
        table.addCell(cell);
    }

    private String buildSummaryStatement(ReportStats stats, String monthName, int year,
            boolean adminReport) {
        if (stats.itemsSuccessfullyReused > 0 || stats.completedDonationTransactions > 0) {
            return "In " + monthName + " " + year + ", ShareHub supported "
                    + stats.itemsSuccessfullyReused + " successfully reused item(s) and "
                    + stats.completedDonationTransactions + " completed donation transaction(s). "
                    + "These activities show continued participation in reuse, reduced waste, "
                    + "and community support within UMT.";
        }
        return "In " + monthName + " " + year + ", ShareHub recorded "
                + stats.totalDonationsSubmitted + " donation submission(s) and "
                + stats.totalRequestsSubmitted + " request submission(s). "
                + (adminReport
                ? "This report can support monitoring, moderation review, and sustainability planning."
                : "Your participation helps build a reuse culture within the UMT community.");
    }

    private boolean isAdmin(HttpSession session) {
        Object roleObj = session.getAttribute("role");
        String role = roleObj == null ? "" : roleObj.toString().trim().toLowerCase();
        return role.contains("admin");
    }

    private String resolvePreparedFor(HttpSession session, boolean adminReport) {
        Object nameObj = session.getAttribute("username");
        String name = nameObj == null ? "" : nameObj.toString().trim();
        if (name.length() == 0) {
            return adminReport ? "ShareHub Admin" : "ShareHub User";
        }
        return name;
    }

    private int parseInt(String value, int fallback) {
        try {
            return Integer.parseInt(value == null ? "" : value.trim());
        } catch (NumberFormatException ex) {
            return fallback;
        }
    }

    private String twoDigits(int value) {
        return value < 10 ? "0" + value : String.valueOf(value);
    }

    private static class ReportStats {
        int totalDonationsSubmitted;
        int approvedDonations;
        int rejectedDonations;
        int completedDonations;
        int activeDonations;
        int expiredDonations;
        int totalRequestsSubmitted;
        int approvedRequests;
        int rejectedRequests;
        int completedRequests;
        int itemsSuccessfullyReused;
        int completedDonationTransactions;
        int books;
        int electronics;
        int clothes;
        int household;
        int others;
    }
}
