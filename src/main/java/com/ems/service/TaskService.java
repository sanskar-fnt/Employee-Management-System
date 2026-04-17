package com.ems.service;

import com.ems.config.DBConfig;
import com.ems.model.Task;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class TaskService {

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

    public boolean updateTaskStatus(int taskId, String status) {
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
}
