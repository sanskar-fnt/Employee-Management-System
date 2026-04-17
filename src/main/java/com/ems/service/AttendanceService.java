package com.ems.service;

import com.ems.config.DBConfig;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Time;
import java.time.LocalDate;
import java.time.LocalTime;

import com.ems.model.AttendanceSnapshot;

public class AttendanceService {

    public boolean checkIn(int userId) {
        Integer attendanceUserId = userId;
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
        if (!hasOpenSession(attendanceUserId)) {
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
        return hasOpenSession(userId);
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
        String sql = "SELECT e.id, e.name, e.email, e.department, a.work_date, a.check_in, a.check_out, "
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
        String sql = "SELECT e.id, e.name, e.email, e.department, a.work_date, a.check_in, a.check_out, "
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
        String sql = "SELECT e.id, e.name, e.email, e.department, a.work_date, a.check_in, a.check_out, "
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
}