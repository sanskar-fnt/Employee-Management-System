package com.ems.controllers;

import com.ems.model.User;
import com.ems.service.UserService;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

@WebServlet("/login")
public class AuthServlet extends HttpServlet {

    private final UserService userService = new UserService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session != null && session.getAttribute("user") != null) {
            response.sendRedirect(request.getContextPath() + "/dashboard");
            return;
        }
        if (session != null) {
            String loginError = (String) session.getAttribute("loginError");
            if (loginError != null) {
                session.removeAttribute("loginError");
                request.setAttribute("error", loginError);
            }
        }
        RequestDispatcher dispatcher = request.getRequestDispatcher("/WEB-INF/pages/login.jsp");
        dispatcher.forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        String action = request.getParameter("action");

        if (action != null && action.equals("logout")) {
            if (session != null) {
                session.invalidate();
            }
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        if (session != null && session.getAttribute("user") != null) {
            response.sendRedirect(request.getContextPath() + "/dashboard");
            return;
        }

        String username = request.getParameter("username");
        String password = request.getParameter("password");
        if (isBlank(username) || username.trim().length() < 3 || isBlank(password) || password.trim().length() < 4) {
            HttpSession newSession = request.getSession(true);
            newSession.setAttribute("loginError", "Please enter a valid username and password.");
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        User user = userService.authenticate(username, password);

        if (user != null) {
            if (session != null) {
                session.invalidate();
            }
            HttpSession newSession = request.getSession(true);
            newSession.setAttribute("user", user);
            newSession.setMaxInactiveInterval(1800);
            if ("EMPLOYEE".equalsIgnoreCase(user.getRole())) {
                com.ems.service.EmployeeService employeeService = new com.ems.service.EmployeeService();
                com.ems.model.Employee employee = employeeService.getByUserId(user.getId());
                if (employee == null) {
                    newSession.setAttribute("loginError", "Employee profile not linked.");
                    response.sendRedirect(request.getContextPath() + "/login");
                    return;
                }
                response.sendRedirect(request.getContextPath() + "/emp-dashboard");
            } else {
                response.sendRedirect(request.getContextPath() + "/dashboard");
            }
        } else {
            HttpSession newSession = request.getSession(true);
            newSession.setAttribute("loginError", "Invalid username or password.");
            response.sendRedirect(request.getContextPath() + "/login");
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}