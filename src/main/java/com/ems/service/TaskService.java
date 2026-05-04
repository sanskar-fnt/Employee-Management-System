package com.ems.service;

import com.ems.config.DBConfig;
import com.ems.model.Task;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class TaskService {

    public static class TaskActionResult {
        private final boolean success;
        private final String message;

        public TaskActionResult(boolean success, String message) {
            this.success = success;
            this.message = message;
        }

        public boolean isSuccess() {
            return success;
        }

        public String getMessage() {
            return message;
        }
    }

    public TaskActionResult attemptAssignTask(Task task) {
        String validationError = validateTaskAssignment(task);
        if (validationError != null) {
            return new TaskActionResult(false, validationError);
        }
        boolean created = assignTask(task);
        return new TaskActionResult(created, created
                ? "Task assigned successfully."
                : "Unable to assign task.");
    }

    public TaskActionResult attemptStatusUpdate(int taskId, int userId, String status) {
        if (!isTaskAssignedToUser(taskId, userId)) {
            return new TaskActionResult(false, "You cannot update this task.");
        }
        String currentStatus = getTaskStatus(taskId);
        String transitionError = validateStatusTransition(currentStatus, status);
        if (transitionError != null) {
            return new TaskActionResult(false, transitionError);
        }
        boolean updated = updateTaskStatus(taskId, status);
        return new TaskActionResult(updated, updated
                ? "Task status updated."
                : "Unable to update task status.");
    }

    public boolean assignTask(Task task) {
        String sql = "INSERT INTO tasks (title, description, assigned_to, assigned_by, status, priority, due_date, reminder_at, created_at, updated_at) "
                + "VALUES (?,?,?,?,?,?,?,?,CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, task.getTitle());
            statement.setString(2, task.getDescription());
            statement.setInt(3, task.getAssignedTo());
            statement.setInt(4, task.getAssignedBy());
            statement.setString(5, task.getStatus());
            statement.setString(6, task.getPriority());
            statement.setDate(7, task.getDueDate());
            statement.setTimestamp(8, task.getReminderAt());
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public List<Task> getTasksByEmployee(int userId) {
        List<Task> tasks = new ArrayList<>();
        String sql = "SELECT t.*, u.username AS assigned_by_name "
                + "FROM tasks t "
                + "LEFT JOIN users u ON u.id = t.assigned_by "
                + "WHERE t.assigned_to=? "
                + "ORDER BY t.updated_at DESC";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    tasks.add(mapTask(resultSet));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return tasks;
    }

    public List<Task> getTasksByEmployee(int userId, String statusFilter, int limit, int offset) {
        if (isBlank(statusFilter) || !isAllowedStatus(statusFilter.trim().toUpperCase())) {
            return getTasksByEmployee(userId, limit, offset);
        }
        List<Task> tasks = new ArrayList<>();
        String sql = "SELECT t.*, u.username AS assigned_by_name "
                + "FROM tasks t "
                + "LEFT JOIN users u ON u.id = t.assigned_by "
                + "WHERE t.assigned_to=? AND t.status=? "
                + "ORDER BY t.updated_at DESC LIMIT ? OFFSET ?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            statement.setString(2, statusFilter.trim().toUpperCase());
            statement.setInt(3, limit);
            statement.setInt(4, offset);
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    tasks.add(mapTask(resultSet));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return tasks;
    }

    public List<Task> getTasksByEmployee(int userId, int limit, int offset) {
        List<Task> tasks = new ArrayList<>();
        String sql = "SELECT t.*, u.username AS assigned_by_name "
                + "FROM tasks t "
                + "LEFT JOIN users u ON u.id = t.assigned_by "
                + "WHERE t.assigned_to=? "
                + "ORDER BY t.updated_at DESC LIMIT ? OFFSET ?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            statement.setInt(2, limit);
            statement.setInt(3, offset);
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    tasks.add(mapTask(resultSet));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return tasks;
    }

    public List<Task> getAllTasks() {
        List<Task> tasks = new ArrayList<>();
        String sql = "SELECT t.*, u.username AS assigned_to_name, ua.username AS assigned_by_name "
                + "FROM tasks t "
                + "LEFT JOIN users u ON u.id = t.assigned_to "
                + "LEFT JOIN users ua ON ua.id = t.assigned_by "
                + "ORDER BY t.updated_at DESC";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            while (resultSet.next()) {
                tasks.add(mapTask(resultSet));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return tasks;
    }

    public List<Task> getAllTasks(String statusFilter, int limit, int offset) {
        if (isBlank(statusFilter) || !isAllowedStatus(statusFilter.trim().toUpperCase())) {
            return getAllTasks(limit, offset);
        }
        List<Task> tasks = new ArrayList<>();
        String sql = "SELECT t.*, u.username AS assigned_to_name, ua.username AS assigned_by_name "
                + "FROM tasks t "
                + "LEFT JOIN users u ON u.id = t.assigned_to "
                + "LEFT JOIN users ua ON ua.id = t.assigned_by "
                + "WHERE t.status=? "
                + "ORDER BY t.updated_at DESC LIMIT ? OFFSET ?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, statusFilter.trim().toUpperCase());
            statement.setInt(2, limit);
            statement.setInt(3, offset);
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    tasks.add(mapTask(resultSet));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return tasks;
    }

    public List<Task> getAllTasks(int limit, int offset) {
        List<Task> tasks = new ArrayList<>();
        String sql = "SELECT t.*, u.username AS assigned_to_name, ua.username AS assigned_by_name "
                + "FROM tasks t "
                + "LEFT JOIN users u ON u.id = t.assigned_to "
                + "LEFT JOIN users ua ON ua.id = t.assigned_by "
                + "ORDER BY t.updated_at DESC LIMIT ? OFFSET ?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, limit);
            statement.setInt(2, offset);
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    tasks.add(mapTask(resultSet));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return tasks;
    }

    public int getTaskCount(String statusFilter) {
        if (isBlank(statusFilter) || !isAllowedStatus(statusFilter.trim().toUpperCase())) {
            return getTaskCount();
        }
        String sql = "SELECT COUNT(*) AS total FROM tasks WHERE status=?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, statusFilter.trim().toUpperCase());
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return resultSet.getInt("total");
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    public int getTaskCount() {
        String sql = "SELECT COUNT(*) AS total FROM tasks";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            if (resultSet.next()) {
                return resultSet.getInt("total");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    public int getTaskCountForEmployee(int userId, String statusFilter) {
        if (isBlank(statusFilter) || !isAllowedStatus(statusFilter.trim().toUpperCase())) {
            return getTaskCountForEmployee(userId);
        }
        String sql = "SELECT COUNT(*) AS total FROM tasks WHERE assigned_to=? AND status=?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            statement.setString(2, statusFilter.trim().toUpperCase());
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return resultSet.getInt("total");
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    public int getTaskCountForEmployee(int userId) {
        String sql = "SELECT COUNT(*) AS total FROM tasks WHERE assigned_to=?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return resultSet.getInt("total");
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    public boolean updateTaskStatus(int taskId, String status) {
        String currentStatus = getTaskStatus(taskId);
        if (validateStatusTransition(currentStatus, status) != null) {
            return false;
        }
        String sql = "UPDATE tasks SET status=?, updated_at=CURRENT_TIMESTAMP WHERE id=?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, status);
            statement.setInt(2, taskId);
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public Map<String, Integer> getTaskStats() {
        Map<String, Integer> stats = new HashMap<>();
        String sql = "SELECT "
                + "SUM(CASE WHEN status='PENDING' THEN 1 ELSE 0 END) AS pending_count, "
                + "SUM(CASE WHEN status='IN_PROGRESS' THEN 1 ELSE 0 END) AS progress_count, "
                + "SUM(CASE WHEN status='COMPLETED' THEN 1 ELSE 0 END) AS completed_count "
                + "FROM tasks";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            if (resultSet.next()) {
                stats.put("PENDING", resultSet.getInt("pending_count"));
                stats.put("IN_PROGRESS", resultSet.getInt("progress_count"));
                stats.put("COMPLETED", resultSet.getInt("completed_count"));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return stats;
    }

    public boolean isTaskAssignedToUser(int taskId, int userId) {
        String sql = "SELECT 1 FROM tasks WHERE id=? AND assigned_to=?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, taskId);
            statement.setInt(2, userId);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next();
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public String validateTaskAssignment(Task task) {
        if (task == null) {
            return "Task details are required.";
        }
        if (isBlank(task.getTitle())) {
            return "Title is required.";
        }
        if (isBlank(task.getDescription())) {
            return "Description is required.";
        }
        if (task.getAssignedTo() <= 0 || !isAssignableUser(task.getAssignedTo())) {
            return "Invalid assignee selected.";
        }
        if (task.getDueDate() != null) {
            LocalDate due = task.getDueDate().toLocalDate();
            if (due.isBefore(LocalDate.now())) {
                return "Due date cannot be in the past.";
            }
        }
        return null;
    }

    private String validateStatusTransition(String currentStatus, String nextStatus) {
        if (currentStatus == null || nextStatus == null) {
            return "Invalid task status.";
        }
        String current = currentStatus.trim().toUpperCase();
        String next = nextStatus.trim().toUpperCase();
        if (!isAllowedStatus(next)) {
            return "Invalid status selection.";
        }
        if (current.equals(next)) {
            return null;
        }
        if ("PENDING".equals(current)) {
            return "IN_PROGRESS".equals(next) ? null : "Invalid status transition.";
        }
        if ("IN_PROGRESS".equals(current)) {
            return "COMPLETED".equals(next) ? null : "Invalid status transition.";
        }
        if ("COMPLETED".equals(current)) {
            return "Invalid status transition.";
        }
        return "Invalid status transition.";
    }

    private String getTaskStatus(int taskId) {
        String sql = "SELECT status FROM tasks WHERE id=?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, taskId);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return resultSet.getString("status");
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    private boolean isAssignableUser(int userId) {
        String sql = "SELECT 1 FROM users WHERE id=? AND role='EMPLOYEE'";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next();
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    private boolean isAllowedStatus(String value) {
        return "PENDING".equals(value) || "IN_PROGRESS".equals(value) || "COMPLETED".equals(value);
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private Task mapTask(ResultSet resultSet) throws SQLException {
        Task task = new Task();
        task.setId(resultSet.getInt("id"));
        task.setTitle(resultSet.getString("title"));
        task.setDescription(resultSet.getString("description"));
        task.setAssignedTo(resultSet.getInt("assigned_to"));
        task.setAssignedBy(resultSet.getInt("assigned_by"));
        task.setStatus(resultSet.getString("status"));
        task.setPriority(resultSet.getString("priority"));
        task.setDueDate(resultSet.getDate("due_date"));
        task.setReminderAt(resultSet.getTimestamp("reminder_at"));
        Timestamp createdAt = resultSet.getTimestamp("created_at");
        Timestamp updatedAt = resultSet.getTimestamp("updated_at");
        task.setCreatedAt(createdAt);
        task.setUpdatedAt(updatedAt);
        try {
            task.setAssignedToName(resultSet.getString("assigned_to_name"));
        } catch (SQLException ignored) {
            task.setAssignedToName(null);
        }
        try {
            task.setAssignedByName(resultSet.getString("assigned_by_name"));
        } catch (SQLException ignored) {
            task.setAssignedByName(null);
        }
        return task;
    }

    public List<Task> searchAllTasks(String query, String statusFilter, int limit, int offset) {
        if (isBlank(query)) {
            return getAllTasks(statusFilter, limit, offset);
        }
        List<Task> tasks = new ArrayList<>();
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT t.*, u.username AS assigned_to_name, ua.username AS assigned_by_name ")
           .append("FROM tasks t ")
           .append("LEFT JOIN users u ON u.id = t.assigned_to ")
           .append("LEFT JOIN users ua ON ua.id = t.assigned_by ")
           .append("WHERE (t.title LIKE ? OR t.description LIKE ? OR u.username LIKE ? OR ua.username LIKE ?) ");
        if (!isBlank(statusFilter) && isAllowedStatus(statusFilter.trim().toUpperCase())) {
            sql.append("AND t.status=? ");
        }
        sql.append("ORDER BY t.updated_at DESC LIMIT ? OFFSET ?");

        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            String value = "%" + query.trim() + "%";
            int idx = 1;
            statement.setString(idx++, value);
            statement.setString(idx++, value);
            statement.setString(idx++, value);
            statement.setString(idx++, value);
            if (!isBlank(statusFilter) && isAllowedStatus(statusFilter.trim().toUpperCase())) {
                statement.setString(idx++, statusFilter.trim().toUpperCase());
            }
            statement.setInt(idx++, limit);
            statement.setInt(idx, offset);
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    tasks.add(mapTask(resultSet));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return tasks;
    }

    public List<Task> searchTasksForEmployee(int userId, String query, String statusFilter, int limit, int offset) {
        if (isBlank(query)) {
            return getTasksByEmployee(userId, statusFilter, limit, offset);
        }
        List<Task> tasks = new ArrayList<>();
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT t.*, u.username AS assigned_by_name ")
           .append("FROM tasks t ")
           .append("LEFT JOIN users u ON u.id = t.assigned_by ")
           .append("WHERE t.assigned_to=? ")
           .append("AND (t.title LIKE ? OR t.description LIKE ? OR u.username LIKE ?) ");
        if (!isBlank(statusFilter) && isAllowedStatus(statusFilter.trim().toUpperCase())) {
            sql.append("AND t.status=? ");
        }
        sql.append("ORDER BY t.updated_at DESC LIMIT ? OFFSET ?");

        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            int idx = 1;
            statement.setInt(idx++, userId);
            String value = "%" + query.trim() + "%";
            statement.setString(idx++, value);
            statement.setString(idx++, value);
            statement.setString(idx++, value);
            if (!isBlank(statusFilter) && isAllowedStatus(statusFilter.trim().toUpperCase())) {
                statement.setString(idx++, statusFilter.trim().toUpperCase());
            }
            statement.setInt(idx++, limit);
            statement.setInt(idx, offset);
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    tasks.add(mapTask(resultSet));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return tasks;
    }

    public int getTaskCountForSearch(String query, String statusFilter) {
        if (isBlank(query)) {
            return getTaskCount(statusFilter);
        }
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT COUNT(*) AS total ")
           .append("FROM tasks t ")
           .append("LEFT JOIN users u ON u.id = t.assigned_to ")
           .append("LEFT JOIN users ua ON ua.id = t.assigned_by ")
           .append("WHERE (t.title LIKE ? OR t.description LIKE ? OR u.username LIKE ? OR ua.username LIKE ?) ");
        if (!isBlank(statusFilter) && isAllowedStatus(statusFilter.trim().toUpperCase())) {
            sql.append("AND t.status=? ");
        }
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            String value = "%" + query.trim() + "%";
            int idx = 1;
            statement.setString(idx++, value);
            statement.setString(idx++, value);
            statement.setString(idx++, value);
            statement.setString(idx++, value);
            if (!isBlank(statusFilter) && isAllowedStatus(statusFilter.trim().toUpperCase())) {
                statement.setString(idx++, statusFilter.trim().toUpperCase());
            }
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return resultSet.getInt("total");
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    public int getTaskCountForEmployeeSearch(int userId, String query, String statusFilter) {
        if (isBlank(query)) {
            return getTaskCountForEmployee(userId, statusFilter);
        }
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT COUNT(*) AS total ")
           .append("FROM tasks t ")
           .append("LEFT JOIN users u ON u.id = t.assigned_by ")
           .append("WHERE t.assigned_to=? ")
           .append("AND (t.title LIKE ? OR t.description LIKE ? OR u.username LIKE ?) ");
        if (!isBlank(statusFilter) && isAllowedStatus(statusFilter.trim().toUpperCase())) {
            sql.append("AND t.status=? ");
        }
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            int idx = 1;
            statement.setInt(idx++, userId);
            String value = "%" + query.trim() + "%";
            statement.setString(idx++, value);
            statement.setString(idx++, value);
            statement.setString(idx++, value);
            if (!isBlank(statusFilter) && isAllowedStatus(statusFilter.trim().toUpperCase())) {
                statement.setString(idx++, statusFilter.trim().toUpperCase());
            }
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return resultSet.getInt("total");
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }
}