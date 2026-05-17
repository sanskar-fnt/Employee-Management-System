package com.ems.service;

import com.ems.config.DBConfig;
import com.ems.model.Employee;
import com.ems.model.PerformanceBreakdown;
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

    public static final int WEEKLY_WORKING_DAYS = 5;
    public static final double LATE_PENALTY_PER_DAY = 5.0;
    public static final double LATE_PENALTY_CAP = 25.0;

    private final AttendanceService attendanceService = new AttendanceService();
    private final EmployeeService employeeService = new EmployeeService();
    private final LeaveService     leaveService     = new LeaveService();

    public PerformanceBreakdown getPerformanceBreakdown(int userId) {
        int completedTasks = getCompletedTaskCount(userId);
        int totalTasks = getTotalTaskCount(userId);
        int attendanceDays = attendanceService.getWeeklyAttendanceCount(userId);
        int lateDays = attendanceService.getLateDaysThisWeek(userId);

        // Approved leave days inside the rolling 7-day window (denominator-reduction model:
        // a day off on approved leave is neither absent nor a presence — it's removed
        // from the working-day count entirely).
        java.time.LocalDate end   = java.time.LocalDate.now();
        java.time.LocalDate start = end.minusDays(6);
        int leaveDays = leaveService.approvedLeaveDaysInRange(userId, start, end);
        int effectiveWorkingDays = Math.max(0, WEEKLY_WORKING_DAYS - leaveDays);

        double attendancePercentage = effectiveWorkingDays == 0
                ? 100.0   // entire week was approved leave → don't punish
                : Math.min(100.0, (attendanceDays * 100.0) / effectiveWorkingDays);
        double taskCompletionRate = totalTasks == 0
                ? 0.0
                : (completedTasks * 100.0) / totalTasks;
        double latePenalty = Math.min(LATE_PENALTY_CAP, lateDays * LATE_PENALTY_PER_DAY);

        double finalScore = (attendancePercentage * 0.4)
                + (taskCompletionRate * 0.6)
                - latePenalty;
        if (finalScore < 0) finalScore = 0;
        if (finalScore > 100) finalScore = 100;

        PerformanceBreakdown b = new PerformanceBreakdown();
        b.setUserId(userId);
        b.setCompletedTasks(completedTasks);
        b.setTotalTasks(totalTasks);
        b.setAttendanceDays(attendanceDays);
        b.setWorkingDays(effectiveWorkingDays);
        b.setLateDays(lateDays);
        b.setAttendancePercentage(round1(attendancePercentage));
        b.setTaskCompletionRate(round1(taskCompletionRate));
        b.setLatePenalty(round1(latePenalty));
        b.setFinalScore(round1(finalScore));
        return b;
    }

    private double round1(double v) {
        return Math.round(v * 10.0) / 10.0;
    }

    public int getTotalTaskCount(int userId) {
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
