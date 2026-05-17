<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.ems.model.User" %>
<%@ page import="com.ems.model.Employee" %>
<%@ page import="com.ems.model.PerformanceBreakdown" %>
<%@ page import="com.ems.model.WorkloadEntry" %>
<%@ page import="com.ems.model.AttendanceRow" %>
<%@ page import="com.ems.model.Task" %>
<%@ page import="com.ems.model.AuditLog" %>
<%@ page import="java.util.List" %>
<%
  User viewer = (User) session.getAttribute("user");
  if (viewer == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

  Employee employee  = (Employee) request.getAttribute("employee");
  Boolean  isAdminO  = (Boolean)  request.getAttribute("isAdmin");
  boolean  isAdmin   = isAdminO != null && isAdminO;
  PerformanceBreakdown perf = (PerformanceBreakdown) request.getAttribute("performance");
  WorkloadEntry        workload = (WorkloadEntry) request.getAttribute("workload");
  Integer  lateObj   = (Integer) request.getAttribute("lateDaysWeek");
  int      lateDays  = lateObj == null ? 0 : lateObj;
  List<AttendanceRow> attendanceHistory = (List<AttendanceRow>) request.getAttribute("attendanceHistory");
  List<Task>          taskHistory       = (List<Task>)          request.getAttribute("taskHistory");
  List<AuditLog>      recentActivity    = (List<AuditLog>)      request.getAttribute("recentActivity");

  String csrfToken = (String) request.getAttribute("csrfToken"); if (csrfToken == null) csrfToken = "";
  String initials  = "U";
  if (viewer.getUsername() != null && !viewer.getUsername().isEmpty()) initials = viewer.getUsername().substring(0,1).toUpperCase();
  String empInitials = "?";
  if (employee != null && employee.getName() != null && !employee.getName().isEmpty()) empInitials = employee.getName().substring(0,1).toUpperCase();
%>
<%!
  private String esc(String v) {
    if (v == null) return "";
    return v.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
  }
  private String fmt1(double v) {
    if (v == Math.floor(v)) return String.valueOf((int) v);
    return String.format("%.1f", v);
  }
  private String chipForTask(String s) {
    if (s == null) return "badge-info";
    if ("COMPLETED".equalsIgnoreCase(s))   return "badge-ok";
    if ("IN_PROGRESS".equalsIgnoreCase(s)) return "badge-info";
    return "badge-warn";
  }
  private String chipForAction(String action) {
    if (action == null) return "badge-info";
    if (action.endsWith("DELETE") || "LOGIN_FAILED".equals(action)) return "badge-err";
    if ("PASSWORD_CHANGE".equals(action)) return "badge-warn";
    if (action.startsWith("CHECK_")) return "badge-ok";
    return "badge-info";
  }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><%= esc(employee == null ? "Profile" : employee.getName()) %> — EMS</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css?v=8">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/ems-ui.css?v=8">
  <script src="${pageContext.request.contextPath}/js/theme-init.js"></script>
</head>
<body>
<div class="app-layout">

  <aside class="sidebar">
    <div class="sb-hd">
      <a class="sb-brand" href="${pageContext.request.contextPath}/<%= isAdmin ? "dashboard" : "emp-dashboard" %>">
        <div class="sb-mark">E</div><span class="sb-name">EMS</span>
      </a>
    </div>
    <nav class="sb-nav">
      <div class="nav-label">Main</div>
      <a class="nav-item" href="${pageContext.request.contextPath}/<%= isAdmin ? "dashboard" : "emp-dashboard" %>"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg></span><span class="nav-tx">Dashboard</span></a>
      <% if (isAdmin) { %>
      <a class="nav-item active" href="${pageContext.request.contextPath}/employees"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg></span><span class="nav-tx">Employees</span></a>
      <% } %>
      <a class="nav-item" href="${pageContext.request.contextPath}/tasks"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg></span><span class="nav-tx">Tasks</span></a>
      <% if (isAdmin) { %>
      <a class="nav-item" href="${pageContext.request.contextPath}/attendance"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 2v4"/><path d="M16 2v4"/><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M3 10h18"/></svg></span><span class="nav-tx">Attendance</span></a>
      <a class="nav-item" href="${pageContext.request.contextPath}/analytics"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3v18h18"/><path d="M7 14l4-4 4 3 5-7"/></svg></span><span class="nav-tx">Analytics</span></a>
      <a class="nav-item" href="${pageContext.request.contextPath}/audit"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="9" y1="13" x2="15" y2="13"/><line x1="9" y1="17" x2="15" y2="17"/></svg></span><span class="nav-tx">Audit Logs</span></a>
      <% } %>
      <a class="nav-item" href="${pageContext.request.contextPath}/leaves"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/><polyline points="9 16 11 18 15 14"/></svg></span><span class="nav-tx">Leaves</span></a>
    </nav>
    <div class="sb-ft">
      <form action="${pageContext.request.contextPath}/login" method="POST">
        <input type="hidden" name="action" value="logout">
        <input type="hidden" name="csrfToken" value="<%= esc(csrfToken) %>">
        <button type="submit" class="nav-item" style="width:100%;">
          <span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg></span>
          <span class="nav-tx">Logout</span>
        </button>
      </form>
    </div>
  </aside>

  <div class="main">
    <header class="topbar">
      <div class="tb-left">
        <button class="sb-toggle" type="button" data-sb-toggle aria-label="Toggle sidebar"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg></button>
        <span class="tb-title">Profile</span>
      </div>
      <div class="tb-right">
        <% if (isAdmin) { %>
          <button class="ic-btn" type="button" aria-label="Notifications">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
          </button>
        <% } %>
        <div class="user-menu">
          <button class="user-trigger" type="button" data-dropdown>
            <div class="avatar"><%= initials %></div>
            <span class="user-name"><%= esc(viewer.getUsername()) %></span>
          </button>
        </div>
      </div>
    </header>

    <main class="content">
      <div class="content-wrap">

        <div class="page-intro" style="display:flex; align-items:center; gap:var(--s4); flex-wrap:wrap;">
          <div class="av-sm" style="width:48px; height:48px; font-size:18px;"><%= esc(empInitials) %></div>
          <div style="flex:1; min-width:200px;">
            <div class="page-intro-eyebrow">Employee profile</div>
            <div class="page-intro-title"><%= esc(employee.getName()) %></div>
            <div class="page-intro-sub">
              <%= esc(employee.getDepartment() == null ? "—" : employee.getDepartment()) %>
              · <%= esc(employee.getEmail()) %>
              <% if (workload != null) { %>
                · <span class="badge <%= "err".equals(workload.getWorkloadTone()) ? "badge-err"
                                       : "ok".equals(workload.getWorkloadTone())  ? "badge-ok"  : "badge-info" %>">
                    <%= esc(workload.getWorkloadStatus()) %>
                  </span>
              <% } %>
            </div>
          </div>
          <% if (isAdmin) { %>
            <a class="btn btn-secondary btn-sm" href="${pageContext.request.contextPath}/employees">← Back to employees</a>
          <% } %>
        </div>

        <!-- KPI strip -->
        <div class="an-kpi-row">
          <div class="an-kpi">
            <div class="an-kpi-head">
              <span class="an-kpi-label">Performance</span>
              <span class="an-kpi-icon tone-p"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3v18h18"/><path d="M7 14l4-4 4 3 5-7"/></svg></span>
            </div>
            <div class="an-kpi-value"><%= perf == null ? "—" : fmt1(perf.getFinalScore()) %></div>
            <div class="an-kpi-foot">Final score · <%= perf == null ? "—" : esc(perf.getBadge()) %></div>
          </div>
          <div class="an-kpi">
            <div class="an-kpi-head">
              <span class="an-kpi-label">Attendance</span>
              <span class="an-kpi-icon tone-info"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 2v4"/><path d="M16 2v4"/><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M3 10h18"/></svg></span>
            </div>
            <div class="an-kpi-value"><%= perf == null ? "—" : (fmt1(perf.getAttendancePercentage()) + "%") %></div>
            <div class="an-kpi-foot">
              <%= perf == null ? "—" : (perf.getAttendanceDays() + "/" + perf.getWorkingDays() + " days this week") %>
            </div>
          </div>
          <div class="an-kpi">
            <div class="an-kpi-head">
              <span class="an-kpi-label">Workload</span>
              <span class="an-kpi-icon tone-warn"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="20" x2="12" y2="10"/><line x1="18" y1="20" x2="18" y2="4"/><line x1="6"  y1="20" x2="6"  y2="16"/></svg></span>
            </div>
            <div class="an-kpi-value"><%= workload == null ? "—" : workload.getWorkloadScore() %></div>
            <div class="an-kpi-foot">
              <% if (workload != null) { %>
                <%= workload.getActiveTasks() %> active · <%= workload.getOverdueTasks() %> overdue
              <% } else { %>—<% } %>
            </div>
          </div>
          <div class="an-kpi">
            <div class="an-kpi-head">
              <span class="an-kpi-label">Late days (week)</span>
              <span class="an-kpi-icon <%= lateDays == 0 ? "tone-ok" : "tone-err" %>">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
              </span>
            </div>
            <div class="an-kpi-value"><%= lateDays %></div>
            <div class="an-kpi-foot">After 09:15 check-in</div>
          </div>
        </div>

        <!-- Personal info -->
        <div class="card mb-24">
          <div class="card-hd">
            <div class="card-hd-left">
              <div class="card-title">Personal information</div>
              <div class="card-subtitle">Stored in employees table</div>
            </div>
          </div>
          <div class="info-grid" style="padding: var(--s4) var(--s5); display:grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: var(--s4);">
            <div class="info-item">
              <div class="info-label">Full name</div>
              <div class="info-value"><%= esc(employee.getName()) %></div>
            </div>
            <div class="info-item">
              <div class="info-label">Email</div>
              <div class="info-value"><%= esc(employee.getEmail()) %></div>
            </div>
            <div class="info-item">
              <div class="info-label">Phone</div>
              <div class="info-value"><%= esc(employee.getPhone() == null ? "—" : employee.getPhone()) %></div>
            </div>
            <div class="info-item">
              <div class="info-label">Department</div>
              <div class="info-value"><%= esc(employee.getDepartment() == null ? "—" : employee.getDepartment()) %></div>
            </div>
            <div class="info-item">
              <div class="info-label">Status</div>
              <div class="info-value">
                <span class="badge <%= "Active".equalsIgnoreCase(employee.getStatus()) ? "badge-ok" : "badge-info" %>">
                  <%= esc(employee.getStatus() == null ? "—" : employee.getStatus()) %>
                </span>
              </div>
            </div>
            <div class="info-item">
              <div class="info-label">Employee ID</div>
              <div class="info-value">#<%= employee.getId() %></div>
            </div>
          </div>
        </div>

        <div class="analytics-grid-2">
          <!-- Attendance history -->
          <div class="card">
            <div class="card-hd">
              <div class="card-hd-left">
                <div class="card-title">Attendance history</div>
                <div class="card-subtitle">Last 12 days</div>
              </div>
            </div>
            <div class="dg-container scrollbar">
              <table class="table">
                <thead>
                  <tr><th>Date</th><th>Check-in</th><th>Check-out</th><th>Status</th></tr>
                </thead>
                <tbody>
                  <% if (attendanceHistory == null || attendanceHistory.isEmpty()) { %>
                    <tr class="dg-empty"><td colspan="4">No attendance recorded yet.</td></tr>
                  <% } else { for (AttendanceRow r : attendanceHistory) {
                       String label = r.isOnLeave() ? "On Leave" : (r.getAttendanceStatus() == null ? "—" : r.getAttendanceStatus());
                       String chip  = r.isOnLeave() ? "badge-info"
                                    : "Active".equalsIgnoreCase(r.getAttendanceStatus()) ? "badge-ok" : "badge-info";
                  %>
                    <tr>
                      <td><%= r.getWorkDate()    == null ? "—" : r.getWorkDate().toString()    %></td>
                      <td><%= r.getCheckInTime() == null ? "—" : r.getCheckInTime().toString() %></td>
                      <td><%= r.getCheckOutTime()== null ? "—" : r.getCheckOutTime().toString()%></td>
                      <td><span class="badge <%= chip %>"><%= esc(label) %></span></td>
                    </tr>
                  <% } } %>
                </tbody>
              </table>
            </div>
          </div>

          <!-- Task history -->
          <div class="card">
            <div class="card-hd">
              <div class="card-hd-left">
                <div class="card-title">Task history</div>
                <div class="card-subtitle">Most recent <%= taskHistory == null ? 0 : taskHistory.size() %></div>
              </div>
            </div>
            <div class="dg-container scrollbar">
              <table class="table">
                <thead>
                  <tr><th>Title</th><th>Due</th><th>Priority</th><th>Status</th></tr>
                </thead>
                <tbody>
                  <% if (taskHistory == null || taskHistory.isEmpty()) { %>
                    <tr class="dg-empty"><td colspan="4">No tasks assigned to this employee.</td></tr>
                  <% } else { for (Task t : taskHistory) { %>
                    <tr>
                      <td><span class="result-title" style="font-weight:600;"><%= esc(t.getTitle()) %></span></td>
                      <td><%= t.getDueDate() == null ? "—" : t.getDueDate().toString() %></td>
                      <td><span class="card-subtitle"><%= esc(t.getPriority() == null ? "—" : t.getPriority()) %></span></td>
                      <td><span class="badge <%= chipForTask(t.getStatus()) %>"><%= esc(t.getStatus() == null ? "—" : t.getStatus()) %></span></td>
                    </tr>
                  <% } } %>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <!-- Recent activity -->
        <div class="card mb-24">
          <div class="card-hd">
            <div class="card-hd-left">
              <div class="card-title">Recent activity</div>
              <div class="card-subtitle">Last 10 audit events for this user</div>
            </div>
          </div>
          <% if (recentActivity == null || recentActivity.isEmpty()) { %>
            <div class="empty-state">
              <div class="empty-state-icon">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
              </div>
              <div class="empty-state-title">No recorded activity</div>
              <div class="empty-state-msg">Logins, check-ins and other actions will appear here as they happen.</div>
            </div>
          <% } else { %>
            <div class="feed-list">
              <% for (AuditLog a : recentActivity) { %>
                <div class="feed-item">
                  <div class="feed-icon">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                  </div>
                  <div class="feed-body">
                    <div class="feed-title">
                      <span class="badge <%= chipForAction(a.getAction()) %>"><%= esc(a.getAction()) %></span>
                      <% if (a.getEntityType() != null) { %>
                        <span class="card-subtitle"> · <%= esc(a.getEntityType()) %><% if (a.getEntityId() != null) { %> #<%= a.getEntityId() %><% } %></span>
                      <% } %>
                    </div>
                    <% if (a.getDetails() != null && !a.getDetails().isEmpty()) { %>
                      <div class="feed-detail"><%= esc(a.getDetails()) %></div>
                    <% } %>
                  </div>
                  <div class="feed-time"><%= a.getCreatedAt() == null ? "" : a.getCreatedAt().toString() %></div>
                </div>
              <% } %>
            </div>
          <% } %>
        </div>

      </div>
    </main>
  </div>
</div>

<script src="${pageContext.request.contextPath}/js/app.js"></script>
</body>
</html>
