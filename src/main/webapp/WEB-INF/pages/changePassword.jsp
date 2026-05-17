<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.ems.model.User" %>
<%
  User user = (User) session.getAttribute("user");
  if (user == null) {
    response.sendRedirect(request.getContextPath() + "/login");
    return;
  }
  String csrfToken = (String) request.getAttribute("csrfToken");
  if (csrfToken == null) csrfToken = "";
  String formError = (String) request.getAttribute("formError");
  boolean firstLogin = user.isMustChangePassword();
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
  <title><%= firstLogin ? "Set a new password" : "Change password" %> — EMS</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css?v=8">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/ems-ui.css?v=8">
  <script src="${pageContext.request.contextPath}/js/theme-init.js"></script>
</head>
<body>
  <div class="auth-shell">
    <section class="auth-left">
      <div class="auth-left-content">
        <div class="auth-brand">
          <div class="sb-mark">E</div>
          <span style="font-size:18px; font-weight:700; color:#fff;">EMS</span>
        </div>
        <h1 class="auth-headline" style="margin-top:auto;">
          <%= firstLogin ? "One last step before you continue." : "Update your password." %>
        </h1>
        <p class="auth-sub">
          <%= firstLogin
                ? "For security, please replace the temporary password from your welcome email."
                : "Choose a strong password you don't use elsewhere." %>
        </p>
      </div>
    </section>

    <section class="auth-right">
      <div class="auth-form-wrap">
        <div class="auth-eyebrow"><%= firstLogin ? "First login" : "Account security" %></div>
        <h2 class="auth-form-title"><%= firstLogin ? "Set a new password" : "Change password" %></h2>
        <p class="auth-form-sub">Signed in as <strong><%= esc(user.getUsername()) %></strong>.</p>

        <% if (formError != null) { %>
          <div class="alert alert-error mb-16"><%= esc(formError) %></div>
        <% } %>

        <form class="auth-form" action="${pageContext.request.contextPath}/change-password" method="POST">
          <input type="hidden" name="csrfToken" value="<%= esc(csrfToken) %>">
          <div class="field">
            <label class="field-label" for="currentPassword"><%= firstLogin ? "Temporary password" : "Current password" %></label>
            <input class="input" type="password" id="currentPassword" name="currentPassword" required autocomplete="current-password">
          </div>
          <div class="field">
            <label class="field-label" for="newPassword">New password</label>
            <input class="input" type="password" id="newPassword" name="newPassword" required autocomplete="new-password" minlength="8" placeholder="Min. 8 characters, letters + numbers">
          </div>
          <div class="field">
            <label class="field-label" for="confirmPassword">Confirm new password</label>
            <input class="input" type="password" id="confirmPassword" name="confirmPassword" required autocomplete="new-password" minlength="8">
          </div>
          <button type="submit" class="btn btn-primary btn-lg btn-block">Update password</button>
        </form>

        <% if (!firstLogin) { %>
        <p class="auth-form-sub" style="margin-top: var(--s4);">
          <a href="${pageContext.request.contextPath}/<%= "EMPLOYEE".equalsIgnoreCase(user.getRole()) ? "emp-dashboard" : "dashboard" %>">← Back to dashboard</a>
        </p>
        <% } %>
      </div>
    </section>
  </div>
  <script src="${pageContext.request.contextPath}/js/app.js"></script>
</body>
</html>
