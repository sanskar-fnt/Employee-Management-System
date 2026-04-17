<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="com.ems.model.Employee" %>
<%@ page import="com.ems.model.User" %>
<%@ page import="com.ems.model.AttendanceSnapshot" %>
<%
  User user = (User) session.getAttribute("user");
  if (user == null) {
    response.sendRedirect(request.getContextPath() + "/login");
    return;
  }
  Employee employee = (Employee) request.getAttribute("employee");
  AttendanceSnapshot snapshot = (AttendanceSnapshot) request.getAttribute("snapshot");
  Boolean canCheckIn = (Boolean) request.getAttribute("canCheckIn");
  Boolean canCheckOut = (Boolean) request.getAttribute("canCheckOut");
  String todayStatus = (String) request.getAttribute("todayStatus");
  if (todayStatus == null) {
    todayStatus = "Not Marked";
  }
  String sessionRange = "--";
  if (snapshot != null && snapshot.getCheckInTime() != null) {
    String start = snapshot.getCheckInTime().toString();
    String end = snapshot.getCheckOutTime() == null ? "--" : snapshot.getCheckOutTime().toString();
    sessionRange = start + " → " + end;
  }
  String initials = "U";
  if (user != null && user.getUsername() != null && !user.getUsername().isEmpty()) {
    initials = user.getUsername().substring(0, 1).toUpperCase();
  }
  Integer attendanceCountObj = (Integer) request.getAttribute("attendanceCount");
  int attendanceCount = attendanceCountObj == null ? 0 : attendanceCountObj;
%>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>My Dashboard</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body class="page-user-dashboard">
  <div class="app-layout">
    <aside class="sidebar">
      <div class="sidebar-brand">EMS</div>
      <nav class="sidebar-nav">
        <a class="active" href="${pageContext.request.contextPath}/user-dashboard"><span class="nav-icon">🏠</span>Dashboard</a>
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
        <div class="topbar-title">My Dashboard</div>
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
      <%
        String attendanceMessage = (String) request.getAttribute("attendanceMessage");
        String attendanceError = (String) request.getAttribute("attendanceError");
        if (attendanceMessage != null) {
      %>
        <div class="alert alert-info"><%= attendanceMessage %></div>
      <%
        }
        if (attendanceError != null) {
      %>
        <div class="alert alert-error"><%= attendanceError %></div>
      <%
        }
      %>

      <div class="card">
        <div class="card-header">
          <div class="card-title">My Profile</div>
        </div>
        <%
          if (employee == null) {
        %>
          <div class="alert alert-info">Your profile is not linked to an employee record.</div>
        <%
          } else {
        %>
          <p><strong>Name:</strong> <%= employee.getName() %></p>
          <p><strong>Email:</strong> <%= employee.getEmail() %></p>
          <p><strong>Phone:</strong> <%= employee.getPhone() %></p>
          <p><strong>Department:</strong> <%= employee.getDepartment() %></p>
          <p><strong>Status:</strong> <%= employee.getStatus() %></p>
        <%
          }
        %>
      </div>

      <div class="card">
        <div class="card-header">
          <div class="card-title">Mark Attendance</div>
        </div>
        <div class="info-grid">
          <div class="info-item">
            <div class="info-label">Status</div>
            <div class="info-value"><%= todayStatus %></div>
          </div>
          <div class="info-item">
            <div class="info-label">Check-in</div>
            <div class="info-value"><%= snapshot != null && snapshot.getCheckInTime() != null ? snapshot.getCheckInTime() : "--" %></div>
          </div>
          <div class="info-item">
            <div class="info-label">Check-out</div>
            <div class="info-value"><%= snapshot != null && snapshot.getCheckOutTime() != null ? snapshot.getCheckOutTime() : "--" %></div>
          </div>
          <div class="info-item">
            <div class="info-label">Total Logs</div>
            <div class="info-value"><%= attendanceCount %></div>
          </div>
        </div>
        <div class="action-buttons" style="margin-top: 16px;">
          <form action="${pageContext.request.contextPath}/attendance" method="POST">
            <input type="hidden" name="action" value="checkin">
            <button type="submit" class="btn btn-success btn-glow-success" <%= (canCheckIn != null && canCheckIn) ? "" : "disabled" %>>Mark Present (Check-in)</button>
          </form>
          <form action="${pageContext.request.contextPath}/attendance" method="POST">
            <input type="hidden" name="action" value="checkout">
            <button type="submit" class="btn btn-info btn-glow-info" <%= (canCheckOut != null && canCheckOut) ? "" : "disabled" %>>Mark Exit (Check-out)</button>
          </form>
        </div>
        <div class="timeline" style="margin-top: 16px;">
          <div class="timeline-item">
            <span class="timeline-dot"></span>
            <span><%= sessionRange %></span>
          </div>
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
