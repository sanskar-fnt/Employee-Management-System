package com.ems.controllers;

import com.ems.model.AuditLog;
import com.ems.model.Employee;
import com.ems.model.PerformanceBreakdown;
import com.ems.model.User;
import com.ems.model.WorkloadEntry;
import com.ems.service.AttendanceService;
import com.ems.service.AuditService;
import com.ems.service.EmployeeService;
import com.ems.service.LeaveService;
import com.ems.service.PerformanceService;
import com.ems.service.TaskService;
import com.ems.service.WorkloadService;
import com.ems.util.CsrfUtil;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.util.List;

/**
 * /employees/profile?id=N
 *
 * Read-only deep profile for one employee.
 * Reuses every existing service — no business logic added.
 *
 * Access:
 *   - ADMIN can view any employee.
 *   - EMPLOYEE can only view their own profile.
 */
@WebServlet("/employees/profile")
public class EmployeeProfileServlet extends HttpServlet {

    private final EmployeeService    employeeService    = new EmployeeService();
    private final AttendanceService  attendanceService  = new AttendanceService();
    private final TaskService        taskService        = new TaskService();
    private final PerformanceService performanceService = new PerformanceService();
    private final WorkloadService    workloadService    = new WorkloadService();
    private final AuditService       auditService       = new AuditService();
    private final LeaveService       leaveService       = new LeaveService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        request.setAttribute("csrfToken", CsrfUtil.ensureToken(session));

        User viewer  = (User) session.getAttribute("user");
        boolean isAdmin = "ADMIN".equalsIgnoreCase(viewer.getRole());

        int employeeId;
        try { employeeId = Integer.parseInt(request.getParameter("id")); }
        catch (Exception e) {
            response.sendRedirect(request.getContextPath()
                    + (isAdmin ? "/employees" : "/emp-dashboard"));
            return;
        }

        Employee employee = employeeService.getEmployeeById(employeeId);
        if (employee == null) {
            session.setAttribute("formError", "Employee not found.");
            response.sendRedirect(request.getContextPath()
                    + (isAdmin ? "/employees" : "/emp-dashboard"));
            return;
        }

        // ─────────────────────────────────────────────────────────────
        //  ACCESS RULE (do not change without product approval):
        //    • ADMIN  → can view ANY employee profile.
        //    • EMPLOYEE → can view ONLY their own profile (the one whose
        //                 user_id matches the viewer's user id).
        //  Anyone else attempting to view a profile that isn't theirs is
        //  silently redirected to /emp-dashboard (no leak of existence).
        // ─────────────────────────────────────────────────────────────
        Integer empUserId = employee.getUserId();
        if (!isAdmin && (empUserId == null || empUserId.intValue() != viewer.getId())) {
            response.sendRedirect(request.getContextPath() + "/emp-dashboard");
            return;
        }
        if (empUserId == null || empUserId <= 0) {
            session.setAttribute("formError", "Employee is not linked to a user account.");
            response.sendRedirect(request.getContextPath() + "/employees");
            return;
        }

        int userId = empUserId;

        // Existing services do all the work.
        PerformanceBreakdown perf = performanceService.getPerformanceBreakdown(userId);
        WorkloadEntry workload    = findWorkload(userId);

        request.setAttribute("employee",          employee);
        request.setAttribute("isAdmin",           isAdmin);
        request.setAttribute("performance",       perf);
        request.setAttribute("workload",          workload);
        request.setAttribute("lateDaysWeek",      attendanceService.getLateDaysThisWeek(userId));
        java.util.List<com.ems.model.AttendanceRow> history =
                attendanceService.getAttendanceHistoryForUser(userId, 12);
        leaveService.markOnLeave(history);
        request.setAttribute("attendanceHistory", history);
        request.setAttribute("taskHistory",       taskService.getTasksByEmployee(userId, 15, 0));
        // Recent activity = last few audit log rows where this user is the actor.
        request.setAttribute("recentActivity",    auditService.findLogs(null, userId, null, null, 10, 0));

        RequestDispatcher dispatcher = request.getRequestDispatcher("/WEB-INF/pages/profile.jsp");
        dispatcher.forward(request, response);
    }

    /** Locate the workload entry for one user without adding a new service method. */
    private WorkloadEntry findWorkload(int userId) {
        List<WorkloadEntry> all = workloadService.getAllWorkloads();
        if (all == null) return null;
        for (WorkloadEntry w : all) {
            if (w.getUserId() == userId) return w;
        }
        return null;
    }
}
