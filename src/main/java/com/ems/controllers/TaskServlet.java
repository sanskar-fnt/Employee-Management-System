package com.ems.controllers;

import com.ems.model.Employee;
import com.ems.model.Task;
import com.ems.model.User;
import com.ems.service.EmployeeService;
import com.ems.service.TaskService;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.util.List;
import java.util.Map;

@WebServlet("/tasks")
public class TaskServlet extends HttpServlet {

    private final TaskService taskService = new TaskService();
    private final EmployeeService employeeService = new EmployeeService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        User user = (User) session.getAttribute("user");
        String role = user == null ? null : user.getRole();
        if (user == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String success = (String) session.getAttribute("taskSuccess");
        String error = (String) session.getAttribute("taskError");
        if (success != null) {
            session.removeAttribute("taskSuccess");
            request.setAttribute("taskSuccess", success);
        }
        if (error != null) {
            session.removeAttribute("taskError");
            request.setAttribute("taskError", error);
        }

        if ("ADMIN".equalsIgnoreCase(role)) {
            List<Task> tasks = taskService.getAllTasks();
            Map<String, Integer> stats = taskService.getTaskStats();
            List<Employee> employees = employeeService.getAllEmployees();
            request.setAttribute("tasks", tasks);
            request.setAttribute("taskStats", stats);
            request.setAttribute("employees", employees);
        } else if ("EMPLOYEE".equalsIgnoreCase(role)) {
            List<Task> tasks = taskService.getTasksByEmployee(user.getId());
            request.setAttribute("tasks", tasks);
        } else {
            response.sendRedirect(request.getContextPath() + "/dashboard");
            return;
        }

        RequestDispatcher dispatcher = request.getRequestDispatcher("/WEB-INF/pages/tasks.jsp");
        dispatcher.forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        User user = (User) session.getAttribute("user");
        if (user == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String action = request.getParameter("action");
        String role = user.getRole();
        if (action == null) {
            response.sendRedirect(request.getContextPath() + "/tasks");
            return;
        }

        if ("ADMIN".equalsIgnoreCase(role) && "assign".equalsIgnoreCase(action)) {
            handleAssign(request, session, user);
            response.sendRedirect(request.getContextPath() + "/tasks");
            return;
        }

        if ("EMPLOYEE".equalsIgnoreCase(role) && "update".equalsIgnoreCase(action)) {
            handleUpdateStatus(request, session, user);
            response.sendRedirect(request.getContextPath() + "/tasks");
            return;
        }

        session.setAttribute("taskError", "Invalid task action.");
        response.sendRedirect(request.getContextPath() + "/tasks");
    }

    private void handleAssign(HttpServletRequest request, HttpSession session, User user) {
        String title = request.getParameter("title");
        String description = request.getParameter("description");
        String assignedToParam = request.getParameter("assignedTo");
        String priority = request.getParameter("priority");
        String dueDate = request.getParameter("dueDate");
        String reminderAt = request.getParameter("reminderAt");

        if (isBlank(title) || isBlank(description) || isBlank(assignedToParam)) {
            session.setAttribute("taskError", "Title, description, and assignee are required.");
            return;
        }

        int assignedTo;
        try {
            assignedTo = Integer.parseInt(assignedToParam);
        } catch (NumberFormatException e) {
            session.setAttribute("taskError", "Invalid assignee selected.");
            return;
        }

        Task task = new Task();
        task.setTitle(title.trim());
        task.setDescription(description.trim());
        task.setAssignedTo(assignedTo);
        task.setAssignedBy(user.getId());
        task.setStatus("PENDING");
        task.setPriority(isBlank(priority) ? "MEDIUM" : priority.trim().toUpperCase());
        task.setDueDate(parseDate(dueDate));
        task.setReminderAt(parseTimestamp(reminderAt));

        boolean created = taskService.assignTask(task);
        session.setAttribute(created ? "taskSuccess" : "taskError",
                created ? "Task assigned successfully." : "Unable to assign task.");
    }

    private void handleUpdateStatus(HttpServletRequest request, HttpSession session, User user) {
        String taskIdParam = request.getParameter("taskId");
        String status = request.getParameter("status");
        if (isBlank(taskIdParam) || isBlank(status)) {
            session.setAttribute("taskError", "Task status update is incomplete.");
            return;
        }

        int taskId;
        try {
            taskId = Integer.parseInt(taskIdParam);
        } catch (NumberFormatException e) {
            session.setAttribute("taskError", "Invalid task selected.");
            return;
        }

        String normalized = status.trim().toUpperCase();
        if (!isAllowedStatus(normalized)) {
            session.setAttribute("taskError", "Invalid status selection.");
            return;
        }

        if (!taskService.isTaskAssignedToUser(taskId, user.getId())) {
            session.setAttribute("taskError", "You cannot update this task.");
            return;
        }

        boolean updated = taskService.updateTaskStatus(taskId, normalized);
        session.setAttribute(updated ? "taskSuccess" : "taskError",
                updated ? "Task status updated." : "Unable to update task status.");
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private boolean isAllowedStatus(String value) {
        return "PENDING".equals(value) || "IN_PROGRESS".equals(value) || "COMPLETED".equals(value);
    }

    private java.sql.Date parseDate(String value) {
        if (isBlank(value)) {
            return null;
        }
        try {
            return java.sql.Date.valueOf(value);
        } catch (IllegalArgumentException ex) {
            return null;
        }
    }

    private java.sql.Timestamp parseTimestamp(String value) {
        if (isBlank(value)) {
            return null;
        }
        try {
            String normalized = value.contains("T") ? value.replace("T", " ") + ":00" : value;
            return java.sql.Timestamp.valueOf(normalized);
        } catch (IllegalArgumentException ex) {
            return null;
        }
    }
}
