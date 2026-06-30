package util;

import java.util.Properties;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ThreadFactory;
import javax.mail.Authenticator;
import javax.mail.Message;
import javax.mail.PasswordAuthentication;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;

/**
 * Lightweight async Gmail SMTP utility for ShareHub notifications.
 * Credentials are loaded from environment variables or JVM system properties.
 */
public final class EmailUtility {

    private static final String EMAIL_FOOTER = "\n\nWarm regards,\nShareHub Admin";

    private static final ExecutorService EMAIL_EXECUTOR = Executors.newSingleThreadExecutor(new ThreadFactory() {
        @Override
        public Thread newThread(Runnable runnable) {
            Thread thread = new Thread(runnable, "sharehub-email-worker");
            return thread;
        }
    });

    private EmailUtility() {
    }

    public static void sendNotificationAsync(final String recipientEmail, final String subject, final String bodyText) {
        if (isBlank(recipientEmail) || isBlank(subject) || isBlank(bodyText)) {
            return;
        }

        EMAIL_EXECUTOR.submit(new Runnable() {
            @Override
            public void run() {
                boolean sent = sendNotification(recipientEmail, subject, bodyText);
                if (sent) {
                    System.out.println("ShareHub email sent: " + subject + " -> " + recipientEmail);
                } else {
                    System.err.println("ShareHub email failed: " + subject + " -> " + recipientEmail);
                }
            }
        });
    }

    public static void sendWelcomeEmailAsync(String recipientEmail, String fullName) {
        String greetingName = greetingName(fullName);
        String body = withFooter("Hi " + greetingName + ",\n\n"
                + "Welcome to ShareHub! We are happy to have you in our student sharing community.\n\n"
                + "ShareHub helps students donate, request, and reuse useful items so fewer things go to waste. "
                + "Every shared book, tool, or daily item can support another student and encourage a more sustainable campus.\n\n"
                + "Thank you for joining us. We hope ShareHub makes it easier for you to give, receive, and share with care.");

        sendNotificationAsync(recipientEmail, "Welcome to ShareHub", body);
    }

    public static void sendDonationSubmittedEmailAsync(String recipientEmail, String fullName, String itemTitle) {
        String greetingName = greetingName(fullName);
        String safeTitle = isBlank(itemTitle) ? "your donation item" : itemTitle.trim();
        String body = withFooter("Hi " + greetingName + ",\n\n"
                + "Thank you for submitting \"" + safeTitle + "\" to ShareHub.\n\n"
                + "We have received your donation item successfully. It is now pending admin approval before it appears publicly for other students to request.\n\n"
                + "Your willingness to share helps students reuse helpful items and keeps our campus community supportive and sustainable.");

        sendNotificationAsync(recipientEmail, "ShareHub Donation Submitted", body);
    }

    public static boolean sendNotification(final String recipientEmail, final String subject, final String bodyText) {
        final MailConfig config = MailConfig.load();
        if (!config.isEnabled() || isBlank(recipientEmail) || isBlank(subject) || isBlank(bodyText)) {
            return false;
        }

        try {
            Session session = Session.getInstance(config.smtpProperties(), new Authenticator() {
                @Override
                protected PasswordAuthentication getPasswordAuthentication() {
                    return new PasswordAuthentication(config.username, config.appPassword);
                }
            });

            Message message = new MimeMessage(session);
            message.setFrom(new InternetAddress(config.fromAddress, config.fromDisplayName));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(recipientEmail));
            message.setSubject(subject);
            message.setText(bodyText);

            Transport.send(message);
            return true;
        } catch (Exception ex) {
            // Email must never break core workflow.
            System.err.println("ShareHub email send failed: " + ex.getMessage());
            return false;
        }
    }

    private static String firstNonBlank(String first, String second) {
        return isBlank(first) ? second : first;
    }

    public static String withFooter(String bodyText) {
        return (bodyText == null ? "" : bodyText.trim()) + EMAIL_FOOTER;
    }

    private static String greetingName(String fullName) {
        return isBlank(fullName) ? "there" : fullName.trim();
    }

    private static boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private static final class MailConfig {
        private final String host;
        private final String port;
        private final String username;
        private final String appPassword;
        private final String fromAddress;
        private final String fromDisplayName;

        private MailConfig(String host, String port, String username, String appPassword, String fromAddress, String fromDisplayName) {
            this.host = host;
            this.port = port;
            this.username = username;
            this.appPassword = appPassword;
            this.fromAddress = fromAddress;
            this.fromDisplayName = fromDisplayName;
        }

        private static MailConfig load() {
            String host = firstNonBlank(
                    System.getenv("SHAREHUB_SMTP_HOST"),
                    System.getProperty("sharehub.smtp.host", "smtp.gmail.com"));
            String port = firstNonBlank(
                    System.getenv("SHAREHUB_SMTP_PORT"),
                    System.getProperty("sharehub.smtp.port", "587"));
            String username = firstNonBlank(
                    System.getenv("SHAREHUB_SMTP_USER"),
                    System.getProperty("sharehub.smtp.user"));
            String appPassword = firstNonBlank(
                    System.getenv("SHAREHUB_SMTP_APP_PASSWORD"),
                    System.getProperty("sharehub.smtp.appPassword"));
            String fromAddress = firstNonBlank(
                    System.getenv("SHAREHUB_SMTP_FROM"),
                    System.getProperty("sharehub.smtp.from", username));
            String fromDisplayName = firstNonBlank(
                    System.getenv("SHAREHUB_SMTP_FROM_NAME"),
                    System.getProperty("sharehub.smtp.fromName", "ShareHub"));

            return new MailConfig(host, port, username, appPassword, fromAddress, fromDisplayName);
        }

        private boolean isEnabled() {
            return !isBlank(host)
                    && !isBlank(port)
                    && !isBlank(username)
                    && !isBlank(appPassword)
                    && !isBlank(fromAddress);
        }

        private Properties smtpProperties() {
            Properties properties = new Properties();
            properties.put("mail.smtp.auth", "true");
            properties.put("mail.smtp.starttls.enable", "true");
            properties.put("mail.smtp.host", host);
            properties.put("mail.smtp.port", port);
            properties.put("mail.smtp.connectiontimeout", "5000");
            properties.put("mail.smtp.timeout", "5000");
            properties.put("mail.smtp.writetimeout", "5000");
            return properties;
        }
    }
}
