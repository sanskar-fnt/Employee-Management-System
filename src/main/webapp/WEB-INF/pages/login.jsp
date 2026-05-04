<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Sign in — EMS</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css?v=1">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/ems-ui.css?v=2">
</head>
<body>
  <div class="auth-shell">

    <!-- Left decorative panel -->
    <section class="auth-left">
      <span class="auth-float auth-float-1"></span>
      <span class="auth-float auth-float-2"></span>
      <span class="auth-float auth-float-3"></span>
      <div class="auth-left-content">
        <div class="auth-brand">
          <div class="auth-brand-mark">E</div>
          <span class="auth-brand-name">EMS</span>
        </div>
        <h1 class="auth-heading">Employee Management, simplified.</h1>
        <p class="auth-lead">Track attendance, assign tasks, and manage your entire workforce from one central dashboard.</p>
        <div class="auth-features">
          <div class="auth-feat">
            <span class="auth-feat-ic">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
            </span>
            Real-time attendance tracking
          </div>
          <div class="auth-feat">
            <span class="auth-feat-ic">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
            </span>
            Task assignment &amp; progress monitoring
          </div>
          <div class="auth-feat">
            <span class="auth-feat-ic">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
            </span>
            Role-based access for admins &amp; employees
          </div>
          <div class="auth-feat">
            <span class="auth-feat-ic">
              <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
            </span>
            Analytics &amp; workforce insights
          </div>
        </div>
      </div>
    </section>

    <!-- Right form panel -->
    <section class="auth-right">
      <div class="auth-form-wrap">
        <div class="auth-eyebrow">Secure Login</div>
        <h2 class="auth-form-title">Welcome back</h2>
        <p class="auth-form-sub">Sign in with your EMS credentials to continue.</p>

        <% if (request.getAttribute("error") != null) { %>
          <div class="alert alert-error mb-16"><%= request.getAttribute("error") %></div>
        <% } %>

        <form class="auth-form" action="${pageContext.request.contextPath}/login" method="POST">
          <input type="hidden" name="csrfToken" value="<%= request.getAttribute("csrfToken") == null ? "" : request.getAttribute("csrfToken") %>">
          <div class="field">
            <label class="field-label" for="username">Username</label>
            <input class="input" type="text" id="username" name="username" placeholder="your.username" required autocomplete="username">
          </div>
          <div class="field">
            <label class="field-label" for="password">Password</label>
            <input class="input" type="password" id="password" name="password" placeholder="••••••••" required autocomplete="current-password">
          </div>
          <button type="submit" class="btn btn-primary btn-lg btn-block">Sign in</button>
        </form>
      </div>
    </section>

  </div>
  <script src="${pageContext.request.contextPath}/js/app.js"></script>
</body>
</html>
