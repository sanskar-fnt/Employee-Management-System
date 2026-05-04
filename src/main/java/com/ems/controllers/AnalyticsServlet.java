package com.ems.controllers;

import com.ems.model.User;
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
import java.util.Map;

@WebServlet("/analytics")
public class AnalyticsServlet extends HttpServlet {

    private final TaskService taskService = new TaskService();

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

        Map<String, Integer> stats = taskService.getTaskStats();
        int pending = stats.getOrDefault("PENDING", 0);
        int inProgress = stats.getOrDefault("IN_PROGRESS", 0);
        int completed = stats.getOrDefault("COMPLETED", 0);
        int total = pending + inProgress + completed;

        request.setAttribute("taskPending", pending);
        request.setAttribute("taskProgress", inProgress);
        request.setAttribute("taskCompleted", completed);
        request.setAttribute("taskTotal", total);

        RequestDispatcher dispatcher = request.getRequestDispatcher("/WEB-INF/pages/analytics.jsp");
        dispatcher.forward(request, response);
    }
}
