<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="com.ems.model.User" %>
<%@ page import="com.ems.model.AttendanceRow" %>
<%@ page import="java.util.List" %>
<%
  User user = (User) session.getAttribute("user");
  if (user == null) {
    response.sendRedirect(request.getContextPath() + "/login");
    return;
  }
  Integer totalEmployeesObj = (Integer) request.getAttribute("totalEmployees");
  Integer activeEmployeesObj = (Integer) request.getAttribute("activeEmployees");
  Integer inactiveEmployeesObj = (Integer) request.getAttribute("inactiveEmployees");
  Integer todayAttendanceObj = (Integer) request.getAttribute("todayAttendance");
  Integer totalAttendanceObj = (Integer) request.getAttribute("totalAttendance");
  List<AttendanceRow> attendanceRows = (List<AttendanceRow>) request.getAttribute("attendanceRows");
  List<AttendanceRow> recentAttendanceRows = (List<AttendanceRow>) request.getAttribute("recentAttendanceRows");
  int totalEmployees = totalEmployeesObj == null ? 0 : totalEmployeesObj;
  int activeEmployees = activeEmployeesObj == null ? 0 : activeEmployeesObj;
  int inactiveEmployees = inactiveEmployeesObj == null ? 0 : inactiveEmployeesObj;
  int todayAttendance = todayAttendanceObj == null ? 0 : todayAttendanceObj;
  int totalAttendance = totalAttendanceObj == null ? 0 : totalAttendanceObj;
  String initials = "U";
  if (user != null && user.getUsername() != null && !user.getUsername().isEmpty()) {
    initials = user.getUsername().substring(0, 1).toUpperCase();
  }
  String startDate = (String) request.getAttribute("startDate");
  String endDate = (String) request.getAttribute("endDate");
  if (startDate == null) {
    startDate = "";
  }
  if (endDate == null) {
    endDate = "";
  }
%>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>EMS Dashboard</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body class="page-dashboard">
  <div class="app-layout">
    <aside class="sidebar">
      <div class="sidebar-brand">EMS</div>
      <nav class="sidebar-nav">
        <a class="active" href="${pageContext.request.contextPath}/dashboard"><span class="nav-icon">🏠</span>Dashboard</a>
        <a href="${pageContext.request.contextPath}/employees"><span class="nav-icon">👥</span>Employees</a>
        <a href="${pageContext.request.contextPath}/tasks"><span class="nav-icon">🗂</span>Tasks</a>
      </nav>
      <form class="sidebar-logout" action="${pageContext.request.contextPath}/login" method="POST">
        <input type="hidden" name="action" value="logout">
        <button type="submit" class="btn btn-danger btn-block">Logout</button>
      </form>
    </aside>

    <div class="main">
      <header class="topbar">
        <div class="topbar-title">Dashboard</div>
        <div class="topbar-right">
          <div class="topbar-search">
            <span>🔍</span>
            <input type="text" placeholder="Search...">
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
          <div class="card">
            <div class="card-title">Welcome back, <%= user.getUsername() %></div>
            <p class="text-muted">Here is a quick overview of your team and attendance today.</p>
          </div>

          <div class="stats-grid">
            <div class="stat-card">
              <div class="stat-icon">👥</div>
              <div class="stat-label">Total Employees</div>
              <div class="stat-value"><%= totalEmployees %></div>
            </div>
            <div class="stat-card">
              <div class="stat-icon">✅</div>
              <div class="stat-label">Attendance Today</div>
              <div class="stat-value"><%= todayAttendance %></div>
            </div>
            <div class="stat-card">
              <div class="stat-icon">⚡</div>
              <div class="stat-label">Active Users</div>
              <div class="stat-value"><%= activeEmployees %></div>
            </div>
          </div>

          <div class="card">
            <div class="card-header">
              <div class="card-title">Recent Activity</div>
            </div>
            <div class="activity-list">
              <div class="activity-item">
                <div>
                  New employee added
                  <div class="activity-meta">A few moments ago</div>
                </div>
                <span class="status-badge status-present">Info</span>
              </div>
              <div class="activity-item">
                <div>
                  Attendance marked for today
                  <div class="activity-meta">Today</div>
                </div>
                <span class="status-badge status-active">Active</span>
              </div>
              <div class="activity-item">
                <div>
                  Profile updated
                  <div class="activity-meta">Yesterday</div>
                </div>
                <span class="status-badge status-inactive">Update</span>
              </div>
            </div>
          </div>

          <div class="card">
            <div class="card-header">
              <div class="card-title">Attendance Logs</div>
              <form class="filter-bar" action="${pageContext.request.contextPath}/dashboard" method="GET">
                <input class="input" type="date" name="startDate" value="<%= startDate %>">
                <input class="input" type="date" name="endDate" value="<%= endDate %>">
                <button type="submit" class="btn btn-primary btn-sm">Apply</button>
              </form>
            </div>
          </div>

          <div class="card">
            <div class="card-header">
              <div class="card-title">Today's Attendance</div>
            </div>
            <div class="table-container">
              <table class="table">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Name</th>
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
                  <tr>
                    <td colspan="7">No attendance data available.</td>
                  </tr>
                <%
                  } else {
                    for (AttendanceRow row : attendanceRows) {
                      String statusClass = "status-badge "+ ("Active".equalsIgnoreCase(row.getAttendanceStatus()) ? "status-active" : "status-inactive");
                %>
                  <tr>
                    <td><%= row.getEmployeeId() %></td>
                    <td><%= row.getName() %></td>
                    <td><%= row.getEmail() %></td>
                    <td><%= row.getDepartment() %></td>
                    <td>
                      <span class="<%= statusClass %>"><%= row.getAttendanceStatus() %></span>
                    </td>
                    <td><%= row.getCheckInTime() == null ? "--" : row.getCheckInTime() %></td>
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

          <div class="card">
            <div class="card-header">
              <div class="card-title">Recent Attendance Logs</div>
            </div>
            <div class="table-container">
              <table class="table">
                <thead>
                  <tr>
                    <th>Date</th>
                    <th>ID</th>
                    <th>Name</th>
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
                  <tr>
                    <td colspan="7">No recent attendance logs.</td>
                  </tr>
                <%
                  } else {
                    for (AttendanceRow row : recentAttendanceRows) {
                      String recentStatusClass = "status-badge "+ ("Active".equalsIgnoreCase(row.getAttendanceStatus()) ? "status-active" : "status-inactive");
                %>
                  <tr>
                    <td><%= row.getWorkDate() == null ? "--" : row.getWorkDate() %></td>
                    <td><%= row.getEmployeeId() %></td>
                    <td><%= row.getName() %></td>
                    <td><%= row.getDepartment() %></td>
                    <td>
                      <span class="<%= recentStatusClass %>"><%= row.getAttendanceStatus() %></span>
                    </td>
                    <td><%= row.getCheckInTime() == null ? "--" : row.getCheckInTime() %></td>
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
    })();
  </script>
</body>
</html>
