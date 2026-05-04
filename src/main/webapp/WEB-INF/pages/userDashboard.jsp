<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.ems.model.Employee" %>
<%@ page import="com.ems.model.User" %>
<%@ page import="com.ems.model.AttendanceSnapshot" %>
<%
  User user = (User) session.getAttribute("user");
  if (user == null) {
    response.sendRedirect(request.getContextPath() + "/login");
    return;
  }
  Employee employee   = (Employee)          request.getAttribute("employee");
  AttendanceSnapshot snapshot = (AttendanceSnapshot) request.getAttribute("snapshot");
  Boolean canCheckIn  = (Boolean) request.getAttribute("canCheckIn");
  Boolean canCheckOut = (Boolean) request.getAttribute("canCheckOut");
  String todayStatus  = (String)  request.getAttribute("todayStatus");
  if (todayStatus == null) todayStatus = "Not Marked";

  Integer attendanceCountObj = (Integer) request.getAttribute("attendanceCount");
  int attendanceCount = attendanceCountObj == null ? 0 : attendanceCountObj;

  String checkInTime  = "--";
  String checkOutTime = "--";
  String sessionRange = "--";
  if (snapshot != null && snapshot.getCheckInTime() != null) {
    checkInTime  = snapshot.getCheckInTime().toString();
    checkOutTime = snapshot.getCheckOutTime() == null ? "--" : snapshot.getCheckOutTime().toString();
    sessionRange = checkInTime + " → " + checkOutTime;
  }

  String initials = "U";
  if (user.getUsername() != null && !user.getUsername().isEmpty()) {
    initials = user.getUsername().substring(0, 1).toUpperCase();
  }

  String attendanceMessage = (String) request.getAttribute("attendanceMessage");
  String attendanceError   = (String) request.getAttribute("attendanceError");

  boolean checkedIn  = canCheckIn  != null && canCheckIn;
  boolean checkedOut = canCheckOut != null && canCheckOut;
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>My Dashboard — EMS</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css?v=1">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/ems-ui.css?v=2">
</head>
<body>
<div class="app-layout">

  <!-- Sidebar -->
  <aside class="sidebar">
    <div class="sb-head">
      <div class="sb-brand">
        <div class="sb-brand-mark">E</div>
        <span class="sb-brand-name">EMS</span>
      </div>
      <button class="sb-toggle" data-sb-toggle aria-label="Collapse sidebar">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
      </button>
    </div>
    <nav class="sb-nav">
      <a class="sb-link active" href="${pageContext.request.contextPath}/user-dashboard" data-label="Dashboard">
        <span class="sb-icon"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg></span>
        <span class="sb-label">Dashboard</span>
      </a>
      <a class="sb-link" href="${pageContext.request.contextPath}/tasks" data-label="Tasks">
        <span class="sb-icon"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg></span>
        <span class="sb-label">Tasks</span>
      </a>
    </nav>
      <div class="sb-foot">
      <form action="${pageContext.request.contextPath}/login" method="POST">
        <input type="hidden" name="action" value="logout">
        <input type="hidden" name="csrfToken" value="<%= request.getAttribute("csrfToken") == null ? "" : request.getAttribute("csrfToken") %>">
        <button type="submit" class="sb-logout" data-label="Logout">
          <span class="sb-icon"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg></span>
          <span class="sb-label">Logout</span>
        </button>
      </form>
    </div>
  </aside>

  <!-- Main area -->
  <div class="main">
    <header class="topbar">
      <div class="topbar-left">
        <div class="topbar-title">My Dashboard</div>
      </div>
      <div class="topbar-right">
        <div class="tb-avatar-wrap" data-dropdown>
          <button class="tb-avatar" aria-label="User menu"><%= initials %></button>
          <div class="dd-popup">
            <div class="dd-header">
              <div class="dd-av"><%= initials %></div>
              <div>
                <div class="dd-name"><%= user.getUsername() %></div>
                <div class="dd-role"><%= user.getRole() %></div>
              </div>
            </div>
            <div class="dd-divider"></div>
            <form action="${pageContext.request.contextPath}/login" method="POST">
              <input type="hidden" name="action" value="logout">
              <button type="submit" class="dd-item dd-item-danger">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
                Sign out
              </button>
            </form>
          </div>
        </div>
      </div>
    </header>

    <main class="content">

      <!-- Toast alerts -->
      <% if (attendanceMessage != null) { %>
        <div class="page-alert" data-toast="success"><%= attendanceMessage %></div>
      <% } %>
      <% if (attendanceError != null) { %>
        <div class="page-alert" data-toast="error"><%= attendanceError %></div>
      <% } %>

      <!-- Hero check-in card -->
      <div class="emp-hero-card">
        <div class="emp-hero-left">
          <div class="emp-hero-clock">
            <div class="live-clock" id="liveClock">--:--:-- --</div>
            <div class="live-date" id="liveDate">Loading…</div>
          </div>
          <div class="emp-hero-status">
            Today:
            <span class="badge <%= "Not Marked".equalsIgnoreCase(todayStatus) || "Absent".equalsIgnoreCase(todayStatus) ? "chip-err" : "chip-ok" %>">
              <%= todayStatus %>
            </span>
          </div>
        </div>
        <div class="emp-hero-actions">
          <form action="${pageContext.request.contextPath}/attendance" method="POST">
            <input type="hidden" name="action" value="checkin">
            <button type="submit" class="btn btn-ok btn-lg" <%= checkedIn ? "" : "disabled" %>>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
              Check In
            </button>
          </form>
          <form action="${pageContext.request.contextPath}/attendance" method="POST">
            <input type="hidden" name="action" value="checkout">
            <button type="submit" class="btn btn-outline btn-lg" <%= checkedOut ? "" : "disabled" %>>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
              Check Out
            </button>
          </form>
        </div>
      </div>

      <!-- KPI row -->
      <div class="kpi-row">
        <div class="kpi-card">
          <div class="kpi-accent" style="background:var(--p)"></div>
          <div class="kpi-icon" style="background:var(--p-dim);color:var(--p)">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
          </div>
          <div class="kpi-body">
            <div class="kpi-label">Check-in</div>
            <div class="kpi-value kpi-value-sm"><%= checkInTime %></div>
          </div>
        </div>
        <div class="kpi-card">
          <div class="kpi-accent" style="background:var(--info)"></div>
          <div class="kpi-icon" style="background:rgba(14,165,233,0.1);color:var(--info)">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
          </div>
          <div class="kpi-body">
            <div class="kpi-label">Check-out</div>
            <div class="kpi-value kpi-value-sm"><%= checkOutTime %></div>
          </div>
        </div>
        <div class="kpi-card">
          <div class="kpi-accent" style="background:var(--ok)"></div>
          <div class="kpi-icon" style="background:rgba(16,185,129,0.1);color:var(--ok)">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
          </div>
          <div class="kpi-body">
            <div class="kpi-label">Total Logs</div>
            <div class="kpi-value"><%= attendanceCount %></div>
          </div>
        </div>
      </div>

      <!-- Session timeline -->
      <div class="card mb-24">
        <div class="card-hd">
          <div class="card-title">Today's Session</div>
        </div>
        <div class="timeline" style="padding: var(--s4) var(--s5);">
          <div class="timeline-item">
            <span class="timeline-dot"></span>
            <span><%= sessionRange %></span>
          </div>
        </div>
      </div>

      <!-- Profile card -->
      <div class="card">
        <div class="card-hd">
          <div class="card-title">My Profile</div>
        </div>
        <% if (employee == null) { %>
          <div class="alert alert-info" style="margin: var(--s4) var(--s5);">
            Your profile is not linked to an employee record.
          </div>
        <% } else { %>
        <div class="info-grid" style="padding: var(--s4) var(--s5);">
          <div class="info-item">
            <div class="info-label">Name</div>
            <div class="info-value"><%= employee.getName() != null ? employee.getName() : "--" %></div>
          </div>
          <div class="info-item">
            <div class="info-label">Email</div>
            <div class="info-value"><%= employee.getEmail() != null ? employee.getEmail() : "--" %></div>
          </div>
          <div class="info-item">
            <div class="info-label">Phone</div>
            <div class="info-value"><%= employee.getPhone() != null ? employee.getPhone() : "--" %></div>
          </div>
          <div class="info-item">
            <div class="info-label">Department</div>
            <div class="info-value"><%= employee.getDepartment() != null ? employee.getDepartment() : "--" %></div>
          </div>
          <div class="info-item">
            <div class="info-label">Status</div>
            <div class="info-value">
              <span class="badge <%= "Active".equalsIgnoreCase(employee.getStatus()) ? "chip-ok" : "chip-err" %>">
                <%= employee.getStatus() != null ? employee.getStatus() : "--" %>
              </span>
            </div>
          </div>
        </div>
        <% } %>
      </div>

    </main>
  </div>
</div>

<script src="${pageContext.request.contextPath}/js/app.js"></script>
</body>
</html>
