<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.ems.model.User" %>
<%@ page import="com.ems.model.WorkloadEntry" %>
<%@ page import="com.ems.model.PerformanceEntry" %>
<%@ page import="com.ems.model.ActivityItem" %>
<%@ page import="com.ems.model.InsightCard" %>
<%@ page import="com.ems.model.DepartmentInsight" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.time.LocalDateTime" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="java.time.LocalDate" %>
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

  // Tasks
  Integer pendingObj   = (Integer) request.getAttribute("taskPending");
  Integer progressObj  = (Integer) request.getAttribute("taskProgress");
  Integer completedObj = (Integer) request.getAttribute("taskCompleted");
  Integer totalObj     = (Integer) request.getAttribute("taskTotal");
  Integer overdueObj   = (Integer) request.getAttribute("taskOverdue");
  int pending   = pendingObj   == null ? 0 : pendingObj;
  int progress  = progressObj  == null ? 0 : progressObj;
  int completed = completedObj == null ? 0 : completedObj;
  int total     = totalObj     == null ? 0 : totalObj;
  int overdue   = overdueObj   == null ? 0 : overdueObj;

  // Headcount + attendance
  Integer totalEmployeesObj  = (Integer) request.getAttribute("totalEmployees");
  Integer activeEmployeesObj = (Integer) request.getAttribute("activeEmployees");
  Integer todayAttendanceObj = (Integer) request.getAttribute("todayAttendance");
  Integer attendanceRateObj  = (Integer) request.getAttribute("attendanceRate");
  int totalEmployees   = totalEmployeesObj  == null ? 0 : totalEmployeesObj;
  int activeEmployees  = activeEmployeesObj == null ? 0 : activeEmployeesObj;
  int todayAttendance  = todayAttendanceObj == null ? 0 : todayAttendanceObj;
  int attendanceRate   = attendanceRateObj  == null ? 0 : attendanceRateObj;

  Double productivityObj = (Double) request.getAttribute("productivityScore");
  double productivityScore = productivityObj == null ? 0.0 : productivityObj;

  List<WorkloadEntry> workloads     = (List<WorkloadEntry>) request.getAttribute("workloads");
  List<WorkloadEntry> topOverloaded = (List<WorkloadEntry>) request.getAttribute("topOverloaded");
  List<WorkloadEntry> mostOverdue   = (List<WorkloadEntry>) request.getAttribute("mostOverdue");
  Map<String,Integer> workloadDist  = (Map<String,Integer>) request.getAttribute("workloadDist");
  List<PerformanceEntry> leaderboard = (List<PerformanceEntry>) request.getAttribute("performanceLeaderboard");
  List<Map<String,Object>> mostLate  = (List<Map<String,Object>>) request.getAttribute("mostLate");
  List<int[]> attendanceTrend = (List<int[]>) request.getAttribute("attendanceTrend");
  List<ActivityItem> activityFeed = (List<ActivityItem>) request.getAttribute("activityFeed");
  List<InsightCard> insightCards = (List<InsightCard>) request.getAttribute("insightCards");
  List<DepartmentInsight> departmentInsights = (List<DepartmentInsight>) request.getAttribute("departmentInsights");

  String csrfToken = (String) request.getAttribute("csrfToken");
  if (csrfToken == null) { csrfToken = ""; }

  int wlLow        = workloadDist == null ? 0 : workloadDist.getOrDefault("LOW", 0);
  int wlBalanced   = workloadDist == null ? 0 : workloadDist.getOrDefault("BALANCED", 0);
  int wlOverloaded = workloadDist == null ? 0 : workloadDist.getOrDefault("OVERLOADED", 0);

  int completionRate = total > 0 ? (int) Math.round(completed * 100.0 / total) : 0;
%>
<%!
  private String esc(String value) {
    if (value == null) { return ""; }
    return value.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
  }
  private String relTime(java.time.LocalDateTime t) {
    if (t == null) return "";
    long mins = java.time.Duration.between(t, java.time.LocalDateTime.now()).toMinutes();
    if (mins < 1)   return "just now";
    if (mins < 60)  return mins + "m ago";
    long hrs = mins / 60;
    if (hrs < 24)   return hrs + "h ago";
    long days = hrs / 24;
    if (days < 7)   return days + "d ago";
    return t.toLocalDate().toString();
  }
  private String fmt1(double v) {
    if (v == Math.floor(v)) return String.valueOf((int) v);
    return String.format("%.1f", v);
  }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>EMS &mdash; Analytics</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css?v=8">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/ems-ui.css?v=8">
  <script src="${pageContext.request.contextPath}/js/theme-init.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
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
        <a class="nav-item" href="${pageContext.request.contextPath}/dashboard"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg></span><span class="nav-tx">Dashboard</span></a>
        <a class="nav-item" href="${pageContext.request.contextPath}/employees"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg></span><span class="nav-tx">Employees</span></a>
        <a class="nav-item" href="${pageContext.request.contextPath}/tasks"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg></span><span class="nav-tx">Tasks</span></a>
        <a class="nav-item" href="${pageContext.request.contextPath}/attendance"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 2v4"/><path d="M16 2v4"/><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M3 10h18"/></svg></span><span class="nav-tx">Attendance</span></a>
        <a class="nav-item active" href="${pageContext.request.contextPath}/analytics"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3v18h18"/><path d="M7 14l4-4 4 3 5-7"/></svg></span><span class="nav-tx">Analytics</span></a>
        <a class="nav-item" href="${pageContext.request.contextPath}/audit"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="9" y1="13" x2="15" y2="13"/><line x1="9" y1="17" x2="15" y2="17"/></svg></span><span class="nav-tx">Audit Logs</span></a>
      <a class="nav-item" href="${pageContext.request.contextPath}/leaves" data-label="Leaves"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/><polyline points="9 16 11 18 15 14"/></svg></span><span class="nav-tx">Leaves</span></a>
      </nav>
      <div class="sb-ft">
        <form action="${pageContext.request.contextPath}/login" method="POST">
          <input type="hidden" name="action" value="logout">
          <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
          <button type="submit" class="nav-item" style="width:100%;"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg></span><span class="nav-tx">Logout</span></button>
        </form>
      </div>
    </aside>

    <div class="main">
      <header class="topbar">
        <div class="tb-left">
          <button class="sb-toggle" type="button" data-sb-toggle aria-label="Toggle sidebar"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg></button>
          <span class="tb-title">Analytics</span>
        </div>
        <div class="tb-right">
          <div class="user-menu">
            <button class="user-trigger" type="button" data-dropdown>
              <div class="avatar"><%= initials %></div>
              <span class="user-name"><%= esc(user.getUsername()) %></span>
            </button>
          </div>
        </div>
      </header>

      <main class="content">
        <div class="content-wrap">

          <!-- ===== Hero ===== -->
          <div class="an-hero">
            <div>
              <div class="page-intro-eyebrow">Insights</div>
              <div class="an-hero-title">Workforce Analytics</div>
              <div class="an-hero-sub">Live workload, productivity, and attendance signals across the organization.</div>
            </div>
            <div style="display:flex; gap:var(--s2); flex-wrap:wrap;">
              <a class="btn btn-secondary btn-sm" href="${pageContext.request.contextPath}/reports/attendance">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
                Attendance CSV
              </a>
              <a class="btn btn-secondary btn-sm" href="${pageContext.request.contextPath}/reports/tasks">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
                Tasks CSV
              </a>
            </div>
          </div>

          <!-- ===== Today Snapshot strip ===== -->
          <% int lateThisWeek = mostLate == null ? 0 : mostLate.size(); %>
          <div class="snapshot-strip">
            <div class="snapshot-cell">
              <div class="snapshot-icon tone-info">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="4" fill="currentColor"/></svg>
              </div>
              <div class="snapshot-meta">
                <div class="snapshot-num" data-count="<%= activeEmployees %>"><%= activeEmployees %></div>
                <div class="snapshot-label">Active now</div>
              </div>
            </div>
            <div class="snapshot-cell">
              <div class="snapshot-icon tone-ok">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
              </div>
              <div class="snapshot-meta">
                <div class="snapshot-num" data-count="<%= todayAttendance %>"><%= todayAttendance %></div>
                <div class="snapshot-label">Checked in today</div>
              </div>
            </div>
            <div class="snapshot-cell">
              <div class="snapshot-icon <%= overdue > 0 ? "tone-err" : "tone-ok" %>">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
              </div>
              <div class="snapshot-meta">
                <div class="snapshot-num" data-count="<%= overdue %>"><%= overdue %></div>
                <div class="snapshot-label">Overdue tasks</div>
              </div>
            </div>
            <div class="snapshot-cell">
              <div class="snapshot-icon <%= lateThisWeek > 0 ? "tone-warn" : "tone-ok" %>">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
              </div>
              <div class="snapshot-meta">
                <div class="snapshot-num" data-count="<%= lateThisWeek %>"><%= lateThisWeek %></div>
                <div class="snapshot-label">Late this week</div>
              </div>
            </div>
          </div>

          <!-- ===== 1. Executive KPI row (4 cards) ===== -->
          <div class="an-kpi-row">
            <div class="an-kpi">
              <div class="an-kpi-head">
                <span class="an-kpi-label">Total Employees</span>
                <span class="an-kpi-icon tone-p"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg></span>
              </div>
              <div class="an-kpi-value" data-count="<%= totalEmployees %>"><%= totalEmployees %></div>
              <div class="an-kpi-foot">
                <span class="an-kpi-trend up"><%= activeEmployees %> active</span>
                <span style="margin-left:6px;">on the clock</span>
              </div>
            </div>
            <div class="an-kpi">
              <div class="an-kpi-head">
                <span class="an-kpi-label">Attendance Rate</span>
                <span class="an-kpi-icon tone-ok"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 2v4"/><path d="M16 2v4"/><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M3 10h18"/></svg></span>
              </div>
              <div class="an-kpi-value" data-count="<%= attendanceRate %>" data-suffix="%"><%= attendanceRate %>%</div>
              <div class="an-kpi-foot">
                <span class="an-kpi-trend <%= attendanceRate >= 75 ? "up" : "down" %>"><%= todayAttendance %>/<%= totalEmployees %></span>
                <span style="margin-left:6px;">today</span>
              </div>
            </div>
            <div class="an-kpi">
              <div class="an-kpi-head">
                <span class="an-kpi-label">Productivity</span>
                <span class="an-kpi-icon tone-info"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3v18h18"/><path d="M7 14l4-4 4 3 5-7"/></svg></span>
              </div>
              <div class="an-kpi-value" data-count="<%= productivityScore %>" data-decimals="1"><%= fmt1(productivityScore) %></div>
              <div class="an-kpi-foot">
                <span class="an-kpi-trend <%= productivityScore >= 70 ? "up" : "down" %>"><%= completionRate %>%</span>
                <span style="margin-left:6px;">completion rate</span>
              </div>
            </div>
            <div class="an-kpi">
              <div class="an-kpi-head">
                <span class="an-kpi-label">Overdue Tasks</span>
                <span class="an-kpi-icon <%= overdue > 0 ? "tone-err" : "tone-ok" %>"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg></span>
              </div>
              <div class="an-kpi-value" data-count="<%= overdue %>"><%= overdue %></div>
              <div class="an-kpi-foot">
                <span class="an-kpi-trend <%= overdue == 0 ? "up" : "down" %>"><%= pending %> pending</span>
                <span style="margin-left:6px;">· <%= progress %> active</span>
              </div>
            </div>
          </div>

          <!-- ===== 2. Donut + Trend (side by side) ===== -->
          <div class="charts-row">
            <div class="card">
              <div class="card-hd">
                <div class="card-hd-left">
                  <div class="card-title">Task Status</div>
                  <div class="card-subtitle">Pipeline split</div>
                </div>
              </div>
              <div class="chart-frame">
                <% if (total == 0) { %>
                  <div class="empty-state" style="padding: var(--s6) 0;">
                    <div class="empty-state-icon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15.5A9 9 0 1 1 8.5 3"/><path d="M21 11.5A9 9 0 0 0 12.5 3v8.5z"/></svg></div>
                    <div class="empty-state-title">No tasks yet</div>
                  </div>
                <% } else { %>
                  <div class="chart-box chart-box-md">
                    <canvas id="taskDonut"></canvas>
                    <div class="donut-center">
                      <div class="donut-center-num"><%= completionRate %>%</div>
                      <div class="donut-center-lbl">Completion</div>
                    </div>
                  </div>
                <% } %>
              </div>
              <% if (total > 0) { %>
              <div class="chart-legend">
                <span class="chart-legend-item"><span class="insight-dot tone-warn"></span>Pending <span class="wl-num-muted"><%= pending %></span></span>
                <span class="chart-legend-item"><span class="insight-dot tone-info"></span>In Progress <span class="wl-num-muted"><%= progress %></span></span>
                <span class="chart-legend-item"><span class="insight-dot tone-ok"></span>Completed <span class="wl-num-muted"><%= completed %></span></span>
              </div>
              <% } %>
            </div>

            <div class="card">
              <div class="card-hd">
                <div class="card-hd-left">
                  <div class="card-title">Attendance Trend</div>
                  <div class="card-subtitle">Daily unique check-ins · last 7 days</div>
                </div>
              </div>
              <div class="chart-frame">
                <div class="chart-box chart-box-md"><canvas id="attendanceTrendChart"></canvas></div>
              </div>
            </div>
          </div>

          <!-- ===== 3. Workload heatmap ===== -->
          <div class="an-section-hd">
            <div class="an-section-title">Workload Heatmap</div>
            <div class="an-section-sub">Distribution across the workforce</div>
          </div>
          <div class="heatmap-grid">
            <%
              int wlTotal = wlLow + wlBalanced + wlOverloaded;
              int lowPct  = wlTotal > 0 ? (int) Math.round(wlLow        * 100.0 / wlTotal) : 0;
              int balPct  = wlTotal > 0 ? (int) Math.round(wlBalanced   * 100.0 / wlTotal) : 0;
              int ovPct   = wlTotal > 0 ? (int) Math.round(wlOverloaded * 100.0 / wlTotal) : 0;
            %>
            <div class="heatmap-card tone-info">
              <div class="heatmap-card-head">
                <div style="display:flex; align-items:center; gap:var(--s2);">
                  <span class="heatmap-icon"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="6" y1="20" x2="6" y2="14"/><line x1="12" y1="20" x2="12" y2="10"/><line x1="18" y1="20" x2="18" y2="4" opacity=".3"/></svg></span>
                  <span class="heatmap-card-label">Low load</span>
                </div>
                <span class="heatmap-card-pill"><%= lowPct %>%</span>
              </div>
              <div class="heatmap-card-num" data-count="<%= wlLow %>"><%= wlLow %></div>
              <div class="heatmap-card-msg">Capacity for new work</div>
            </div>
            <div class="heatmap-card tone-ok">
              <div class="heatmap-card-head">
                <div style="display:flex; align-items:center; gap:var(--s2);">
                  <span class="heatmap-icon"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="12" x2="21" y2="12"/><circle cx="12" cy="12" r="3"/></svg></span>
                  <span class="heatmap-card-label">Balanced</span>
                </div>
                <span class="heatmap-card-pill"><%= balPct %>%</span>
              </div>
              <div class="heatmap-card-num" data-count="<%= wlBalanced %>"><%= wlBalanced %></div>
              <div class="heatmap-card-msg">Healthy workload</div>
            </div>
            <div class="heatmap-card tone-err">
              <div class="heatmap-card-head">
                <div style="display:flex; align-items:center; gap:var(--s2);">
                  <span class="heatmap-icon"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg></span>
                  <span class="heatmap-card-label">Overloaded</span>
                </div>
                <span class="heatmap-card-pill"><%= ovPct %>%</span>
              </div>
              <div class="heatmap-card-num" data-count="<%= wlOverloaded %>"><%= wlOverloaded %></div>
              <div class="heatmap-card-msg">May need rebalancing</div>
            </div>
          </div>

          <!-- ===== 4. Leaderboard (ranked table) ===== -->
          <div class="an-section-hd">
            <div class="an-section-title">Leaderboard</div>
            <div class="an-section-sub">Top performers · this week</div>
          </div>
          <div class="card mb-24">
            <div class="dg-container scrollbar">
              <table class="table">
                <thead>
                  <tr>
                    <th style="width:48px;">#</th>
                    <th>Employee</th>
                    <th style="text-align:right;">Tasks done</th>
                    <th style="text-align:right;">Days present</th>
                    <th style="text-align:right;">Score</th>
                  </tr>
                </thead>
                <tbody>
                  <% if (leaderboard == null || leaderboard.isEmpty()) { %>
                    <tr class="dg-empty"><td colspan="5">
                      <div class="empty-state" style="padding: var(--s8) var(--s4);">
                        <div class="empty-state-icon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="6"/><path d="M15.477 12.89 17 22l-5-3-5 3 1.523-9.11"/></svg></div>
                        <div class="empty-state-title">No leaderboard yet</div>
                        <div class="empty-state-msg">Once tasks are completed and attendance is recorded, top performers will appear here.</div>
                      </div>
                    </td></tr>
                  <% } else { int idx = 1; for (PerformanceEntry p : leaderboard) {
                       String first = (p.getName() == null || p.getName().isEmpty()) ? "?" : p.getName().substring(0,1).toUpperCase();
                       String medalClass = idx == 1 ? "gold" : idx == 2 ? "silver" : idx == 3 ? "bronze" : "";
                  %>
                    <tr class="lb-row" onclick="location.href='${pageContext.request.contextPath}/employees/profile?id=<%= p.getEmployeeId() %>'">
                      <td>
                        <% if (!medalClass.isEmpty()) { %>
                          <span class="medal <%= medalClass %>">
                            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="15" r="6"/><polyline points="8.21 13.89 7 23 12 20 17 23 15.79 13.88"/></svg>
                          </span>
                        <% } else { %>
                          <span class="rank-num"><%= idx %></span>
                        <% } %>
                        <% idx++; %>
                      </td>
                      <td>
                        <div class="wl-emp">
                          <div class="av-sm"><%= esc(first) %></div>
                          <div>
                            <div class="wl-emp-name"><%= esc(p.getName()) %></div>
                            <div class="wl-emp-dept">user #<%= p.getUserId() %></div>
                          </div>
                        </div>
                      </td>
                      <td style="text-align:right;"><span class="wl-num"><%= p.getCompletedTasks() %></span></td>
                      <td style="text-align:right;"><span class="wl-num-muted"><%= p.getAttendanceDays() %></span></td>
                      <td style="text-align:right;"><span class="badge badge-info" style="font-weight:700;"><%= p.getScore() %></span></td>
                    </tr>
                  <% } } %>
                </tbody>
              </table>
            </div>
          </div>

          <!-- ===== Smaller intelligence rows: Most Overloaded · Most Late · Most Overdue ===== -->
          <div class="analytics-grid-2">
            <div class="card">
              <div class="card-hd"><div class="card-hd-left"><div class="card-title">Most Overloaded</div><div class="card-subtitle">Highest active workload</div></div></div>
              <div class="rank-list">
                <% if (topOverloaded == null || topOverloaded.isEmpty()) { %>
                  <div class="empty-state" style="padding: var(--s8) var(--s4);">
                    <div class="empty-state-icon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="6" y1="20" x2="6" y2="14"/><line x1="12" y1="20" x2="12" y2="10"/><line x1="18" y1="20" x2="18" y2="4"/></svg></div>
                    <div class="empty-state-title">No workload data</div>
                    <div class="empty-state-msg">Top-loaded employees will appear here as tasks are assigned.</div>
                  </div>
                <% } else { int i = 1; for (WorkloadEntry w : topOverloaded) { %>
                  <div class="rank-item">
                    <div class="rank-num"><%= i++ %></div>
                    <div>
                      <div class="rank-name"><%= esc(w.getName()) %></div>
                      <div class="rank-meta"><%= w.getActiveTasks() %> active · <%= w.getOverdueTasks() %> overdue</div>
                    </div>
                    <div class="rank-value">
                      <div class="rank-value-num"><%= w.getWorkloadScore() %></div>
                      <% String tone = w.getWorkloadTone(); String chip = "err".equals(tone) ? "chip-err" : "ok".equals(tone) ? "chip-ok" : "chip-info"; %>
                      <span class="badge <%= chip %>" style="font-size:10px;"><%= w.getWorkloadStatus() %></span>
                    </div>
                  </div>
                <% } } %>
              </div>
            </div>

            <div class="card">
              <div class="card-hd"><div class="card-hd-left"><div class="card-title">Most Late This Week</div><div class="card-subtitle">Check-ins after 09:15</div></div></div>
              <div class="rank-list">
                <% if (mostLate == null || mostLate.isEmpty()) { %>
                  <div class="empty-state" style="padding: var(--s8) var(--s4);">
                    <div class="empty-state-icon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg></div>
                    <div class="empty-state-title">All on time</div>
                    <div class="empty-state-msg">No employees have late check-ins this week.</div>
                  </div>
                <% } else { int i = 1; for (Map<String,Object> m : mostLate) { %>
                  <div class="rank-item">
                    <div class="rank-num"><%= i++ %></div>
                    <div>
                      <div class="rank-name"><%= esc(String.valueOf(m.get("name"))) %></div>
                      <div class="rank-meta"><%= esc(String.valueOf(m.get("department") == null ? "—" : m.get("department"))) %></div>
                    </div>
                    <div class="rank-value">
                      <div class="rank-value-num"><%= m.get("lateCount") %></div>
                      <div class="rank-value-sub">days</div>
                    </div>
                  </div>
                <% } } %>
              </div>
            </div>
          </div>

          <!-- ===== 5. Recent activity timeline ===== -->
          <div class="an-section-hd">
            <div class="an-section-title">Recent Activity</div>
            <div class="an-section-sub">Last <%= activityFeed == null ? 0 : activityFeed.size() %> events</div>
          </div>
          <div class="card mb-24">
            <% if (activityFeed == null || activityFeed.isEmpty()) { %>
              <div class="empty-state">
                <div class="empty-state-icon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg></div>
                <div class="empty-state-title">No recent activity</div>
                <div class="empty-state-msg">Check-ins, task updates and overdue alerts will appear here.</div>
              </div>
            <% } else { %>
              <div class="feed-list">
                <% for (ActivityItem a : activityFeed) {
                     String t = a.getTone();
                     String iconTone = "feed-icon tone-" + (t == null ? "info" : t);
                %>
                <div class="feed-item">
                  <div class="<%= iconTone %>">
                    <% if ("OVERDUE".equals(a.getType()) || "LATE".equals(a.getType())) { %>
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
                    <% } else if ("TASK_DONE".equals(a.getType())) { %>
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
                    <% } else if ("CHECK_IN".equals(a.getType())) { %>
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                    <% } else { %>
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>
                    <% } %>
                  </div>
                  <div class="feed-body">
                    <div class="feed-title"><%= esc(a.getTitle()) %></div>
                    <div class="feed-detail"><%= esc(a.getDetail()) %></div>
                  </div>
                  <div class="feed-time"><%= relTime(a.getWhen()) %></div>
                </div>
                <% } %>
              </div>
            <% } %>
          </div>

          <!-- ===== 6. Department insight cards ===== -->
          <% if (departmentInsights != null && !departmentInsights.isEmpty()) { %>
          <div class="an-section-hd">
            <div class="an-section-title">Department Insights</div>
            <div class="an-section-sub"><%= departmentInsights.size() %> department<%= departmentInsights.size() == 1 ? "" : "s" %></div>
          </div>
          <div class="dept-grid">
            <% for (DepartmentInsight d : departmentInsights) {
                 String tone = d.getProductivityTone();
                 String chip = "ok".equals(tone) ? "badge-ok" : "info".equals(tone) ? "badge-info" : "warn".equals(tone) ? "badge-warn" : "badge-err";
                 int barPct = (int) Math.max(0, Math.min(100, Math.round(d.getAvgCompletion())));
                 String barTone = barPct >= 70 ? "tone-ok" : barPct >= 50 ? "" : barPct >= 30 ? "tone-warn" : "tone-err";
            %>
            <div class="dept-card">
              <div class="dept-card-head">
                <span class="dept-card-name"><%= esc(d.getDepartment()) %></span>
                <span class="badge <%= chip %>"><%= fmt1(d.getAvgProductivity()) %></span>
              </div>
              <div class="dept-card-count"><%= d.getHeadcount() %> employee<%= d.getHeadcount() == 1 ? "" : "s" %></div>
              <div class="dept-card-row"><span>Avg. completion</span><span class="v"><%= fmt1(d.getAvgCompletion()) %>%</span></div>
              <div class="dept-card-bar"><div class="dept-card-bar-fill <%= barTone %>" style="width: <%= barPct %>%;"></div></div>
              <div class="dept-card-row"><span>Overloaded</span><span class="v <%= d.getOverloaded() > 0 ? "danger" : "muted" %>"><%= d.getOverloaded() %></span></div>
              <div class="dept-card-row"><span>Overdue tasks</span><span class="v <%= d.getOverdueTasks() > 0 ? "danger" : "muted" %>"><%= d.getOverdueTasks() %></span></div>
            </div>
            <% } %>
          </div>
          <% } %>

          <!-- ===== Workload table (kept as the dense source-of-truth grid) ===== -->
          <div class="an-section-hd">
            <div class="an-section-title">Workload Table</div>
            <div class="an-section-sub"><%= workloads == null ? 0 : workloads.size() %> employees</div>
          </div>
          <div class="card">
            <div class="dg-container scrollbar wl-table-wrap">
              <table class="wl-table">
                <thead>
                  <tr>
                    <th>Employee</th>
                    <th style="text-align:right;">Assigned</th>
                    <th style="text-align:right;">Completed</th>
                    <th style="text-align:right;">Pending</th>
                    <th style="text-align:right;">Overdue</th>
                    <th>Status</th>
                    <th style="min-width:140px;">Productivity</th>
                  </tr>
                </thead>
                <tbody>
                  <% if (workloads == null || workloads.isEmpty()) { %>
                    <tr><td colspan="7" style="text-align:center; padding:var(--s10) var(--s4); color:var(--t4);">No employee data available.</td></tr>
                  <% } else { for (WorkloadEntry w : workloads) {
                       String tone = w.getWorkloadTone();
                       String chip = "err".equals(tone) ? "chip-err" : "ok".equals(tone) ? "chip-ok" : "chip-info";
                       int prodPct = (int) Math.round(w.getProductivityScore());
                       String prodTone = prodPct >= 70 ? "ok" : prodPct >= 50 ? "" : prodPct >= 30 ? "warn" : "err";
                       String firstChar = (w.getName() == null || w.getName().isEmpty()) ? "?" : w.getName().substring(0,1).toUpperCase();
                  %>
                  <tr>
                    <td>
                      <div class="wl-emp">
                        <div class="av-sm"><%= esc(firstChar) %></div>
                        <div>
                          <div class="wl-emp-name"><%= esc(w.getName()) %></div>
                          <div class="wl-emp-dept"><%= esc(w.getDepartment() == null ? "—" : w.getDepartment()) %></div>
                        </div>
                      </div>
                    </td>
                    <td style="text-align:right;"><span class="wl-num"><%= w.getTotalAssignedTasks() %></span></td>
                    <td style="text-align:right;"><span class="wl-num-muted"><%= w.getCompletedTasks() %></span></td>
                    <td style="text-align:right;"><span class="wl-num-muted"><%= w.getPendingTasks() %></span></td>
                    <td style="text-align:right;"><span class="wl-num" style="<%= w.getOverdueTasks() > 0 ? "color:var(--err);" : "" %>"><%= w.getOverdueTasks() %></span></td>
                    <td><span class="badge <%= chip %>"><%= w.getWorkloadStatus() %></span></td>
                    <td>
                      <div class="wl-prod">
                        <div class="wl-prod-num"><%= fmt1(w.getProductivityScore()) %> <span style="color:var(--t4); font-weight:500;">/ 100</span></div>
                        <div class="wl-bar"><div class="wl-bar-fill <%= prodTone.isEmpty() ? "" : "tone-" + prodTone %>" style="width: <%= Math.max(0, Math.min(100, prodPct)) %>%;"></div></div>
                      </div>
                    </td>
                  </tr>
                  <% } } %>
                </tbody>
              </table>
            </div>
          </div>

        </div>
      </main>
    </div>
  </div>

  <script src="${pageContext.request.contextPath}/js/app.js"></script>
  <script>
    (function () {
      if (typeof Chart === 'undefined') return;

      // Dark-mode aware: pull tick + grid colors from the live CSS variables so charts
      // match whichever theme is active at render time.
      var rs = getComputedStyle(document.documentElement);
      function v(name, fallback) { var x = rs.getPropertyValue(name); return (x && x.trim()) || fallback; }
      var DARK = document.documentElement.getAttribute('data-theme') === 'dark';
      var COLORS = {
        primary:  v('--p',    '#4f46e5'),
        ok:       v('--ok',   '#10b981'),
        warn:     v('--warn', '#f59e0b'),
        err:      v('--err',  '#ef4444'),
        info:     v('--info', '#2563eb'),
        muted:    v('--t3',   '#6b7280'),
        grid:     DARK ? 'rgba(255,255,255,0.06)' : 'rgba(17,24,39,0.06)'
      };

      Chart.defaults.font.family = '"Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif';
      Chart.defaults.font.size = 11;
      Chart.defaults.color = COLORS.muted;

      // Attendance trend (line)
      var trendData = <%
        StringBuilder sb = new StringBuilder();
        sb.append("[");
        if (attendanceTrend != null) {
          for (int i = 0; i < attendanceTrend.size(); i++) {
            int[] p = attendanceTrend.get(i);
            LocalDate d = LocalDate.ofEpochDay(p[0]);
            if (i > 0) sb.append(",");
            sb.append("{\"label\":\"").append(d.toString()).append("\",\"count\":").append(p[1]).append("}");
          }
        }
        sb.append("]");
        out.print(sb.toString());
      %>;
      var trendEl = document.getElementById('attendanceTrendChart');
      if (trendEl && trendData.length > 0) {
        var ctx = trendEl.getContext('2d');
        // Subtle vertical gradient fill — Stripe-dashboard feel.
        var grad = ctx.createLinearGradient(0, 0, 0, trendEl.offsetHeight || 220);
        if (DARK) {
          grad.addColorStop(0, 'rgba(99,102,241,0.32)');
          grad.addColorStop(1, 'rgba(99,102,241,0.00)');
        } else {
          grad.addColorStop(0, 'rgba(79,70,229,0.22)');
          grad.addColorStop(1, 'rgba(79,70,229,0.00)');
        }
        new Chart(trendEl, {
          type: 'line',
          data: {
            labels: trendData.map(function (d) { return d.label.slice(5); }),
            datasets: [{
              label: 'Check-ins',
              data: trendData.map(function (d) { return d.count; }),
              borderColor: COLORS.primary,
              backgroundColor: grad,
              fill: true,
              tension: 0.45,
              cubicInterpolationMode: 'monotone',
              pointRadius: 0,
              pointHoverRadius: 6,
              pointHitRadius: 16,
              pointBackgroundColor: COLORS.primary,
              pointBorderColor: '#fff',
              pointBorderWidth: 2,
              borderWidth: 2.5
            }]
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            interaction: { mode: 'index', intersect: false },
            animation: { duration: 700, easing: 'easeOutQuart' },
            plugins: {
              legend: { display: false },
              tooltip: {
                padding: { x: 12, y: 8 },
                cornerRadius: 10,
                backgroundColor: DARK ? 'rgba(15,23,42,0.95)' : 'rgba(17,24,39,0.95)',
                titleColor: '#fff',
                bodyColor: '#e5e7eb',
                borderColor: 'rgba(99,102,241,0.4)',
                borderWidth: 1,
                titleFont: { weight: '600', size: 12 },
                bodyFont: { size: 12 },
                displayColors: false,
                callbacks: { label: function (c) { return c.parsed.y + ' check-ins'; } }
              }
            },
            scales: {
              x: { grid: { display: false, drawBorder: false }, ticks: { color: COLORS.muted, padding: 6 } },
              y: { beginAtZero: true, ticks: { precision: 0, color: COLORS.muted, padding: 6, maxTicksLimit: 5 },
                   grid: { color: COLORS.grid, drawBorder: false } }
            }
          }
        });
      }

      // Task donut (existing JSON endpoint)
      var donutEl = document.getElementById('taskDonut');
      if (donutEl) {
        fetch('${pageContext.request.contextPath}/analytics/tasks')
          .then(function (res) { return res.json(); })
          .then(function (data) {
            new Chart(donutEl, {
              type: 'doughnut',
              data: {
                labels: ['Pending', 'In Progress', 'Completed'],
                datasets: [{
                  data: [data.pending || 0, data.inProgress || 0, data.completed || 0],
                  backgroundColor: [COLORS.warn, COLORS.info, COLORS.ok],
                  borderColor: DARK ? '#1e293b' : '#ffffff',
                  borderWidth: 2,
                  hoverOffset: 8,
                  hoverBorderWidth: 0
                }]
              },
              options: {
                responsive: true,
                maintainAspectRatio: false,
                cutout: '72%',
                animation: { animateRotate: true, duration: 700, easing: 'easeOutQuart' },
                plugins: {
                  legend: { display: false },
                  tooltip: {
                    padding: { x: 12, y: 8 },
                    cornerRadius: 10,
                    backgroundColor: DARK ? 'rgba(15,23,42,0.95)' : 'rgba(17,24,39,0.95)',
                    titleColor: '#fff',
                    bodyColor: '#e5e7eb',
                    borderColor: 'rgba(99,102,241,0.4)',
                    borderWidth: 1,
                    displayColors: true,
                    boxPadding: 6
                  }
                }
              }
            });
          });
      }

      /* ── Count-up animation for KPI + snapshot numbers ──
         Reads `data-count` (target), optional `data-decimals` and `data-suffix`. */
      var counters = document.querySelectorAll('[data-count]');
      counters.forEach(function (el) {
        var target = parseFloat(el.getAttribute('data-count'));
        if (!isFinite(target)) return;
        var decimals = parseInt(el.getAttribute('data-decimals') || '0', 10);
        var suffix   = el.getAttribute('data-suffix') || '';
        var dur = 700, t0 = null;
        function step(ts) {
          if (t0 === null) t0 = ts;
          var p = Math.min(1, (ts - t0) / dur);
          // easeOutCubic
          var e = 1 - Math.pow(1 - p, 3);
          var v = target * e;
          el.textContent = (decimals > 0 ? v.toFixed(decimals) : Math.round(v).toLocaleString()) + suffix;
          if (p < 1) requestAnimationFrame(step);
          else el.textContent = (decimals > 0 ? target.toFixed(decimals) : Math.round(target).toLocaleString()) + suffix;
        }
        requestAnimationFrame(step);
      });
    })();
  </script>
</body>
</html>
