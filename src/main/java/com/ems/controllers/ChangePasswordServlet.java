package com.ems.controllers;

import com.ems.model.User;
import com.ems.service.AuditService;
import com.ems.service.NotificationService;
import com.ems.service.UserService;
import com.ems.util.CsrfUtil;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

@WebServlet("/change-password")
public class ChangePasswordServlet extends HttpServlet {

    private final UserService         userService         = new UserService();
    private final AuditService        auditService        = new AuditService();
    private final NotificationService notificationService = new NotificationService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        request.setAttribute("csrfToken", CsrfUtil.ensureToken(session));

        String formError = (String) session.getAttribute("formError");
        if (formError != null) {
            session.removeAttribute("formError");
            request.setAttribute("formError", formError);
        }

        RequestDispatcher dispatcher = request.getRequestDispatcher("/WEB-INF/pages/changePassword.jsp");
        dispatcher.forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        if (!CsrfUtil.isValid(request)) {
            session.setAttribute("formError", "Invalid request token.");
            response.sendRedirect(request.getContextPath() + "/change-password");
            return;
        }

        User user = (User) session.getAttribute("user");
        String current  = request.getParameter("currentPassword");
        String fresh    = request.getParameter("newPassword");
        String confirm  = request.getParameter("confirmPassword");

        String error = validate(current, fresh, confirm);
        if (error == null && !userService.verifyPassword(user.getId(), current)) {
            error = "Current password is incorrect.";
        }
        if (error != null) {
            session.setAttribute("formError", error);
            response.sendRedirect(request.getContextPath() + "/change-password");
            return;
        }

        boolean updated = userService.updatePassword(user.getId(), fresh);
        if (!updated) {
            session.setAttribute("formError", "Could not update password. Please try again.");
            response.sendRedirect(request.getContextPath() + "/change-password");
            return;
        }
        userService.clearMustChangePassword(user.getId());
        user.setMustChangePassword(false);
        auditService.log(user.getId(), AuditService.PASSWORD_CHANGE, "USER", user.getId(),
                "user=" + user.getUsername());
        notificationService.notifyPasswordChange(user.getId(), user.getUsername());

        String target = "EMPLOYEE".equalsIgnoreCase(user.getRole())
                ? "/emp-dashboard" : "/dashboard";
        response.sendRedirect(request.getContextPath() + target);
    }

    private String validate(String current, String fresh, String confirm) {
        if (isBlank(current))   return "Enter your current password.";
        if (isBlank(fresh))     return "Enter a new password.";
        if (fresh.length() < 8) return "New password must be at least 8 characters.";
        if (!fresh.matches(".*[A-Za-z].*") || !fresh.matches(".*\\d.*"))
            return "New password must include letters and numbers.";
        if (!fresh.equals(confirm)) return "New passwords do not match.";
        if (fresh.equals(current))  return "New password must differ from the current password.";
        return null;
    }

    private boolean isBlank(String v) { return v == null || v.trim().isEmpty(); }
}
