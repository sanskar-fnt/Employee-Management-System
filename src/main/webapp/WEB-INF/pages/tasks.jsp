<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.ems.model.User" %>
<%@ page import="com.ems.model.Task" %>
<%@ page import="com.ems.model.Employee" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%
  User user = (User) session.getAttribute("user");
  if (user == null) {
    response.sendRedirect(request.getContextPath() + "/login");
    return;
  }
  String role = user.getRole();
  String initials = "U";
  if (user.getUsername() != null && !user.getUsername().isEmpty()) {
    initials = user.getUsername().substring(0, 1).toUpperCase();
  }
  String taskSuccess = (String) request.getAttribute("taskSuccess");
  String taskError   = (String) request.getAttribute("taskError");
  List<Task>     tasks     = (List<Task>)     request.getAttribute("tasks");
  List<Employee> employees = (List<Employee>) request.getAttribute("employees");
  Map<String, Integer> stats = (Map<String, Integer>) request.getAttribute("taskStats");
  int pending   = stats == null ? 0 : stats.getOrDefault("PENDING",     0);
  int progress  = stats == null ? 0 : stats.getOrDefault("IN_PROGRESS", 0);
  int completed = stats == null ? 0 : stats.getOrDefault("COMPLETED",   0);
  int total     = pending + progress + completed;
  String csrfToken = (String) request.getAttribute("csrfToken");
  if (csrfToken == null) { csrfToken = ""; }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Tasks — EMS</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css?v=8">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/ems-ui.css?v=8">
  <script src="${pageContext.request.contextPath}/js/theme-init.js"></script>
  <% if ("ADMIN".equalsIgnoreCase(role)) { %>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <% } %>
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
      <% if ("ADMIN".equalsIgnoreCase(role)) { %>
      <a class="sb-link" href="${pageContext.request.contextPath}/dashboard" data-label="Dashboard">
        <span class="sb-icon"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg></span>
        <span class="sb-label">Dashboard</span>
      </a>
      <a class="sb-link" href="${pageContext.request.contextPath}/employees" data-label="Employees">
        <span class="sb-icon"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg></span>
        <span class="sb-label">Employees</span>
      </a>
      <a class="sb-link active" href="${pageContext.request.contextPath}/tasks" data-label="Tasks">
        <span class="sb-icon"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg></span>
        <span class="sb-label">Tasks</span>
      </a>
      <a class="sb-link" href="${pageContext.request.contextPath}/attendance" data-label="Attendance">
        <span class="sb-icon"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 2v4"/><path d="M16 2v4"/><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M3 10h18"/></svg></span>
        <span class="sb-label">Attendance</span>
      </a>
      <a class="sb-link" href="${pageContext.request.contextPath}/analytics" data-label="Analytics">
        <span class="sb-icon"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3v18h18"/><path d="M7 14l4-4 4 3 5-7"/></svg></span>
        <span class="sb-label">Analytics</span>
      </a>
      <a class="sb-link" href="${pageContext.request.contextPath}/audit" data-label="Audit Logs">
        <span class="sb-icon"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="9" y1="13" x2="15" y2="13"/><line x1="9" y1="17" x2="15" y2="17"/></svg></span>
        <span class="sb-label">Audit Logs</span>
      </a>
      <a class="sb-link" href="${pageContext.request.contextPath}/leaves" data-label="Leaves">
        <span class="sb-icon"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/><polyline points="9 16 11 18 15 14"/></svg></span>
        <span class="sb-label">Leaves</span>
      </a>
      <% } else { %>
      <a class="sb-link" href="${pageContext.request.contextPath}/emp-dashboard" data-label="Dashboard">
        <span class="sb-icon"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg></span>
        <span class="sb-label">Dashboard</span>
      </a>
      <a class="sb-link active" href="${pageContext.request.contextPath}/tasks" data-label="Tasks">
        <span class="sb-icon"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg></span>
        <span class="sb-label">Tasks</span>
      </a>
      <a class="sb-link" href="${pageContext.request.contextPath}/leaves" data-label="Leaves">
        <span class="sb-icon"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/><polyline points="9 16 11 18 15 14"/></svg></span>
        <span class="sb-label">Leaves</span>
      </a>
      <% } %>
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
        <div class="topbar-title"><%= "ADMIN".equalsIgnoreCase(role) ? "Task Management" : "My Tasks" %></div>
      </div>
      <div class="topbar-right">
        <div class="tb-avatar-wrap" data-dropdown>
          <button class="tb-avatar" aria-label="User menu"><%= initials %></button>
          <div class="dd-popup">
            <div class="dd-header">
              <div class="dd-av"><%= initials %></div>
              <div>
                <div class="dd-name"><%= user.getUsername() %></div>
                <div class="dd-role"><%= role %></div>
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
      <% if (taskSuccess != null) { %>
        <div class="page-alert" data-toast="success"><%= taskSuccess %></div>
      <% } %>
      <% if (taskError != null) { %>
        <div class="page-alert" data-toast="error"><%= taskError %></div>
      <% } %>

      <!-- Page intro -->
      <div class="page-intro">
        <div>
          <h1 class="page-title"><%= "ADMIN".equalsIgnoreCase(role) ? "Task Management" : "My Tasks" %></h1>
          <p class="page-sub"><%= total %> task<%= total == 1 ? "" : "s" %> total</p>
        </div>
        <% if ("ADMIN".equalsIgnoreCase(role)) { %>
        <button class="btn btn-primary" data-modal-open="assignTaskModal">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
          Assign Task
        </button>
        <% } %>
      </div>

      <!-- KPI cards (admin only) -->
      <% if ("ADMIN".equalsIgnoreCase(role)) { %>
      <div class="kpi-row">
        <div class="kpi-card">
          <div class="kpi-accent" style="background:var(--err)"></div>
          <div class="kpi-icon" style="background:rgba(239,68,68,0.1);color:var(--err)">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
          </div>
          <div class="kpi-body">
            <div class="kpi-label">Pending</div>
            <div class="kpi-value"><%= pending %></div>
          </div>
        </div>
        <div class="kpi-card">
          <div class="kpi-accent" style="background:var(--warn)"></div>
          <div class="kpi-icon" style="background:rgba(245,158,11,0.1);color:var(--warn)">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
          </div>
          <div class="kpi-body">
            <div class="kpi-label">In Progress</div>
            <div class="kpi-value"><%= progress %></div>
          </div>
        </div>
        <div class="kpi-card">
          <div class="kpi-accent" style="background:var(--ok)"></div>
          <div class="kpi-icon" style="background:rgba(16,185,129,0.1);color:var(--ok)">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
          </div>
          <div class="kpi-body">
            <div class="kpi-label">Completed</div>
            <div class="kpi-value"><%= completed %></div>
          </div>
        </div>
        <div class="kpi-card">
          <div class="kpi-accent" style="background:var(--p)"></div>
          <div class="kpi-icon" style="background:var(--p-dim);color:var(--p)">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>
          </div>
          <div class="kpi-body">
            <div class="kpi-label">Total</div>
            <div class="kpi-value"><%= total %></div>
          </div>
        </div>
      </div>

      <!-- Analytics chart -->
      <div class="card mb-24">
        <div class="card-hd">
          <div class="card-hd-left">
            <div class="card-title">Task Analytics</div>
            <div class="card-sub">Distribution by status</div>
          </div>
        </div>
        <div class="chart-sm">
          <canvas id="taskChart" height="80"></canvas>
        </div>
      </div>
      <% } %>

      <!-- Task table card -->
      <div class="card">
        <div class="card-hd">
          <div class="card-hd-left">
            <div class="card-title"><%= "ADMIN".equalsIgnoreCase(role) ? "All Tasks" : "My Tasks" %></div>
          </div>
          <div class="card-hd-right">
            <div class="chip-group">
              <button class="chip active" data-select="filterStatus" data-value="">All</button>
              <button class="chip" data-select="filterStatus" data-value="PENDING">Pending</button>
              <button class="chip" data-select="filterStatus" data-value="IN_PROGRESS">In Progress</button>
              <button class="chip" data-select="filterStatus" data-value="COMPLETED">Completed</button>
            </div>
          </div>
        </div>
        <div class="card-filter-bar">
          <select class="input input-sm" id="filterStatus" style="display:none"></select>
          <select class="input input-sm" id="filterPriority">
            <option value="">All Priorities</option>
            <option value="HIGH">High</option>
            <option value="MEDIUM">Medium</option>
            <option value="LOW">Low</option>
          </select>
          <input class="input input-sm" type="date" id="filterStartDate" title="From date">
          <input class="input input-sm" type="date" id="filterEndDate" title="To date">
        </div>
        <div class="dg-container">
          <table class="dg" id="tasksTable">
            <thead>
              <tr>
                <th>Task</th>
                <th>Status</th>
                <th>Priority</th>
                <th>Due</th>
                <th>Reminder</th>
                <% if ("ADMIN".equalsIgnoreCase(role)) { %>
                <th>Assigned To</th>
                <th>Assigned By</th>
                <% } %>
                <th>Updated</th>
                <% if (!"ADMIN".equalsIgnoreCase(role)) { %>
                <th>Action</th>
                <% } %>
              </tr>
            </thead>
            <tbody>
              <% if (tasks == null || tasks.isEmpty()) { %>
              <tr>
                <td colspan="<%= "ADMIN".equalsIgnoreCase(role) ? "8" : "7" %>">
                  <div class="empty-state">
                    <div class="empty-state-icon">
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>
                    </div>
                    <div class="empty-state-title">No tasks yet</div>
                    <div class="empty-state-msg"><%= "ADMIN".equalsIgnoreCase(role) ? "Assign the first task to get the workflow moving." : "Tasks assigned to you will appear here." %></div>
                  </div>
                </td>
              </tr>
              <% } else {
                  for (Task task : tasks) {
                    String st = task.getStatus() == null ? "" : task.getStatus().toUpperCase();
                    String pr = task.getPriority() == null ? "" : task.getPriority().toUpperCase();
                    String statusChip, priorityChip;
                    if ("PENDING".equals(st))      statusChip = "chip-err";
                    else if ("IN_PROGRESS".equals(st)) statusChip = "chip-warn";
                    else                            statusChip = "chip-ok";
                    if ("HIGH".equals(pr))          priorityChip = "chip-err";
                    else if ("MEDIUM".equals(pr))   priorityChip = "chip-warn";
                    else                            priorityChip = "chip-ok";
              %>
              <tr>
                <td>
                  <div class="cell-strong"><%= task.getTitle() != null ? task.getTitle() : "" %></div>
                  <% if (task.getDescription() != null && !task.getDescription().isEmpty()) { %>
                  <div class="cell-sub"><%= task.getDescription() %></div>
                  <% } %>
                </td>
                <td><span class="badge <%= statusChip %>"><%= st.replace("_", " ") %></span></td>
                <td><span class="badge <%= priorityChip %>"><%= pr %></span></td>
                <td class="cell-mono"><%= task.getDueDate() == null ? "--" : task.getDueDate() %></td>
                <td>
                  <% if (task.getReminderAt() != null) { %>
                  <span class="reminder-tag">
                    <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                    <%= task.getReminderAt() %>
                  </span>
                  <% } else { %>--<% } %>
                </td>
                <% if ("ADMIN".equalsIgnoreCase(role)) { %>
                <td><%= task.getAssignedToName() == null ? "--" : task.getAssignedToName() %></td>
                <td><%= task.getAssignedByName() == null ? "--" : task.getAssignedByName() %></td>
                <% } %>
                <td class="cell-muted cell-mono"><%= task.getUpdatedAt() == null ? "--" : task.getUpdatedAt() %></td>
                <% if (!"ADMIN".equalsIgnoreCase(role)) { %>
                <td>
                  <form action="${pageContext.request.contextPath}/tasks" method="POST" class="inline-status-form">
                    <input type="hidden" name="action" value="update">
                    <input type="hidden" name="taskId" value="<%= task.getId() %>">
                    <input type="hidden" name="csrfToken" value="<%= request.getAttribute("csrfToken") == null ? "" : request.getAttribute("csrfToken") %>">
                    <div class="input-btn-pair">
                      <select class="input input-sm" name="status">
                        <option value="PENDING"     <%= "PENDING".equals(st)     ? "selected" : "" %>>Pending</option>
                        <option value="IN_PROGRESS" <%= "IN_PROGRESS".equals(st) ? "selected" : "" %>>In Progress</option>
                        <option value="COMPLETED"   <%= "COMPLETED".equals(st)   ? "selected" : "" %>>Completed</option>
                      </select>
                      <button type="submit" class="btn btn-sm btn-primary">Save</button>
                    </div>
                  </form>
                </td>
                <% } %>
              </tr>
              <%  }
                }
              %>
            </tbody>
          </table>
        </div>
      </div>

    </main>
  </div>
</div>

<!-- Assign Task Modal (admin only) -->
<% if ("ADMIN".equalsIgnoreCase(role)) { %>
<div class="modal-bd" id="assignTaskModal">
  <div class="modal">
    <div class="modal-hd">
      <div class="modal-title">Assign New Task</div>
      <button class="modal-close" data-modal-close aria-label="Close">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
      </button>
    </div>
    <form action="${pageContext.request.contextPath}/tasks" method="POST">
      <input type="hidden" name="action" value="assign">
      <input type="hidden" name="csrfToken" value="<%= request.getAttribute("csrfToken") == null ? "" : request.getAttribute("csrfToken") %>">
      <div class="modal-body">
        <div class="form-grid-2">
          <div class="field">
            <label class="field-label" for="title">Title <span class="field-req">*</span></label>
            <input class="input" type="text" id="title" name="title" placeholder="Task title" required>
          </div>
          <div class="field">
            <label class="field-label" for="priority">Priority</label>
            <select class="input" id="priority" name="priority">
              <option value="LOW">Low</option>
              <option value="MEDIUM" selected>Medium</option>
              <option value="HIGH">High</option>
            </select>
          </div>
          <div class="field">
            <label class="field-label" for="assignedTo">Assign To <span class="field-req">*</span></label>
            <select class="input" id="assignedTo" name="assignedTo" required>
              <option value="">Select employee…</option>
              <% if (employees != null) {
                  for (Employee emp : employees) {
                    if (emp.getUserId() != null) { %>
              <option value="<%= emp.getUserId() %>"><%= emp.getName() %> (<%= emp.getEmail() %>)</option>
              <%    }
                  }
                }
              %>
            </select>
          </div>
          <div class="field">
            <label class="field-label" for="dueDate">Due Date</label>
            <input class="input" type="date" id="dueDate" name="dueDate">
          </div>
          <div class="field">
            <label class="field-label" for="reminderAt">Reminder</label>
            <input class="input" type="datetime-local" id="reminderAt" name="reminderAt">
          </div>
          <div class="field field-span2">
            <label class="field-label" for="description">Description <span class="field-req">*</span></label>
            <textarea class="input" id="description" name="description" rows="3" placeholder="Describe the task…" required></textarea>
          </div>
        </div>
      </div>
      <div class="modal-ft">
        <button type="button" class="btn btn-ghost" data-modal-close>Cancel</button>
        <button type="submit" class="btn btn-primary">Assign Task</button>
      </div>
    </form>
  </div>
</div>
<% } %>

<script src="${pageContext.request.contextPath}/js/app.js"></script>
<script>
(function () {
  /* Chart.js — admin only */
  if (typeof Chart !== 'undefined') {
    fetch('${pageContext.request.contextPath}/analytics/tasks')
      .then(function (r) { return r.json(); })
      .then(function (data) {
        var ctx = document.getElementById('taskChart');
        if (!ctx) return;
        new Chart(ctx, {
          type: 'line',
          data: {
            labels: ['Pending', 'In Progress', 'Completed'],
            datasets: [{
              data: [data.pending, data.inProgress, data.completed],
              borderColor: '#4f46e5',
              backgroundColor: 'rgba(79,70,229,0.12)',
              tension: 0.4,
              fill: true,
              pointRadius: 5,
              pointBackgroundColor: '#4f46e5'
            }]
          },
          options: {
            responsive: true,
            plugins: { legend: { display: false } },
            scales: { y: { beginAtZero: true, ticks: { precision: 0 } } }
          }
        });
      })
      .catch(function () {});
  }

  /* Client-side filtering */
  var table        = document.getElementById('tasksTable');
  var selStatus    = document.getElementById('filterStatus');
  var selPriority  = document.getElementById('filterPriority');
  var selStartDate = document.getElementById('filterStartDate');
  var selEndDate   = document.getElementById('filterEndDate');

  function applyFilters() {
    if (!table) return;
    var st  = selStatus   ? selStatus.value.toUpperCase()   : '';
    var pr  = selPriority ? selPriority.value.toUpperCase() : '';
    var sd  = selStartDate && selStartDate.value ? new Date(selStartDate.value) : null;
    var ed  = selEndDate   && selEndDate.value   ? new Date(selEndDate.value)   : null;
    Array.from(table.querySelectorAll('tbody tr')).forEach(function (row) {
      var stCell  = row.querySelector('td:nth-child(2)');
      var prCell  = row.querySelector('td:nth-child(3)');
      var dueCell = row.querySelector('td:nth-child(4)');
      var rowSt   = stCell  ? stCell.textContent.trim().replace(' ', '_').toUpperCase() : '';
      var rowPr   = prCell  ? prCell.textContent.trim().toUpperCase() : '';
      var dueStr  = dueCell ? dueCell.textContent.trim() : '';
      var dueDate = dueStr && dueStr !== '--' ? new Date(dueStr) : null;
      var stOk    = !st || rowSt === st;
      var prOk    = !pr || rowPr === pr;
      var dtOk    = true;
      if (sd || ed) {
        dtOk = dueDate !== null;
        if (dtOk && sd) dtOk = dueDate >= sd;
        if (dtOk && ed) dtOk = dueDate <= ed;
      }
      row.style.display = stOk && prOk && dtOk ? '' : 'none';
    });
  }

  [selStatus, selPriority, selStartDate, selEndDate].forEach(function (el) {
    if (el) el.addEventListener('change', applyFilters);
  });
})();
</script>
</body>
</html>
