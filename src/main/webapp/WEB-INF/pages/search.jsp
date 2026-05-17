<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.ems.model.User" %>
<%@ page import="com.ems.model.Employee" %>
<%@ page import="com.ems.model.Task" %>
<%@ page import="com.ems.model.AttendanceRow" %>
<%@ page import="java.util.List" %>
<%
  User user = (User) session.getAttribute("user");
  if (user == null) {
    response.sendRedirect(request.getContextPath() + "/login");
    return;
  }
  String query = (String) request.getAttribute("query");
  if (query == null) query = "";
  Boolean isAdminObj = (Boolean) request.getAttribute("isAdmin");
  boolean isAdmin = isAdminObj != null && isAdminObj;
  Integer totalObj = (Integer) request.getAttribute("totalResults");
  int total = totalObj == null ? 0 : totalObj;

  List<Employee>      employeeResults   = (List<Employee>)      request.getAttribute("employeeResults");
  List<Task>          taskResults       = (List<Task>)          request.getAttribute("taskResults");
  List<AttendanceRow> attendanceResults = (List<AttendanceRow>) request.getAttribute("attendanceResults");

  String csrfToken = (String) request.getAttribute("csrfToken");
  if (csrfToken == null) csrfToken = "";
  String initials = "U";
  if (user.getUsername() != null && !user.getUsername().isEmpty()) {
    initials = user.getUsername().substring(0, 1).toUpperCase();
  }
%>
<%!
  private String esc(String v) {
    if (v == null) return "";
    return v.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
  }
  // Escape, then wrap occurrences of `q` (case-insensitive) in <mark>. Safe because input is escaped first.
  private String highlight(String text, String q) {
    String safe = esc(text);
    if (q == null || q.trim().isEmpty() || safe.isEmpty()) return safe;
    String safeQ = esc(q.trim());
    if (safeQ.isEmpty()) return safe;
    String pattern = "(?i)" + java.util.regex.Pattern.quote(safeQ);
    return safe.replaceAll(pattern, "<mark class=\"hl\">$0</mark>");
  }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Search — EMS</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css?v=8">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/ems-ui.css?v=8">
  <script src="${pageContext.request.contextPath}/js/theme-init.js"></script>
  <style>
    .hl { background: var(--warn-dim); color: var(--t1); padding: 0 2px; border-radius: 3px; }
    :root[data-theme="dark"] .hl { color: #fde68a; }
    .search-hero { padding: var(--s5) 0 var(--s4); }
    .search-input-row { display: flex; gap: var(--s2); margin-top: var(--s3); }
    .search-input-row .input { flex: 1; height: 40px; font-size: var(--f-md); }
    .result-meta { font-size: var(--f-xs); color: var(--t3); margin-top: 2px; }
    .result-row {
      display: grid; grid-template-columns: 36px 1fr auto; gap: var(--s3);
      align-items: center; padding: var(--s3) var(--s5);
      border-bottom: 1px solid var(--bd);
    }
    .result-row:last-child { border-bottom: none; }
    .result-row:hover { background: var(--surface-2); }
    .result-title { font-size: var(--f-md); font-weight: 600; color: var(--t1); line-height: 1.3; }
    .result-link { color: inherit; text-decoration: none; display: contents; }
    .group-count { color: var(--t3); font-weight: 500; font-size: var(--f-sm); }
  </style>
</head>
<body>
<div class="app-layout">

  <aside class="sidebar">
    <div class="sb-hd">
      <a class="sb-brand" href="${pageContext.request.contextPath}/<%= isAdmin ? "dashboard" : "emp-dashboard" %>">
        <div class="sb-mark">E</div>
        <span class="sb-name">EMS</span>
      </a>
    </div>
    <nav class="sb-nav">
      <div class="nav-label">Main</div>
      <a class="nav-item" href="${pageContext.request.contextPath}/<%= isAdmin ? "dashboard" : "emp-dashboard" %>"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg></span><span class="nav-tx">Dashboard</span></a>
      <% if (isAdmin) { %>
      <a class="nav-item" href="${pageContext.request.contextPath}/employees"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg></span><span class="nav-tx">Employees</span></a>
      <% } %>
      <a class="nav-item" href="${pageContext.request.contextPath}/tasks"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg></span><span class="nav-tx">Tasks</span></a>
      <% if (isAdmin) { %>
      <a class="nav-item" href="${pageContext.request.contextPath}/attendance"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 2v4"/><path d="M16 2v4"/><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M3 10h18"/></svg></span><span class="nav-tx">Attendance</span></a>
      <a class="nav-item" href="${pageContext.request.contextPath}/analytics"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3v18h18"/><path d="M7 14l4-4 4 3 5-7"/></svg></span><span class="nav-tx">Analytics</span></a>
      <% } %>
    </nav>
    <div class="sb-ft">
      <form action="${pageContext.request.contextPath}/login" method="POST">
        <input type="hidden" name="action" value="logout">
        <input type="hidden" name="csrfToken" value="<%= esc(csrfToken) %>">
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
        <button class="sb-toggle" type="button" data-sb-toggle aria-label="Toggle sidebar"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg></button>
        <span class="tb-title">Search</span>
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

        <div class="page-intro search-hero">
          <div class="page-intro-eyebrow">Global search</div>
          <div class="page-intro-title">
            <% if (query.isEmpty()) { %>
              Search the workspace
            <% } else { %>
              Results for &ldquo;<%= esc(query) %>&rdquo;
              <span class="group-count">· <%= total %> match<%= total == 1 ? "" : "es" %></span>
            <% } %>
          </div>
          <div class="page-intro-sub">
            <% if (isAdmin) { %>
              Searches across employees, tasks and attendance.
            <% } else { %>
              Searches across your assigned tasks.
            <% } %>
          </div>
          <form action="${pageContext.request.contextPath}/search" method="GET" class="search-input-row">
            <input class="input" type="text" name="q" value="<%= esc(query) %>"
                   placeholder="Type a name, task title, status, or YYYY-MM-DD…" autofocus>
            <button type="submit" class="btn btn-primary">Search</button>
          </form>
        </div>

        <% if (query.isEmpty()) { %>
          <div class="card">
            <div class="empty-state">
              <div class="empty-state-icon">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
              </div>
              <div class="empty-state-title">Start typing above</div>
              <div class="empty-state-msg">
                Try an employee name, a task title, a status (PENDING / IN_PROGRESS / COMPLETED) or a work date in YYYY-MM-DD form.
              </div>
            </div>
          </div>
        <% } else if (total == 0) { %>
          <div class="card">
            <div class="empty-state">
              <div class="empty-state-icon">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
              </div>
              <div class="empty-state-title">No results for &ldquo;<%= esc(query) %>&rdquo;</div>
              <div class="empty-state-msg">Check the spelling, try a shorter query, or search by date (YYYY-MM-DD).</div>
            </div>
          </div>
        <% } else { %>

          <!-- ===== Employees ===== -->
          <% if (isAdmin && employeeResults != null && !employeeResults.isEmpty()) { %>
          <div class="card mb-24">
            <div class="card-hd">
              <div class="card-hd-left">
                <div class="card-title">Employees <span class="group-count">· <%= employeeResults.size() %></span></div>
                <div class="card-subtitle">Matched on name, email, department</div>
              </div>
            </div>
            <div>
              <% for (Employee e : employeeResults) {
                   String first = (e.getName() == null || e.getName().isEmpty()) ? "?" : e.getName().substring(0,1).toUpperCase();
              %>
              <a class="result-link" href="${pageContext.request.contextPath}/employees?q=<%= java.net.URLEncoder.encode(e.getName() == null ? "" : e.getName(), "UTF-8") %>">
                <div class="result-row">
                  <div class="av-sm"><%= esc(first) %></div>
                  <div>
                    <div class="result-title"><%= highlight(e.getName(), query) %></div>
                    <div class="result-meta">
                      <%= highlight(e.getEmail(), query) %>
                      <% if (e.getDepartment() != null && !e.getDepartment().isEmpty()) { %>
                        · <%= highlight(e.getDepartment(), query) %>
                      <% } %>
                    </div>
                  </div>
                  <span class="badge <%= "Active".equalsIgnoreCase(e.getStatus()) ? "badge-ok" : "badge-info" %>">
                    <%= esc(e.getStatus() == null ? "—" : e.getStatus()) %>
                  </span>
                </div>
              </a>
              <% } %>
            </div>
          </div>
          <% } %>

          <!-- ===== Tasks ===== -->
          <% if (taskResults != null && !taskResults.isEmpty()) { %>
          <div class="card mb-24">
            <div class="card-hd">
              <div class="card-hd-left">
                <div class="card-title">Tasks <span class="group-count">· <%= taskResults.size() %></span></div>
                <div class="card-subtitle">Matched on title, description, assignee</div>
              </div>
            </div>
            <div>
              <% for (Task t : taskResults) {
                   String s = t.getStatus() == null ? "" : t.getStatus().toUpperCase();
                   String chip = "COMPLETED".equals(s) ? "badge-ok"
                              : "IN_PROGRESS".equals(s) ? "badge-info"
                              : "badge-warn";
              %>
              <a class="result-link" href="${pageContext.request.contextPath}/tasks?q=<%= java.net.URLEncoder.encode(t.getTitle() == null ? "" : t.getTitle(), "UTF-8") %>">
                <div class="result-row">
                  <div class="av-sm" style="background: var(--p-dim); color: var(--p);">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>
                  </div>
                  <div>
                    <div class="result-title"><%= highlight(t.getTitle(), query) %></div>
                    <div class="result-meta">
                      <% if (t.getAssignedToName() != null) { %>
                        <%= highlight(t.getAssignedToName(), query) %>
                      <% } %>
                      <% if (t.getDueDate() != null) { %>
                        · due <%= esc(t.getDueDate().toString()) %>
                      <% } %>
                      <% if (t.getPriority() != null) { %>
                        · <%= esc(t.getPriority()) %>
                      <% } %>
                    </div>
                  </div>
                  <span class="badge <%= chip %>"><%= esc(s.isEmpty() ? "—" : s) %></span>
                </div>
              </a>
              <% } %>
            </div>
          </div>
          <% } %>

          <!-- ===== Attendance ===== -->
          <% if (isAdmin && attendanceResults != null && !attendanceResults.isEmpty()) { %>
          <div class="card mb-24">
            <div class="card-hd">
              <div class="card-hd-left">
                <div class="card-title">Attendance <span class="group-count">· <%= attendanceResults.size() %></span></div>
                <div class="card-subtitle">Matched on employee or work date</div>
              </div>
            </div>
            <div>
              <% for (AttendanceRow r : attendanceResults) {
                   String first = (r.getName() == null || r.getName().isEmpty()) ? "?" : r.getName().substring(0,1).toUpperCase();
                   String checkIn  = r.getCheckInTime()  == null ? "—" : r.getCheckInTime().toString();
                   String checkOut = r.getCheckOutTime() == null ? "—" : r.getCheckOutTime().toString();
                   String dateStr  = r.getWorkDate()     == null ? "—" : r.getWorkDate().toString();
                   String chip = "Active".equalsIgnoreCase(r.getAttendanceStatus()) ? "badge-ok" : "badge-info";
              %>
              <a class="result-link" href="${pageContext.request.contextPath}/attendance?employeeId=<%= r.getEmployeeId() %>">
                <div class="result-row">
                  <div class="av-sm"><%= esc(first) %></div>
                  <div>
                    <div class="result-title"><%= highlight(r.getName(), query) %></div>
                    <div class="result-meta">
                      <%= highlight(dateStr, query) %> · in <%= esc(checkIn) %> · out <%= esc(checkOut) %>
                    </div>
                  </div>
                  <span class="badge <%= chip %>"><%= esc(r.getAttendanceStatus() == null ? "—" : r.getAttendanceStatus()) %></span>
                </div>
              </a>
              <% } %>
            </div>
          </div>
          <% } %>

        <% } %>
      </div>
    </main>
  </div>
</div>

<script src="${pageContext.request.contextPath}/js/app.js"></script>
</body>
</html>
