<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
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
  String taskError = (String) request.getAttribute("taskError");
  List<Task> tasks = (List<Task>) request.getAttribute("tasks");
  List<Employee> employees = (List<Employee>) request.getAttribute("employees");
  Map<String, Integer> stats = (Map<String, Integer>) request.getAttribute("taskStats");
  int pending = stats == null ? 0 : stats.getOrDefault("PENDING", 0);
  int progress = stats == null ? 0 : stats.getOrDefault("IN_PROGRESS", 0);
  int completed = stats == null ? 0 : stats.getOrDefault("COMPLETED", 0);
%>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Tasks</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
  <% if ("ADMIN".equalsIgnoreCase(role)) { %>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <% } %>
</head>
<body class="page-tasks">
  <div class="app-layout">
    <aside class="sidebar">
      <div class="sidebar-brand">EMS</div>
      <nav class="sidebar-nav">
        <a href="${pageContext.request.contextPath}/dashboard"><span class="nav-icon">🏠</span>Dashboard</a>
        <a href="${pageContext.request.contextPath}/employees"><span class="nav-icon">👥</span>Employees</a>
        <a class="active" href="${pageContext.request.contextPath}/tasks"><span class="nav-icon">🗂</span>Tasks</a>
      </nav>
      <form class="sidebar-logout" action="${pageContext.request.contextPath}/login" method="POST">
        <input type="hidden" name="action" value="logout">
        <button type="submit" class="btn btn-danger btn-block">Logout</button>
      </form>
    </aside>

    <div class="main">
      <header class="topbar">
        <div class="topbar-title">Tasks</div>
        <div class="topbar-right">
          <div class="topbar-search">
            <span>🔍</span>
            <input type="text" placeholder="Search tasks...">
          </div>
          <button class="icon-button" type="button" aria-label="Notifications">🔔</button>
          <div class="dropdown">
            <button class="icon-button" type="button" data-dropdown-toggle>
              <div class="avatar"><%= initials %></div>
            </button>
            <div class="dropdown-menu" data-dropdown-menu>
              <div class="dropdown-item">Signed in as <strong><%= user.getUsername() %></strong></div>
              <div class="dropdown-item">Profile</div>
              <div class="dropdown-item">Settings</div>
            </div>
          </div>
          <div class="avatar"><%= initials %></div>
          <span class="text-muted"><%= user.getUsername() %></span>
        </div>
      </header>

      <main class="content">
        <div class="container">
          <% if (taskSuccess != null) { %>
            <div class="alert alert-success"><%= taskSuccess %></div>
          <% } %>
          <% if (taskError != null) { %>
            <div class="alert alert-error"><%= taskError %></div>
          <% } %>

          <% if ("ADMIN".equalsIgnoreCase(role)) { %>
          <div class="card">
            <div class="card-header">
              <div class="card-title">Assign Task</div>
            </div>
            <form action="${pageContext.request.contextPath}/tasks" method="POST">
              <input type="hidden" name="action" value="assign">
              <div class="form-grid">
                <div class="form-group">
                  <label for="title">Title</label>
                  <input class="input" type="text" id="title" name="title" required>
                </div>
                <div class="form-group">
                  <label for="priority">Priority</label>
                  <select class="input" id="priority" name="priority">
                    <option value="LOW">LOW</option>
                    <option value="MEDIUM" selected>MEDIUM</option>
                    <option value="HIGH">HIGH</option>
                  </select>
                </div>
                <div class="form-group">
                  <label for="assignedTo">Assign To</label>
                  <select class="input" id="assignedTo" name="assignedTo" required>
                    <option value="">Select employee</option>
                    <% if (employees != null) {
                        for (Employee emp : employees) {
                          if (emp.getUserId() != null) {
                    %>
                      <option value="<%= emp.getUserId() %>"><%= emp.getName() %> (<%= emp.getEmail() %>)</option>
                    <%      }
                        }
                      }
                    %>
                  </select>
                </div>
                <div class="form-group">
                  <label for="dueDate">Due Date</label>
                  <input class="input" type="date" id="dueDate" name="dueDate">
                </div>
                <div class="form-group">
                  <label for="reminderAt">Reminder</label>
                  <input class="input" type="datetime-local" id="reminderAt" name="reminderAt">
                </div>
                <div class="form-group">
                  <label for="description">Description</label>
                  <textarea class="input" id="description" name="description" rows="3" required></textarea>
                </div>
              </div>
              <div class="form-actions">
                <button type="submit" class="btn btn-primary">Assign Task</button>
              </div>
            </form>
          </div>

          <div class="card">
            <div class="card-header">
              <div class="card-title">Task Analytics</div>
            </div>
            <div class="info-grid">
              <div class="info-item">
                <div class="info-label">Pending</div>
                <div class="info-value"><%= pending %></div>
              </div>
              <div class="info-item">
                <div class="info-label">In Progress</div>
                <div class="info-value"><%= progress %></div>
              </div>
              <div class="info-item">
                <div class="info-label">Completed</div>
                <div class="info-value"><%= completed %></div>
              </div>
            </div>
            <div class="chart-sm" style="margin-top: 20px;">
              <canvas id="taskChart" height="80"></canvas>
            </div>
          </div>
          <% } %>

          <div class="card">
            <div class="card-header">
              <div class="card-title"><%= "ADMIN".equalsIgnoreCase(role) ? "All Tasks" : "My Tasks" %></div>
              <div class="filter-bar">
                <select class="input" id="filterStatus">
                  <option value="">All Statuses</option>
                  <option value="PENDING">PENDING</option>
                  <option value="IN_PROGRESS">IN_PROGRESS</option>
                  <option value="COMPLETED">COMPLETED</option>
                </select>
                <select class="input" id="filterPriority">
                  <option value="">All Priorities</option>
                  <option value="LOW">LOW</option>
                  <option value="MEDIUM">MEDIUM</option>
                  <option value="HIGH">HIGH</option>
                </select>
                <input class="input" type="date" id="filterStartDate">
                <input class="input" type="date" id="filterEndDate">
              </div>
            </div>
            <div class="table-wrapper custom-scrollbar">
              <table class="table" id="tasksTable">
                <thead>
                  <tr>
                    <th>Title</th>
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
                      <th>Actions</th>
                    <% } %>
                  </tr>
                </thead>
                <tbody>
                  <% if (tasks == null || tasks.isEmpty()) { %>
                    <tr>
                      <td colspan="7">No tasks available.</td>
                    </tr>
                  <% } else {
                      for (Task task : tasks) {
                        String statusClass = "status-badge ";
                        if ("PENDING".equalsIgnoreCase(task.getStatus())) {
                          statusClass += "status-pending";
                        } else if ("IN_PROGRESS".equalsIgnoreCase(task.getStatus())) {
                          statusClass += "status-progress";
                        } else {
                          statusClass += "status-completed";
                        }
                        String priorityClass = "status-badge ";
                        if ("HIGH".equalsIgnoreCase(task.getPriority())) {
                          priorityClass += "status-pending";
                        } else if ("MEDIUM".equalsIgnoreCase(task.getPriority())) {
                          priorityClass += "status-progress";
                        } else {
                          priorityClass += "status-completed";
                        }
                  %>
                    <tr>
                      <td>
                        <div class="text-strong"><%= task.getTitle() %></div>
                        <div class="text-muted"><%= task.getDescription() %></div>
                      </td>
                      <td><span class="<%= statusClass %>"><%= task.getStatus() %></span></td>
                      <td><span class="<%= priorityClass %>"><%= task.getPriority() %></span></td>
                      <td><%= task.getDueDate() == null ? "--" : task.getDueDate() %></td>
                      <td>
                        <% if (task.getReminderAt() == null) { %>
                          --
                        <% } else { %>
                          <span class="reminder-badge">⏰ <%= task.getReminderAt() %></span>
                        <% } %>
                      </td>
                      <% if ("ADMIN".equalsIgnoreCase(role)) { %>
                        <td><%= task.getAssignedToName() == null ? "--" : task.getAssignedToName() %></td>
                        <td><%= task.getAssignedByName() == null ? "--" : task.getAssignedByName() %></td>
                      <% } %>
                      <td><%= task.getUpdatedAt() == null ? "--" : task.getUpdatedAt() %></td>
                      <% if (!"ADMIN".equalsIgnoreCase(role)) { %>
                        <td>
                          <form action="${pageContext.request.contextPath}/tasks" method="POST">
                            <input type="hidden" name="action" value="update">
                            <input type="hidden" name="taskId" value="<%= task.getId() %>">
                            <select class="input" name="status">
                              <option value="PENDING" <%= "PENDING".equalsIgnoreCase(task.getStatus()) ? "selected" : "" %>>PENDING</option>
                              <option value="IN_PROGRESS" <%= "IN_PROGRESS".equalsIgnoreCase(task.getStatus()) ? "selected" : "" %>>IN_PROGRESS</option>
                              <option value="COMPLETED" <%= "COMPLETED".equalsIgnoreCase(task.getStatus()) ? "selected" : "" %>>COMPLETED</option>
                            </select>
                            <button type="submit" class="btn btn-success btn-sm" style="margin-top: 8px;">Update</button>
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
        </div>
      </main>
    </div>
  </div>

  <script>
    (function () {
      var topbar = document.querySelector('.topbar');
      var dropdownToggle = document.querySelector('[data-dropdown-toggle]');
      var dropdownMenu = document.querySelector('[data-dropdown-menu]');

      function onScroll() {
        if (!topbar) {
          return;
        }
        if (window.scrollY > 4) {
          topbar.classList.add('scrolled');
        } else {
          topbar.classList.remove('scrolled');
        }
      }

      window.addEventListener('scroll', onScroll);
      onScroll();

      if (dropdownToggle && dropdownMenu) {
        dropdownToggle.addEventListener('click', function () {
          dropdownMenu.classList.toggle('active');
        });
        document.addEventListener('click', function (event) {
          if (!dropdownToggle.contains(event.target) && !dropdownMenu.contains(event.target)) {
            dropdownMenu.classList.remove('active');
          }
        });
      }

      if (typeof Chart !== 'undefined') {
        fetch('${pageContext.request.contextPath}/analytics/tasks')
          .then(function (response) { return response.json(); })
          .then(function (data) {
            var ctx = document.getElementById('taskChart');
            if (!ctx) {
              return;
            }
            new Chart(ctx, {
              type: 'line',
              data: {
                labels: ['Pending', 'In Progress', 'Completed'],
                datasets: [{
                  data: [data.pending, data.inProgress, data.completed],
                  borderColor: '#4f46e5',
                  backgroundColor: 'rgba(79, 70, 229, 0.15)',
                  tension: 0.35,
                  fill: true,
                  pointRadius: 4
                }]
              },
              options: {
                responsive: true,
                plugins: {
                  legend: {
                    display: false
                  }
                },
                scales: {
                  y: {
                    beginAtZero: true
                  }
                }
              }
            });
          });
      }

      var tasksTable = document.getElementById('tasksTable');
      var filterStatus = document.getElementById('filterStatus');
      var filterPriority = document.getElementById('filterPriority');
      var filterStartDate = document.getElementById('filterStartDate');
      var filterEndDate = document.getElementById('filterEndDate');

      function applyFilters() {
        if (!tasksTable) {
          return;
        }
        var statusValue = filterStatus ? filterStatus.value : '';
        var priorityValue = filterPriority ? filterPriority.value : '';
        var startValue = filterStartDate && filterStartDate.value ? new Date(filterStartDate.value) : null;
        var endValue = filterEndDate && filterEndDate.value ? new Date(filterEndDate.value) : null;
        Array.from(tasksTable.querySelectorAll('tbody tr')).forEach(function (row) {
          var statusCell = row.querySelector('td:nth-child(2)');
          var priorityCell = row.querySelector('td:nth-child(3)');
          var dueCell = row.querySelector('td:nth-child(4)');
          var statusText = statusCell ? statusCell.textContent.trim().toUpperCase() : '';
          var priorityText = priorityCell ? priorityCell.textContent.trim().toUpperCase() : '';
          var statusMatch = !statusValue || statusText === statusValue;
          var priorityMatch = !priorityValue || priorityText === priorityValue;
          var dueText = dueCell ? dueCell.textContent.trim() : '';
          var dueDate = dueText && dueText !== '--' ? new Date(dueText) : null;
          var rangeMatch = true;
          if (startValue || endValue) {
            rangeMatch = dueDate !== null;
            if (rangeMatch && startValue) {
              rangeMatch = dueDate >= startValue;
            }
            if (rangeMatch && endValue) {
              rangeMatch = dueDate <= endValue;
            }
          }
          row.style.display = statusMatch && priorityMatch && rangeMatch ? '' : 'none';
        });
      }

      if (filterStatus) {
        filterStatus.addEventListener('change', applyFilters);
      }
      if (filterPriority) {
        filterPriority.addEventListener('change', applyFilters);
      }
      if (filterStartDate) {
        filterStartDate.addEventListener('change', applyFilters);
      }
      if (filterEndDate) {
        filterEndDate.addEventListener('change', applyFilters);
      }
    })();
  </script>
</body>
</html>
