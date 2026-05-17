<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.ems.model.User" %>
<%@ page import="com.ems.model.AuditLog" %>
<%@ page import="java.util.List" %>
<%
  User user = (User) session.getAttribute("user");
  if (user == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

  List<AuditLog> rows           = (List<AuditLog>) request.getAttribute("rows");
  List<String>   distinctActions = (List<String>) request.getAttribute("distinctActions");
  String filterAction  = (String)  request.getAttribute("filterAction");   if (filterAction  == null) filterAction  = "";
  String filterActorId = (String)  request.getAttribute("filterActorId");  if (filterActorId == null) filterActorId = "";
  String filterFrom    = (String)  request.getAttribute("filterFrom");     if (filterFrom    == null) filterFrom    = "";
  String filterTo      = (String)  request.getAttribute("filterTo");       if (filterTo      == null) filterTo      = "";
  Integer pageObj      = (Integer) request.getAttribute("page");           int pageNum  = pageObj == null ? 1 : pageObj;
  Integer sizeObj      = (Integer) request.getAttribute("size");           int size  = sizeObj == null ? 25 : sizeObj;
  Integer totalObj     = (Integer) request.getAttribute("total");          int total = totalObj == null ? 0 : totalObj;
  Integer pagesObj     = (Integer) request.getAttribute("totalPages");     int totalPages = pagesObj == null ? 1 : pagesObj;

  String csrfToken = (String) request.getAttribute("csrfToken"); if (csrfToken == null) csrfToken = "";
  String initials  = "U";
  if (user.getUsername() != null && !user.getUsername().isEmpty()) initials = user.getUsername().substring(0,1).toUpperCase();
%>
<%!
  private String esc(String v) {
    if (v == null) return "";
    return v.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
  }
  private String chipForAction(String action) {
    if (action == null) return "badge-info";
    if (action.startsWith("LOGIN") || action.equals("LOGOUT")) return "badge-info";
    if (action.endsWith("DELETE") || action.equals("LOGIN_FAILED")) return "badge-err";
    if (action.equals("PASSWORD_CHANGE")) return "badge-warn";
    if (action.startsWith("CHECK_")) return "badge-ok";
    return "badge-info";
  }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Audit Logs — EMS</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css?v=8">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/ems-ui.css?v=8">
  <script src="${pageContext.request.contextPath}/js/theme-init.js"></script>
</head>
<body>
<div class="app-layout">

  <aside class="sidebar">
    <div class="sb-hd">
      <a class="sb-brand" href="${pageContext.request.contextPath}/dashboard"><div class="sb-mark">E</div><span class="sb-name">EMS</span></a>
    </div>
    <nav class="sb-nav">
      <div class="nav-label">Main</div>
      <a class="nav-item" href="${pageContext.request.contextPath}/dashboard"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg></span><span class="nav-tx">Dashboard</span></a>
      <a class="nav-item" href="${pageContext.request.contextPath}/employees"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg></span><span class="nav-tx">Employees</span></a>
      <a class="nav-item" href="${pageContext.request.contextPath}/tasks"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg></span><span class="nav-tx">Tasks</span></a>
      <a class="nav-item" href="${pageContext.request.contextPath}/attendance"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 2v4"/><path d="M16 2v4"/><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M3 10h18"/></svg></span><span class="nav-tx">Attendance</span></a>
      <a class="nav-item" href="${pageContext.request.contextPath}/analytics"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 3v18h18"/><path d="M7 14l4-4 4 3 5-7"/></svg></span><span class="nav-tx">Analytics</span></a>
      <a class="nav-item active" href="${pageContext.request.contextPath}/audit"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="9" y1="13" x2="15" y2="13"/><line x1="9" y1="17" x2="15" y2="17"/></svg></span><span class="nav-tx">Audit Logs</span></a>
      <a class="nav-item" href="${pageContext.request.contextPath}/leaves" data-label="Leaves"><span class="nav-ic"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/><polyline points="9 16 11 18 15 14"/></svg></span><span class="nav-tx">Leaves</span></a>
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
        <span class="tb-title">Audit Logs</span>
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

        <div class="page-intro" style="display:flex; align-items:flex-end; justify-content:space-between; gap:var(--s4); flex-wrap:wrap;">
          <div>
            <div class="page-intro-eyebrow">Compliance</div>
            <div class="page-intro-title">Audit Logs <span class="card-subtitle" style="font-weight:500; margin-left:var(--s2);"><%= total %> event<%= total == 1 ? "" : "s" %></span></div>
            <div class="page-intro-sub">Append-only history of significant actions across the system.</div>
          </div>
        </div>

        <div class="card mb-24">
          <div class="card-hd">
            <div class="card-hd-left">
              <div class="card-title">Filters</div>
            </div>
          </div>
          <form action="${pageContext.request.contextPath}/audit" method="GET" class="form-grid" style="padding: var(--s4) var(--s5); grid-template-columns: 1fr 1fr 1fr 1fr auto; gap: var(--s3); align-items:end;">
            <div class="field">
              <label class="field-label" for="audit-action">Action</label>
              <select class="input input-sm" id="audit-action" name="action">
                <option value="">All actions</option>
                <% if (distinctActions != null) for (String a : distinctActions) { %>
                  <option value="<%= esc(a) %>" <%= a.equals(filterAction) ? "selected" : "" %>><%= esc(a) %></option>
                <% } %>
              </select>
            </div>
            <div class="field">
              <label class="field-label" for="audit-actor">Actor user id</label>
              <input class="input input-sm" type="number" id="audit-actor" name="actorUserId" value="<%= esc(filterActorId) %>" min="1" placeholder="e.g. 7">
            </div>
            <div class="field">
              <label class="field-label" for="audit-from">From</label>
              <input class="input input-sm" type="date" id="audit-from" name="from" value="<%= esc(filterFrom) %>">
            </div>
            <div class="field">
              <label class="field-label" for="audit-to">To</label>
              <input class="input input-sm" type="date" id="audit-to" name="to" value="<%= esc(filterTo) %>">
            </div>
            <div style="display:flex; gap:var(--s2);">
              <button type="submit" class="btn btn-primary btn-sm">Apply</button>
              <a class="btn btn-secondary btn-sm" href="${pageContext.request.contextPath}/audit">Reset</a>
            </div>
          </form>
        </div>

        <div class="card">
          <div class="card-hd">
            <div class="card-hd-left">
              <div class="card-title">Events</div>
              <div class="card-subtitle">Page <%= pageNum %> of <%= totalPages %> · newest first</div>
            </div>
          </div>
          <div class="dg-container scrollbar">
            <table class="table">
              <thead>
                <tr>
                  <th style="width:170px;">Time</th>
                  <th>Action</th>
                  <th>Actor</th>
                  <th>Entity</th>
                  <th>Details</th>
                </tr>
              </thead>
              <tbody>
                <% if (rows == null || rows.isEmpty()) { %>
                  <tr><td colspan="5">
                    <div class="empty-state">
                      <div class="empty-state-icon">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="9" y1="13" x2="15" y2="13"/><line x1="9" y1="17" x2="15" y2="17"/></svg>
                      </div>
                      <div class="empty-state-title">No audit events</div>
                      <div class="empty-state-msg">Nothing matches these filters yet — try a wider date range or clearing the action.</div>
                    </div>
                  </td></tr>
                <% } else { for (AuditLog a : rows) { %>
                  <tr>
                    <td><span class="wl-num-muted"><%= a.getCreatedAt() == null ? "" : a.getCreatedAt().toString() %></span></td>
                    <td><span class="badge <%= chipForAction(a.getAction()) %>"><%= esc(a.getAction()) %></span></td>
                    <td>
                      <% if (a.getActorUsername() != null) { %>
                        <span class="result-title" style="font-weight:600;"><%= esc(a.getActorUsername()) %></span>
                        <span class="card-subtitle">· #<%= a.getActorUserId() %></span>
                      <% } else if (a.getActorUserId() != null) { %>
                        #<%= a.getActorUserId() %>
                      <% } else { %>
                        <span class="card-subtitle">— system</span>
                      <% } %>
                    </td>
                    <td>
                      <% if (a.getEntityType() != null) { %>
                        <%= esc(a.getEntityType()) %><% if (a.getEntityId() != null) { %> #<%= a.getEntityId() %><% } %>
                      <% } else { %>
                        <span class="card-subtitle">—</span>
                      <% } %>
                    </td>
                    <td><%= esc(a.getDetails()) %></td>
                  </tr>
                <% } } %>
              </tbody>
            </table>
          </div>

          <% if (totalPages > 1) {
               StringBuilder qsb = new StringBuilder();
               if (!filterAction.isEmpty())  qsb.append("&action=").append(java.net.URLEncoder.encode(filterAction, "UTF-8"));
               if (!filterActorId.isEmpty()) qsb.append("&actorUserId=").append(filterActorId);
               if (!filterFrom.isEmpty())    qsb.append("&from=").append(filterFrom);
               if (!filterTo.isEmpty())      qsb.append("&to=").append(filterTo);
               String qs = qsb.toString();
          %>
          <div style="display:flex; gap:var(--s2); padding: var(--s3) var(--s5); border-top: 1px solid var(--bd); justify-content:flex-end;">
            <% if (pageNum > 1) { %>
              <a class="btn btn-secondary btn-sm" href="${pageContext.request.contextPath}/audit?page=<%= pageNum-1 %><%= qs %>">← Prev</a>
            <% } %>
            <span class="card-subtitle" style="align-self:center;">Page <%= pageNum %> / <%= totalPages %></span>
            <% if (pageNum < totalPages) { %>
              <a class="btn btn-secondary btn-sm" href="${pageContext.request.contextPath}/audit?page=<%= pageNum+1 %><%= qs %>">Next →</a>
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
