package com.ems.controllers;

import com.ems.model.AttendanceSnapshot;
import com.ems.model.Employee;
import com.ems.model.User;
import com.ems.service.AttendanceService;
import com.ems.service.EmployeeService;
import com.ems.service.NotificationService;
import com.ems.service.PerformanceService;
import com.ems.util.CsrfUtil;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

@WebServlet("/emp-dashboard")
public class EmployeeDashboardServlet extends HttpServlet {

    private final EmployeeService employeeService = new EmployeeService();
    private final AttendanceService attendanceService = new AttendanceService();
    private final PerformanceService performanceService = new PerformanceService();
    private final NotificationService notificationService = new NotificationService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        request.setAttribute("csrfToken", CsrfUtil.ensureToken(session));

        User user = (User) session.getAttribute("user");
        if (user == null || !"EMPLOYEE".equalsIgnoreCase(user.getRole())) {
            response.sendRedirect(request.getContextPath() + "/dashboard");
            return;
        }
        if (user.isMustChangePassword()) {
            response.sendRedirect(request.getContextPath() + "/change-password");
            return;
        }

        String attendanceMessage = (String) session.getAttribute("attendanceMessage");
        String attendanceError = (String) session.getAttribute("attendanceError");
        if (attendanceMessage != null) {
            session.removeAttribute("attendanceMessage");
            request.setAttribute("attendanceMessage", attendanceMessage);
        }
        if (attendanceError != null) {
            session.removeAttribute("attendanceError");
            request.setAttribute("attendanceError", attendanceError);
        }

        Employee employee = employeeService.getByUserId(user.getId());
        if (employee == null) {
            request.setAttribute("attendanceError", "Your account is not linked to an employee profile.");
        } else {
            AttendanceSnapshot snapshot = attendanceService.getTodaySnapshot(user.getId());
            boolean canCheckIn = attendanceService.canCheckIn(user.getId());
            boolean canCheckOut = attendanceService.canCheckOut(user.getId());

            String todayStatus = "Absent";
            if (snapshot != null && snapshot.getCheckInTime() != null && snapshot.getCheckOutTime() == null) {
                todayStatus = "Active";
            } else if (snapshot != null && snapshot.getCheckOutTime() != null) {
                todayStatus = "Checked Out";
            }

            request.setAttribute("employee", employee);
            request.setAttribute("snapshot", snapshot);
            request.setAttribute("canCheckIn", canCheckIn);
            request.setAttribute("canCheckOut", canCheckOut);
            request.setAttribute("todayStatus", todayStatus);
            request.setAttribute("attendanceCount", attendanceService.getAttendanceCountForUser(user.getId()));
            request.setAttribute("attendanceHistory", attendanceService.getAttendanceHistoryForUser(user.getId(), 10));
            request.setAttribute("workHoursToday", attendanceService.getTodayWorkHours(user.getId()));
            request.setAttribute("lateToday", attendanceService.isLateToday(user.getId()));
            request.setAttribute("weeklyAttendance", attendanceService.getWeeklyAttendanceCount(user.getId()));
            request.setAttribute("performanceScore", performanceService.calculateScore(user.getId()));
            request.setAttribute("performanceBreakdown", performanceService.getPerformanceBreakdown(user.getId()));
            request.setAttribute("attendanceDiscipline", attendanceService.getDisciplineThisWeek(user.getId()));
            request.setAttribute("currentStreak",     attendanceService.getCurrentStreak(user.getId()));
            request.setAttribute("weeklyOvertimeMin", attendanceService.getOvertimeMinutesThisWeek(user.getId()));
            request.setAttribute("notifications", notificationService.forEmployee(user.getId()));
        }
        RequestDispatcher dispatcher = request.getRequestDispatcher("/WEB-INF/pages/empDashboard.jsp");
        dispatcher.forward(request, response);
    }
}