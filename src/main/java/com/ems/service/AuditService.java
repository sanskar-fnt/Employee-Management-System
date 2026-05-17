package com.ems.service;

import com.ems.config.DBConfig;
import com.ems.model.AuditLog;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * Append-only audit log writer + reader.
 *
 * Writes are best-effort: if logging fails (e.g. table missing on a legacy DB)
 * the surrounding business operation is NOT rolled back — the caller just
 * sees a console warning. Reads are admin-only and support filter + pagination.
 */
public class AuditService {

    public static final String LOGIN           = "LOGIN";
    public static final String LOGOUT          = "LOGOUT";
    public static final String LOGIN_FAILED    = "LOGIN_FAILED";
    public static final String EMPLOYEE_CREATE = "EMPLOYEE_CREATE";
    public static final String EMPLOYEE_UPDATE = "EMPLOYEE_UPDATE";
    public static final String EMPLOYEE_DELETE = "EMPLOYEE_DELETE";
    public static final String TASK_ASSIGN     = "TASK_ASSIGN";
    public static final String TASK_UPDATE     = "TASK_UPDATE";
    public static final String CHECK_IN        = "CHECK_IN";
    public static final String CHECK_OUT       = "CHECK_OUT";
    public static final String PASSWORD_CHANGE = "PASSWORD_CHANGE";
    public static final String LEAVE_APPLY     = "LEAVE_APPLY";
    public static final String LEAVE_APPROVE   = "LEAVE_APPROVE";
    public static final String LEAVE_REJECT    = "LEAVE_REJECT";

    private static final String INSERT_SQL =
            "INSERT INTO audit_logs (actor_user_id, action, entity_type, entity_id, details) "
          + "VALUES (?,?,?,?,?)";

    public void log(Integer actorUserId, String action, String entityType, Integer entityId, String details) {
        try (Connection c = DBConfig.getConnection();
             PreparedStatement ps = c.prepareStatement(INSERT_SQL)) {
            if (actorUserId != null) ps.setInt(1, actorUserId);    else ps.setNull(1, java.sql.Types.INTEGER);
            ps.setString(2, action == null ? "UNKNOWN" : action);
            if (entityType != null) ps.setString(3, entityType);   else ps.setNull(3, java.sql.Types.VARCHAR);
            if (entityId != null)   ps.setInt(4, entityId);        else ps.setNull(4, java.sql.Types.INTEGER);
            if (details != null)    ps.setString(5, truncate(details, 500));
            else                    ps.setNull(5, java.sql.Types.VARCHAR);
            ps.executeUpdate();
        } catch (SQLException e) {
            System.out.println("[AuditService] log failed (action=" + action + "): " + e.getMessage());
        }
    }

    public List<AuditLog> findLogs(String actionFilter, Integer actorUserId,
                                   LocalDate from, LocalDate to,
                                   int limit, int offset) {
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT a.*, u.username AS actor_username ")
           .append("FROM audit_logs a LEFT JOIN users u ON u.id = a.actor_user_id ")
           .append("WHERE 1=1 ");
        List<Object> params = new ArrayList<>();
        if (actionFilter != null && !actionFilter.trim().isEmpty()) {
            sql.append("AND a.action = ? ");
            params.add(actionFilter.trim());
        }
        if (actorUserId != null && actorUserId > 0) {
            sql.append("AND a.actor_user_id = ? ");
            params.add(actorUserId);
        }
        if (from != null) {
            sql.append("AND a.created_at >= ? ");
            params.add(Date.valueOf(from));
        }
        if (to != null) {
            sql.append("AND a.created_at < DATE_ADD(?, INTERVAL 1 DAY) ");
            params.add(Date.valueOf(to));
        }
        sql.append("ORDER BY a.created_at DESC, a.id DESC LIMIT ? OFFSET ?");
        params.add(limit);
        params.add(offset);

        List<AuditLog> out = new ArrayList<>();
        try (Connection c = DBConfig.getConnection();
             PreparedStatement ps = c.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) ps.setObject(i + 1, params.get(i));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    out.add(map(rs));
                }
            }
        } catch (SQLException e) {
            System.out.println("[AuditService] findLogs failed: " + e.getMessage());
        }
        return out;
    }

    public int countLogs(String actionFilter, Integer actorUserId, LocalDate from, LocalDate to) {
        StringBuilder sql = new StringBuilder("SELECT COUNT(*) AS c FROM audit_logs WHERE 1=1 ");
        List<Object> params = new ArrayList<>();
        if (actionFilter != null && !actionFilter.trim().isEmpty()) {
            sql.append("AND action = ? "); params.add(actionFilter.trim());
        }
        if (actorUserId != null && actorUserId > 0) {
            sql.append("AND actor_user_id = ? "); params.add(actorUserId);
        }
        if (from != null) { sql.append("AND created_at >= ? "); params.add(Date.valueOf(from)); }
        if (to   != null) { sql.append("AND created_at < DATE_ADD(?, INTERVAL 1 DAY) "); params.add(Date.valueOf(to)); }
        try (Connection c = DBConfig.getConnection();
             PreparedStatement ps = c.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) ps.setObject(i + 1, params.get(i));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt("c");
            }
        } catch (SQLException e) {
            System.out.println("[AuditService] countLogs failed: " + e.getMessage());
        }
        return 0;
    }

    public List<String> getDistinctActions() {
        List<String> out = new ArrayList<>();
        String sql = "SELECT DISTINCT action FROM audit_logs ORDER BY action";
        try (Connection c = DBConfig.getConnection();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) out.add(rs.getString(1));
        } catch (SQLException e) {
            System.out.println("[AuditService] getDistinctActions failed: " + e.getMessage());
        }
        return out;
    }

    private AuditLog map(ResultSet rs) throws SQLException {
        AuditLog a = new AuditLog();
        a.setId(rs.getLong("id"));
        int actor = rs.getInt("actor_user_id");
        a.setActorUserId(rs.wasNull() ? null : actor);
        a.setActorUsername(rs.getString("actor_username"));
        a.setAction(rs.getString("action"));
        a.setEntityType(rs.getString("entity_type"));
        int eid = rs.getInt("entity_id");
        a.setEntityId(rs.wasNull() ? null : eid);
        a.setDetails(rs.getString("details"));
        a.setCreatedAt(rs.getTimestamp("created_at"));
        return a;
    }

    private String truncate(String v, int max) {
        return v.length() <= max ? v : v.substring(0, max);
    }
}
