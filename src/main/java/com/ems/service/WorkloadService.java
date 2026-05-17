package com.ems.service;

import com.ems.config.DBConfig;
import com.ems.model.Employee;
import com.ems.model.PerformanceBreakdown;
import com.ems.model.WorkloadEntry;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class WorkloadService {

    private final EmployeeService employeeService = new EmployeeService();
    private final PerformanceService performanceService = new PerformanceService();

    /**
     * Bulk computation:
     *   1 SELECT  for employees
     *   1 SELECT  for task counts per (user_id, status)        — replaces N queries
     *   1 SELECT  for overdue task count per user_id           — replaces N queries
     *   N SELECTs (one per employee) for productivity score    — unchanged for now
     *
     * Old version did 3 queries × N employees on the task side. New version: 2.
     */
    public List<WorkloadEntry> getAllWorkloads() {
        List<WorkloadEntry> out = new ArrayList<>();
        List<Employee> employees = employeeService.getAllEmployees();
        if (employees == null || employees.isEmpty()) return out;

        // Collect user IDs once.
        List<Integer> userIds = new ArrayList<>(employees.size());
        for (Employee e : employees) {
            Integer uid = e.getUserId();
            if (uid != null && uid > 0) userIds.add(uid);
        }
        if (userIds.isEmpty()) return out;

        Map<Integer, Map<String, Integer>> statusCounts = bulkStatusCounts(userIds);
        Map<Integer, Integer>              overdueCounts = bulkOverdueCounts(userIds);

        for (Employee e : employees) {
            Integer userId = e.getUserId();
            if (userId == null || userId <= 0) continue;

            Map<String, Integer> counts = statusCounts.getOrDefault(userId, java.util.Collections.emptyMap());
            int pending   = counts.getOrDefault("PENDING",     0);
            int active    = counts.getOrDefault("IN_PROGRESS", 0);
            int completed = counts.getOrDefault("COMPLETED",   0);
            int overdue   = overdueCounts.getOrDefault(userId, 0);
            int total     = pending + active + completed;

            int workloadScore = (pending * 2) + (overdue * 3) + active;
            double completionRate = total == 0 ? 0.0
                    : Math.round((completed * 1000.0) / total) / 10.0;

            // Productivity still per-employee (PerformanceService internal SQL is layered).
            PerformanceBreakdown perf = performanceService.getPerformanceBreakdown(userId);

            WorkloadEntry w = new WorkloadEntry();
            w.setEmployeeId(e.getId());
            w.setUserId(userId);
            w.setName(e.getName());
            w.setDepartment(e.getDepartment());
            w.setTotalAssignedTasks(total);
            w.setCompletedTasks(completed);
            w.setPendingTasks(pending);
            w.setActiveTasks(active);
            w.setOverdueTasks(overdue);
            w.setWorkloadScore(workloadScore);
            w.setCompletionRate(completionRate);
            w.setProductivityScore(perf == null ? 0.0 : perf.getFinalScore());
            out.add(w);
        }
        return out;
    }

    public Map<String, Integer> getDistribution(List<WorkloadEntry> all) {
        java.util.LinkedHashMap<String, Integer> dist = new java.util.LinkedHashMap<>();
        dist.put("LOW", 0);
        dist.put("BALANCED", 0);
        dist.put("OVERLOADED", 0);
        if (all == null) return dist;
        for (WorkloadEntry w : all) {
            String s = w.getWorkloadStatus().toUpperCase();
            if ("OVERLOADED".equals(s)) dist.put("OVERLOADED", dist.get("OVERLOADED") + 1);
            else if ("BALANCED".equals(s)) dist.put("BALANCED", dist.get("BALANCED") + 1);
            else dist.put("LOW", dist.get("LOW") + 1);
        }
        return dist;
    }

    public List<WorkloadEntry> sortByWorkloadDesc(List<WorkloadEntry> all, int limit) {
        List<WorkloadEntry> copy = new ArrayList<>(all);
        copy.sort(Comparator.comparingInt(WorkloadEntry::getWorkloadScore).reversed());
        return copy.size() > limit ? copy.subList(0, limit) : copy;
    }

    public List<WorkloadEntry> sortByOverdueDesc(List<WorkloadEntry> all, int limit) {
        List<WorkloadEntry> copy = new ArrayList<>(all);
        copy.sort(Comparator.comparingInt(WorkloadEntry::getOverdueTasks).reversed());
        return copy.size() > limit ? copy.subList(0, limit) : copy;
    }

    // ───────────────────────────── internals ─────────────────────────────

    /** SELECT assigned_to, status, COUNT(*) GROUP BY assigned_to, status — one round-trip. */
    private Map<Integer, Map<String, Integer>> bulkStatusCounts(List<Integer> userIds) {
        Map<Integer, Map<String, Integer>> out = new HashMap<>();
        if (userIds == null || userIds.isEmpty()) return out;

        String placeholders = repeatPlaceholders(userIds.size());
        String sql = "SELECT assigned_to, status, COUNT(*) AS c FROM tasks "
                   + "WHERE assigned_to IN (" + placeholders + ") "
                   + "GROUP BY assigned_to, status";

        try (Connection c = DBConfig.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            for (int i = 0; i < userIds.size(); i++) ps.setInt(i + 1, userIds.get(i));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    int uid = rs.getInt("assigned_to");
                    String status = rs.getString("status");
                    int count = rs.getInt("c");
                    out.computeIfAbsent(uid, k -> new HashMap<>()).put(status, count);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return out;
    }

    /** SELECT assigned_to, COUNT(*) FROM tasks WHERE overdue+open GROUP BY assigned_to. */
    private Map<Integer, Integer> bulkOverdueCounts(List<Integer> userIds) {
        Map<Integer, Integer> out = new HashMap<>();
        if (userIds == null || userIds.isEmpty()) return out;

        String placeholders = repeatPlaceholders(userIds.size());
        String sql = "SELECT assigned_to, COUNT(*) AS c FROM tasks "
                   + "WHERE assigned_to IN (" + placeholders + ") "
                   + "AND due_date IS NOT NULL AND due_date < CURDATE() "
                   + "AND status <> 'COMPLETED' "
                   + "GROUP BY assigned_to";

        try (Connection c = DBConfig.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            for (int i = 0; i < userIds.size(); i++) ps.setInt(i + 1, userIds.get(i));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) out.put(rs.getInt("assigned_to"), rs.getInt("c"));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return out;
    }

    private static String repeatPlaceholders(int n) {
        StringBuilder sb = new StringBuilder(n * 2);
        for (int i = 0; i < n; i++) {
            if (i > 0) sb.append(',');
            sb.append('?');
        }
        return sb.toString();
    }
}
