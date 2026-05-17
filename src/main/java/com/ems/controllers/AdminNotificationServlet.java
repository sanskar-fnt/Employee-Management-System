package com.ems.controllers;

import com.ems.model.AdminNotification;
import com.ems.model.User;
import com.ems.service.NotificationService;
import com.ems.util.CsrfUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;

/**
 * JSON endpoint for the admin bell-icon popover.
 *
 *   GET  /admin/notifications              → { unreadCount, items: [...] }
 *   POST /admin/notifications?action=mark_read&id=N
 *   POST /admin/notifications?action=mark_all_read
 *   POST /admin/notifications?action=clear_all
 *
 * All POSTs require a valid CSRF token. Admin-only.
 */
@WebServlet("/admin/notifications")
public class AdminNotificationServlet extends HttpServlet {

    private final NotificationService notificationService = new NotificationService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!ensureAdmin(request, response)) return;

        List<AdminNotification> items = notificationService.getAdminNotifications();
        int unread = notificationService.getUnreadAdminCount();

        writeJson(response, buildJson(items, unread));
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!ensureAdmin(request, response)) return;
        if (!CsrfUtil.isValid(request)) {
            writeJson(response, "{\"ok\":false,\"error\":\"csrf\"}");
            return;
        }

        String action = request.getParameter("action");
        if ("mark_read".equals(action)) {
            try {
                long id = Long.parseLong(request.getParameter("id"));
                notificationService.markAdminRead(id);
            } catch (Exception ignored) {}
        } else if ("mark_all_read".equals(action)) {
            notificationService.markAllAdminRead();
        } else if ("clear_all".equals(action)) {
            notificationService.clearAllAdmin();
        } else {
            writeJson(response, "{\"ok\":false,\"error\":\"unknown_action\"}");
            return;
        }

        List<AdminNotification> items = notificationService.loadAdmin(false, 30);
        int unread = notificationService.getUnreadAdminCount();
        writeJson(response, buildJson(items, unread));
    }

    private boolean ensureAdmin(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            writeJson(response, "{\"ok\":false,\"error\":\"unauthenticated\"}");
            return false;
        }
        User user = (User) session.getAttribute("user");
        if (user == null || !"ADMIN".equalsIgnoreCase(user.getRole())) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            writeJson(response, "{\"ok\":false,\"error\":\"forbidden\"}");
            return false;
        }
        request.setAttribute("csrfToken", CsrfUtil.ensureToken(session));
        return true;
    }

    private void writeJson(HttpServletResponse response, String body) throws IOException {
        response.setContentType("application/json; charset=UTF-8");
        response.setHeader("Cache-Control", "no-store");
        try (PrintWriter out = response.getWriter()) {
            out.print(body);
        }
    }

    private String buildJson(List<AdminNotification> items, int unread) {
        StringBuilder sb = new StringBuilder(256);
        sb.append("{\"ok\":true,\"unreadCount\":").append(unread).append(",\"items\":[");
        for (int i = 0; i < items.size(); i++) {
            if (i > 0) sb.append(',');
            AdminNotification a = items.get(i);
            sb.append('{')
              .append("\"id\":").append(a.getId()).append(',')
              .append("\"type\":\"").append(jsonEscape(a.getType())).append("\",")
              .append("\"severity\":\"").append(jsonEscape(a.getSeverity())).append("\",")
              .append("\"title\":\"").append(jsonEscape(a.getTitle())).append("\",")
              .append("\"message\":\"").append(jsonEscape(a.getMessage())).append("\",")
              .append("\"href\":\"").append(jsonEscape(a.getHref())).append("\",")
              .append("\"createdAt\":\"").append(a.getCreatedAt() == null ? "" : a.getCreatedAt().toString()).append("\",")
              .append("\"unread\":").append(a.isUnread())
              .append('}');
        }
        sb.append("]}");
        return sb.toString();
    }

    private String jsonEscape(String v) {
        if (v == null) return "";
        StringBuilder sb = new StringBuilder(v.length() + 8);
        for (int i = 0; i < v.length(); i++) {
            char c = v.charAt(i);
            switch (c) {
                case '\\': sb.append("\\\\"); break;
                case '"':  sb.append("\\\""); break;
                case '\n': sb.append("\\n");  break;
                case '\r': sb.append("\\r");  break;
                case '\t': sb.append("\\t");  break;
                default:
                    if (c < 0x20) sb.append(String.format("\\u%04x", (int) c));
                    else          sb.append(c);
            }
        }
        return sb.toString();
    }
}
