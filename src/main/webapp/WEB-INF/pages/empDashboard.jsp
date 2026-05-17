<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.ems.model.Employee" %>
<%@ page import="com.ems.model.AttendanceSnapshot" %>
<%@ page import="com.ems.model.User" %>
<%@ page import="com.ems.model.PerformanceBreakdown" %>
<%@ page import="com.ems.model.AttendanceDiscipline" %>
<%@ page import="com.ems.model.Notification" %>
<%@ page import="java.util.List" %>
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
  Integer attendanceCountObj = (Integer) request.getAttribute("attendanceCount");
  if (todayStatus == null) todayStatus = "Absent";
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

  PerformanceBreakdown perf = (PerformanceBreakdown) request.getAttribute("performanceBreakdown");
  AttendanceDiscipline disc = (AttendanceDiscipline) request.getAttribute("attendanceDiscipline");
  List<Notification> notifications = (List<Notification>) request.getAttribute("notifications");
  Integer currentStreakObj = (Integer) request.getAttribute("currentStreak");
  Long    overtimeMinObj   = (Long)    request.getAttribute("weeklyOvertimeMin");
  int  currentStreak = currentStreakObj == null ? 0 : currentStreakObj;
  long overtimeMin   = overtimeMinObj   == null ? 0L : overtimeMinObj;
  String overtimeFmt = (overtimeMin / 60) + "h " + (overtimeMin % 60) + "m";
%>
<%!
  private String escHtml(String v) {
    if (v == null) return "";
    return v.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
  }
%>
<%!
  private String fmt(double v) {
    if (v == Math.floor(v)) return String.valueOf((int) v);
    return String.format("%.1f", v);
  }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Employee Dashboard — EMS</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css?v=8">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/ems-ui.css?v=8">
  <script src="${pageContext.request.contextPath}/js/theme-init.js"></script>
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
      <a class="sb-link active" href="${pageContext.request.contextPath}/emp-dashboard" data-label="Dashboard">
        <span class="sb-icon"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg></span>
        <span class="sb-label">Dashboard</span>
      </a>
      <a class="sb-link" href="${pageContext.request.contextPath}/tasks" data-label="Tasks">
        <span class="sb-icon"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg></span>
        <span class="sb-label">Tasks</span>
      </a>
      <a class="sb-link" href="${pageContext.request.contextPath}/leaves" data-label="Leaves"><span class="sb-icon"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/><polyline points="9 16 11 18 15 14"/></svg></span><span class="sb-label">Leaves</span></a>
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
        <div class="topbar-title">Employee Dashboard</div>
      </div>
      <div class="topbar-right">
        <div class="tb-avatar-wrap" data-dropdown>
          <button class="tb-avatar" aria-label="User menu"><%= initials %></button>
          <div class="dd-popup">
            <div class="dd-header">
              <div class="dd-av"><%= initials %></div>
              <div>
                <div class="dd-name"><%= user.getUsername() %></div>
                <div class="dd-role">Employee</div>
              </div>
            </div>
            <div class="dd-divider"></div>
            <form action="${pageContext.request.contextPath}/login" method="POST">
              <input type="hidden" name="action" value="logout">
              <input type="hidden" name="csrfToken" value="<%= request.getAttribute("csrfToken") == null ? "" : request.getAttribute("csrfToken") %>">
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

      <!-- Notifications -->
      <% if (notifications != null && !notifications.isEmpty()) { %>
      <div class="card mb-24">
        <div class="card-hd">
          <div class="card-title">Notifications</div>
          <span class="badge chip-info"><%= notifications.size() %></span>
        </div>
        <div class="noti-list" style="padding: var(--s3) var(--s4);">
          <% for (Notification n : notifications) {
               String sev = n.getSeverity() == null ? "info" : n.getSeverity();
               String sevClass = "sev-" + sev;
          %>
          <div class="noti-item <%= sevClass %>" data-noti-id="<%= escHtml(n.getId()) %>">
            <div class="noti-icon">
              <% if ("danger".equals(sev)) { %>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
              <% } else if ("warning".equals(sev)) { %>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              <% } else { %>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>
              <% } %>
            </div>
            <div class="noti-body">
              <div class="noti-title"><%= escHtml(n.getTitle()) %></div>
              <div class="noti-msg"><%= escHtml(n.getMessage()) %></div>
            </div>
            <div class="noti-actions">
              <% if (n.getHref() != null && !n.getHref().isEmpty()) { %>
                <a class="noti-link" href="${pageContext.request.contextPath}/<%= escHtml(n.getHref()) %>">View</a>
              <% } %>
              <button type="button" class="noti-dismiss" data-noti-id="<%= escHtml(n.getId()) %>" aria-label="Dismiss">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
              </button>
            </div>
          </div>
          <% } %>
        </div>
      </div>
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
            <span class="badge <%= "Absent".equalsIgnoreCase(todayStatus) ? "chip-err" : "chip-ok" %>">
              <%= todayStatus %>
            </span>
          </div>
        </div>
        <div class="emp-hero-actions">
          <form action="${pageContext.request.contextPath}/attendance" method="POST">
            <input type="hidden" name="action" value="checkin">
            <input type="hidden" name="csrfToken" value="<%= request.getAttribute("csrfToken") == null ? "" : request.getAttribute("csrfToken") %>">
            <button type="submit" class="btn btn-ok btn-lg" <%= checkedIn ? "" : "disabled" %>>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
              Check In
            </button>
          </form>
          <form action="${pageContext.request.contextPath}/attendance" method="POST">
            <input type="hidden" name="action" value="checkout">
            <input type="hidden" name="csrfToken" value="<%= request.getAttribute("csrfToken") == null ? "" : request.getAttribute("csrfToken") %>">
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

      <!-- Attendance discipline -->
      <% if (disc != null) {
           String dTone = disc.getDisciplineTone();
           String dChip = "ok".equals(dTone) ? "chip-ok" : "info".equals(dTone) ? "chip-info" : "warn".equals(dTone) ? "chip-warn" : "chip-err";
           int dPct = (int) Math.round(disc.getAttendanceDisciplineScore());
      %>
      <div class="card mb-24">
        <div class="card-hd">
          <div class="card-title">Attendance Discipline (this week)</div>
          <span class="badge <%= dChip %>"><%= disc.getDisciplineLabel() %></span>
        </div>
        <div class="perf-grid">
          <div class="perf-metric">
            <div class="perf-metric-head">
              <span class="perf-metric-label">On Time</span>
              <span class="perf-metric-sub">of <%= disc.getTotalDays() %> days</span>
            </div>
            <div class="perf-metric-value"><%= disc.getOnTimeCount() %></div>
            <div class="perf-metric-sub">Check-in by 09:15</div>
          </div>
          <div class="perf-metric">
            <div class="perf-metric-head">
              <span class="perf-metric-label">Late Arrivals</span>
              <span class="perf-metric-sub">after 09:15</span>
            </div>
            <div class="perf-metric-value"><%= disc.getLateCount() %></div>
            <div class="perf-metric-sub">-8 pts each</div>
          </div>
          <div class="perf-metric">
            <div class="perf-metric-head">
              <span class="perf-metric-label">Early Leaves</span>
              <span class="perf-metric-sub">before 17:00</span>
            </div>
            <div class="perf-metric-value"><%= disc.getEarlyLeaveCount() %></div>
            <div class="perf-metric-sub">-6 pts each</div>
          </div>
          <div class="perf-metric">
            <div class="perf-metric-head">
              <span class="perf-metric-label">Current Streak</span>
              <span class="perf-metric-sub">consecutive days</span>
            </div>
            <div class="perf-metric-value"><%= currentStreak %></div>
            <div class="perf-metric-sub"><%= currentStreak >= 5 ? "Strong consistency" : "Keep showing up" %></div>
          </div>
          <div class="perf-metric">
            <div class="perf-metric-head">
              <span class="perf-metric-label">Weekly Overtime</span>
              <span class="perf-metric-sub">past 17:00</span>
            </div>
            <div class="perf-metric-value"><%= overtimeFmt %></div>
            <div class="perf-metric-sub"><%= overtimeMin > 0 ? "Recognized contribution" : "Within standard hours" %></div>
          </div>
        </div>
        <div class="perf-final">
          <div class="perf-final-num"><%= fmt(disc.getAttendanceDisciplineScore()) %></div>
          <div class="perf-final-meta" style="flex:1;">
            <div class="perf-final-label">Discipline Score</div>
            <div class="progress-track" style="margin: var(--s1) 0;"><div class="progress-fill tone-<%= dTone %>" style="width: <%= dPct %>%;"></div></div>
            <div class="perf-final-formula">work hours 09:00 – 17:00 · late > 09:15 · early &lt; 17:00</div>
          </div>
        </div>
      </div>
      <% } %>

      <!-- Performance breakdown -->
      <% if (perf != null) {
           int attPct  = (int) Math.round(perf.getAttendancePercentage());
           int taskPct = (int) Math.round(perf.getTaskCompletionRate());
           int penPct  = (int) Math.round(perf.getLatePenalty());
           int finalPct= (int) Math.round(perf.getFinalScore());
           String tone = perf.getBadgeTone();
           String chip = "ok".equals(tone) ? "chip-ok" : "info".equals(tone) ? "chip-info" : "warn".equals(tone) ? "chip-warn" : "chip-err";
      %>
      <div class="card mb-24">
        <div class="card-hd">
          <div class="card-title">Performance Breakdown</div>
          <span class="badge <%= chip %>"><%= perf.getBadge() %></span>
        </div>
        <div class="perf-grid">
          <div class="perf-metric">
            <div class="perf-metric-head">
              <span class="perf-metric-label">Attendance</span>
              <span class="perf-metric-sub"><%= perf.getAttendanceDays() %>/<%= perf.getWorkingDays() %> days</span>
            </div>
            <div class="perf-metric-value"><%= fmt(perf.getAttendancePercentage()) %>%</div>
            <div class="progress-track"><div class="progress-fill tone-info" style="width: <%= attPct %>%;"></div></div>
            <div class="perf-metric-sub">Weight 40%</div>
          </div>

          <div class="perf-metric">
            <div class="perf-metric-head">
              <span class="perf-metric-label">Task Completion</span>
              <span class="perf-metric-sub"><%= perf.getCompletedTasks() %>/<%= perf.getTotalTasks() %> tasks</span>
            </div>
            <div class="perf-metric-value"><%= fmt(perf.getTaskCompletionRate()) %>%</div>
            <div class="progress-track"><div class="progress-fill tone-p" style="width: <%= taskPct %>%;"></div></div>
            <div class="perf-metric-sub">Weight 60%</div>
          </div>

          <div class="perf-metric">
            <div class="perf-metric-head">
              <span class="perf-metric-label">Late Penalty</span>
              <span class="perf-metric-sub"><%= perf.getLateDays() %> late this week</span>
            </div>
            <div class="perf-metric-value">-<%= fmt(perf.getLatePenalty()) %></div>
            <div class="progress-track"><div class="progress-fill tone-warn" style="width: <%= penPct %>%;"></div></div>
            <div class="perf-metric-sub">Capped at 25</div>
          </div>
        </div>
        <div class="perf-final">
          <div class="perf-final-num"><%= fmt(perf.getFinalScore()) %></div>
          <div class="perf-final-meta" style="flex:1;">
            <div class="perf-final-label">Final Score</div>
            <div class="progress-track" style="margin: var(--s1) 0;"><div class="progress-fill tone-<%= tone %>" style="width: <%= finalPct %>%;"></div></div>
            <div class="perf-final-formula">finalScore = attendance × 0.4 + tasks × 0.6 − latePenalty</div>
          </div>
        </div>
      </div>
      <% } %>

      <!-- Employee details -->
      <div class="card">
        <div class="card-hd">
          <div class="card-title">My Profile</div>
          <% if (employee != null) { %>
            <a class="btn btn-secondary btn-sm" href="${pageContext.request.contextPath}/employees/profile?id=<%= employee.getId() %>">View full profile →</a>
          <% } %>
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
            <div class="info-label">Username</div>
            <div class="info-value"><%= user.getUsername() %></div>
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
