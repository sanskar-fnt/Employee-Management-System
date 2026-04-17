<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>404 - Page Not Found</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>
  <div class="app-layout">
    <aside class="sidebar">
      <div class="sidebar-brand">EMS</div>
      <nav class="sidebar-nav">
        <a href="${pageContext.request.contextPath}/dashboard">Dashboard</a>
        <a href="${pageContext.request.contextPath}/employees">Employees</a>
      </nav>
    </aside>

    <div class="main">
      <header class="topbar">
        <div class="topbar-title">Page Not Found</div>
        <div class="topbar-user">Error 404</div>
      </header>

      <main class="content">
        <div class="card text-center">
          <div class="card-title">404 - Page Not Found</div>
          <p class="text-muted">The page you are looking for doesn't exist.</p>
          <div class="form-actions">
            <a class="btn btn-primary" href="${pageContext.request.contextPath}/dashboard">Back to Dashboard</a>
            <a class="btn btn-secondary" href="${pageContext.request.contextPath}/login">Login</a>
          </div>
        </div>
      </main>
    </div>
  </div>
</body>
</html>
