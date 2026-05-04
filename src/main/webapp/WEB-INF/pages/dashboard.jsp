<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.ems.model.User" %>
<%@ page import="com.ems.model.AttendanceRow" %>
<%@ page import="java.util.List" %>
<%
  User user = (User) session.getAttribute("user");
  if (user == null) {
    response.sendRedirect(request.getContextPath() + "/login");
    return;
  }
  Integer totalEmployeesObj  = (Integer) request.getAttribute("totalEmployees");
  Integer activeEmployeesObj  = (Integer) request.getAttribute("activeEmployees");
  Integer inactiveEmployeesObj= (Integer) request.getAttribute("inactiveEmployees");
  Integer todayAttendanceObj  = (Integer) request.getAttribute("todayAttendance");
  List<AttendanceRow> attendanceRows       = (List<AttendanceRow>) request.getAttribute("attendanceRows");
  List<AttendanceRow> recentAttendanceRows = (List<AttendanceRow>) request.getAttribute("recentAttendanceRows");
  int totalEmployees   = totalEmployeesObj   == null ? 0 : totalEmployeesObj;
  int activeEmployees  = activeEmployeesObj  == null ? 0 : activeEmployeesObj;
  int inactiveEmployees= inactiveEmployeesObj== null ? 0 : inactiveEmployeesObj;
  int todayAttendance  = todayAttendanceObj  == null ? 0 : todayAttendanceObj;
  int attendanceRate   = totalEmployees > 0 ? (int) Math.round(todayAttendance * 100.0 / totalEmployees) : 0;
  String initials = "U";
  if (user.getUsername() != null && !user.getUsername().isEmpty())
    initials = user.getUsername().substring(0, 1).toUpperCase();
  String startDate = (String) request.getAttribute("startDate");
  String endDate   = (String) request.getAttribute("endDate");
  if (startDate == null) startDate = "";
  if (endDate   == null) endDate   = "";
%>
<%!
  private String esc(String v) {
    if (v == null) return "";
    return v.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
  }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Dashboard — EMS</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css?v=1">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/ems-ui.css?v=2">
</head>
<body>
<div class="app-layout">

  <aside class="sidebar">
    <div class="sb-hd">
      <a class="sb-brand" href="${pageContext.request.contextPath}/dashboard">
        <div class="sb-mark">E</div>
        <span class="sb-name">EMS</span>
      </a>
    </div>
    <nav class="sb-nav">
      <div class="nav-label">Main</div>
      <a class="nav-item active" href="${pageContext.request.contextPath}/dashboard" data-label="Dashboard">
        <span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg></span>
        <span class="nav-tx">Dashboard</span>
      </a>
      <a class="nav-item" href="${pageContext.request.contextPath}/employees" data-label="Employees">
        <span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg></span>
        <span class="nav-tx">Employees</span>
      </a>
      <a class="nav-item" href="${pageContext.request.contextPath}/tasks" data-label="Tasks">
        <span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg></span>
        <span class="nav-tx">Tasks</span>
      </a>
      <a class="nav-item" href="${pageContext.request.contextPath}/attendance" data-label="Attendance">
        <span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 2v4"/><path d="M16 2v4"/><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M3 10h18"/></svg></span>
        <span class="nav-tx">Attendance</span>
      </a>
    </nav>
    <div class="sb-ft">
      <form action="${pageContext.request.contextPath}/login" method="POST">
        <input type="hidden" name="action" value="logout">
        <input type="hidden" name="csrfToken" value="<%= request.getAttribute("csrfToken") == null ? "" : request.getAttribute("csrfToken") %>">
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
        <button class="sb-toggle" type="button" data-sb-toggle aria-label="Toggle sidebar">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
        </button>
        <span class="tb-title">Dashboard</span>
      </div>
      <div class="tb-right">
        <div class="tb-search">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
          <input type="text" placeholder="Search...">
        </div>
        <button class="ic-btn" type="button" aria-label="Notifications">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
        </button>
        <div class="user-menu">
          <button class="user-trigger" type="button" data-dropdown>
            <div class="avatar"><%= initials %></div>
            <span class="user-name"><%= esc(user.getUsername()) %></span>
            <span class="chevron-ic"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg></span>
          </button>
          <div class="dd-popup">
            <div class="dd-section">
              <div class="dd-section-name"><%= esc(user.getUsername()) %></div>
              <div class="dd-section-sub">Administrator</div>
            </div>
            <div class="dd-sep"></div>
            <a class="dd-item" href="#">Profile</a>
            <a class="dd-item" href="#">Settings</a>
          </div>
        </div>
      </div>
    </header>

    <main class="content">
      <div class="content-wrap">

        <div class="page-intro">
          <div class="page-intro-eyebrow">Overview</div>
          <div class="page-intro-title">Welcome back, <%= esc(user.getUsername()) %></div>
          <div class="page-intro-sub">Here is a quick overview of your team and attendance today.</div>
        </div>

        <!-- KPI row -->
        <div class="kpi-grid">
          <div class="kpi-card kpi-p">
            <div class="kpi-bar"></div>
            <div class="kpi-ic">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
            </div>
            <div class="kpi-label">Total Employees</div>
            <div class="kpi-value"><%= totalEmployees %></div>
          </div>
          <div class="kpi-card kpi-ok">
            <div class="kpi-bar"></div>
            <div class="kpi-ic">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
            </div>
            <div class="kpi-label">Attendance Today</div>
            <div class="kpi-value"><%= todayAttendance %></div>
            <div class="rate-bar-wrap mt-8">
              <div class="rate-bar-track">
                <div class="rate-bar-fill" data-pct="<%= attendanceRate %>"></div>
              </div>
              <span class="rate-pct"><%= attendanceRate %>%</span>
            </div>
          </div>
          <div class="kpi-card kpi-info">
            <div class="kpi-bar"></div>
            <div class="kpi-ic">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg>
            </div>
            <div class="kpi-label">Active Employees</div>
            <div class="kpi-value"><%= activeEmployees %></div>
          </div>
          <div class="kpi-card kpi-err">
            <div class="kpi-bar"></div>
            <div class="kpi-ic">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>
            </div>
            <div class="kpi-label">Inactive Employees</div>
            <div class="kpi-value"><%= inactiveEmployees %></div>
          </div>
        </div>

        <!-- Today's attendance table -->
        <div class="card mb-20">
          <div class="card-hd">
            <div class="card-hd-left">
              <div class="card-title">Today's Attendance</div>
              <div class="card-subtitle">All check-ins recorded for today</div>
            </div>
            <form style="display:flex; gap:var(--s2); align-items:center; flex-wrap:wrap;" action="${pageContext.request.contextPath}/dashboard" method="GET">
              <input class="input input-sm" type="date" name="startDate" value="<%= esc(startDate) %>">
              <input class="input input-sm" type="date" name="endDate"   value="<%= esc(endDate) %>">
              <button type="submit" class="btn btn-primary btn-sm">Apply</button>
            </form>
          </div>
          <div class="dg-container scrollbar">
            <table class="table">
              <thead>
                <tr>
                  <th>#</th>
                  <th>Employee</th>
                  <th>Email</th>
                  <th>Department</th>
                  <th>Status</th>
                  <th>Check-in</th>
                  <th>Check-out</th>
                </tr>
              </thead>
              <tbody>
                <%
                  if (attendanceRows == null || attendanceRows.isEmpty()) {
                %>
                  <tr class="dg-empty"><td colspan="7">No attendance data for today.</td></tr>
                <%
                  } else {
                    for (AttendanceRow row : attendanceRows) {
                      String sClass = "status-badge " + ("Active".equalsIgnoreCase(row.getAttendanceStatus()) ? "status-active" : "status-inactive");
                %>
                  <tr>
                    <td><span class="tm f-sm">#<%= row.getEmployeeId() %></span></td>
                    <td><span class="fw-6"><%= esc(row.getName()) %></span></td>
                    <td><span class="tm"><%= esc(row.getEmail()) %></span></td>
                    <td><%= esc(row.getDepartment()) %></td>
                    <td><span class="<%= sClass %>"><%= esc(row.getAttendanceStatus()) %></span></td>
                    <td><%= row.getCheckInTime()  == null ? "--" : row.getCheckInTime() %></td>
                    <td><%= row.getCheckOutTime() == null ? "--" : row.getCheckOutTime() %></td>
                  </tr>
                <%
                    }
                  }
                %>
              </tbody>
            </table>
          </div>
        </div>

        <!-- Recent logs table -->
        <div class="card">
          <div class="card-hd">
            <div class="card-hd-left">
              <div class="card-title">Recent Attendance Logs</div>
              <div class="card-subtitle">Historical attendance across all employees</div>
            </div>
          </div>
          <div class="dg-container scrollbar">
            <table class="table">
              <thead>
                <tr>
                  <th>Date</th>
                  <th>#</th>
                  <th>Employee</th>
                  <th>Department</th>
                  <th>Status</th>
                  <th>Check-in</th>
                  <th>Check-out</th>
                </tr>
              </thead>
              <tbody>
                <%
                  if (recentAttendanceRows == null || recentAttendanceRows.isEmpty()) {
                %>
                  <tr class="dg-empty"><td colspan="7">No recent attendance logs.</td></tr>
                <%
                  } else {
                    for (AttendanceRow row : recentAttendanceRows) {
                      String rClass = "status-badge " + ("Active".equalsIgnoreCase(row.getAttendanceStatus()) ? "status-active" : "status-inactive");
                %>
                  <tr>
                    <td><span class="tm f-sm"><%= row.getWorkDate() == null ? "--" : row.getWorkDate() %></span></td>
                    <td><span class="tm f-sm">#<%= row.getEmployeeId() %></span></td>
                    <td><span class="fw-6"><%= esc(row.getName()) %></span></td>
                    <td><%= esc(row.getDepartment()) %></td>
                    <td><span class="<%= rClass %>"><%= esc(row.getAttendanceStatus()) %></span></td>
                    <td><%= row.getCheckInTime()  == null ? "--" : row.getCheckInTime() %></td>
                    <td><%= row.getCheckOutTime() == null ? "--" : row.getCheckOutTime() %></td>
                  </tr>
                <%
                    }
                  }
                %>
              </tbody>
            </table>
          </div>
        </div>

      </div>
    </main>
  </div>
</div>
<script src="${pageContext.request.contextPath}/js/app.js"></script>
</body>
</html>
