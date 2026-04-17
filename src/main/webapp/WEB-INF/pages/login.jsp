<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>EMS Login</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body class="page-login">
  <div class="login-layout">
    <section class="login-left">
      <span class="floating-shape shape-1"></span>
      <span class="floating-shape shape-2"></span>
      <div>
        <h1>Employee Management System</h1>
        <p class="text-muted" style="color: rgba(255, 255, 255, 0.8); margin-top: 12px;">Manage your team, attendance, and records with clarity.</p>
      </div>
    </section>
    <section class="login-right">
      <div class="auth-container">
        <div class="card auth-card">
          <div class="card-header">
            <div class="card-title">EMS Login</div>
          </div>
          <form action="${pageContext.request.contextPath}/login" method="POST">
            <div class="form-grid">
              <div class="form-group input-icon">
                <label for="username">👤Username</label>
                <input class="input" type="text" id="username" name="username" required>
              </div>
              <div class="form-group input-icon">
                <label for="password">🔒Password</label>
                <input class="input" type="password" id="password" name="password" required>
              </div>
            </div>
            <div class="form-actions">
              <button type="submit" class="btn btn-primary btn-block">Login</button>
            </div>
          </form>
          <% if (request.getAttribute("error") != null) { %>
            <div class="alert alert-error"><%= request.getAttribute("error") %></div>
          <% } %>
        </div>
      </div>
    </section>
  </div>
</body>
</html>