package com.ems.controllers;

import com.ems.model.User;
import com.ems.service.TaskService;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.util.Map;

@WebServlet("/analytics/tasks")
public class TaskAnalyticsServlet extends HttpServlet {

    private final TaskService taskService = new TaskService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        User user = (User) session.getAttribute("user");
        if (user == null || !"ADMIN".equalsIgnoreCase(user.getRole())) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }

        Map<String, Integer> stats = taskService.getTaskStats();
        int pending = stats.getOrDefault("PENDING", 0);
        int progress = stats.getOrDefault("IN_PROGRESS", 0);
        int completed = stats.getOrDefault("COMPLETED", 0);

        response.setContentType("application/json");
        response.getWriter().write("{\"pending\":" + pending + ",\"inProgress\":" + progress + ",\"completed\":" + completed + "}");
    }
}
