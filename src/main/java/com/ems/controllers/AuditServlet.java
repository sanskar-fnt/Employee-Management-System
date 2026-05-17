package com.ems.controllers;

import com.ems.model.AuditLog;
import com.ems.model.User;
import com.ems.service.AuditService;
import com.ems.util.CsrfUtil;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.time.LocalDate;
import java.util.List;

@WebServlet("/audit")
public class AuditServlet extends HttpServlet {

    private final AuditService auditService = new AuditService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        request.setAttribute("csrfToken", CsrfUtil.ensureToken(session));

        User user = (User) session.getAttribute("user");
        if (user == null || !"ADMIN".equalsIgnoreCase(user.getRole())) {
            response.sendRedirect(request.getContextPath() + "/dashboard");
            return;
        }

        String action      = trimmed(request.getParameter("action"));
        Integer actorId    = parseInt(request.getParameter("actorUserId"));
        LocalDate from     = parseDate(request.getParameter("from"));
        LocalDate to       = parseDate(request.getParameter("to"));
        int page           = parsePage(request.getParameter("page"));
        int size           = parseSize(request.getParameter("size"));
        int offset         = (page - 1) * size;

        int total          = auditService.countLogs(action, actorId, from, to);
        int totalPages     = Math.max(1, (int) Math.ceil(total / (double) size));
        List<AuditLog> rows = auditService.findLogs(action, actorId, from, to, size, offset);
        List<String> distinctActions = auditService.getDistinctActions();

        request.setAttribute("rows",            rows);
        request.setAttribute("distinctActions", distinctActions);
        request.setAttribute("filterAction",    action == null ? "" : action);
        request.setAttribute("filterActorId",   actorId == null ? "" : actorId.toString());
        request.setAttribute("filterFrom",      from == null ? "" : from.toString());
        request.setAttribute("filterTo",        to   == null ? "" : to.toString());
        request.setAttribute("page",            page);
        request.setAttribute("size",            size);
        request.setAttribute("total",           total);
        request.setAttribute("totalPages",      totalPages);

        RequestDispatcher dispatcher = request.getRequestDispatcher("/WEB-INF/pages/audit.jsp");
        dispatcher.forward(request, response);
    }

    private String trimmed(String v) { return v == null ? null : (v.trim().isEmpty() ? null : v.trim()); }
    private Integer parseInt(String v)  { try { int i = Integer.parseInt(v); return i > 0 ? i : null; } catch (Exception e) { return null; } }
    private LocalDate parseDate(String v) { try { return v == null || v.trim().isEmpty() ? null : LocalDate.parse(v.trim()); } catch (Exception e) { return null; } }
    private int parsePage(String v) { try { int p = Integer.parseInt(v); return p < 1 ? 1 : p; } catch (Exception e) { return 1; } }
    private int parseSize(String v) {
        try { int s = Integer.parseInt(v); return s < 10 ? 10 : Math.min(s, 100); }
        catch (Exception e) { return 25; }
    }
}
