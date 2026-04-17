package com.ems.controllers;

import com.ems.model.User;
import com.ems.model.Employee;
import com.ems.service.AttendanceService;
import com.ems.service.EmployeeService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

@WebServlet("/attendance")
public class AttendanceServlet extends HttpServlet {

    private final AttendanceService attendanceService = new AttendanceService();
    private final EmployeeService employeeService = new EmployeeService();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
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
        boolean updated;
        if ("checkin".equalsIgnoreCase(action)) {
            if (attendanceService.hasCheckedInToday(user.getId())) {
                session.setAttribute("attendanceError", "You have already checked in today.");
                response.sendRedirect(request.getContextPath() + "/emp-dashboard");
                return;
            }
            updated = attendanceService.checkIn(user.getId());
        } else if ("checkout".equalsIgnoreCase(action)) {
            if (!attendanceService.hasCheckedInToday(user.getId())) {
                session.setAttribute("attendanceError", "Please check in before checking out.");
                response.sendRedirect(request.getContextPath() + "/emp-dashboard");
                return;
            }
            updated = attendanceService.checkOut(user.getId());
        } else {
            session.setAttribute("attendanceError", "Invalid attendance action.");
            response.sendRedirect(request.getContextPath() + "/emp-dashboard");
            return;
        }
        if (updated) {
            session.setAttribute("attendanceMessage", "Attendance saved for today.");
        } else {
            session.setAttribute("attendanceError", "Unable to save attendance. Please check database setup.");
        }
        response.sendRedirect(request.getContextPath() + "/emp-dashboard");
    }
}