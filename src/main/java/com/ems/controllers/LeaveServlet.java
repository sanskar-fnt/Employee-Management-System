package com.ems.controllers;

import com.ems.model.LeaveRequest;
import com.ems.model.User;
import com.ems.service.AuditService;
import com.ems.service.LeaveService;
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

/**
 * /leaves
 *   GET  → renders leave.jsp with the appropriate view (admin sees all; employee sees their own + form).
 *   POST action=apply               → employee submits a new request
 *   POST action=approve|reject id=N → admin decides on a pending request
 */
@WebServlet("/leaves")
public class LeaveServlet extends HttpServlet {

    private final LeaveService leaveService = new LeaveService();
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
        boolean isAdmin = "ADMIN".equalsIgnoreCase(user.getRole());

        String flashOk  = (String) session.getAttribute("leaveSuccess");
        String flashErr = (String) session.getAttribute("leaveError");
        if (flashOk  != null) { session.removeAttribute("leaveSuccess"); request.setAttribute("leaveSuccess", flashOk); }
        if (flashErr != null) { session.removeAttribute("leaveError");   request.setAttribute("leaveError",   flashErr); }

        if (isAdmin) {
            String statusFilter = request.getParameter("status");
            int page    = parsePage(request.getParameter("page"));
            int size    = 20;
            int offset  = (page - 1) * size;
            int total   = leaveService.countAll(statusFilter);
            int pages   = Math.max(1, (int) Math.ceil(total / (double) size));
            List<LeaveRequest> rows = leaveService.findAll(statusFilter, size, offset);
            request.setAttribute("rows",         rows);
            request.setAttribute("pendingCount", leaveService.countPending());
            request.setAttribute("statusFilter", statusFilter == null ? "" : statusFilter);
            request.setAttribute("pageNum",      page);
            request.setAttribute("totalPages",   pages);
            request.setAttribute("totalCount",   total);
        } else {
            request.setAttribute("rows", leaveService.findForUser(user.getId(), 50));
        }
        request.setAttribute("isAdmin", isAdmin);

        RequestDispatcher dispatcher = request.getRequestDispatcher("/WEB-INF/pages/leave.jsp");
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
            session.setAttribute("leaveError", "Invalid request token.");
            response.sendRedirect(request.getContextPath() + "/leaves");
            return;
        }

        User user = (User) session.getAttribute("user");
        String action = request.getParameter("action");

        if ("apply".equalsIgnoreCase(action)) {
            // Employees (and admins, if they want to) can apply. Admin self-apply is allowed.
            String type    = request.getParameter("leaveType");
            LocalDate start = parseDate(request.getParameter("startDate"));
            LocalDate end   = parseDate(request.getParameter("endDate"));
            String reason  = request.getParameter("reason");
            LeaveService.LeaveResult r = leaveService.applyLeave(user.getId(), type, start, end, reason);
            session.setAttribute(r.isSuccess() ? "leaveSuccess" : "leaveError", r.getMessage());
            if (r.isSuccess()) {
                auditService.log(user.getId(), AuditService.LEAVE_APPLY, "LEAVE", null,
                        "type=" + (type == null ? "" : type)
                              + " from=" + start + " to=" + end);
            }
        } else if ("approve".equalsIgnoreCase(action) || "reject".equalsIgnoreCase(action)) {
            if (!"ADMIN".equalsIgnoreCase(user.getRole())) {
                session.setAttribute("leaveError", "Only admins can decide on requests.");
                response.sendRedirect(request.getContextPath() + "/leaves");
                return;
            }
            String idParam = request.getParameter("id");
            int id;
            try { id = Integer.parseInt(idParam); }
            catch (Exception e) {
                session.setAttribute("leaveError", "Invalid leave id.");
                response.sendRedirect(request.getContextPath() + "/leaves");
                return;
            }
            String status = "approve".equalsIgnoreCase(action) ? LeaveRequest.APPROVED : LeaveRequest.REJECTED;
            LeaveService.LeaveResult r = leaveService.decide(id, status, user.getId());
            session.setAttribute(r.isSuccess() ? "leaveSuccess" : "leaveError", r.getMessage());
            if (r.isSuccess()) {
                String auditAction = LeaveRequest.APPROVED.equals(status)
                        ? AuditService.LEAVE_APPROVE
                        : AuditService.LEAVE_REJECT;
                auditService.log(user.getId(), auditAction, "LEAVE", id,
                        "decided by admin#" + user.getId());
            }
        } else {
            session.setAttribute("leaveError", "Unknown action.");
        }

        response.sendRedirect(request.getContextPath() + "/leaves");
    }

    private LocalDate parseDate(String v) {
        try { return v == null || v.trim().isEmpty() ? null : LocalDate.parse(v.trim()); }
        catch (Exception e) { return null; }
    }
    private int parsePage(String v) {
        try { int p = Integer.parseInt(v); return p < 1 ? 1 : p; }
        catch (Exception e) { return 1; }
    }
}
