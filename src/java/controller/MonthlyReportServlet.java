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
    private static final Color DARK_GREEN = new Color(27, 94, 32);
    private static final Color LIGHT_GREEN = new Color(232, 245, 233);
    private static final Color LIGHT_GRAY = new Color(245, 247, 250);
    private static final Color BORDER = new Color(218, 226, 232);
    private static final Color WHITE = Color.WHITE;
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
        String filename = (adminReport
                ? "ShareHub_Monthly_Platform_Report_"
                : "ShareHub_Monthly_Sustainability_Report_")
                + year + "_" + twoDigits(month) + ".pdf";

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

        Document document = new Document(PageSize.A4, 36, 36, 34, 34);
        PdfWriter.getInstance(document, out);
        document.open();

        addReportHeader(document, monthName, year, preparedFor, adminReport);
        addKpiStrip(document, stats, adminReport);

        addTwoColumnStats(document,
                "DONATION BREAKDOWN",
                new String[][]{
                    {"Submitted", String.valueOf(stats.totalDonationsSubmitted)},
                    {"Approved", String.valueOf(stats.approvedDonations)},
                    {"Rejected", String.valueOf(stats.rejectedDonations)},
                    {"Completed", String.valueOf(stats.completedDonations)},
                    {"Active", String.valueOf(stats.activeDonations)},
                    {"Expired", String.valueOf(stats.expiredDonations)}
                },
                "REQUEST BREAKDOWN",
                new String[][]{
                    {"Submitted", String.valueOf(stats.totalRequestsSubmitted)},
                    {"Approved", String.valueOf(stats.approvedRequests)},
                    {"Rejected", String.valueOf(stats.rejectedRequests)},
                    {"Completed", String.valueOf(stats.completedRequests)},
                    {"Reuse transactions", String.valueOf(stats.completedDonationTransactions)}
                });

        if (adminReport) {
            addTwoColumnStats(document,
                    "CATEGORY DISTRIBUTION",
                    categoryRows(stats),
                    "ADMINISTRATIVE SNAPSHOT",
                    new String[][]{
                        {"Moderation outcomes", String.valueOf(stats.approvedDonations + stats.rejectedDonations + stats.approvedRequests + stats.rejectedRequests)},
                        {"Listings to monitor", String.valueOf(stats.activeDonations)},
                        {"Expired listings", String.valueOf(stats.expiredDonations)},
                        {"Top active category", topCategory(stats)}
                    });
        } else {
            addTwoColumnStats(document,
                    "CATEGORY BREAKDOWN",
                    categoryRows(stats),
                    "PERSONAL IMPACT",
                    new String[][]{
                        {"Items received or donated", String.valueOf(stats.itemsSuccessfullyReused)},
                        {"Completed reuse transactions", String.valueOf(stats.completedDonationTransactions)},
                        {"Requests submitted", String.valueOf(stats.totalRequestsSubmitted)},
                        {"Top category", topCategory(stats)}
                    });
        }

        addImpactNarrative(document, stats, adminReport);
        addSummaryBox(document, adminReport ? "PLATFORM SUMMARY" : "MONTHLY SUMMARY",
                buildSummaryStatement(stats, monthName, year, adminReport, preparedFor));

        Paragraph footer = new Paragraph("Generated by ShareHub on "
                + new SimpleDateFormat("dd MMM yyyy, h:mm a").format(new Date()),
                FontFactory.getFont(FontFactory.HELVETICA_OBLIQUE, 9, TEXT_MUTED));
        footer.setAlignment(Element.ALIGN_RIGHT);
        document.add(footer);

        document.close();
    }

    private void addReportHeader(Document document, String monthName, int year,
            String preparedFor, boolean adminReport) throws DocumentException {
        PdfPTable header = new PdfPTable(1);
        header.setWidthPercentage(100);
        header.setSpacingAfter(14);

        String title = adminReport
                ? "SHAREHUB MONTHLY PLATFORM REPORT"
                : "SHAREHUB MONTHLY SUSTAINABILITY REPORT";
        PdfPCell top = new PdfPCell();
        top.setBackgroundColor(DARK_GREEN);
        top.setBorder(Rectangle.NO_BORDER);
        top.setPadding(14);

        Paragraph titleP = new Paragraph(title,
                FontFactory.getFont(FontFactory.HELVETICA_BOLD, 16, WHITE));
        titleP.setAlignment(Element.ALIGN_CENTER);
        titleP.setSpacingAfter(6);
        top.addElement(titleP);

        String scope = adminReport ? "Platform-wide | All users and donations" : "Personal contribution report";
        Paragraph metaP = new Paragraph(scope + " | " + monthName + " " + year
                + " | Prepared for: " + preparedFor,
                FontFactory.getFont(FontFactory.HELVETICA, 9, new Color(225, 245, 228)));
        metaP.setAlignment(Element.ALIGN_CENTER);
        top.addElement(metaP);
        header.addCell(top);
        document.add(header);
    }

    private void addKpiStrip(Document document, ReportStats stats, boolean adminReport)
            throws DocumentException {
        PdfPTable table = new PdfPTable(3);
        table.setWidthPercentage(100);
        table.setWidths(new float[]{1f, 1f, 1f});
        table.setSpacingAfter(12);
        if (adminReport) {
            addBannerCell(table, "Total donations", stats.totalDonationsSubmitted);
            addBannerCell(table, "Total requests", stats.totalRequestsSubmitted);
            addBannerCell(table, "Items reused", stats.itemsSuccessfullyReused);
        } else {
            addBannerCell(table, "Donations Submitted", stats.totalDonationsSubmitted);
            addBannerCell(table, "Requests Submitted", stats.totalRequestsSubmitted);
            addBannerCell(table, "Items Reused", stats.itemsSuccessfullyReused);
        }
        document.add(table);
    }

    private void addBannerCell(PdfPTable table, String label, int value) {
        Font numberFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 20, GREEN);
        Font labelFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 8, TEXT_MUTED);
        Paragraph p = new Paragraph();
        p.add(new Chunk(String.valueOf(value), numberFont));
        p.add(Chunk.NEWLINE);
        p.add(new Chunk(label, labelFont));
        PdfPCell cell = new PdfPCell(p);
        cell.setBackgroundColor(LIGHT_GREEN);
        cell.setBorderColor(new Color(190, 224, 194));
        cell.setPadding(13);
        cell.setHorizontalAlignment(Element.ALIGN_CENTER);
        table.addCell(cell);
    }

    private void addTwoColumnStats(Document document, String leftTitle, String[][] leftRows,
            String rightTitle, String[][] rightRows)
            throws DocumentException {
        PdfPTable wrapper = new PdfPTable(2);
        wrapper.setWidthPercentage(100);
        wrapper.setWidths(new float[]{1f, 1f});
        wrapper.setSpacingAfter(12);
        wrapper.addCell(statsCard(leftTitle, leftRows));
        wrapper.addCell(statsCard(rightTitle, rightRows));
        document.add(wrapper);
    }

    private PdfPCell statsCard(String title, String[][] rows) throws DocumentException {
        PdfPTable table = new PdfPTable(2);
        table.setWidthPercentage(100);
        table.setWidths(new float[]{2.7f, 1f});

        PdfPCell heading = new PdfPCell(new Phrase(title,
                FontFactory.getFont(FontFactory.HELVETICA_BOLD, 9, GREEN)));
        heading.setColspan(2);
        heading.setPadding(8);
        heading.setBorder(Rectangle.BOTTOM);
        heading.setBorderColor(BORDER);
        heading.setBackgroundColor(WHITE);
        table.addCell(heading);

        for (int i = 0; i < rows.length; i++) {
            addTableCell(table, rows[i][0], false, i);
            addTableCell(table, rows[i][1], true, i);
        }

        PdfPCell card = new PdfPCell(table);
        card.setPadding(0);
        card.setBorder(Rectangle.BOX);
        card.setBorderColor(BORDER);
        card.setBackgroundColor(WHITE);
        return card;
    }

    private void addTableCell(PdfPTable table, String text, boolean valueCell, int rowIndex) {
        Font font = FontFactory.getFont(valueCell ? FontFactory.HELVETICA_BOLD : FontFactory.HELVETICA,
                9, TEXT_DARK);
        PdfPCell cell = new PdfPCell(new Phrase(text, font));
        cell.setPadding(7);
        cell.setBorder(Rectangle.BOTTOM);
        cell.setBorderColor(BORDER);
        cell.setBackgroundColor((rowIndex % 2 == 0) ? LIGHT_GRAY : WHITE);
        cell.setHorizontalAlignment(valueCell ? Element.ALIGN_CENTER : Element.ALIGN_LEFT);
        table.addCell(cell);
    }

    private void addImpactNarrative(Document document, ReportStats stats, boolean adminReport)
            throws DocumentException {
        String title = adminReport ? "SUSTAINABILITY IMPACT" : "YOUR SHAREHUB IMPACT";
        String body;
        if (stats.itemsSuccessfullyReused > 0) {
            body = "This month recorded " + stats.itemsSuccessfullyReused
                    + " reused item(s). Each completed handover keeps a useful item in circulation "
                    + "and reduces unnecessary waste in the UMT community.";
        } else if (adminReport) {
            body = "No completed reuse transactions were recorded this month. The "
                    + stats.activeDonations + " active donation listing(s) remain potential reuse opportunities.";
        } else {
            body = "No items were reused through this account this month. Donating an item or requesting "
                    + "an available listing helps build a stronger reuse culture at UMT.";
        }
        addSummaryBox(document, title, body);
    }

    private void addSummaryBox(Document document, String title, String body)
            throws DocumentException {
        PdfPTable table = new PdfPTable(1);
        table.setWidthPercentage(100);
        table.setSpacingAfter(12);

        Paragraph p = new Paragraph();
        p.add(new Chunk(title + "\n",
                FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10, GREEN)));
        p.add(new Chunk(body,
                FontFactory.getFont(FontFactory.HELVETICA, 9, TEXT_DARK)));
        p.setLeading(14);

        PdfPCell cell = new PdfPCell(p);
        cell.setPadding(12);
        cell.setBackgroundColor(LIGHT_GRAY);
        cell.setBorder(Rectangle.BOX);
        cell.setBorderColor(BORDER);
        table.addCell(cell);
        document.add(table);
    }

    private String[][] categoryRows(ReportStats stats) {
        return new String[][]{
            {"Books & Study Materials", String.valueOf(stats.books)},
            {"Electronics & Gadgets", String.valueOf(stats.electronics)},
            {"Clothes & Accessories", String.valueOf(stats.clothes)},
            {"Household & Hostel Items", String.valueOf(stats.household)},
            {"Others", String.valueOf(stats.others)}
        };
    }

    private String topCategory(ReportStats stats) {
        int max = stats.books;
        String label = "Books";
        if (stats.electronics > max) {
            max = stats.electronics;
            label = "Electronics";
        }
        if (stats.clothes > max) {
            max = stats.clothes;
            label = "Clothes";
        }
        if (stats.household > max) {
            max = stats.household;
            label = "Household";
        }
        if (stats.others > max) {
            max = stats.others;
            label = "Others";
        }
        return max == 0 ? "No activity" : label + " (" + max + ")";
    }

    private String buildSummaryStatement(ReportStats stats, String monthName, int year,
            boolean adminReport, String preparedFor) {
        if (stats.itemsSuccessfullyReused > 0 || stats.completedDonationTransactions > 0) {
            if (adminReport) {
                return "In " + monthName + " " + year + ", the ShareHub platform recorded "
                        + stats.totalDonationsSubmitted + " donation submission(s), "
                        + stats.totalRequestsSubmitted + " request submission(s), and "
                        + stats.completedDonationTransactions + " completed donation transaction(s). "
                        + "These platform-wide results help the administrator monitor student participation, "
                        + "moderation outcomes, and the reuse impact created through ShareHub.";
            }
            return "In " + monthName + " " + year + ", ShareHub supported "
                    + stats.itemsSuccessfullyReused + " successfully reused item(s) and "
                    + stats.completedDonationTransactions + " completed donation transaction(s). "
                    + "These activities show continued participation in reuse, reduced waste, "
                    + "and community support within UMT.";
        }
        if (adminReport) {
            return "In " + monthName + " " + year + ", ShareHub recorded "
                    + stats.totalDonationsSubmitted + " donation submission(s) and "
                    + stats.totalRequestsSubmitted + " request submission(s). "
                    + "There were " + stats.activeDonations + " active listing(s), "
                    + stats.rejectedRequests + " rejected request(s), and "
                    + stats.expiredDonations + " expired listing(s). This report supports moderation review, "
                    + "activity monitoring, and sustainability planning.";
        }
        return "In " + monthName + " " + year + ", " + preparedFor + " submitted "
                + stats.totalDonationsSubmitted + " donation(s) and "
                + stats.totalRequestsSubmitted + " request(s). "
                + "Personal contribution reports help students understand how their activity supports reuse "
                + "and reduces unnecessary waste within the UMT community.";
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
