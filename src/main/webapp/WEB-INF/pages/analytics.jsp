<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="com.ems.model.User" %>
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
  Integer pendingObj = (Integer) request.getAttribute("taskPending");
  Integer progressObj = (Integer) request.getAttribute("taskProgress");
  Integer completedObj = (Integer) request.getAttribute("taskCompleted");
  Integer totalObj = (Integer) request.getAttribute("taskTotal");
  int pending = pendingObj == null ? 0 : pendingObj;
  int progress = progressObj == null ? 0 : progressObj;
  int completed = completedObj == null ? 0 : completedObj;
  int total = totalObj == null ? 0 : totalObj;
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
  <title>EMS &mdash; Analytics</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css?v=1">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/ems-ui.css?v=2">
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
        <a class="nav-item" href="${pageContext.request.contextPath}/attendance" data-label="Attendance">
          <span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 2v4"/><path d="M16 2v4"/><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M3 10h18"/><path d="M8 14h.01"/><path d="M12 14h.01"/><path d="M16 14h.01"/><path d="M8 18h.01"/><path d="M12 18h.01"/><path d="M16 18h.01"/></svg></span>
          <span class="nav-tx">Attendance</span>
        </a>
        <a class="nav-item active" href="${pageContext.request.contextPath}/analytics" data-label="Analytics">
          <span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3v18h18"/><path d="M7 14l4-4 4 3 5-7"/></svg></span>
          <span class="nav-tx">Analytics</span>
        </a>
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
          <span class="tb-title">Analytics</span>
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
            <div class="page-intro-title">Task Analytics</div>
            <div class="page-intro-sub">Track workload distribution and completion trends.</div>
          </div>

          <div class="kpi-grid" style="grid-template-columns: repeat(4, 1fr); margin-bottom: var(--s5);">
            <div class="kpi-card kpi-p">
              <div class="kpi-bar"></div>
              <div class="kpi-label">Total Tasks</div>
              <div class="kpi-value"><%= total %></div>
            </div>
            <div class="kpi-card kpi-err">
              <div class="kpi-bar"></div>
              <div class="kpi-label">Pending</div>
              <div class="kpi-value"><%= pending %></div>
            </div>
            <div class="kpi-card kpi-warn">
              <div class="kpi-bar"></div>
              <div class="kpi-label">In Progress</div>
              <div class="kpi-value"><%= progress %></div>
            </div>
            <div class="kpi-card kpi-ok">
              <div class="kpi-bar"></div>
              <div class="kpi-label">Completed</div>
              <div class="kpi-value"><%= completed %></div>
            </div>
          </div>

          <div class="card">
            <div class="card-hd">
              <div class="card-hd-left">
                <div class="card-title">Task Completion Trend</div>
                <div class="card-subtitle">Live snapshot based on current task statuses</div>
              </div>
            </div>
            <div class="card-bd">
              <canvas id="taskChart" height="90"></canvas>
            </div>
          </div>
        </div>
      </main>
    </div>
  </div>

  <script src="${pageContext.request.contextPath}/js/app.js"></script>
  <script>
    (function () {
      var ctx = document.getElementById('taskChart');
      if (!ctx || typeof Chart === 'undefined') return;
      fetch('${pageContext.request.contextPath}/analytics/tasks')
        .then(function (res) { return res.json(); })
        .then(function (data) {
          new Chart(ctx, {
            type: 'doughnut',
            data: {
              labels: ['Pending', 'In Progress', 'Completed'],
              datasets: [{
                data: [data.pending, data.inProgress, data.completed],
                backgroundColor: ['#f59e0b', '#0ea5e9', '#10b981'],
                borderWidth: 0
              }]
            },
            options: {
              responsive: true,
              plugins: { legend: { position: 'bottom' } }
            }
          });
        });
    })();
  </script>
</body>
</html>
