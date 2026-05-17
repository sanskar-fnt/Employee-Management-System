package com.ems.controllers;

import com.ems.model.AttendanceRow;
import com.ems.model.Employee;
import com.ems.model.Task;
import com.ems.model.User;
import com.ems.service.AttendanceService;
import com.ems.service.EmployeeService;
import com.ems.service.TaskService;
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
import java.util.ArrayList;
import java.util.List;

/**
 * Global search across employees, tasks and attendance.
 *
 * Admin: searches all three modules.
 * Employee: searches their own tasks only (employees + attendance are admin-scope data).
 *
 * Reuses existing search methods on the services — no new DB queries except a
 * small composition for attendance (employees-by-name, then their recent attendance).
 */
@WebServlet("/search")
public class SearchServlet extends HttpServlet {

    private static final int RESULTS_PER_GROUP = 8;

    private final EmployeeService   employeeService   = new EmployeeService();
    private final TaskService       taskService       = new TaskService();
    private final AttendanceService attendanceService = new AttendanceService();

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
        boolean isAdmin = user != null && "ADMIN".equalsIgnoreCase(user.getRole());

        String raw = request.getParameter("q");
        String q   = raw == null ? "" : raw.trim();
        request.setAttribute("query", q);

        List<Employee>      employees  = new ArrayList<>();
        List<Task>          tasks      = new ArrayList<>();
        List<AttendanceRow> attendance = new ArrayList<>();

        if (!q.isEmpty()) {
            if (isAdmin) {
                employees = employeeService.searchEmployees(q, RESULTS_PER_GROUP, 0);
                tasks     = taskService.searchAllTasks(q, null, RESULTS_PER_GROUP, 0);
                attendance = searchAttendance(q);
            } else {
                tasks = taskService.searchTasksForEmployee(user.getId(), q, null, RESULTS_PER_GROUP, 0);
            }
        }

        request.setAttribute("employeeResults",   employees);
        request.setAttribute("taskResults",       tasks);
        request.setAttribute("attendanceResults", attendance);
        request.setAttribute("isAdmin",           isAdmin);
        request.setAttribute("totalResults",
                employees.size() + tasks.size() + attendance.size());

        RequestDispatcher dispatcher = request.getRequestDispatcher("/WEB-INF/pages/search.jsp");
        dispatcher.forward(request, response);
    }

    /**
     * Attendance search:
     *   1. If the query parses as YYYY-MM-DD → return that day's attendance.
     *   2. Otherwise → look up matching employees by name/email and return their
     *      recent attendance rows (one per employee, up to RESULTS_PER_GROUP).
     */
    private List<AttendanceRow> searchAttendance(String q) {
        // Date path
        try {
            LocalDate date = LocalDate.parse(q);
            return attendanceService.getAttendanceRecords(date, null, RESULTS_PER_GROUP, 0);
        } catch (Exception ignored) {
            // not a date — fall through
        }

        // Employee-name path
        List<AttendanceRow> rows = new ArrayList<>();
        List<Employee> matched = employeeService.searchEmployees(q, RESULTS_PER_GROUP, 0);
        for (Employee e : matched) {
            if (rows.size() >= RESULTS_PER_GROUP) break;
            List<AttendanceRow> latest = attendanceService.getAttendanceHistoryForUser(
                    e.getUserId() == null ? 0 : e.getUserId(), 1);
            if (latest != null && !latest.isEmpty()) {
                rows.add(latest.get(0));
            }
        }
        return rows;
    }
}
