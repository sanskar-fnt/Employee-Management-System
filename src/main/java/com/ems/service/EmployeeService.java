package com.ems.service;

import com.ems.config.DBConfig;
import com.ems.model.AttendanceRow;
import com.ems.model.Employee;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class EmployeeService {

    public boolean addEmployee(Employee employee) {
        String sql = "INSERT INTO employees (name, email, phone, department) VALUES (?,?,?,?)";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, employee.getName());
            statement.setString(2, employee.getEmail());
            statement.setString(3, employee.getPhone());
            statement.setString(4, employee.getDepartment());
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean addEmployeeWithUserId(Employee employee, int userId) {
        if (userId <= 0) {
            return false;
        }
        String sql = "INSERT INTO employees (user_id, name, email, phone, department) VALUES (?,?,?,?,?)";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            statement.setString(2, employee.getName());
            statement.setString(3, employee.getEmail());
            statement.setString(4, employee.getPhone());
            statement.setString(5, employee.getDepartment());
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean addEmployee(Employee employee, int userId) {
        return addEmployeeWithUserId(employee, userId);
    }

    public boolean isEmailExists(String email) {
        String sql = "SELECT 1 FROM employees WHERE email=?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, email);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next();
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean isEmailExistsForOther(String email, int employeeId) {
        String sql = "SELECT 1 FROM employees WHERE email=? AND id<>?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, email);
            statement.setInt(2, employeeId);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next();
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public Employee getByUserId(int userId) {
        String sql = "SELECT e.*, CASE WHEN a.check_in IS NOT NULL AND a.check_out IS NULL THEN 'Active' ELSE 'Inactive' END AS status "
                + "FROM employees e "
                + "LEFT JOIN attendance a ON a.user_id = e.user_id AND a.work_date = CURDATE() "
                + "WHERE e.user_id=?";
        String fallbackSql = "SELECT * FROM employees WHERE user_id=?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return mapEmployee(resultSet);
                }
            }
        } catch (SQLException e) {
            try (Connection connection = DBConfig.getConnection();
                 PreparedStatement statement = connection.prepareStatement(fallbackSql)) {
                statement.setInt(1, userId);
                try (ResultSet resultSet = statement.executeQuery()) {
                    if (resultSet.next()) {
                        Employee employee = mapEmployee(resultSet);
                        if (employee.getStatus() == null) {
                            employee.setStatus("Inactive");
                        }
                        return employee;
                    }
                }
            } catch (SQLException fallbackException) {
                fallbackException.printStackTrace();
            }
        }
        return null;
    }

    public Integer getUserIdByEmployeeId(int employeeId) {
        String sql = "SELECT user_id FROM employees WHERE id=?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, employeeId);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    int userId = resultSet.getInt("user_id");
                    if (!resultSet.wasNull()) {
                        return userId;
                    }
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public List<Employee> getAllEmployees() {
        return getAllEmployees(1000, 0);
    }

    public List<Employee> getAllEmployees(int limit, int offset) {
        List<Employee> employees = new ArrayList<>();
        String sql = "SELECT e.*, CASE WHEN a.check_in IS NOT NULL AND a.check_out IS NULL THEN 'Active' ELSE 'Inactive' END AS status "
                + "FROM employees e "
                + "LEFT JOIN ("
                + "  SELECT t.user_id, t.check_in, t.check_out FROM attendance t "
                + "  WHERE t.work_date = CURDATE() "
                + "  AND t.check_in = (SELECT MAX(t2.check_in) FROM attendance t2 WHERE t2.user_id = t.user_id AND t2.work_date = CURDATE())"
                + ") a ON a.user_id = e.user_id "
                + "ORDER BY e.name LIMIT ? OFFSET ?";
        String fallbackSql = "SELECT * FROM employees ORDER BY name LIMIT ? OFFSET ?";

        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, limit);
            statement.setInt(2, offset);
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    employees.add(mapEmployee(resultSet));
                }
            }
        } catch (SQLException e) {
            employees.clear();
            try (Connection connection = DBConfig.getConnection();
                 PreparedStatement statement = connection.prepareStatement(fallbackSql)) {
                statement.setInt(1, limit);
                statement.setInt(2, offset);
                try (ResultSet resultSet = statement.executeQuery()) {
                    while (resultSet.next()) {
                        Employee employee = mapEmployee(resultSet);
                        if (employee.getStatus() == null) {
                            employee.setStatus("Inactive");
                        }
                        employees.add(employee);
                    }
                }
            } catch (SQLException fallbackException) {
                fallbackException.printStackTrace();
            }
        }

        return employees;
    }

    public static class DeletionResult {
        private final boolean success;
        private final String  message;
        public DeletionResult(boolean success, String message) {
            this.success = success;
            this.message = message;
        }
        public boolean isSuccess() { return success; }
        public String  getMessage() { return message; }
    }

    /**
     * Cascade-delete an employee atomically:
     *   1. Reassign tasks AUTHORED by this user to the acting admin (preserves task history for other employees).
     *   2. Delete tasks ASSIGNED TO this user.
     *   3. Delete attendance rows for this user.
     *   4. Delete the employee row.
     *   5. Delete the user row.
     * All steps share one connection inside a transaction. Any failure rolls back.
     */
    public DeletionResult deleteEmployeeAndCascade(int employeeId, int adminUserId) {
        Integer userId = getUserIdByEmployeeId(employeeId);
        if (userId == null) {
            return new DeletionResult(false, "Employee not found or not linked to a user account.");
        }
        if (userId == adminUserId) {
            return new DeletionResult(false, "You cannot delete your own account.");
        }

        Connection connection = null;
        try {
            connection = DBConfig.getConnection();
            connection.setAutoCommit(false);

            // 1. Re-authorize tasks created by this user to the acting admin (skip self-assigned ones,
            //    those are handled by the next step).
            try (PreparedStatement ps = connection.prepareStatement(
                    "UPDATE tasks SET assigned_by=? WHERE assigned_by=? AND assigned_to<>?")) {
                ps.setInt(1, adminUserId);
                ps.setInt(2, userId);
                ps.setInt(3, userId);
                ps.executeUpdate();
            }

            // 2. Delete tasks assigned to this user (no other owner possible).
            try (PreparedStatement ps = connection.prepareStatement(
                    "DELETE FROM tasks WHERE assigned_to=?")) {
                ps.setInt(1, userId);
                ps.executeUpdate();
            }

            // 3. Delete attendance rows for this user.
            try (PreparedStatement ps = connection.prepareStatement(
                    "DELETE FROM attendance WHERE user_id=?")) {
                ps.setInt(1, userId);
                ps.executeUpdate();
            }

            // 4. Delete the employee row.
            int empAffected;
            try (PreparedStatement ps = connection.prepareStatement(
                    "DELETE FROM employees WHERE id=?")) {
                ps.setInt(1, employeeId);
                empAffected = ps.executeUpdate();
            }
            if (empAffected == 0) {
                connection.rollback();
                return new DeletionResult(false, "Employee record was not removed.");
            }

            // 5. Delete the user row.
            int userAffected;
            try (PreparedStatement ps = connection.prepareStatement(
                    "DELETE FROM users WHERE id=?")) {
                ps.setInt(1, userId);
                userAffected = ps.executeUpdate();
            }
            if (userAffected == 0) {
                connection.rollback();
                return new DeletionResult(false, "Linked user account was not removed.");
            }

            connection.commit();
            return new DeletionResult(true, "Employee and all linked records deleted.");
        } catch (SQLException e) {
            e.printStackTrace();
            if (connection != null) {
                try { connection.rollback(); } catch (SQLException ignored) {}
            }
            return new DeletionResult(false,
                    "Could not delete employee: " + (e.getMessage() == null ? "database error." : e.getMessage()));
        } finally {
            if (connection != null) {
                try { connection.setAutoCommit(true); } catch (SQLException ignored) {}
                try { connection.close(); } catch (SQLException ignored) {}
            }
        }
    }

    public boolean deleteEmployee(int id) {
        String sql = "DELETE FROM employees WHERE id=?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, id);
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean updateEmployee(Employee employee) {
        String sql = "UPDATE employees SET name=?, email=?, phone=?, department=? WHERE id=?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, employee.getName());
            statement.setString(2, employee.getEmail());
            statement.setString(3, employee.getPhone());
            statement.setString(4, employee.getDepartment());
            statement.setInt(5, employee.getId());
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public Employee getEmployeeById(int id) {
        String sql = "SELECT e.*, CASE WHEN a.check_in IS NOT NULL AND a.check_out IS NULL THEN 'Active' ELSE 'Inactive' END AS status "
                + "FROM employees e "
                + "LEFT JOIN attendance a ON a.user_id = e.user_id AND a.work_date = CURDATE() "
                + "WHERE e.id=?";
        String fallbackSql = "SELECT * FROM employees WHERE id=?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, id);
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return mapEmployee(resultSet);
                }
            }
        } catch (SQLException e) {
            try (Connection connection = DBConfig.getConnection();
                 PreparedStatement statement = connection.prepareStatement(fallbackSql)) {
                statement.setInt(1, id);
                try (ResultSet resultSet = statement.executeQuery()) {
                    if (resultSet.next()) {
                        Employee employee = mapEmployee(resultSet);
                        if (employee.getStatus() == null) {
                            employee.setStatus("Inactive");
                        }
                        return employee;
                    }
                }
            } catch (SQLException fallbackException) {
                fallbackException.printStackTrace();
            }
        }
        return null;
    }

    public List<Employee> searchEmployees(String query) {
        return searchEmployees(query, 1000, 0);
    }

    public List<Employee> searchEmployees(String query, int limit, int offset) {
        List<Employee> employees = new ArrayList<>();
        String sql = "SELECT e.*, CASE WHEN a.check_in IS NOT NULL AND a.check_out IS NULL THEN 'Active' ELSE 'Inactive' END AS status "
                + "FROM employees e "
                + "LEFT JOIN ("
                + "  SELECT t.user_id, t.check_in, t.check_out FROM attendance t "
                + "  WHERE t.work_date = CURDATE() "
                + "  AND t.check_in = (SELECT MAX(t2.check_in) FROM attendance t2 WHERE t2.user_id = t.user_id AND t2.work_date = CURDATE())"
                + ") a ON a.user_id = e.user_id "
                + "WHERE e.name LIKE ? OR e.email LIKE ? "
                + "ORDER BY e.name LIMIT ? OFFSET ?";
        String fallbackSql = "SELECT * FROM employees WHERE name LIKE ? OR email LIKE ? ORDER BY name LIMIT ? OFFSET ?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            String value = "%" + query + "%";
            statement.setString(1, value);
            statement.setString(2, value);
            statement.setInt(3, limit);
            statement.setInt(4, offset);
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    employees.add(mapEmployee(resultSet));
                }
            }
        } catch (SQLException e) {
            employees.clear();
            try (Connection connection = DBConfig.getConnection();
                 PreparedStatement statement = connection.prepareStatement(fallbackSql)) {
                String value = "%" + query + "%";
                statement.setString(1, value);
                statement.setString(2, value);
                statement.setInt(3, limit);
                statement.setInt(4, offset);
                try (ResultSet resultSet = statement.executeQuery()) {
                    while (resultSet.next()) {
                        Employee employee = mapEmployee(resultSet);
                        if (employee.getStatus() == null) {
                            employee.setStatus("Inactive");
                        }
                        employees.add(employee);
                    }
                }
            } catch (SQLException fallbackException) {
                fallbackException.printStackTrace();
            }
        }
        return employees;
    }

    public int getEmployeeCountByQuery(String query) {
        if (query == null || query.trim().isEmpty()) {
            return getEmployeeCount();
        }
        String sql = "SELECT COUNT(*) AS total FROM employees WHERE name LIKE ? OR email LIKE ?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            String value = "%" + query.trim() + "%";
            statement.setString(1, value);
            statement.setString(2, value);
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

    private Employee mapEmployee(ResultSet resultSet) throws SQLException {
        Employee employee = new Employee();
        employee.setId(resultSet.getInt("id"));
        try {
            int userId = resultSet.getInt("user_id");
            if (!resultSet.wasNull()) {
                employee.setUserId(userId);
            }
        } catch (SQLException ignored) {
            employee.setUserId(null);
        }
        employee.setName(resultSet.getString("name"));
        employee.setEmail(resultSet.getString("email"));
        employee.setPhone(resultSet.getString("phone"));
        employee.setDepartment(resultSet.getString("department"));
        try {
            employee.setStatus(resultSet.getString("status"));
        } catch (SQLException ignored) {
            employee.setStatus(null);
        }
        return employee;
    }

    public int getEmployeeCount() {
        String sql = "SELECT COUNT(*) AS total FROM employees";
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

    public int getActiveEmployeeCount() {
        String sql = "SELECT COUNT(DISTINCT user_id) AS total FROM attendance "
                + "WHERE work_date=? AND check_in IS NOT NULL AND check_out IS NULL";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setDate(1, java.sql.Date.valueOf(java.time.LocalDate.now()));
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

    public List<AttendanceRow> getTodayAttendance() {
        List<AttendanceRow> rows = new ArrayList<>();
        String sql = "SELECT e.id, e.user_id AS user_id, e.name, e.email, e.department, "
                + "CASE WHEN a.check_in IS NOT NULL AND a.check_out IS NULL THEN 'Active' ELSE 'Inactive' END AS attendance_status, "
                + "a.work_date, a.check_in, a.check_out "
                + "FROM employees e "
                + "LEFT JOIN attendance a ON a.user_id = e.user_id AND a.work_date = CURDATE() "
                + "ORDER BY e.name";
        String fallbackSql = "SELECT id, name, email, department FROM employees ORDER BY name";

        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            while (resultSet.next()) {
                rows.add(mapAttendanceRow(resultSet));
            }
        } catch (SQLException e) {
            rows.clear();
            try (Connection connection = DBConfig.getConnection();
                 PreparedStatement statement = connection.prepareStatement(fallbackSql);
                 ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    AttendanceRow row = new AttendanceRow();
                    row.setEmployeeId(resultSet.getInt("id"));
                    row.setName(resultSet.getString("name"));
                    row.setEmail(resultSet.getString("email"));
                    row.setDepartment(resultSet.getString("department"));
                    row.setAttendanceStatus("Absent");
                    rows.add(row);
                }
            } catch (SQLException fallbackException) {
                fallbackException.printStackTrace();
            }
        }
        return rows;
    }

    private AttendanceRow mapAttendanceRow(ResultSet resultSet) throws SQLException {
        AttendanceRow row = new AttendanceRow();
        row.setEmployeeId(resultSet.getInt("id"));
        try {
            int uid = resultSet.getInt("user_id");
            row.setUserId(resultSet.wasNull() ? null : uid);
        } catch (SQLException ignored) { row.setUserId(null); }
        row.setName(resultSet.getString("name"));
        row.setEmail(resultSet.getString("email"));
        row.setDepartment(resultSet.getString("department"));
        row.setAttendanceStatus(resultSet.getString("attendance_status"));
        try {
            java.sql.Date wd = resultSet.getDate("work_date");
            row.setWorkDate(wd == null ? java.sql.Date.valueOf(java.time.LocalDate.now()) : wd);
        } catch (SQLException ignored) {
            row.setWorkDate(java.sql.Date.valueOf(java.time.LocalDate.now()));
        }
        java.sql.Timestamp checkIn = resultSet.getTimestamp("check_in");
        java.sql.Timestamp checkOut = resultSet.getTimestamp("check_out");
        row.setCheckInTime(checkIn == null ? null : new java.sql.Time(checkIn.getTime()));
        row.setCheckOutTime(checkOut == null ? null : new java.sql.Time(checkOut.getTime()));
        return row;
    }

    public boolean setEmployeeStatus(int employeeId, String status) {
        String sql = "UPDATE employees SET status=? WHERE id=?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, status);
            statement.setInt(2, employeeId);
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public String validateEmployee(Employee employee) {
        if (employee == null) {
            return "Employee details are required.";
        }
        if (isBlank(employee.getName())) {
            return "Name is required.";
        }
        if (isBlank(employee.getEmail()) || !isValidEmail(employee.getEmail())) {
            return "Please enter a valid email address.";
        }
        if (isBlank(employee.getDepartment())) {
            return "Department is required.";
        }
        String phone = employee.getPhone();
        if (!isBlank(phone) && !isNumeric(phone)) {
            return "Phone must contain digits only.";
        }
        return null;
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private boolean isNumeric(String value) {
        return value != null && value.matches("\\d+");
    }

    private boolean isValidEmail(String value) {
        return value != null && value.matches("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$");
    }
}