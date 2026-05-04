package com.ems.controllers;

import com.ems.model.User;
import com.ems.model.Employee;
import com.ems.service.AttendanceService;
import com.ems.service.EmployeeService;
import com.ems.util.CsrfUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.time.LocalDate;
import java.util.List;

@WebServlet("/attendance")
public class AttendanceServlet extends HttpServlet {

    private final AttendanceService attendanceService = new AttendanceService();
    private final EmployeeService employeeService = new EmployeeService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
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

        LocalDate date = parseDate(request.getParameter("date"));
        Integer employeeId = parseInt(request.getParameter("employeeId"));
        int page = parsePage(request.getParameter("page"));
        int size = parseSize(request.getParameter("size"));
        int offset = (page - 1) * size;

        int total = attendanceService.getAttendanceRecordCount(date, employeeId);
        int totalPages = Math.max(1, (int) Math.ceil(total / (double) size));

        request.setAttribute("attendanceRows", attendanceService.getAttendanceRecords(date, employeeId, size, offset));
        request.setAttribute("employees", employeeService.getAllEmployees());
        request.setAttribute("filterDate", date == null ? "" : date.toString());
        request.setAttribute("filterEmployeeId", employeeId == null ? "" : employeeId.toString());
        request.setAttribute("page", page);
        request.setAttribute("size", size);
        request.setAttribute("totalPages", totalPages);

        request.getRequestDispatcher("/WEB-INF/pages/attendance.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        if (!CsrfUtil.isValid(request)) {
            session.setAttribute("attendanceError", "Invalid request token.");
            response.sendRedirect(request.getContextPath() + "/emp-dashboard");
            return;
        }

        User user = (User) session.getAttribute("user");
        if (user == null || !"EMPLOYEE".equalsIgnoreCase(user.getRole())) {
            response.sendRedirect(request.getContextPath() + "/dashboard");
            return;
        }

        Employee employee = employeeService.getByUserId(user.getId());
        if (employee == null) {
            session.setAttribute("attendanceError", "Your account is not linked to an employee profile.");
            response.sendRedirect(request.getContextPath() + "/emp-dashboard");
            return;
        }

        String action = request.getParameter("action");
        AttendanceService.AttendanceActionResult result;
        if ("checkin".equalsIgnoreCase(action)) {
            result = attendanceService.attemptCheckIn(user.getId());
        } else if ("checkout".equalsIgnoreCase(action)) {
            result = attendanceService.attemptCheckOut(user.getId());
        } else {
            session.setAttribute("attendanceError", "Invalid attendance action.");
            response.sendRedirect(request.getContextPath() + "/emp-dashboard");
            return;
        }

        session.setAttribute(result.isSuccess() ? "attendanceMessage" : "attendanceError", result.getMessage());
        response.sendRedirect(request.getContextPath() + "/emp-dashboard");
    }

    private LocalDate parseDate(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        try {
            return LocalDate.parse(value);
        } catch (Exception ex) {
            return null;
        }
    }

    private Integer parseInt(String value) {
        try {
            int parsed = Integer.parseInt(value);
            return parsed > 0 ? parsed : null;
        } catch (Exception ex) {
            return null;
        }
    }

    private int parsePage(String value) {
        try {
            int page = Integer.parseInt(value);
            return page < 1 ? 1 : page;
        } catch (Exception ex) {
            return 1;
        }
    }

    private int parseSize(String value) {
        try {
            int size = Integer.parseInt(value);
            if (size < 5) {
                return 5;
            }
            return Math.min(size, 50);
        } catch (Exception ex) {
            return 10;
        }
    }
}