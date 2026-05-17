package com.ems.service;

import com.ems.config.DBConfig;
import com.ems.model.AdminNotification;
import com.ems.model.AttendanceRow;
import com.ems.model.Employee;
import com.ems.model.Notification;
import com.ems.model.Task;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class NotificationService {

    private static final int RECENT_ASSIGN_DAYS = 2;
    private static final double LOW_ATTENDANCE_THRESHOLD = 0.60; // 60%

    public static final String T_EMPLOYEE_CREATE  = "EMPLOYEE_CREATE";
    public static final String T_OVERDUE_TASK     = "OVERDUE_TASK";
    public static final String T_MISSED_CHECKOUT  = "MISSED_CHECKOUT";
    public static final String T_LOW_ATTENDANCE   = "LOW_ATTENDANCE";
    public static final String T_PASSWORD_CHANGE  = "PASSWORD_CHANGE";

    private final TaskService taskService = new TaskService();
    private final AttendanceService attendanceService = new AttendanceService();
    private final EmployeeService   employeeService   = new EmployeeService();

    public List<Notification> forEmployee(int userId) {
        List<Notification> out = new ArrayList<>();
        List<Task> tasks = taskService.getTasksByEmployee(userId);
        LocalDate today = LocalDate.now();

        int pending = 0;
        for (Task t : tasks) {
            String status = t.getStatus();
            if ("PENDING".equalsIgnoreCase(status) || "IN_PROGRESS".equalsIgnoreCase(status)) {
                pending++;
                Date due = t.getDueDate();
                if (due != null && due.toLocalDate().isBefore(today)) {
                    long daysOver = ChronoUnit.DAYS.between(due.toLocalDate(), today);
                    out.add(new Notification(
                            "task-overdue-" + t.getId(),
                            "OVERDUE_TASK",
                            "danger",
                            "Overdue task",
                            t.getTitle() + " was due " + daysOver + " day" + (daysOver == 1 ? "" : "s") + " ago.",
                            "tasks"
                    ));
                }
            }
            if (t.getCreatedAt() != null) {
                long daysSince = ChronoUnit.DAYS.between(t.getCreatedAt().toLocalDateTime().toLocalDate(), today);
                if (daysSince >= 0 && daysSince <= RECENT_ASSIGN_DAYS
                        && ("PENDING".equalsIgnoreCase(t.getStatus()) || "IN_PROGRESS".equalsIgnoreCase(t.getStatus()))) {
                    out.add(new Notification(
                            "task-assigned-" + t.getId(),
                            "TASK_ASSIGNED",
                            "info",
                            "New task assigned",
                            t.getTitle() + (t.getDueDate() == null ? "" : " · due " + t.getDueDate()),
                            "tasks"
                    ));
                }
            }
        }

        if (pending > 0) {
            out.add(new Notification(
                    "tasks-pending",
                    "PENDING_TASKS",
                    "warning",
                    "Pending tasks",
                    "You have " + pending + " task" + (pending == 1 ? "" : "s") + " in progress or pending.",
                    "tasks"
            ));
        }

        if (attendanceService.isLateToday(userId)) {
            out.add(new Notification(
                    "attendance-late",
                    "LATE_ATTENDANCE",
                    "warning",
                    "Late check-in today",
                    "Your check-in was after 09:15. Try to arrive by 09:00 to keep your discipline score up.",
                    null
            ));
        }

        return out;
    }

    // ============================================================
    //  ADMIN NOTIFICATIONS — persisted in admin_notifications table
    // ============================================================

    /** Idempotent insert: dedupe_key uniqueness prevents repeats. */
    public boolean push(String type, String severity, String title, String message,
                        String href, String dedupeKey) {
        String sql = "INSERT IGNORE INTO admin_notifications "
                + "(type, severity, title, message, href, dedupe_key) VALUES (?,?,?,?,?,?)";
        try (Connection c = DBConfig.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, type);
            ps.setString(2, severity == null ? "info" : severity);
            ps.setString(3, truncate(title, 160));
            if (message != null) ps.setString(4, truncate(message, 500)); else ps.setNull(4, java.sql.Types.VARCHAR);
            if (href    != null) ps.setString(5, truncate(href, 255));    else ps.setNull(5, java.sql.Types.VARCHAR);
            ps.setString(6, truncate(dedupeKey, 120));
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.out.println("[NotificationService] push failed: " + e.getMessage());
            return false;
        }
    }

    /** Trigger called from EmployeeServlet after a successful create. */
    public void notifyEmployeeCreated(int newEmployeeId, String name, String email) {
        push(T_EMPLOYEE_CREATE, "info",
                "New employee onboarded",
                (name == null ? "Employee" : name) + " (" + (email == null ? "—" : email) + ") was added.",
                "employees",
                "EMPLOYEE_CREATE_" + newEmployeeId);
    }

    /** Trigger called from ChangePasswordServlet after a successful change. */
    public void notifyPasswordChange(int userId, String username) {
        push(T_PASSWORD_CHANGE, "warn",
                "Password changed",
                (username == null ? "user#" + userId : username) + " updated their password.",
                null,
                "PASSWORD_CHANGE_" + userId + "_" + LocalDate.now());
    }

    /**
     * Run lightweight scans and insert any new alerts that are not already in the table
     * (idempotent via dedupe_key). Cheap enough to call on every admin page load.
     */
    public void scanAndPersist() {
        LocalDate today = LocalDate.now();

        // 1. Overdue tasks — one notification per still-incomplete overdue task.
        try {
            List<Task> tasks = taskService.getAllTasks();
            if (tasks != null) {
                for (Task t : tasks) {
                    if (t.getDueDate() == null) continue;
                    if (!t.getDueDate().toLocalDate().isBefore(today)) continue;
                    String s = t.getStatus();
                    if ("COMPLETED".equalsIgnoreCase(s)) continue;
                    push(T_OVERDUE_TASK, "err",
                            "Overdue task",
                            t.getTitle() + (t.getAssignedToName() == null ? "" : " · " + t.getAssignedToName())
                                  + " · due " + t.getDueDate(),
                            "tasks",
                            "OVERDUE_TASK_" + t.getId());
                }
            }
        } catch (Exception e) {
            System.out.println("[NotificationService] overdue scan failed: " + e.getMessage());
        }

        // 2. Missed check-out (yesterday): user has check_in but no check_out for the prior work day.
        try {
            LocalDate yesterday = today.minusDays(1);
            List<AttendanceRow> rows = attendanceService.getAttendanceByRange(yesterday, yesterday);
            if (rows != null) {
                Set<Integer> seen = new HashSet<>();
                for (AttendanceRow r : rows) {
                    if (r.getCheckInTime() == null || r.getCheckOutTime() != null) continue;
                    int empId = r.getEmployeeId();
                    if (!seen.add(empId)) continue;
                    push(T_MISSED_CHECKOUT, "warn",
                            "Missed check-out",
                            (r.getName() == null ? "Employee #" + empId : r.getName())
                                  + " did not check out on " + yesterday,
                            "attendance",
                            "MISSED_CHECKOUT_" + empId + "_" + yesterday);
                }
            }
        } catch (Exception e) {
            System.out.println("[NotificationService] missed-checkout scan failed: " + e.getMessage());
        }

        // 3. Low attendance today (< threshold of headcount).
        try {
            int headcount = employeeService.getEmployeeCount();
            int present   = attendanceService.getTodayAttendanceCount();
            if (headcount >= 3) {  // skip the warning when there's barely anyone in the system
                double rate = (double) present / (double) headcount;
                if (rate < LOW_ATTENDANCE_THRESHOLD) {
                    int pct = (int) Math.round(rate * 100);
                    push(T_LOW_ATTENDANCE, "warn",
                            "Low attendance today",
                            "Only " + present + " of " + headcount + " employees checked in (" + pct + "%).",
                            "attendance",
                            "LOW_ATTENDANCE_" + today);
                }
            }
        } catch (Exception e) {
            System.out.println("[NotificationService] low-attendance scan failed: " + e.getMessage());
        }
    }

    /** Convenience: run scans then return the freshest unread+read alerts (limit 30). */
    public List<AdminNotification> getAdminNotifications() {
        scanAndPersist();
        return loadAdmin(false, 30);
    }

    public List<AdminNotification> loadAdmin(boolean unreadOnly, int limit) {
        String sql = "SELECT * FROM admin_notifications "
                   + (unreadOnly ? "WHERE read_at IS NULL " : "")
                   + "ORDER BY (read_at IS NULL) DESC, created_at DESC LIMIT ?";
        List<AdminNotification> out = new ArrayList<>();
        try (Connection c = DBConfig.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) out.add(map(rs));
            }
        } catch (SQLException e) {
            System.out.println("[NotificationService] loadAdmin failed: " + e.getMessage());
        }
        return out;
    }

    public int getUnreadAdminCount() {
        try (Connection c = DBConfig.getConnection();
             PreparedStatement ps = c.prepareStatement(
                     "SELECT COUNT(*) FROM admin_notifications WHERE read_at IS NULL");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) {
            System.out.println("[NotificationService] getUnreadAdminCount failed: " + e.getMessage());
        }
        return 0;
    }

    public boolean markAdminRead(long id) {
        return execUpdate("UPDATE admin_notifications SET read_at=CURRENT_TIMESTAMP "
                        + "WHERE id=? AND read_at IS NULL", id);
    }

    public int markAllAdminRead() {
        try (Connection c = DBConfig.getConnection();
             PreparedStatement ps = c.prepareStatement(
                     "UPDATE admin_notifications SET read_at=CURRENT_TIMESTAMP WHERE read_at IS NULL")) {
            return ps.executeUpdate();
        } catch (SQLException e) {
            System.out.println("[NotificationService] markAllAdminRead failed: " + e.getMessage());
            return 0;
        }
    }

    public int clearAllAdmin() {
        try (Connection c = DBConfig.getConnection();
             PreparedStatement ps = c.prepareStatement("DELETE FROM admin_notifications")) {
            return ps.executeUpdate();
        } catch (SQLException e) {
            System.out.println("[NotificationService] clearAllAdmin failed: " + e.getMessage());
            return 0;
        }
    }

    private boolean execUpdate(String sql, long id) {
        try (Connection c = DBConfig.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setLong(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.out.println("[NotificationService] update failed: " + e.getMessage());
            return false;
        }
    }

    private AdminNotification map(ResultSet rs) throws SQLException {
        AdminNotification a = new AdminNotification();
        a.setId(rs.getLong("id"));
        a.setType(rs.getString("type"));
        a.setSeverity(rs.getString("severity"));
        a.setTitle(rs.getString("title"));
        a.setMessage(rs.getString("message"));
        a.setHref(rs.getString("href"));
        a.setDedupeKey(rs.getString("dedupe_key"));
        a.setCreatedAt(rs.getTimestamp("created_at"));
        a.setReadAt(rs.getTimestamp("read_at"));
        return a;
    }

    private String truncate(String v, int max) {
        if (v == null) return null;
        return v.length() <= max ? v : v.substring(0, max);
    }
}
