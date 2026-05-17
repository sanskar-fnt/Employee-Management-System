package com.ems.service;

import com.ems.config.DBConfig;
import com.ems.model.LeaveRequest;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class LeaveService {

    public static class LeaveResult {
        private final boolean success;
        private final String  message;
        public LeaveResult(boolean s, String m) { success = s; message = m; }
        public boolean isSuccess() { return success; }
        public String  getMessage() { return message; }
    }

    /** Validate + insert a new pending request. */
    public LeaveResult applyLeave(int userId, String leaveType, LocalDate start, LocalDate end, String reason) {
        if (userId <= 0)               return new LeaveResult(false, "Invalid user.");
        if (start == null || end == null) return new LeaveResult(false, "Both start and end dates are required.");
        if (end.isBefore(start))       return new LeaveResult(false, "End date cannot be before start date.");
        if (start.isBefore(LocalDate.now())) return new LeaveResult(false, "Cannot apply for a leave in the past.");
        if (reason == null || reason.trim().isEmpty()) return new LeaveResult(false, "Reason is required.");
        String type = isAllowedType(leaveType) ? leaveType.trim().toUpperCase() : "CASUAL";

        String sql = "INSERT INTO leave_requests (user_id, leave_type, start_date, end_date, reason, status) "
                + "VALUES (?,?,?,?,?,?)";
        try (Connection c = DBConfig.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt   (1, userId);
            ps.setString(2, type);
            ps.setDate  (3, Date.valueOf(start));
            ps.setDate  (4, Date.valueOf(end));
            ps.setString(5, reason.trim());
            ps.setString(6, LeaveRequest.PENDING);
            return ps.executeUpdate() > 0
                    ? new LeaveResult(true,  "Leave request submitted.")
                    : new LeaveResult(false, "Could not submit leave request.");
        } catch (SQLException e) {
            e.printStackTrace();
            return new LeaveResult(false, "Database error: " + e.getMessage());
        }
    }

    /** Admin decides on a request. status must be APPROVED or REJECTED. */
    public LeaveResult decide(int requestId, String status, int adminUserId) {
        if (!LeaveRequest.APPROVED.equals(status) && !LeaveRequest.REJECTED.equals(status)) {
            return new LeaveResult(false, "Invalid decision.");
        }
        String sql = "UPDATE leave_requests SET status=?, decided_by=?, decided_at=CURRENT_TIMESTAMP "
                + "WHERE id=? AND status='PENDING'";
        try (Connection c = DBConfig.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt   (2, adminUserId);
            ps.setInt   (3, requestId);
            int n = ps.executeUpdate();
            return n > 0
                    ? new LeaveResult(true,  "Leave " + status.toLowerCase() + ".")
                    : new LeaveResult(false, "Leave request not found or already decided.");
        } catch (SQLException e) {
            e.printStackTrace();
            return new LeaveResult(false, "Database error: " + e.getMessage());
        }
    }

    public List<LeaveRequest> findForUser(int userId, int limit) {
        return query("WHERE l.user_id = ? ORDER BY l.created_at DESC LIMIT ?",
                ps -> { ps.setInt(1, userId); ps.setInt(2, limit); });
    }

    /** Admin view: optional status filter (PENDING / APPROVED / REJECTED / null=all). */
    public List<LeaveRequest> findAll(String statusFilter, int limit, int offset) {
        if (statusFilter != null && !statusFilter.trim().isEmpty()
                && (LeaveRequest.PENDING.equals(statusFilter)
                 || LeaveRequest.APPROVED.equals(statusFilter)
                 || LeaveRequest.REJECTED.equals(statusFilter))) {
            return query("WHERE l.status = ? ORDER BY l.created_at DESC LIMIT ? OFFSET ?",
                    ps -> { ps.setString(1, statusFilter); ps.setInt(2, limit); ps.setInt(3, offset); });
        }
        return query("ORDER BY l.created_at DESC LIMIT ? OFFSET ?",
                ps -> { ps.setInt(1, limit); ps.setInt(2, offset); });
    }

    public int countAll(String statusFilter) {
        String sql = "SELECT COUNT(*) FROM leave_requests"
                + (statusFilter != null && !statusFilter.trim().isEmpty() ? " WHERE status=?" : "");
        try (Connection c = DBConfig.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            if (statusFilter != null && !statusFilter.trim().isEmpty()) ps.setString(1, statusFilter);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }

    public int countPending() { return countAll(LeaveRequest.PENDING); }

    /**
     * For each row in `rows`, set its `onLeave` flag to true when the row's
     * (userId, workDate) is covered by an APPROVED leave. Safe to call with
     * null/empty input. Performs at most one DB call per distinct (user, day).
     */
    public void markOnLeave(java.util.List<com.ems.model.AttendanceRow> rows) {
        if (rows == null || rows.isEmpty()) return;
        java.util.Map<String, Boolean> cache = new java.util.HashMap<>();
        for (com.ems.model.AttendanceRow r : rows) {
            Integer uid = r.getUserId();
            java.sql.Date wd = r.getWorkDate();
            if (uid == null || uid <= 0 || wd == null) continue;
            String key = uid + "|" + wd.toString();
            Boolean cached = cache.get(key);
            if (cached == null) {
                cached = isOnApprovedLeave(uid, wd.toLocalDate());
                cache.put(key, cached);
            }
            r.setOnLeave(cached);
        }
    }

    /** True iff `userId` has an APPROVED leave covering `date`. */
    public boolean isOnApprovedLeave(int userId, LocalDate date) {
        if (date == null) return false;
        String sql = "SELECT 1 FROM leave_requests WHERE user_id=? AND status='APPROVED' "
                + "AND start_date <= ? AND end_date >= ? LIMIT 1";
        try (Connection c = DBConfig.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ps.setDate(2, Date.valueOf(date));
            ps.setDate(3, Date.valueOf(date));
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    /** Count distinct working days within [start, end] that are covered by an APPROVED leave. */
    public int approvedLeaveDaysInRange(int userId, LocalDate start, LocalDate end) {
        if (start == null || end == null || end.isBefore(start)) return 0;
        // Pull approved leave windows that overlap the range, then compute the union of days.
        String sql = "SELECT start_date, end_date FROM leave_requests "
                + "WHERE user_id=? AND status='APPROVED' AND start_date<=? AND end_date>=?";
        java.util.Set<LocalDate> days = new java.util.HashSet<>();
        try (Connection c = DBConfig.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ps.setDate(2, Date.valueOf(end));
            ps.setDate(3, Date.valueOf(start));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    LocalDate s = rs.getDate("start_date").toLocalDate();
                    LocalDate e = rs.getDate("end_date").toLocalDate();
                    LocalDate from = s.isBefore(start) ? start : s;
                    LocalDate to   = e.isAfter(end)   ? end   : e;
                    for (LocalDate d = from; !d.isAfter(to); d = d.plusDays(1)) {
                        days.add(d);
                    }
                }
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return days.size();
    }

    // -------------- internals --------------

    private interface Binder { void bind(PreparedStatement ps) throws SQLException; }

    private List<LeaveRequest> query(String tail, Binder binder) {
        String sql = "SELECT l.*, u.username AS uname, e.name AS ename "
                + "FROM leave_requests l "
                + "LEFT JOIN users u     ON u.id = l.user_id "
                + "LEFT JOIN employees e ON e.user_id = l.user_id " + tail;
        List<LeaveRequest> out = new ArrayList<>();
        try (Connection c = DBConfig.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            binder.bind(ps);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) out.add(map(rs));
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return out;
    }

    private LeaveRequest map(ResultSet rs) throws SQLException {
        LeaveRequest r = new LeaveRequest();
        r.setId          (rs.getInt   ("id"));
        r.setUserId      (rs.getInt   ("user_id"));
        r.setUsername    (rs.getString("uname"));
        r.setEmployeeName(rs.getString("ename"));
        r.setLeaveType   (rs.getString("leave_type"));
        r.setStartDate   (rs.getDate  ("start_date"));
        r.setEndDate     (rs.getDate  ("end_date"));
        r.setReason      (rs.getString("reason"));
        r.setStatus      (rs.getString("status"));
        int db = rs.getInt("decided_by"); r.setDecidedBy(rs.wasNull() ? null : db);
        Timestamp da = rs.getTimestamp("decided_at"); r.setDecidedAt(da);
        r.setCreatedAt   (rs.getTimestamp("created_at"));
        return r;
    }

    private boolean isAllowedType(String t) {
        if (t == null) return false;
        String u = t.trim().toUpperCase();
        return u.equals("CASUAL") || u.equals("SICK") || u.equals("EARNED") || u.equals("UNPAID");
    }
}
