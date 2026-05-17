<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="com.ems.model.User" %>
<%@ page import="com.ems.model.Employee" %>
<%@ page import="com.ems.model.AttendanceRow" %>
<%@ page import="java.util.List" %>
<%
  User user = (User) session.getAttribute("user");
  if (user == null) {
    response.sendRedirect(request.getContextPath() + "/login");
    return;
  }
  String initials = "U";
  if (user.getUsername() != null && !user.getUsername().isEmpty()) {
    initials = user.getUsername().substring(0, 1).toUpperCase();
  }
  List<AttendanceRow> rows = (List<AttendanceRow>) request.getAttribute("attendanceRows");
  List<Employee> employees = (List<Employee>) request.getAttribute("employees");
  String filterDate = (String) request.getAttribute("filterDate");
  String filterEmployeeId = (String) request.getAttribute("filterEmployeeId");
  Integer pageObj = (Integer) request.getAttribute("page");
  Integer totalPagesObj = (Integer) request.getAttribute("totalPages");
  Integer sizeObj = (Integer) request.getAttribute("size");
  int pageNum = pageObj == null ? 1 : pageObj;
  int totalPages = totalPagesObj == null ? 1 : totalPagesObj;
  int size = sizeObj == null ? 10 : sizeObj;
  if (filterDate == null) { filterDate = ""; }
  if (filterEmployeeId == null) { filterEmployeeId = ""; }
  String csrfToken = (String) request.getAttribute("csrfToken");
  if (csrfToken == null) { csrfToken = ""; }
%>
<%!
  private String esc(String value) {
    if (value == null) { return ""; }
    return value.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&#39;");
  }
%>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>EMS &mdash; Attendance</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css?v=8">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/ems-ui.css?v=8">
  <script src="${pageContext.request.contextPath}/js/theme-init.js"></script>
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
        <a class="nav-item" href="${pageContext.request.contextPath}/dashboard" data-label="Dashboard">
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
        <a class="nav-item active" href="${pageContext.request.contextPath}/attendance" data-label="Attendance">
          <span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 2v4"/><path d="M16 2v4"/><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M3 10h18"/><path d="M8 14h.01"/><path d="M12 14h.01"/><path d="M16 14h.01"/><path d="M8 18h.01"/><path d="M12 18h.01"/><path d="M16 18h.01"/></svg></span>
          <span class="nav-tx">Attendance</span>
        </a>
        <a class="nav-item" href="${pageContext.request.contextPath}/analytics" data-label="Analytics">
          <span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3v18h18"/><path d="M7 14l4-4 4 3 5-7"/></svg></span>
          <span class="nav-tx">Analytics</span>
        </a>
        <a class="nav-item" href="${pageContext.request.contextPath}/audit"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="9" y1="13" x2="15" y2="13"/><line x1="9" y1="17" x2="15" y2="17"/></svg></span><span class="nav-tx">Audit Logs</span></a>
      <a class="nav-item" href="${pageContext.request.contextPath}/leaves" data-label="Leaves"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/><polyline points="9 16 11 18 15 14"/></svg></span><span class="nav-tx">Leaves</span></a>
      </nav>
      <div class="sb-ft">
        <form action="${pageContext.request.contextPath}/login" method="POST">
          <input type="hidden" name="action" value="logout">
          <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
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
          <span class="tb-title">Attendance</span>
        </div>
        <div class="tb-right">
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
              <a class="dd-item" href="${pageContext.request.contextPath}/<%= user.getEmployeeId() == null ? "employees" : ("employees/profile?id=" + user.getEmployeeId()) %>">Profile</a>
              <a class="dd-item" href="${pageContext.request.contextPath}/change-password">Settings</a>
            </div>
          </div>
        </div>
      </header>

      <main class="content">
        <div class="content-wrap">
          <div class="page-intro">
            <div class="page-intro-eyebrow">Overview</div>
            <div class="page-intro-title">Attendance Management</div>
            <div class="page-intro-sub">Filter attendance by date or employee and review work hours.</div>
          </div>

          <div class="card" style="margin-bottom: var(--s5);">
            <div class="card-hd">
              <div class="card-hd-left">
                <div class="card-title">Filters</div>
                <div class="card-subtitle">Narrow results to a specific date or employee</div>
              </div>
              <form style="display:flex; gap:var(--s2); align-items:center; flex-wrap:wrap;" action="${pageContext.request.contextPath}/attendance" method="GET">
                <input class="input input-sm" type="date" name="date" value="<%= filterDate %>">
                <select class="input input-sm" name="employeeId">
                  <option value="">All employees</option>
                  <% if (employees != null) {
                       for (Employee emp : employees) { %>
                    <option value="<%= emp.getId() %>" <%= (String.valueOf(emp.getId()).equals(filterEmployeeId) ? "selected" : "") %>><%= esc(emp.getName()) %></option>
                  <%   }
                     } %>
                </select>
                <button type="submit" class="btn btn-primary btn-sm">Apply</button>
              </form>
            </div>
            <div class="dg-container scrollbar">
              <table class="table table-modern">
                <thead>
                  <tr>
                    <th>Date</th>
                    <th>Employee</th>
                    <th>Email</th>
                    <th>Department</th>
                    <th>Status</th>
                    <th>Check-in</th>
                    <th>Check-out</th>
                    <th>Hours</th>
                  </tr>
                </thead>
                <tbody>
                  <% if (rows == null || rows.isEmpty()) { %>
                    <tr><td colspan="8">
                      <div class="empty-state">
                        <div class="empty-state-icon">
                          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 2v4"/><path d="M16 2v4"/><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M3 10h18"/></svg>
                        </div>
                        <div class="empty-state-title">No attendance records</div>
                        <div class="empty-state-msg">Try widening the date range or clearing the employee filter.</div>
                      </div>
                    </td></tr>
                  <% } else {
                       for (AttendanceRow row : rows) {
                         String statusLabel = row.isOnLeave() ? "On Leave" : row.getAttendanceStatus();
                         String statusCls   = row.isOnLeave()
                              ? "badge badge-info"
                              : "status-badge " + ("Active".equalsIgnoreCase(row.getAttendanceStatus()) ? "status-active" : "status-inactive");
                         double hours = 0.0;
                         if (row.getCheckInTime() != null && row.getCheckOutTime() != null) {
                           long diff = row.getCheckOutTime().getTime() - row.getCheckInTime().getTime();
                           if (diff > 0) { hours = diff / (1000.0 * 60.0 * 60.0); }
                         }
                  %>
                    <tr>
                      <td><span class="tm f-sm"><%= row.getWorkDate() == null ? "--" : row.getWorkDate() %></span></td>
                      <td><span class="fw-6"><%= esc(row.getName()) %></span></td>
                      <td><span class="tm"><%= esc(row.getEmail()) %></span></td>
                      <td><%= esc(row.getDepartment()) %></td>
                      <td><span class="<%= statusCls %>"><%= esc(statusLabel) %></span></td>
                      <td><%= row.getCheckInTime() == null ? "--" : row.getCheckInTime() %></td>
                      <td><%= row.getCheckOutTime() == null ? "--" : row.getCheckOutTime() %></td>
                      <td><span class="tm"><%= String.format("%.2f", hours) %>h</span></td>
                    </tr>
                  <%   }
                     } %>
                </tbody>
              </table>
            </div>
            <div class="card-bd" style="display:flex; justify-content:space-between; align-items:center;">
              <div class="tm">Page <%= pageNum %> of <%= totalPages %></div>
              <div style="display:flex; gap:8px;">
                <a class="btn btn-secondary btn-sm" href="${pageContext.request.contextPath}/attendance?date=<%= filterDate %>&employeeId=<%= filterEmployeeId %>&page=<%= Math.max(1, pageNum - 1) %>&size=<%= size %>">Prev</a>
                <a class="btn btn-secondary btn-sm" href="${pageContext.request.contextPath}/attendance?date=<%= filterDate %>&employeeId=<%= filterEmployeeId %>&page=<%= Math.min(totalPages, pageNum + 1) %>&size=<%= size %>">Next</a>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  </div>

  <script src="${pageContext.request.contextPath}/js/app.js"></script>
</body>
</html>
