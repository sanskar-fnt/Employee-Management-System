package com.ems.service;

import com.ems.config.DBConfig;
import com.ems.model.Employee;
import com.ems.model.PerformanceEntry;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

public class PerformanceService {

    private final AttendanceService attendanceService = new AttendanceService();
    private final EmployeeService employeeService = new EmployeeService();

    public int calculateScore(int userId) {
        int completedTasks = getCompletedTaskCount(userId);
        int attendanceDays = attendanceService.getWeeklyAttendanceCount(userId);
        int lateDays = attendanceService.getLateDaysThisWeek(userId);
        return (completedTasks * 10) + (attendanceDays * 5) - (lateDays * 3);
    }

    public List<PerformanceEntry> getTopPerformers(int limit) {
        List<Employee> employees = employeeService.getAllEmployees();
        List<PerformanceEntry> entries = new ArrayList<>();
        if (employees == null || employees.isEmpty()) {
            return entries;
        }
        for (Employee employee : employees) {
            Integer userId = employee.getUserId();
            if (userId == null || userId <= 0) {
                continue;
            }
            PerformanceEntry entry = new PerformanceEntry();
            entry.setEmployeeId(employee.getId());
            entry.setUserId(userId);
            entry.setName(employee.getName());
            int completedTasks = getCompletedTaskCount(userId);
            int attendanceDays = attendanceService.getWeeklyAttendanceCount(userId);
            int lateDays = attendanceService.getLateDaysThisWeek(userId);
            entry.setCompletedTasks(completedTasks);
            entry.setAttendanceDays(attendanceDays);
            entry.setLateDays(lateDays);
            entry.setScore((completedTasks * 10) + (attendanceDays * 5) - (lateDays * 3));
            entries.add(entry);
        }
        entries.sort(Comparator.comparingInt(PerformanceEntry::getScore).reversed());
        if (entries.size() > limit) {
            return new ArrayList<>(entries.subList(0, limit));
        }
        return entries;
    }

    public int getCompletedTaskCount(int userId) {
        String sql = "SELECT COUNT(*) AS total FROM tasks WHERE assigned_to=? AND status='COMPLETED'";
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
}
