package com.ems.service;

import com.ems.config.DBConfig;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

import com.ems.model.AttendanceSnapshot;

public class AttendanceService {

    public static final LocalTime WORK_START      = LocalTime.of(9, 0);
    public static final LocalTime LATE_THRESHOLD  = LocalTime.of(9, 15);
    public static final LocalTime WORK_END        = LocalTime.of(17, 0);
    private static final String LATE_TIME_SQL       = "09:15:00";
    private static final String EARLY_LEAVE_TIME_SQL = "17:00:00";

    public static class AttendanceActionResult {
        private final boolean success;
        private final String message;

        public AttendanceActionResult(boolean success, String message) {
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

    public AttendanceActionResult attemptCheckIn(int userId) {
        if (!canCheckIn(userId)) {
            return new AttendanceActionResult(false, "You have already checked in today.");
        }
        boolean saved = checkIn(userId);
        return new AttendanceActionResult(saved, saved
                ? "Attendance saved for today."
                : "Unable to save attendance. Please check database setup.");
    }

    public AttendanceActionResult attemptCheckOut(int userId) {
        if (!canCheckOut(userId)) {
            return new AttendanceActionResult(false, "Please check in before checking out.");
        }
        boolean saved = checkOut(userId);
        return new AttendanceActionResult(saved, saved
                ? "Attendance saved for today."
                : "Unable to save attendance. Please check database setup.");
    }

    public boolean canCheckIn(int userId) {
        return !hasAttendanceToday(userId);
    }

    public boolean canCheckOut(int userId) {
        return hasOpenSession(userId);
    }

    public boolean checkIn(int userId) {
        Integer attendanceUserId = userId;
        if (!canCheckIn(attendanceUserId)) {
            return false;
        }
        if (hasOpenSession(attendanceUserId)) {
            return false;
        }

        String sql = "INSERT INTO attendance (user_id, work_date, check_in, status) VALUES (?,?,?,?)";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, attendanceUserId);
            statement.setDate(2, Date.valueOf(LocalDate.now()));
            statement.setTimestamp(3, java.sql.Timestamp.valueOf(java.time.LocalDateTime.now()));
            statement.setString(4, "PRESENT");
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean checkOut(int userId) {
        Integer attendanceUserId = userId;
        if (!canCheckOut(attendanceUserId)) {
            return false;
        }

        String sql = "UPDATE attendance SET check_out=? WHERE user_id=? AND work_date=? AND check_out IS NULL ORDER BY check_in DESC LIMIT 1";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setTimestamp(1, java.sql.Timestamp.valueOf(java.time.LocalDateTime.now()));
            statement.setInt(2, attendanceUserId);
            statement.setDate(3, Date.valueOf(LocalDate.now()));
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean hasCheckedInToday(int userId) {
        return hasAttendanceToday(userId);
    }

    public boolean hasCheckedOutToday(int userId) {
        Integer attendanceUserId = userId;
        String sql = "SELECT 1 FROM attendance WHERE user_id=? AND work_date=? AND check_in IS NOT NULL AND check_out IS NOT NULL";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, attendanceUserId);
            statement.setDate(2, Date.valueOf(LocalDate.now()));
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next();
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public AttendanceSnapshot getTodaySnapshot(int userId) {
        String sql = "SELECT check_in, check_out, status FROM attendance WHERE user_id=? AND work_date=? ORDER BY check_in DESC LIMIT 1";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            statement.setDate(2, Date.valueOf(LocalDate.now()));
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    AttendanceSnapshot snapshot = new AttendanceSnapshot();
                    java.sql.Timestamp checkIn = resultSet.getTimestamp("check_in");
                    java.sql.Timestamp checkOut = resultSet.getTimestamp("check_out");
                    snapshot.setCheckInTime(checkIn == null ? null : new java.sql.Time(checkIn.getTime()));
                    snapshot.setCheckOutTime(checkOut == null ? null : new java.sql.Time(checkOut.getTime()));
                    snapshot.setStatus(resultSet.getString("status"));
                    return snapshot;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public int getActiveEmployeeCount() {
        String sql = "SELECT COUNT(DISTINCT user_id) AS total FROM attendance WHERE work_date=? AND check_in IS NOT NULL AND check_out IS NULL";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setDate(1, Date.valueOf(LocalDate.now()));
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

    public int getTotalAttendanceCount() {
        String sql = "SELECT COUNT(*) AS total FROM attendance";
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

    public int getAttendanceCountForUser(int userId) {
        String sql = "SELECT COUNT(*) AS total FROM attendance WHERE user_id=?";
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

    public int getAttendanceCountForUserInRange(int userId, LocalDate startDate, LocalDate endDate) {
        if (startDate == null || endDate == null) {
            return getAttendanceCountForUser(userId);
        }
        String sql = "SELECT COUNT(*) AS total FROM attendance WHERE user_id=? AND work_date BETWEEN ? AND ?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            statement.setDate(2, Date.valueOf(startDate));
            statement.setDate(3, Date.valueOf(endDate));
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

    public java.util.List<com.ems.model.AttendanceRow> getRecentAttendance(int limit) {
        java.util.List<com.ems.model.AttendanceRow> rows = new java.util.ArrayList<>();
        String sql = "SELECT e.id, a.user_id, e.name, e.email, e.department, a.work_date, a.check_in, a.check_out, "
                + "CASE WHEN a.check_in IS NOT NULL AND a.check_out IS NULL THEN 'Active' ELSE 'Inactive' END AS attendance_status "
                + "FROM attendance a "
                + "JOIN employees e ON e.user_id = a.user_id "
                + "ORDER BY a.work_date DESC, a.check_in DESC "
                + "LIMIT ?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, limit);
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    com.ems.model.AttendanceRow row = new com.ems.model.AttendanceRow();
                    row.setEmployeeId(resultSet.getInt("id"));
                    int __uid = resultSet.getInt("user_id"); row.setUserId(resultSet.wasNull() ? null : __uid);
                    row.setName(resultSet.getString("name"));
                    row.setEmail(resultSet.getString("email"));
                    row.setDepartment(resultSet.getString("department"));
                    row.setWorkDate(resultSet.getDate("work_date"));
                    java.sql.Timestamp checkIn = resultSet.getTimestamp("check_in");
                    java.sql.Timestamp checkOut = resultSet.getTimestamp("check_out");
                    row.setCheckInTime(checkIn == null ? null : new java.sql.Time(checkIn.getTime()));
                    row.setCheckOutTime(checkOut == null ? null : new java.sql.Time(checkOut.getTime()));
                    row.setAttendanceStatus(resultSet.getString("attendance_status"));
                    rows.add(row);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return rows;
    }

    public java.util.List<com.ems.model.AttendanceRow> getAttendanceByRange(LocalDate startDate, LocalDate endDate) {
        java.util.List<com.ems.model.AttendanceRow> rows = new java.util.ArrayList<>();
        if (startDate == null || endDate == null) {
            return getRecentAttendance(10);
        }
        String sql = "SELECT e.id, a.user_id, e.name, e.email, e.department, a.work_date, a.check_in, a.check_out, "
                + "CASE WHEN a.check_in IS NOT NULL AND a.check_out IS NULL THEN 'Active' ELSE 'Inactive' END AS attendance_status "
                + "FROM attendance a "
                + "JOIN employees e ON e.user_id = a.user_id "
                + "WHERE a.work_date BETWEEN ? AND ? "
                + "ORDER BY a.work_date DESC, a.check_in DESC";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setDate(1, Date.valueOf(startDate));
            statement.setDate(2, Date.valueOf(endDate));
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    com.ems.model.AttendanceRow row = new com.ems.model.AttendanceRow();
                    row.setEmployeeId(resultSet.getInt("id"));
                    int __uid = resultSet.getInt("user_id"); row.setUserId(resultSet.wasNull() ? null : __uid);
                    row.setName(resultSet.getString("name"));
                    row.setEmail(resultSet.getString("email"));
                    row.setDepartment(resultSet.getString("department"));
                    row.setWorkDate(resultSet.getDate("work_date"));
                    java.sql.Timestamp checkIn = resultSet.getTimestamp("check_in");
                    java.sql.Timestamp checkOut = resultSet.getTimestamp("check_out");
                    row.setCheckInTime(checkIn == null ? null : new java.sql.Time(checkIn.getTime()));
                    row.setCheckOutTime(checkOut == null ? null : new java.sql.Time(checkOut.getTime()));
                    row.setAttendanceStatus(resultSet.getString("attendance_status"));
                    rows.add(row);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return rows;
    }

    public java.util.List<com.ems.model.AttendanceRow> getRecentAttendanceByRange(LocalDate startDate, LocalDate endDate, int limit) {
        java.util.List<com.ems.model.AttendanceRow> rows = new java.util.ArrayList<>();
        if (startDate == null || endDate == null) {
            return getRecentAttendance(limit);
        }
        String sql = "SELECT e.id, a.user_id, e.name, e.email, e.department, a.work_date, a.check_in, a.check_out, "
                + "CASE WHEN a.check_in IS NOT NULL AND a.check_out IS NULL THEN 'Active' ELSE 'Inactive' END AS attendance_status "
                + "FROM attendance a "
                + "JOIN employees e ON e.user_id = a.user_id "
                + "WHERE a.work_date BETWEEN ? AND ? "
                + "ORDER BY a.work_date DESC, a.check_in DESC "
                + "LIMIT ?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setDate(1, Date.valueOf(startDate));
            statement.setDate(2, Date.valueOf(endDate));
            statement.setInt(3, limit);
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    com.ems.model.AttendanceRow row = new com.ems.model.AttendanceRow();
                    row.setEmployeeId(resultSet.getInt("id"));
                    int __uid = resultSet.getInt("user_id"); row.setUserId(resultSet.wasNull() ? null : __uid);
                    row.setName(resultSet.getString("name"));
                    row.setEmail(resultSet.getString("email"));
                    row.setDepartment(resultSet.getString("department"));
                    row.setWorkDate(resultSet.getDate("work_date"));
                    java.sql.Timestamp checkIn = resultSet.getTimestamp("check_in");
                    java.sql.Timestamp checkOut = resultSet.getTimestamp("check_out");
                    row.setCheckInTime(checkIn == null ? null : new java.sql.Time(checkIn.getTime()));
                    row.setCheckOutTime(checkOut == null ? null : new java.sql.Time(checkOut.getTime()));
                    row.setAttendanceStatus(resultSet.getString("attendance_status"));
                    rows.add(row);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return rows;
    }

    public int getTodayAttendanceCount() {
        String sql = "SELECT COUNT(*) AS total FROM attendance WHERE work_date=?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setDate(1, Date.valueOf(LocalDate.now()));
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

    private boolean hasOpenSession(int userId) {
        String sql = "SELECT 1 FROM attendance WHERE user_id=? AND work_date=? AND check_in IS NOT NULL AND check_out IS NULL";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            statement.setDate(2, Date.valueOf(LocalDate.now()));
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next();
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    private boolean hasAttendanceToday(int userId) {
        String sql = "SELECT 1 FROM attendance WHERE user_id=? AND work_date=? AND check_in IS NOT NULL";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            statement.setDate(2, Date.valueOf(LocalDate.now()));
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next();
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public java.util.List<com.ems.model.AttendanceRow> getAttendanceHistoryForUser(int userId, int limit) {
        java.util.List<com.ems.model.AttendanceRow> rows = new java.util.ArrayList<>();
        String sql = "SELECT e.id, a.user_id, e.name, e.email, e.department, a.work_date, a.check_in, a.check_out, "
                + "CASE WHEN a.check_in IS NOT NULL AND a.check_out IS NULL THEN 'Active' ELSE 'Inactive' END AS attendance_status "
                + "FROM attendance a "
                + "JOIN employees e ON e.user_id = a.user_id "
                + "WHERE a.user_id=? "
                + "ORDER BY a.work_date DESC, a.check_in DESC "
                + "LIMIT ?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            statement.setInt(2, limit);
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    com.ems.model.AttendanceRow row = new com.ems.model.AttendanceRow();
                    row.setEmployeeId(resultSet.getInt("id"));
                    int __uid = resultSet.getInt("user_id"); row.setUserId(resultSet.wasNull() ? null : __uid);
                    row.setName(resultSet.getString("name"));
                    row.setEmail(resultSet.getString("email"));
                    row.setDepartment(resultSet.getString("department"));
                    row.setWorkDate(resultSet.getDate("work_date"));
                    java.sql.Timestamp checkIn = resultSet.getTimestamp("check_in");
                    java.sql.Timestamp checkOut = resultSet.getTimestamp("check_out");
                    row.setCheckInTime(checkIn == null ? null : new java.sql.Time(checkIn.getTime()));
                    row.setCheckOutTime(checkOut == null ? null : new java.sql.Time(checkOut.getTime()));
                    row.setAttendanceStatus(resultSet.getString("attendance_status"));
                    rows.add(row);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return rows;
    }

    public double getTodayWorkHours(int userId) {
        String sql = "SELECT check_in, check_out FROM attendance WHERE user_id=? AND work_date=? ORDER BY check_in DESC LIMIT 1";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            statement.setDate(2, Date.valueOf(LocalDate.now()));
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    Timestamp checkIn = resultSet.getTimestamp("check_in");
                    Timestamp checkOut = resultSet.getTimestamp("check_out");
                    if (checkIn == null || checkOut == null) {
                        return 0.0;
                    }
                    long minutes = Duration.between(checkIn.toInstant(), checkOut.toInstant()).toMinutes();
                    if (minutes <= 0) {
                        return 0.0;
                    }
                    return minutes / 60.0;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0.0;
    }

    public boolean isLateToday(int userId) {
        String sql = "SELECT check_in FROM attendance WHERE user_id=? AND work_date=? ORDER BY check_in DESC LIMIT 1";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            statement.setDate(2, Date.valueOf(LocalDate.now()));
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    Timestamp checkIn = resultSet.getTimestamp("check_in");
                    if (checkIn == null) {
                        return false;
                    }
                    LocalTime checkInTime = checkIn.toLocalDateTime().toLocalTime();
                    return checkInTime.isAfter(LATE_THRESHOLD);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public int getWeeklyAttendanceCount(int userId) {
        LocalDate end = LocalDate.now();
        LocalDate start = end.minusDays(6);
        String sql = "SELECT COUNT(DISTINCT work_date) AS total FROM attendance WHERE user_id=? AND work_date BETWEEN ? AND ?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            statement.setDate(2, Date.valueOf(start));
            statement.setDate(3, Date.valueOf(end));
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

    public int getLateDaysThisWeek(int userId) {
        LocalDate end = LocalDate.now();
        LocalDate start = end.minusDays(6);
        String sql = "SELECT COUNT(*) AS total FROM attendance WHERE user_id=? AND work_date BETWEEN ? AND ? AND TIME(check_in) > '" + LATE_TIME_SQL + "'";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            statement.setDate(2, Date.valueOf(start));
            statement.setDate(3, Date.valueOf(end));
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

    public List<com.ems.model.AttendanceRow> getAttendanceRecords(LocalDate date, Integer employeeId, int limit, int offset) {
        List<com.ems.model.AttendanceRow> rows = new ArrayList<>();
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT e.id, a.user_id, e.name, e.email, e.department, a.work_date, a.check_in, a.check_out, ")
           .append("CASE WHEN a.check_in IS NOT NULL AND a.check_out IS NULL THEN 'Active' ELSE 'Inactive' END AS attendance_status ")
           .append("FROM attendance a ")
           .append("JOIN employees e ON e.user_id = a.user_id ");
        List<Object> params = new ArrayList<>();
        boolean whereAdded = false;
        if (date != null) {
            sql.append("WHERE a.work_date = ? ");
            params.add(Date.valueOf(date));
            whereAdded = true;
        }
        if (employeeId != null && employeeId > 0) {
            sql.append(whereAdded ? "AND " : "WHERE ");
            sql.append("e.id = ? ");
            params.add(employeeId);
        }
        sql.append("ORDER BY a.work_date DESC, a.check_in DESC LIMIT ? OFFSET ?");
        params.add(limit);
        params.add(offset);

        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                statement.setObject(i + 1, params.get(i));
            }
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    com.ems.model.AttendanceRow row = new com.ems.model.AttendanceRow();
                    row.setEmployeeId(resultSet.getInt("id"));
                    int __uid = resultSet.getInt("user_id"); row.setUserId(resultSet.wasNull() ? null : __uid);
                    row.setName(resultSet.getString("name"));
                    row.setEmail(resultSet.getString("email"));
                    row.setDepartment(resultSet.getString("department"));
                    row.setWorkDate(resultSet.getDate("work_date"));
                    java.sql.Timestamp checkIn = resultSet.getTimestamp("check_in");
                    java.sql.Timestamp checkOut = resultSet.getTimestamp("check_out");
                    row.setCheckInTime(checkIn == null ? null : new java.sql.Time(checkIn.getTime()));
                    row.setCheckOutTime(checkOut == null ? null : new java.sql.Time(checkOut.getTime()));
                    row.setAttendanceStatus(resultSet.getString("attendance_status"));
                    rows.add(row);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return rows;
    }

    public int getAttendanceRecordCount(LocalDate date, Integer employeeId) {
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT COUNT(*) AS total FROM attendance a JOIN employees e ON e.user_id = a.user_id ");
        List<Object> params = new ArrayList<>();
        boolean whereAdded = false;
        if (date != null) {
            sql.append("WHERE a.work_date = ? ");
            params.add(Date.valueOf(date));
            whereAdded = true;
        }
        if (employeeId != null && employeeId > 0) {
            sql.append(whereAdded ? "AND " : "WHERE ");
            sql.append("e.id = ? ");
            params.add(employeeId);
        }
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                statement.setObject(i + 1, params.get(i));
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

    public int getEarlyLeaveDaysThisWeek(int userId) {
        LocalDate end = LocalDate.now();
        LocalDate start = end.minusDays(6);
        String sql = "SELECT COUNT(*) AS total FROM attendance WHERE user_id=? AND work_date BETWEEN ? AND ? "
                + "AND check_out IS NOT NULL AND TIME(check_out) < '" + EARLY_LEAVE_TIME_SQL + "'";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            statement.setDate(2, Date.valueOf(start));
            statement.setDate(3, Date.valueOf(end));
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

    public java.util.List<int[]> getDailyAttendanceCounts(int days) {
        java.util.List<int[]> result = new java.util.ArrayList<>();
        if (days <= 0) return result;
        LocalDate end = LocalDate.now();
        LocalDate start = end.minusDays(days - 1L);
        java.util.Map<LocalDate, Integer> map = new java.util.HashMap<>();
        String sql = "SELECT work_date, COUNT(DISTINCT user_id) AS c FROM attendance "
                + "WHERE work_date BETWEEN ? AND ? GROUP BY work_date";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setDate(1, Date.valueOf(start));
            statement.setDate(2, Date.valueOf(end));
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    map.put(rs.getDate("work_date").toLocalDate(), rs.getInt("c"));
                }
            }
        } catch (SQLException e) { e.printStackTrace(); }
        for (int i = 0; i < days; i++) {
            LocalDate d = start.plusDays(i);
            result.add(new int[]{ (int) d.toEpochDay(), map.getOrDefault(d, 0) });
        }
        return result;
    }

    public int getLateCountForUserInRange(int userId, LocalDate start, LocalDate end) {
        if (start == null || end == null) return 0;
        String sql = "SELECT COUNT(*) AS total FROM attendance WHERE user_id=? AND work_date BETWEEN ? AND ? "
                + "AND TIME(check_in) > '" + LATE_TIME_SQL + "'";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            statement.setDate(2, Date.valueOf(start));
            statement.setDate(3, Date.valueOf(end));
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) return rs.getInt("total");
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }

    /** Overtime worked this week, in minutes (any check_out beyond WORK_END, summed). */
    public long getOvertimeMinutesThisWeek(int userId) {
        LocalDate end = LocalDate.now();
        LocalDate start = end.minusDays(6);
        String sql = "SELECT check_out FROM attendance WHERE user_id=? AND work_date BETWEEN ? AND ? "
                + "AND check_out IS NOT NULL";
        long total = 0;
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            statement.setDate(2, Date.valueOf(start));
            statement.setDate(3, Date.valueOf(end));
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    java.sql.Timestamp out = rs.getTimestamp("check_out");
                    if (out == null) continue;
                    LocalTime t = out.toLocalDateTime().toLocalTime();
                    if (t.isAfter(WORK_END)) {
                        total += Duration.between(WORK_END, t).toMinutes();
                    }
                }
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return total;
    }

    /** Consecutive distinct working days ending today (or yesterday if no entry today). */
    public int getCurrentStreak(int userId) {
        String sql = "SELECT DISTINCT work_date FROM attendance WHERE user_id=? "
                + "ORDER BY work_date DESC LIMIT 60";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            try (ResultSet rs = statement.executeQuery()) {
                LocalDate today = LocalDate.now();
                LocalDate expected = null;
                int streak = 0;
                boolean first = true;
                while (rs.next()) {
                    LocalDate d = rs.getDate("work_date").toLocalDate();
                    if (first) {
                        first = false;
                        if (d.equals(today))                   { streak = 1; expected = today.minusDays(1); }
                        else if (d.equals(today.minusDays(1))) { streak = 1; expected = today.minusDays(2); }
                        else                                   { return 0; }
                    } else if (d.equals(expected)) {
                        streak++;
                        expected = expected.minusDays(1);
                    } else {
                        break;
                    }
                }
                return streak;
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }

    public com.ems.model.AttendanceDiscipline getDisciplineThisWeek(int userId) {
        int total       = getWeeklyAttendanceCount(userId);
        int late        = getLateDaysThisWeek(userId);
        int earlyLeave  = getEarlyLeaveDaysThisWeek(userId);
        int onTime      = Math.max(0, total - late);

        double score;
        if (total == 0) {
            score = 0.0;
        } else {
            double penalty = (late * 8.0) + (earlyLeave * 6.0);
            score = 100.0 - penalty;
            if (score < 0) score = 0;
            if (score > 100) score = 100;
        }
        score = Math.round(score * 10.0) / 10.0;

        com.ems.model.AttendanceDiscipline d = new com.ems.model.AttendanceDiscipline();
        d.setUserId(userId);
        d.setTotalDays(total);
        d.setLateCount(late);
        d.setEarlyLeaveCount(earlyLeave);
        d.setOnTimeCount(onTime);
        d.setAttendanceDisciplineScore(score);
        return d;
    }
}
