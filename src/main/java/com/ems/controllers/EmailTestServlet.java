package com.ems.controllers;

import com.ems.model.User;
import com.ems.service.EmailService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.io.PrintWriter;

/**
 * Temporary admin-only smoke test for EmailService.
 *
 *   GET /email-test?to=someone@example.com
 *
 * DEV ONLY — disabled in production.
 * The @WebServlet mapping below is intentionally commented out so this
 * route is unreachable. Re-enable temporarily by uncommenting the
 * annotation, never leave it active in a deployed build.
 */
// @WebServlet("/email-test")  // DEV ONLY - disabled in production
public class EmailTestServlet extends HttpServlet {

    private final EmailService emailService = new EmailService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        User user = (User) session.getAttribute("user");
        if (user == null || !"ADMIN".equalsIgnoreCase(user.getRole())) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Admin access required.");
            return;
        }

        String to = request.getParameter("to");
        response.setContentType("text/plain; charset=UTF-8");
        try (PrintWriter out = response.getWriter()) {
            if (to == null || to.trim().isEmpty()) {
                out.println("Usage: /email-test?to=someone@example.com");
                return;
            }
            boolean ok = emailService.sendEmail(
                    to.trim(),
                    "EMS test email",
                    "Hello — this is a test from EMS EmailService.\n"
                            + "If you can read this, SMTP is configured correctly.");
            out.println(ok
                    ? "OK: email dispatched to " + to
                    : "FAILED: see server log for the underlying MessagingException.");
        }
    }
}
