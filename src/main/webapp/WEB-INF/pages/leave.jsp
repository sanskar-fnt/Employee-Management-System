<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.ems.model.User" %>
<%@ page import="com.ems.model.LeaveRequest" %>
<%@ page import="java.util.List" %>
<%
  User user = (User) session.getAttribute("user");
  if (user == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

  Boolean isAdminObj = (Boolean) request.getAttribute("isAdmin");
  boolean isAdmin = isAdminObj != null && isAdminObj;
  List<LeaveRequest> rows = (List<LeaveRequest>) request.getAttribute("rows");
  String csrfToken = (String) request.getAttribute("csrfToken"); if (csrfToken == null) csrfToken = "";
  String leaveSuccess = (String) request.getAttribute("leaveSuccess");
  String leaveError   = (String) request.getAttribute("leaveError");
  String statusFilter = (String) request.getAttribute("statusFilter"); if (statusFilter == null) statusFilter = "";
  Integer pendingCnt  = (Integer) request.getAttribute("pendingCount");
  int pendingCount = pendingCnt == null ? 0 : pendingCnt;
  Integer pageObj  = (Integer) request.getAttribute("pageNum");     int pageNum    = pageObj  == null ? 1 : pageObj;
  Integer pagesObj = (Integer) request.getAttribute("totalPages");  int totalPages = pagesObj == null ? 1 : pagesObj;
  Integer totalObj = (Integer) request.getAttribute("totalCount");  int totalCount = totalObj == null ? (rows == null ? 0 : rows.size()) : totalObj;

  String initials = "U";
  if (user.getUsername() != null && !user.getUsername().isEmpty()) initials = user.getUsername().substring(0,1).toUpperCase();
%>
<%!
  private String esc(String v) {
    if (v == null) return "";
    return v.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
  }
  private String chip(String s) {
    if (s == null) return "badge-info";
    if ("APPROVED".equals(s)) return "badge-ok";
    if ("REJECTED".equals(s)) return "badge-err";
    return "badge-warn";
  }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Leaves — EMS</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css?v=8">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/ems-ui.css?v=8">
  <script src="${pageContext.request.contextPath}/js/theme-init.js"></script>
</head>
<body>
<div class="app-layout">

  <aside class="sidebar">
    <div class="sb-hd">
      <a class="sb-brand" href="${pageContext.request.contextPath}/<%= isAdmin ? "dashboard" : "emp-dashboard" %>">
        <div class="sb-mark">E</div><span class="sb-name">EMS</span>
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
        <a class="nav-item" href="${pageContext.request.contextPath}/audit"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="9" y1="13" x2="15" y2="13"/><line x1="9" y1="17" x2="15" y2="17"/></svg></span><span class="nav-tx">Audit Logs</span></a>
      <% } %>
      <a class="nav-item active" href="${pageContext.request.contextPath}/leaves"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/><polyline points="9 16 11 18 15 14"/></svg></span><span class="nav-tx">Leaves</span></a>
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
        <span class="tb-title">Leaves</span>
      </div>
      <div class="tb-right">
        <% if (isAdmin) { %>
          <button class="ic-btn" type="button" aria-label="Notifications">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
          </button>
        <% } %>
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

        <% if (leaveSuccess != null) { %><div class="page-alert" data-toast="success"><%= esc(leaveSuccess) %></div><% } %>
        <% if (leaveError   != null) { %><div class="page-alert" data-toast="error"><%= esc(leaveError) %></div><% } %>

        <div class="page-intro" style="display:flex; align-items:flex-end; justify-content:space-between; gap:var(--s4); flex-wrap:wrap;">
          <div>
            <div class="page-intro-eyebrow">Time off</div>
            <div class="page-intro-title">
              <%= isAdmin ? "Leave requests" : "My leave requests" %>
              <% if (isAdmin && pendingCount > 0) { %>
                <span class="badge badge-warn" style="margin-left:var(--s2);"><%= pendingCount %> pending</span>
              <% } %>
            </div>
            <div class="page-intro-sub">
              <% if (isAdmin) { %>
                Approve or reject employee leave requests. Approved leaves are excluded from absence and performance penalties.
              <% } else { %>
                Apply for casual, sick, earned or unpaid leave. Approved leaves are not counted as absent.
              <% } %>
            </div>
          </div>
        </div>

        <% if (!isAdmin) { %>
          <!-- Employee: apply form -->
          <div class="card mb-24">
            <div class="card-hd">
              <div class="card-hd-left">
                <div class="card-title">Apply for leave</div>
                <div class="card-subtitle">Pick the dates and add a short reason.</div>
              </div>
            </div>
            <form action="${pageContext.request.contextPath}/leaves" method="POST" class="form-grid" style="padding: var(--s4) var(--s5); grid-template-columns: 1fr 1fr 1fr; gap: var(--s4);">
              <input type="hidden" name="action" value="apply">
              <input type="hidden" name="csrfToken" value="<%= esc(csrfToken) %>">
              <div class="field">
                <label class="field-label" for="leaveType">Type</label>
                <select class="input" id="leaveType" name="leaveType">
                  <option value="CASUAL">Casual</option>
                  <option value="SICK">Sick</option>
                  <option value="EARNED">Earned</option>
                  <option value="UNPAID">Unpaid</option>
                </select>
              </div>
              <div class="field">
                <label class="field-label" for="startDate">Start date</label>
                <input class="input" type="date" id="startDate" name="startDate" required>
              </div>
              <div class="field">
                <label class="field-label" for="endDate">End date</label>
                <input class="input" type="date" id="endDate" name="endDate" required>
              </div>
              <div class="field" style="grid-column: 1 / -1;">
                <label class="field-label" for="reason">Reason</label>
                <input class="input" type="text" id="reason" name="reason" placeholder="e.g. Family event" maxlength="500" required>
              </div>
              <div style="grid-column: 1 / -1; display:flex; justify-content:flex-end;">
                <button type="submit" class="btn btn-primary">Submit request</button>
              </div>
            </form>
          </div>
        <% } else { %>
          <!-- Admin: status filter -->
          <div class="card mb-24">
            <div class="card-hd">
              <div class="card-hd-left">
                <div class="card-title">Filter</div>
                <div class="card-subtitle"><%= totalCount %> request<%= totalCount == 1 ? "" : "s" %> in view</div>
              </div>
            </div>
            <form action="${pageContext.request.contextPath}/leaves" method="GET" style="display:flex; gap:var(--s2); align-items:center; padding: var(--s4) var(--s5); flex-wrap:wrap;">
              <span class="field-label" style="margin:0;">Status:</span>
              <a class="btn btn-sm <%= statusFilter.isEmpty()             ? "btn-primary" : "btn-secondary" %>" href="${pageContext.request.contextPath}/leaves">All</a>
              <a class="btn btn-sm <%= "PENDING".equals(statusFilter)     ? "btn-primary" : "btn-secondary" %>" href="${pageContext.request.contextPath}/leaves?status=PENDING">Pending</a>
              <a class="btn btn-sm <%= "APPROVED".equals(statusFilter)    ? "btn-primary" : "btn-secondary" %>" href="${pageContext.request.contextPath}/leaves?status=APPROVED">Approved</a>
              <a class="btn btn-sm <%= "REJECTED".equals(statusFilter)    ? "btn-primary" : "btn-secondary" %>" href="${pageContext.request.contextPath}/leaves?status=REJECTED">Rejected</a>
            </form>
          </div>
        <% } %>

        <!-- Requests table -->
        <div class="card">
          <div class="card-hd">
            <div class="card-hd-left">
              <div class="card-title"><%= isAdmin ? "All requests" : "Your requests" %></div>
              <% if (isAdmin) { %>
                <div class="card-subtitle">Page <%= pageNum %> of <%= totalPages %></div>
              <% } %>
            </div>
          </div>
          <div class="dg-container scrollbar">
            <table class="table">
              <thead>
                <tr>
                  <% if (isAdmin) { %><th>Employee</th><% } %>
                  <th>Type</th>
                  <th>From</th>
                  <th>To</th>
                  <th style="text-align:right;">Days</th>
                  <th>Reason</th>
                  <th>Status</th>
                  <% if (isAdmin) { %><th style="text-align:right;">Actions</th><% } %>
                </tr>
              </thead>
              <tbody>
                <% if (rows == null || rows.isEmpty()) { %>
                  <tr class="dg-empty"><td colspan="<%= isAdmin ? 8 : 6 %>">
                    <% if (isAdmin) { %>No leave requests yet.<% } else { %>You haven't submitted any leave requests.<% } %>
                  </td></tr>
                <% } else { for (LeaveRequest r : rows) { %>
                  <tr>
                    <% if (isAdmin) { %>
                      <td>
                        <div class="wl-emp-name" style="font-weight:600;"><%= esc(r.getEmployeeName() != null ? r.getEmployeeName() : r.getUsername()) %></div>
                        <div class="card-subtitle">@<%= esc(r.getUsername()) %></div>
                      </td>
                    <% } %>
                    <td><span class="badge badge-info"><%= esc(r.getLeaveType()) %></span></td>
                    <td><%= r.getStartDate() == null ? "—" : r.getStartDate().toString() %></td>
                    <td><%= r.getEndDate()   == null ? "—" : r.getEndDate().toString()   %></td>
                    <td style="text-align:right;"><span class="wl-num"><%= r.getDays() %></span></td>
                    <td><%= esc(r.getReason() == null ? "—" : r.getReason()) %></td>
                    <td><span class="badge <%= chip(r.getStatus()) %>"><%= esc(r.getStatus()) %></span></td>
                    <% if (isAdmin) { %>
                      <td style="text-align:right;">
                        <% if ("PENDING".equals(r.getStatus())) { %>
                          <form action="${pageContext.request.contextPath}/leaves" method="POST" style="display:inline;">
                            <input type="hidden" name="action"     value="approve">
                            <input type="hidden" name="id"         value="<%= r.getId() %>">
                            <input type="hidden" name="csrfToken"  value="<%= esc(csrfToken) %>">
                            <button type="submit" class="btn btn-success btn-xs">Approve</button>
                          </form>
                          <form action="${pageContext.request.contextPath}/leaves" method="POST" style="display:inline;">
                            <input type="hidden" name="action"     value="reject">
                            <input type="hidden" name="id"         value="<%= r.getId() %>">
                            <input type="hidden" name="csrfToken"  value="<%= esc(csrfToken) %>">
                            <button type="submit" class="btn btn-danger btn-xs">Reject</button>
                          </form>
                        <% } else { %>
                          <span class="card-subtitle">Decided <%= r.getDecidedAt() == null ? "" : r.getDecidedAt().toString() %></span>
                        <% } %>
                      </td>
                    <% } %>
                  </tr>
                <% } } %>
              </tbody>
            </table>
          </div>

          <% if (isAdmin && totalPages > 1) {
               String qs = statusFilter.isEmpty() ? "" : ("&status=" + statusFilter);
          %>
            <div style="display:flex; gap:var(--s2); padding: var(--s3) var(--s5); border-top: 1px solid var(--bd); justify-content:flex-end;">
              <% if (pageNum > 1) { %>
                <a class="btn btn-secondary btn-sm" href="${pageContext.request.contextPath}/leaves?page=<%= pageNum-1 %><%= qs %>">← Prev</a>
              <% } %>
              <span class="card-subtitle" style="align-self:center;">Page <%= pageNum %> / <%= totalPages %></span>
              <% if (pageNum < totalPages) { %>
                <a class="btn btn-secondary btn-sm" href="${pageContext.request.contextPath}/leaves?page=<%= pageNum+1 %><%= qs %>">Next →</a>
              <% } %>
            </div>
          <% } %>
        </div>

      </div>
    </main>
  </div>
</div>

<script src="${pageContext.request.contextPath}/js/app.js"></script>
</body>
</html>
