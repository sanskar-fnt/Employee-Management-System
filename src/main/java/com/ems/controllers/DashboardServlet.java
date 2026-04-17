package com.ems.controllers;

import com.ems.model.User;
import com.ems.service.AttendanceService;
import com.ems.service.EmployeeService;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.time.LocalDate;

@WebServlet("/dashboard")
public class DashboardServlet extends HttpServlet {

    private final EmployeeService employeeService = new EmployeeService();
    private final AttendanceService attendanceService = new AttendanceService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        User user = (User) session.getAttribute("user");
        if (user != null && "EMPLOYEE".equalsIgnoreCase(user.getRole())) {
            response.sendRedirect(request.getContextPath() + "/emp-dashboard");
            return;
        }

        int totalEmployees = employeeService.getEmployeeCount();
        int activeEmployees = attendanceService.getActiveEmployeeCount();
        int inactiveEmployees = Math.max(0, totalEmployees - activeEmployees);
        LocalDate startDate = parseDate(request.getParameter("startDate"));
        LocalDate endDate = parseDate(request.getParameter("endDate"));

        request.setAttribute("totalEmployees", totalEmployees);
        request.setAttribute("activeEmployees", activeEmployees);
        request.setAttribute("inactiveEmployees", inactiveEmployees);
        request.setAttribute("todayAttendance", attendanceService.getTodayAttendanceCount());
        request.setAttribute("totalAttendance", attendanceService.getTotalAttendanceCount());
        if (startDate != null && endDate != null) {
            request.setAttribute("attendanceRows", attendanceService.getAttendanceByRange(startDate, endDate));
            request.setAttribute("recentAttendanceRows", attendanceService.getRecentAttendanceByRange(startDate, endDate, 10));
        } else {
            request.setAttribute("attendanceRows", employeeService.getTodayAttendance());
            request.setAttribute("recentAttendanceRows", attendanceService.getRecentAttendance(10));
        }
        request.setAttribute("startDate", startDate == null ? "" : startDate.toString());
        request.setAttribute("endDate", endDate == null ? "" : endDate.toString());
        RequestDispatcher dispatcher = request.getRequestDispatcher("/WEB-INF/pages/dashboard.jsp");
        dispatcher.forward(request, response);
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
}