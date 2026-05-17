package com.ems.service;

import jakarta.mail.Authenticator;
import jakarta.mail.Message;
import jakarta.mail.MessagingException;
import jakarta.mail.PasswordAuthentication;
import jakarta.mail.Session;
import jakarta.mail.Transport;
import jakarta.mail.internet.AddressException;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;

import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Reusable Gmail SMTP sender.
 *
 * Credentials are read ONLY from the environment:
 *   EMS_EMAIL          → the Gmail address that will appear in the From header
 *   EMS_APP_PASSWORD   → a Gmail App Password (16 chars, NOT the normal Gmail login)
 *                        Generate at https://myaccount.google.com/apppasswords
 *                        (2-Step Verification must be enabled on the account.)
 *
 * If either variable is missing, every send is refused and a readable warning
 * is printed at startup and on the first send attempt. No fallback values
 * are baked into source.
 */
public class EmailService {

    private static final Logger LOGGER = Logger.getLogger(EmailService.class.getName());

    private static final String ENV_FROM = "EMS_EMAIL";
    private static final String ENV_PASS = "EMS_APP_PASSWORD";

    private static final String FROM_ADDRESS = System.getenv(ENV_FROM);
    private static final String APP_PASSWORD = System.getenv(ENV_PASS);

    private static final String SMTP_HOST = "smtp.gmail.com";
    private static final String SMTP_PORT = "587";

    // Static one-shot startup warning, so the message appears the moment the
    // class is loaded — not buried inside the first send attempt's logs.
    static {
        if (!isConfigured()) {
            String msg = "[EmailService] *** WARNING: SMTP credentials not configured. "
                    + "Set environment variables " + ENV_FROM + " and " + ENV_PASS
                    + " before sending email. All sendEmail() calls will be refused until set. ***";
            System.out.println(msg);
            LOGGER.warning(msg);
        }
    }

    private static boolean isConfigured() {
        return FROM_ADDRESS != null && !FROM_ADDRESS.trim().isEmpty()
            && APP_PASSWORD != null && !APP_PASSWORD.trim().isEmpty();
    }

    /** Build a Jakarta Mail Session with TLS + auth, per Gmail's requirements. */
    private Session buildSession() {
        Properties props = new Properties();
        props.put("mail.smtp.host", SMTP_HOST);
        props.put("mail.smtp.port", SMTP_PORT);
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");
        props.put("mail.smtp.starttls.required", "true");
        props.put("mail.smtp.ssl.protocols", "TLSv1.2");
        // 10s connect / 15s read — fail fast instead of hanging the request thread.
        props.put("mail.smtp.connectiontimeout", "10000");
        props.put("mail.smtp.timeout", "15000");
        props.put("mail.smtp.writetimeout", "15000");

        return Session.getInstance(props, new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(FROM_ADDRESS, APP_PASSWORD);
            }
        });
    }

    /**
     * Send a plain-text email. Returns true on success, false on failure.
     * Failures are logged; callers may also want to surface a user-facing message.
     */
    public boolean sendEmail(String to, String subject, String body) {
        System.out.println("[EmailService] sendEmail attempt -> to=" + to + " subject=" + subject);
        if (to == null || to.trim().isEmpty()) {
            System.out.println("[EmailService] aborting: 'to' is empty");
            LOGGER.warning("EmailService.sendEmail: 'to' is empty — aborting.");
            return false;
        }
        if (!isConfigured()) {
            String msg = "[EmailService] aborting: " + ENV_FROM + " or " + ENV_PASS
                    + " not set. Configure SMTP credentials in the environment and restart.";
            System.out.println(msg);
            LOGGER.warning(msg);
            return false;
        }
        System.out.println("[EmailService] using FROM=" + FROM_ADDRESS + " host=" + SMTP_HOST + ":" + SMTP_PORT);

        try {
            Session session = buildSession();
            MimeMessage message = new MimeMessage(session);
            message.setFrom(new InternetAddress(FROM_ADDRESS));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(to));
            message.setSubject(subject == null ? "" : subject);
            message.setText(body == null ? "" : body, "UTF-8");

            Transport.send(message);
            System.out.println("[EmailService] SUCCESS -> " + to);
            LOGGER.info("Email sent successfully to " + to);
            return true;
        } catch (AddressException e) {
            System.out.println("[EmailService] FAILED (AddressException): " + e.getMessage());
            e.printStackTrace();
            LOGGER.log(Level.WARNING, "Invalid email address: " + to, e);
        } catch (MessagingException e) {
            System.out.println("[EmailService] FAILED (MessagingException): " + e.getMessage());
            e.printStackTrace();
            LOGGER.log(Level.SEVERE, "Failed to send email to " + to, e);
        } catch (Exception e) {
            System.out.println("[EmailService] FAILED (Exception): " + e.getMessage());
            e.printStackTrace();
            LOGGER.log(Level.SEVERE, "Unexpected error sending email to " + to, e);
        }
        return false;
    }

    /**
     * Convenience overload for HTML bodies.
     */
    public boolean sendHtmlEmail(String to, String subject, String htmlBody) {
        if (to == null || to.trim().isEmpty()) return false;
        if (!isConfigured()) {
            LOGGER.warning("EmailService.sendHtmlEmail aborted: " + ENV_FROM + " / " + ENV_PASS + " not set.");
            return false;
        }
        try {
            Session session = buildSession();
            MimeMessage message = new MimeMessage(session);
            message.setFrom(new InternetAddress(FROM_ADDRESS));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(to));
            message.setSubject(subject == null ? "" : subject);
            message.setContent(htmlBody == null ? "" : htmlBody, "text/html; charset=UTF-8");

            Transport.send(message);
            LOGGER.info("HTML email sent successfully to " + to);
            return true;
        } catch (MessagingException e) {
            LOGGER.log(Level.SEVERE, "Failed to send HTML email to " + to, e);
            return false;
        }
    }

    /** Quick CLI smoke test. Run from your IDE or via `java com.ems.service.EmailService <to>`. */
    public static void main(String[] args) {
        String to = args.length > 0 ? args[0] : "test-recipient@example.com";
        boolean ok = new EmailService().sendEmail(
                to,
                "EMS test email",
                "If you can read this, EmailService.sendEmail is working.\n\n— EMS");
        System.out.println(ok ? "OK: email dispatched" : "FAILED: see logs above");
    }
}
