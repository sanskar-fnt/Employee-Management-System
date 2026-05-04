package com.ems.controllers;

import com.ems.model.Employee;
import com.ems.model.User;
import com.ems.service.EmployeeService;
import com.ems.service.UserService;
import com.ems.service.AttendanceService;
import com.ems.util.CsrfUtil;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.time.LocalDate;

@WebServlet("/employees")
public class EmployeeServlet extends HttpServlet {

    private final EmployeeService employeeService = new EmployeeService();
    private final UserService userService = new UserService();
    private final AttendanceService attendanceService = new AttendanceService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        request.setAttribute("csrfToken", CsrfUtil.ensureToken(session));

        User user = (User) session.getAttribute("user");
        String role = user == null ? null : user.getRole();
        if (user == null || (role != null && !"ADMIN".equalsIgnoreCase(role))) {
            response.sendRedirect(request.getContextPath() + "/dashboard");
            return;
        }

        String query = request.getParameter("q");
        LocalDate startDate = parseDate(request.getParameter("startDate"));
        LocalDate endDate = parseDate(request.getParameter("endDate"));
        int page = parsePage(request.getParameter("page"));
        int size = parseSize(request.getParameter("size"));
        int offset = (page - 1) * size;
        int totalEmployees;
        List<Employee> employees;
        if (query != null && !query.trim().isEmpty()) {
            employees = employeeService.searchEmployees(query.trim(), size, offset);
            totalEmployees = employeeService.getEmployeeCountByQuery(query.trim());
            request.setAttribute("searchQuery", query.trim());
        } else {
            employees = employeeService.getAllEmployees(size, offset);
            totalEmployees = employeeService.getEmployeeCount();
        }
        int totalPages = Math.max(1, (int) Math.ceil(totalEmployees / (double) size));
        Map<Integer, Integer> attendanceCounts = new HashMap<>();
        for (Employee employee : employees) {
            Integer userId = employee.getUserId();
            int count = userId == null ? 0 : attendanceService.getAttendanceCountForUserInRange(userId, startDate, endDate);
            attendanceCounts.put(employee.getId(), count);
        }
        request.setAttribute("employeeList", employees);
        request.setAttribute("attendanceCounts", attendanceCounts);
        request.setAttribute("startDate", startDate == null ? "" : startDate.toString());
        request.setAttribute("endDate", endDate == null ? "" : endDate.toString());
        request.setAttribute("page", page);
        request.setAttribute("size", size);
        request.setAttribute("totalPages", totalPages);
        RequestDispatcher dispatcher = request.getRequestDispatcher("/WEB-INF/pages/employee.jsp");
        dispatcher.forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        if (!CsrfUtil.isValid(request)) {
            session.setAttribute("formError", "Invalid request token.");
            response.sendRedirect(request.getContextPath() + "/employees");
            return;
        }

        User user = (User) session.getAttribute("user");
        String role = user == null ? null : user.getRole();
        if (user == null || (role != null && !"ADMIN".equalsIgnoreCase(role))) {
            response.sendRedirect(request.getContextPath() + "/dashboard");
            return;
        }

        String action = request.getParameter("action");
        if (action == null) {
            response.sendRedirect(request.getContextPath() + "/employees");
            return;
        }

        if (action.equals("add")) {
            String username = request.getParameter("username");
            String password = request.getParameter("password");
            String name = request.getParameter("name");
            String email = request.getParameter("email");
            String phone = request.getParameter("phone");
            String department = request.getParameter("department");

            User newUser = new User();
            newUser.setUsername(username == null ? null : username.trim());
            newUser.setPassword(password == null ? null : password.trim());
            newUser.setRole("EMPLOYEE");
            String userError = userService.validateNewUser(newUser);
            if (userError != null) {
                session.setAttribute("formError", userError);
                response.sendRedirect(request.getContextPath() + "/employees");
                return;
            }

            Employee employee = new Employee();
            employee.setName(name == null ? null : name.trim());
            employee.setEmail(email == null ? null : email.trim());
            employee.setPhone(phone);
            employee.setDepartment(department);
            String employeeError = employeeService.validateEmployee(employee);
            if (employeeError != null) {
                session.setAttribute("formError", employeeError);
                response.sendRedirect(request.getContextPath() + "/employees");
                return;
            }

            if (employeeService.isEmailExists(employee.getEmail())) {
                session.setAttribute("formError", "Email already exists.");
                response.sendRedirect(request.getContextPath() + "/employees");
                return;
            }

            int userId = userService.createUser(newUser);
            if (userId <= 0) {
                session.setAttribute("formError", "Unable to create login for employee.");
                response.sendRedirect(request.getContextPath() + "/employees");
                return;
            }

            boolean created = employeeService.addEmployee(employee, userId);
            if (!created) {
                userService.deleteUserById(userId);
                session.setAttribute("formError", "Unable to create employee profile.");
                response.sendRedirect(request.getContextPath() + "/employees");
                return;
            }
            session.setAttribute("successMessage", "Employee created successfully.");
            response.sendRedirect(request.getContextPath() + "/employees");
            return;
        }

        if (action.equals("update")) {
            String idParam = request.getParameter("id");
            String name = request.getParameter("name");
            String email = request.getParameter("email");
            String phone = request.getParameter("phone");
            String department = request.getParameter("department");

            if (idParam != null) {
                int id;
                try {
                    id = Integer.parseInt(idParam);
                } catch (NumberFormatException e) {
                    session.setAttribute("formError", "Invalid employee id.");
                    response.sendRedirect(request.getContextPath() + "/employees");
                    return;
                }
                Employee employee = new Employee();
                employee.setId(id);
                employee.setName(name == null ? null : name.trim());
                employee.setEmail(email == null ? null : email.trim());
                employee.setPhone(phone);
                employee.setDepartment(department);
                String employeeError = employeeService.validateEmployee(employee);
                if (employeeError != null) {
                    session.setAttribute("formError", employeeError);
                    response.sendRedirect(request.getContextPath() + "/employees");
                    return;
                }
                if (employeeService.isEmailExistsForOther(employee.getEmail(), id)) {
                    session.setAttribute("formError", "Email already exists.");
                    response.sendRedirect(request.getContextPath() + "/employees");
                    return;
                }
                boolean updated = employeeService.updateEmployee(employee);
                if (updated) {
                    session.setAttribute("successMessage", "Employee updated successfully.");
                } else {
                    session.setAttribute("formError", "Unable to update employee.");
                }
            }
            response.sendRedirect(request.getContextPath() + "/employees");
            return;
        }

        if (action.equals("delete")) {
            String idParam = request.getParameter("id");
            if (idParam != null) {
                int id;
                try {
                    id = Integer.parseInt(idParam);
                } catch (NumberFormatException e) {
                    session.setAttribute("formError", "Invalid employee id.");
                    response.sendRedirect(request.getContextPath() + "/employees");
                    return;
                }
                Integer userId = employeeService.getUserIdByEmployeeId(id);
                boolean deleted = employeeService.deleteEmployee(id);
                if (deleted && userId != null) {
                    userService.deleteUserById(userId);
                }
                session.setAttribute(deleted ? "successMessage" : "formError",
                        deleted ? "Employee deleted successfully." : "Unable to delete employee.");
            }
            response.sendRedirect(request.getContextPath() + "/employees");
        } else {
            response.sendRedirect(request.getContextPath() + "/employees");
        }
    }

    private int parsePage(String value) {
        try {
            int page = Integer.parseInt(value);
            return page < 1 ? 1 : page;
        } catch (Exception ex) {
            return 1;
        }
    }

    private int parseSize(String value) {
        try {
            int size = Integer.parseInt(value);
            if (size < 5) {
                return 5;
            }
            return Math.min(size, 50);
        } catch (Exception ex) {
            return 10;
        }
    }

    private LocalDate parseDate(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        try {
            return LocalDate.parse(value);
        } catch (Exception ex) {
            return null;
        }
    }
}
