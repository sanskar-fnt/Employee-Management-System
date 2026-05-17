package com.ems.controllers;

import com.ems.model.AttendanceRow;
import com.ems.model.Task;
import com.ems.model.User;
import com.ems.service.AttendanceService;
import com.ems.service.TaskService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Time;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;

@WebServlet(urlPatterns = {"/reports/attendance", "/reports/tasks"})
public class ReportServlet extends HttpServlet {

    private final AttendanceService attendanceService = new AttendanceService();
    private final TaskService taskService = new TaskService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        User user = (User) session.getAttribute("user");
        if (user == null || !"ADMIN".equalsIgnoreCase(user.getRole())) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Admin access required.");
            return;
        }

        String path = request.getServletPath();
        if ("/reports/attendance".equals(path)) {
            writeAttendanceCsv(request, response);
        } else if ("/reports/tasks".equals(path)) {
            writeTasksCsv(response);
        } else {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
        }
    }

    private void writeAttendanceCsv(HttpServletRequest request, HttpServletResponse response) throws IOException {
        LocalDate start = parseDate(request.getParameter("startDate"));
        LocalDate end   = parseDate(request.getParameter("endDate"));

        List<AttendanceRow> rows;
        if (start != null && end != null) {
            rows = attendanceService.getAttendanceByRange(start, end);
        } else {
            rows = attendanceService.getRecentAttendance(1000);
        }

        response.setContentType("text/csv; charset=UTF-8");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Content-Disposition",
                "attachment; filename=\"attendance-" + LocalDate.now() + ".csv\"");

        try (PrintWriter out = response.getWriter()) {
            out.print('﻿');
            out.println("username,work_date,check_in,check_out,status");
            for (AttendanceRow r : rows) {
                out.println(String.join(",",
                        csv(r.getName()),
                        csv(r.getWorkDate() == null ? "" : r.getWorkDate().toString()),
                        csv(formatTime(r.getCheckInTime())),
                        csv(formatTime(r.getCheckOutTime())),
                        csv(r.getAttendanceStatus())
                ));
            }
        }
    }

    private void writeTasksCsv(HttpServletResponse response) throws IOException {
        List<Task> tasks = taskService.getAllTasks();

        response.setContentType("text/csv; charset=UTF-8");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Content-Disposition",
                "attachment; filename=\"tasks-" + LocalDate.now() + ".csv\"");

        try (PrintWriter out = response.getWriter()) {
            out.print('﻿');
            out.println("task_title,assigned_employee,due_date,status");
            for (Task t : tasks) {
                out.println(String.join(",",
                        csv(t.getTitle()),
                        csv(t.getAssignedToName()),
                        csv(t.getDueDate() == null ? "" : t.getDueDate().toString()),
                        csv(t.getStatus())
                ));
            }
        }
    }

    private LocalDate parseDate(String value) {
        if (value == null || value.trim().isEmpty()) return null;
        try {
            return LocalDate.parse(value, DateTimeFormatter.ISO_LOCAL_DATE);
        } catch (Exception e) {
            return null;
        }
    }

    private String formatTime(Time t) {
        return t == null ? "" : t.toString();
    }

    private String csv(String value) {
        if (value == null) return "";
        boolean needsQuote = value.indexOf(',') >= 0
                || value.indexOf('"') >= 0
                || value.indexOf('\n') >= 0
                || value.indexOf('\r') >= 0;
        String escaped = value.replace("\"", "\"\"");
        return needsQuote ? "\"" + escaped + "\"" : escaped;
    }
}
