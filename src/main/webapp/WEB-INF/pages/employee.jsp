<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
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
  if (formError != null) session.removeAttribute("formError");
  String searchQuery = (String) request.getAttribute("searchQuery");
  if (searchQuery == null) searchQuery = "";
  String startDate = (String) request.getAttribute("startDate");
  String endDate   = (String) request.getAttribute("endDate");
  if (startDate == null) startDate = "";
  if (endDate   == null) endDate   = "";
  String initials = "U";
  if (user.getUsername() != null && !user.getUsername().isEmpty())
    initials = user.getUsername().substring(0, 1).toUpperCase();
  Map<Integer, Integer> attendanceCounts = (Map<Integer, Integer>) request.getAttribute("attendanceCounts");
  int totalCount = list == null ? 0 : list.size();
%>
<%!
  private String esc(String v) {
    if (v == null) return "";
    return v.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
  }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Employees — EMS</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css?v=1">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/ems-ui.css?v=2">
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
      <a class="nav-item active" href="${pageContext.request.contextPath}/employees" data-label="Employees">
        <span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg></span>
        <span class="nav-tx">Employees</span>
      </a>
      <a class="nav-item" href="${pageContext.request.contextPath}/tasks" data-label="Tasks">
        <span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg></span>
        <span class="nav-tx">Tasks</span>
      </a>
      <a class="nav-item" href="${pageContext.request.contextPath}/attendance" data-label="Attendance">
        <span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 2v4"/><path d="M16 2v4"/><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M3 10h18"/></svg></span>
        <span class="nav-tx">Attendance</span>
      </a>
    </nav>
    <div class="sb-ft">
      <form action="${pageContext.request.contextPath}/login" method="POST">
        <input type="hidden" name="action" value="logout">
        <input type="hidden" name="csrfToken" value="<%= request.getAttribute("csrfToken") == null ? "" : request.getAttribute("csrfToken") %>">
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
        <span class="tb-title">Employees</span>
      </div>
      <div class="tb-right">
        <div class="tb-search">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
          <input type="text" id="empQuickFilter" placeholder="Quick filter...">
        </div>
        <button class="ic-btn" type="button" aria-label="Notifications">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
        </button>
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
        <button type="button" class="btn btn-primary btn-sm" data-modal-open="addEmpModal">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
          Add Employee
        </button>
      </div>
    </header>

    <main class="content">
      <div class="content-wrap">

        <% String successMessage = (String) session.getAttribute("successMessage");
           if (successMessage != null) session.removeAttribute("successMessage"); %>
        <% if (successMessage != null) { %>
          <div class="page-alert" data-toast="success"><%= esc(successMessage) %></div>
        <% } %>
        <% if (formError != null) { %>
          <div class="page-alert" data-toast="error"><%= esc(formError) %></div>
        <% } %>

        <div class="page-intro">
          <div class="page-intro-eyebrow">Directory</div>
          <div class="page-intro-title">Employee Records</div>
          <div class="page-intro-sub">Manage, search, and update your workforce — <strong><%= totalCount %></strong> employee<%= totalCount == 1 ? "" : "s" %> total.</div>
        </div>

        <div class="card">
          <div class="card-hd">
            <div class="card-hd-left">
              <div class="card-title">Employee Directory</div>
              <div class="card-subtitle">Click Edit to unlock inline row editing</div>
            </div>
            <form style="display:flex; gap:var(--s2); align-items:center; flex-wrap:wrap;" action="${pageContext.request.contextPath}/employees" method="GET">
              <input class="input input-sm" type="text"  name="q"         value="<%= esc(searchQuery) %>" placeholder="Name or email">
              <input class="input input-sm" type="date"  name="startDate" value="<%= esc(startDate) %>">
              <input class="input input-sm" type="date"  name="endDate"   value="<%= esc(endDate) %>">
              <button type="submit" class="btn btn-primary btn-sm">Search</button>
            </form>
          </div>
          <div class="dg-container scrollbar">
            <table class="table" id="employeeTable">
              <thead>
                <tr>
                  <th>Employee</th>
                  <th>Email</th>
                  <th>Phone</th>
                  <th>Department</th>
                  <th>Status</th>
                  <th>Attendance</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                <%
                  if (list == null || list.isEmpty()) {
                %>
                  <tr class="dg-empty"><td colspan="7">No employees found.</td></tr>
                <%
                  } else {
                    for (Employee emp : list) {
                      Integer count = attendanceCounts == null ? 0 : attendanceCounts.getOrDefault(emp.getId(), 0);
                      String empInitial = emp.getName() != null && !emp.getName().isEmpty() ? emp.getName().substring(0,1).toUpperCase() : "?";
                      int avIdx = Math.abs(emp.getName() != null ? emp.getName().hashCode() % 6 : 0);
                      String statusText = emp.getStatus() == null ? "Inactive" : emp.getStatus();
                      String statusCls  = "status-badge " + ("Active".equalsIgnoreCase(statusText) ? "status-active" : "status-inactive");
                %>
                  <tr>
                    <td>
                      <div class="person-cell">
                        <div class="row-av row-av-<%= avIdx %>"><%= empInitial %></div>
                        <div class="person-info">
                          <input class="input-inline person-name" type="text" name="name" value="<%= esc(emp.getName()) %>" required form="update-<%= emp.getId() %>" readonly data-emp="<%= emp.getId() %>">
                        </div>
                      </div>
                    </td>
                    <td><input class="input-inline" type="text" name="email"      value="<%= esc(emp.getEmail()) %>"      form="update-<%= emp.getId() %>" readonly data-emp="<%= emp.getId() %>"></td>
                    <td><input class="input-inline" type="text" name="phone"      value="<%= esc(emp.getPhone()) %>"      form="update-<%= emp.getId() %>" readonly data-emp="<%= emp.getId() %>"></td>
                    <td><input class="input-inline" type="text" name="department" value="<%= esc(emp.getDepartment()) %>" form="update-<%= emp.getId() %>" readonly data-emp="<%= emp.getId() %>"></td>
                    <td><span class="<%= statusCls %>"><%= esc(statusText) %></span></td>
                    <td><span class="badge badge-info"><%= count %> days</span></td>
                    <td>
                      <div class="row-actions action-row">
                        <button type="button" class="btn btn-secondary btn-xs btn-edit-emp" data-id="<%= emp.getId() %>">Edit</button>
                        <form id="update-<%= emp.getId() %>" action="${pageContext.request.contextPath}/employees" method="POST" style="display:inline;">
                          <input type="hidden" name="action" value="update">
                          <input type="hidden" name="id"     value="<%= emp.getId() %>">
                          <button type="submit" class="btn btn-primary btn-xs">Save</button>
                        </form>
                        <form action="${pageContext.request.contextPath}/employees" method="POST" style="display:inline;" onsubmit="return confirm('Delete this employee?');">
                          <input type="hidden" name="action" value="delete">
                          <input type="hidden" name="id"     value="<%= emp.getId() %>">
                          <button type="submit" class="btn btn-danger btn-xs">Delete</button>
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

      </div>
    </main>
  </div>
</div>

<!-- Add Employee Modal -->
<div class="modal-bd" id="addEmpModal">
  <div class="modal-box">
    <div class="modal-hd">
      <div class="modal-title">Add New Employee</div>
      <button type="button" class="modal-close" data-modal-close aria-label="Close">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
      </button>
    </div>
    <div class="modal-content">
      <form id="addEmpForm" action="${pageContext.request.contextPath}/employees" method="POST">
        <input type="hidden" name="action" value="add">
        <div class="form-grid">
          <div class="field">
            <label class="field-label" for="modal-username">Username</label>
            <input class="input" type="text"     id="modal-username"   name="username"   required placeholder="e.g. john.doe">
          </div>
          <div class="field">
            <label class="field-label" for="modal-password">Password</label>
            <input class="input" type="password" id="modal-password"   name="password"   required placeholder="Min. 8 characters">
          </div>
          <div class="field">
            <label class="field-label" for="modal-name">Full Name</label>
            <input class="input" type="text"     id="modal-name"       name="name"       required placeholder="e.g. John Doe">
          </div>
          <div class="field">
            <label class="field-label" for="modal-email">Email</label>
            <input class="input" type="text"     id="modal-email"      name="email"      required placeholder="e.g. john@company.com">
          </div>
          <div class="field">
            <label class="field-label" for="modal-phone">Phone</label>
            <input class="input" type="text"     id="modal-phone"      name="phone"      placeholder="e.g. +1 555 0100">
          </div>
          <div class="field">
            <label class="field-label" for="modal-department">Department</label>
            <input class="input" type="text"     id="modal-department" name="department" placeholder="e.g. Engineering">
          </div>
        </div>
      </form>
    </div>
    <div class="modal-ft">
      <button type="button" class="btn btn-secondary" data-modal-close>Cancel</button>
      <button type="submit" form="addEmpForm" class="btn btn-primary">Add Employee</button>
    </div>
  </div>
</div>

<script src="${pageContext.request.contextPath}/js/app.js"></script>
<script>
  (function () {
    var qf = document.getElementById('empQuickFilter');
    var tb = document.getElementById('employeeTable');
    if (qf && tb) {
      qf.addEventListener('input', function () {
        var q = qf.value.toLowerCase();
        Array.from(tb.querySelectorAll('tbody tr')).forEach(function (row) {
          row.style.display = row.textContent.toLowerCase().indexOf(q) > -1 ? '' : 'none';
        });
      });
    }
  })();
</script>
</body>
</html>
