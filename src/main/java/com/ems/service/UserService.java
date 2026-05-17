package com.ems.service;

import com.ems.config.DBConfig;
import com.ems.model.User;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import org.mindrot.jbcrypt.BCrypt;

public class UserService {

    public User authenticate(String username, String password) {
        User user = null;
        String sql = "SELECT * FROM users WHERE username=?";

        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, username);

            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    String storedHash = resultSet.getString("password");
                    if (!isPasswordValid(password, storedHash)) {
                        return null;
                    }
                    String role = null;
                    try {
                        role = resultSet.getString("role");
                    } catch (SQLException ignored) {
                        role = null;
                    }
                    if (!isAllowedRole(role)) {
                        return null;
                    }
                    user = new User();
                    user.setId(resultSet.getInt("id"));
                    user.setUsername(resultSet.getString("username"));
                    user.setPassword(null);
                    user.setRole(role);
                    try {
                        int employeeId = resultSet.getInt("employee_id");
                        if (!resultSet.wasNull()) {
                            user.setEmployeeId(employeeId);
                        }
                    } catch (SQLException ignored) {
                        user.setEmployeeId(null);
                    }
                    // Optional must_change_password column. Older DBs may not have it yet.
                    try {
                        boolean mustChange = resultSet.getBoolean("must_change_password");
                        user.setMustChangePassword(mustChange);
                    } catch (SQLException ignored) {
                        user.setMustChangePassword(false);
                    }
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }

        return user;
    }

    public String hashPassword(String plainPassword) {
        return BCrypt.hashpw(plainPassword, BCrypt.gensalt());
    }

    public boolean isUsernameExists(String username) {
        String sql = "SELECT 1 FROM users WHERE username=?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, username);
            try (ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next();
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean deleteUserById(int userId) {
        String sql = "DELETE FROM users WHERE id=?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public int createUser(User user) {
        // Try the schema with must_change_password first; fall back to legacy schema if missing.
        String sql4 = "INSERT INTO users (username, password, role, must_change_password) VALUES (?,?,?,?)";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql4, Statement.RETURN_GENERATED_KEYS)) {
            statement.setString(1, user.getUsername());
            statement.setString(2, hashPassword(user.getPassword()));
            statement.setString(3, user.getRole());
            statement.setBoolean(4, user.isMustChangePassword());
            int affected = statement.executeUpdate();
            if (affected > 0) {
                try (ResultSet resultSet = statement.getGeneratedKeys()) {
                    if (resultSet.next()) return resultSet.getInt(1);
                }
            }
        } catch (SQLException e) {
            // Legacy schema (no must_change_password column) — fall back.
            String sql3 = "INSERT INTO users (username, password, role) VALUES (?,?,?)";
            try (Connection connection = DBConfig.getConnection();
                 PreparedStatement statement = connection.prepareStatement(sql3, Statement.RETURN_GENERATED_KEYS)) {
                statement.setString(1, user.getUsername());
                statement.setString(2, hashPassword(user.getPassword()));
                statement.setString(3, user.getRole());
                int affected = statement.executeUpdate();
                if (affected > 0) {
                    try (ResultSet resultSet = statement.getGeneratedKeys()) {
                        if (resultSet.next()) return resultSet.getInt(1);
                    }
                }
            } catch (SQLException ee) {
                ee.printStackTrace();
            }
        }
        return 0;
    }

    public boolean updatePassword(int userId, String newPlainPassword) {
        String sql = "UPDATE users SET password=? WHERE id=?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, hashPassword(newPlainPassword));
            statement.setInt(2, userId);
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean clearMustChangePassword(int userId) {
        String sql = "UPDATE users SET must_change_password=0 WHERE id=?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            return statement.executeUpdate() > 0;
        } catch (SQLException e) {
            // Column missing on legacy schema → treat as success so the flow doesn't loop.
            System.out.println("[UserService] clearMustChangePassword: column may not exist yet, ignoring. " + e.getMessage());
            return true;
        }
    }

    public boolean verifyPassword(int userId, String plain) {
        String sql = "SELECT password FROM users WHERE id=?";
        try (Connection connection = DBConfig.getConnection();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, userId);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return isPasswordValid(plain, rs.getString("password"));
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public String validateNewUser(User user) {
        if (user == null) {
            return "User details are required.";
        }
        String username = user.getUsername();
        String password = user.getPassword();
        if (isBlank(username) || username.trim().length() < 3) {
            return "Username must be at least 3 characters.";
        }
        if (isBlank(password) || password.trim().length() < 8) {
            return "Password must be at least 8 characters.";
        }
        if (!isStrongPassword(password)) {
            return "Password must include letters and numbers.";
        }
        if (isUsernameExists(username.trim())) {
            return "Username already exists.";
        }
        return null;
    }

    private boolean isPasswordValid(String plainPassword, String storedHash) {
        if (plainPassword == null || storedHash == null) {
            return false;
        }
        if (storedHash.startsWith("$2")) {
            return BCrypt.checkpw(plainPassword, storedHash);
        }
        return storedHash.equals(plainPassword);
    }

    private boolean isAllowedRole(String role) {
        return role != null && ("ADMIN".equalsIgnoreCase(role) || "EMPLOYEE".equalsIgnoreCase(role));
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private boolean isStrongPassword(String value) {
        if (value == null) {
            return false;
        }
        boolean hasLetter = value.matches(".*[A-Za-z].*");
        boolean hasNumber = value.matches(".*\\d.*");
        return hasLetter && hasNumber;
    }
}