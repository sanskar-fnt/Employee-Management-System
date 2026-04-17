<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="com.ems.model.Employee" %>
<%@ page import="com.ems.model.User" %>
<%@ page import="java.util.Map" %>
<%
  User user = (User) session.getAttribute("user");
  if (user == null) {
    response.sendRedirect(request.getContextPath() + "/login");
    return;
  }
  List<Employee> list = (List<Employee>) request.getAttribute("employeeList");
  String formError = (String) session.getAttribute("formError");
  if (formError != null) {
    session.removeAttribute("formError");
  }
  String searchQuery = (String) request.getAttribute("searchQuery");
  if (searchQuery == null) {
    searchQuery = "";
  }
  String startDate = (String) request.getAttribute("startDate");
  String endDate = (String) request.getAttribute("endDate");
  if (startDate == null) {
    startDate = "";
  }
  if (endDate == null) {
    endDate = "";
  }
  String initials = "U";
  if (user != null && user.getUsername() != null && !user.getUsername().isEmpty()) {
    initials = user.getUsername().substring(0, 1).toUpperCase();
  }
  Map<Integer, Integer> attendanceCounts = (Map<Integer, Integer>) request.getAttribute("attendanceCounts");
%>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>EMS Employees</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body class="page-employees">
  <div class="app-layout">
    <aside class="sidebar">
      <div class="sidebar-brand">EMS</div>
      <nav class="sidebar-nav">
        <a href="${pageContext.request.contextPath}/dashboard"><span class="nav-icon">🏠</span>Dashboard</a>
        <a class="active" href="${pageContext.request.contextPath}/employees"><span class="nav-icon">👥</span>Employees</a>
        <a href="${pageContext.request.contextPath}/tasks"><span class="nav-icon">🗂</span>Tasks</a>
      </nav>
      <form class="sidebar-logout" action="${pageContext.request.contextPath}/login" method="POST">
        <input type="hidden" name="action" value="logout">
        <button type="submit" class="btn btn-danger btn-block">Logout</button>
      </form>
    </aside>

    <div class="main">
      <header class="topbar">
        <div class="topbar-title">Employees</div>
        <div class="topbar-right">
          <div class="topbar-search">
            <span>🔍</span>
            <input type="text" id="employeeSearch" placeholder="Search employees...">
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
          <button type="button" class="btn btn-primary btn-sm" data-open-modal>Add Employee</button>
        </div>
      </header>

      <main class="content">
        <div class="container">
      <%
        String successMessage = (String) session.getAttribute("successMessage");
        if (successMessage != null) {
          session.removeAttribute("successMessage");
        }
      %>
      <% if (successMessage != null) { %>
        <div class="alert alert-success"><%= successMessage %></div>
      <% } %>
      <% if (formError != null) { %>
        <div class="alert alert-error"><%= formError %></div>
      <% } %>

      <div class="card">
        <div class="card-header">
          <div class="card-title">Add New Employee</div>
          <button type="button" class="btn btn-primary btn-sm" data-open-modal>Add Employee</button>
        </div>
        <p class="text-muted">Use the button to open the employee form.</p>
      </div>

      <div class="card">
        <div class="card-header">
          <div class="card-title">Employee Directory</div>
          <form class="search-bar" action="${pageContext.request.contextPath}/employees" method="GET">
            <input class="input search-input" type="text" name="q" value="<%= searchQuery %>" placeholder="Search by name or email">
            <input class="input" type="date" name="startDate" value="<%= startDate %>">
            <input class="input" type="date" name="endDate" value="<%= endDate %>">
            <button type="submit" class="btn btn-primary">Search</button>
          </form>
        </div>

        <div class="table-wrapper custom-scrollbar">
          <table class="table" id="employeeTable">
            <thead>
              <tr>
                <th>ID</th>
                <th>Name</th>
                <th>Email</th>
                <th>Phone</th>
                <th>Department</th>
                <th>Status</th>
                <th>Attendance Count</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
            <%
              if (list == null || list.isEmpty()) {
            %>
              <tr>
                <td colspan="8">No employees found.</td>
              </tr>
            <%
              } else {
                for (Employee emp : list) {
                  Integer count = attendanceCounts == null ? 0 : attendanceCounts.getOrDefault(emp.getId(), 0);
            %>
              <tr>
                <td><%= emp.getId() %></td>
                <td>
                  <input class="input input-sm row-input" type="text" name="name" value="<%= emp.getName() %>" required form="update-<%= emp.getId() %>" readonly data-emp="<%= emp.getId() %>">
                </td>
                <td>
                  <input class="input input-sm row-input" type="text" name="email" value="<%= emp.getEmail() %>" required form="update-<%= emp.getId() %>" readonly data-emp="<%= emp.getId() %>">
                </td>
                <td>
                  <input class="input input-sm row-input" type="text" name="phone" value="<%= emp.getPhone() %>" form="update-<%= emp.getId() %>" readonly data-emp="<%= emp.getId() %>">
                </td>
                <td>
                  <input class="input input-sm row-input" type="text" name="department" value="<%= emp.getDepartment() %>" form="update-<%= emp.getId() %>" readonly data-emp="<%= emp.getId() %>">
                </td>
                <td>
                  <%
                    String statusText = emp.getStatus() == null ? "Inactive" : emp.getStatus();
                    String statusClass = "Active".equalsIgnoreCase(statusText) ? "status-badge status-active" : "status-badge status-inactive";
                  %>
                  <span class="<%= statusClass %>"><%= statusText %></span>
                </td>
                <td><%= count %></td>
                <td>
                  <div class="action-buttons">
                    <button type="button" class="btn btn-info btn-sm btn-edit" data-id="<%= emp.getId() %>">Edit</button>
                    <form id="update-<%= emp.getId() %>" action="${pageContext.request.contextPath}/employees" method="POST">
                      <input type="hidden" name="action" value="update">
                      <input type="hidden" name="id" value="<%= emp.getId() %>">
                      <button type="submit" class="btn btn-success btn-sm">Update</button>
                    </form>
                    <form action="${pageContext.request.contextPath}/employees" method="POST" onsubmit="return confirm('Delete this employee?');">
                      <input type="hidden" name="action" value="delete">
                      <input type="hidden" name="id" value="<%= emp.getId() %>">
                      <button type="submit" class="btn btn-danger btn-sm">Delete</button>
                    </form>
                  </div>
                </td>
              </tr>
            <%
                }
              }
            %>
            </tbody>
          </table>
        </div>
      </div>
        <div class="modal-overlay" data-modal>
          <div class="modal-card">
            <div class="card-header">
              <div class="card-title">Add New Employee</div>
              <button type="button" class="btn btn-secondary btn-sm" data-close-modal>Close</button>
            </div>
            <form action="${pageContext.request.contextPath}/employees" method="POST">
              <input type="hidden" name="action" value="add">
              <div class="form-grid">
                <div class="form-group">
                  <label for="modal-username">Username</label>
                  <input class="input" type="text" id="modal-username" name="username" required>
                </div>
                <div class="form-group">
                  <label for="modal-password">Password</label>
                  <input class="input" type="password" id="modal-password" name="password" required>
                </div>
                <div class="form-group">
                  <label for="modal-name">Name</label>
                  <input class="input" type="text" id="modal-name" name="name" required>
                </div>
                <div class="form-group">
                  <label for="modal-email">Email</label>
                  <input class="input" type="text" id="modal-email" name="email" required>
                </div>
                <div class="form-group">
                  <label for="modal-phone">Phone</label>
                  <input class="input" type="text" id="modal-phone" name="phone">
                </div>
                <div class="form-group">
                  <label for="modal-department">Department</label>
                  <input class="input" type="text" id="modal-department" name="department">
                </div>
              </div>
              <div class="form-actions">
                <button type="submit" class="btn btn-primary">Add Employee</button>
              </div>
            </form>
          </div>
        </div>
        </div>
      </main>
    </div>
  </div>

  <script>
    var topbar = document.querySelector('.topbar');
    var dropdownToggle = document.querySelector('[data-dropdown-toggle]');
    var dropdownMenu = document.querySelector('[data-dropdown-menu]');
    var modal = document.querySelector('[data-modal]');
    var openButtons = document.querySelectorAll('[data-open-modal]');
    var closeButton = document.querySelector('[data-close-modal]');

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

    openButtons.forEach(function (button) {
      button.addEventListener('click', function () {
        if (modal) {
          modal.classList.add('active');
        }
      });
    });

    if (closeButton) {
      closeButton.addEventListener('click', function () {
        modal.classList.remove('active');
      });
    }

    if (modal) {
      modal.addEventListener('click', function (event) {
        if (event.target === modal) {
          modal.classList.remove('active');
        }
      });
    }

    var searchInput = document.getElementById('employeeSearch');
    var table = document.getElementById('employeeTable');
    if (searchInput && table) {
      searchInput.addEventListener('input', function () {
        var query = searchInput.value.toLowerCase();
        Array.from(table.querySelectorAll('tbody tr')).forEach(function (row) {
          var text = row.textContent.toLowerCase();
          row.style.display = text.indexOf(query) > -1 ? '' : 'none';
        });
      });
    }

    document.querySelectorAll('.btn-edit').forEach(function (button) {
      button.addEventListener('click', function () {
        var id = button.getAttribute('data-id');
        var fields = document.querySelectorAll('[data-emp="' + id + '"]');
        var isReadOnly = fields.length > 0 && fields[0].hasAttribute('readonly');
        fields.forEach(function (field) {
          if (isReadOnly) {
            field.removeAttribute('readonly');
            field.classList.add('input-editable');
          } else {
            field.setAttribute('readonly', 'readonly');
            field.classList.remove('input-editable');
          }
        });
        button.textContent = isReadOnly ? 'Cancel' : 'Edit';
      });
    });

  </script>
</body>
</html>
