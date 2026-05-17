package com.ems.controllers;

import com.ems.model.ActivityItem;
import com.ems.model.AttendanceRow;
import com.ems.model.PerformanceEntry;
import com.ems.model.Task;
import com.ems.model.User;
import com.ems.model.WorkloadEntry;
import com.ems.service.AttendanceService;
import com.ems.service.EmployeeService;
import com.ems.service.PerformanceService;
import com.ems.service.TaskService;
import com.ems.service.WorkloadService;
import com.ems.service.InsightService;
import com.ems.util.CsrfUtil;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;

@WebServlet("/analytics")
public class AnalyticsServlet extends HttpServlet {

    private final TaskService taskService = new TaskService();
    private final EmployeeService employeeService = new EmployeeService();
    private final AttendanceService attendanceService = new AttendanceService();
    private final PerformanceService performanceService = new PerformanceService();
    private final WorkloadService workloadService = new WorkloadService();
    private final InsightService  insightService  = new InsightService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        request.setAttribute("csrfToken", CsrfUtil.ensureToken(session));

        User user = (User) session.getAttribute("user");
        if (user == null || !"ADMIN".equalsIgnoreCase(user.getRole())) {
            response.sendRedirect(request.getContextPath() + "/dashboard");
            return;
        }

        // Tasks
        Map<String, Integer> stats = taskService.getTaskStats();
        int pending    = stats.getOrDefault("PENDING", 0);
        int inProgress = stats.getOrDefault("IN_PROGRESS", 0);
        int completed  = stats.getOrDefault("COMPLETED", 0);
        int total      = pending + inProgress + completed;
        int overdue    = taskService.getOverdueTaskCount();

        request.setAttribute("taskPending",   pending);
        request.setAttribute("taskProgress",  inProgress);
        request.setAttribute("taskCompleted", completed);
        request.setAttribute("taskTotal",     total);
        request.setAttribute("taskOverdue",   overdue);

        // Headcount + attendance
        int totalEmployees   = employeeService.getEmployeeCount();
        int activeEmployees  = attendanceService.getActiveEmployeeCount();
        int todayAttendance  = attendanceService.getTodayAttendanceCount();
        int attendanceRate   = totalEmployees > 0 ? (int) Math.round(todayAttendance * 100.0 / totalEmployees) : 0;

        request.setAttribute("totalEmployees",  totalEmployees);
        request.setAttribute("activeEmployees", activeEmployees);
        request.setAttribute("todayAttendance", todayAttendance);
        request.setAttribute("attendanceRate",  attendanceRate);

        // Workloads
        List<WorkloadEntry> workloads = workloadService.getAllWorkloads();
        request.setAttribute("workloads",          workloads);
        request.setAttribute("workloadDist",       workloadService.getDistribution(workloads));
        request.setAttribute("topOverloaded",      workloadService.sortByWorkloadDesc(workloads, 5));
        request.setAttribute("mostOverdue",        workloadService.sortByOverdueDesc(workloads, 5));

        // Productivity score = avg final score across all employees with tasks
        double productivity = 0.0;
        int counted = 0;
        for (WorkloadEntry w : workloads) {
            productivity += w.getProductivityScore();
            counted++;
        }
        productivity = counted == 0 ? 0.0 : Math.round((productivity / counted) * 10.0) / 10.0;
        request.setAttribute("productivityScore", productivity);

        // Headline insights + per-department rollup (pure orchestration of existing data).
        request.setAttribute("insightCards",
                insightService.buildHeadline(workloads, totalEmployees, activeEmployees, overdue, productivity));
        request.setAttribute("departmentInsights",
                insightService.buildDepartmentInsights(workloads));

        // Performance leaderboard
        List<PerformanceEntry> leaderboard = performanceService.getTopPerformers(5);
        request.setAttribute("performanceLeaderboard", leaderboard);

        // Most-late employees this week
        LocalDate weekEnd = LocalDate.now();
        LocalDate weekStart = weekEnd.minusDays(6);
        List<int[]> lateEntries = new ArrayList<>(); // [employeeIndex, lateCount]
        for (int i = 0; i < workloads.size(); i++) {
            int lateCount = attendanceService.getLateCountForUserInRange(workloads.get(i).getUserId(), weekStart, weekEnd);
            if (lateCount > 0) lateEntries.add(new int[]{ i, lateCount });
        }
        lateEntries.sort((a, b) -> Integer.compare(b[1], a[1]));
        List<Map<String, Object>> mostLate = new ArrayList<>();
        for (int i = 0; i < Math.min(5, lateEntries.size()); i++) {
            int[] entry = lateEntries.get(i);
            WorkloadEntry w = workloads.get(entry[0]);
            java.util.LinkedHashMap<String, Object> m = new java.util.LinkedHashMap<>();
            m.put("name", w.getName());
            m.put("department", w.getDepartment());
            m.put("lateCount", entry[1]);
            mostLate.add(m);
        }
        request.setAttribute("mostLate", mostLate);

        // 7-day attendance trend
        request.setAttribute("attendanceTrend", attendanceService.getDailyAttendanceCounts(7));

        // Activity feed (last 12)
        request.setAttribute("activityFeed", buildActivityFeed());

        RequestDispatcher dispatcher = request.getRequestDispatcher("/WEB-INF/pages/analytics.jsp");
        dispatcher.forward(request, response);
    }

    private List<ActivityItem> buildActivityFeed() {
        List<ActivityItem> items = new ArrayList<>();
        LocalDate today = LocalDate.now();

        // Recent attendance check-ins
        List<AttendanceRow> attendance = attendanceService.getRecentAttendance(8);
        if (attendance != null) {
            for (AttendanceRow r : attendance) {
                if (r.getCheckInTime() == null || r.getWorkDate() == null) continue;
                LocalDateTime when = LocalDateTime.of(r.getWorkDate().toLocalDate(), r.getCheckInTime().toLocalTime());
                boolean late = r.getCheckInTime().toLocalTime().isAfter(AttendanceService.LATE_THRESHOLD);
                if (late) {
                    items.add(new ActivityItem("LATE", "warn",
                            "Late arrival",
                            r.getName() + " checked in at " + r.getCheckInTime(), when));
                } else {
                    items.add(new ActivityItem("CHECK_IN", "ok",
                            "Checked in",
                            r.getName() + " · " + r.getCheckInTime(), when));
                }
            }
        }

        // Recent tasks
        List<Task> tasks = taskService.getAllTasks();
        if (tasks != null) {
            int taskLimit = Math.min(8, tasks.size());
            for (int i = 0; i < taskLimit; i++) {
                Task t = tasks.get(i);
                LocalDateTime when = t.getCreatedAt() == null ? LocalDateTime.now() : t.getCreatedAt().toLocalDateTime();
                if ("COMPLETED".equalsIgnoreCase(t.getStatus())) {
                    items.add(new ActivityItem("TASK_DONE", "ok",
                            "Task completed",
                            t.getTitle() + (t.getAssignedToName() == null ? "" : " · " + t.getAssignedToName()),
                            t.getUpdatedAt() == null ? when : t.getUpdatedAt().toLocalDateTime()));
                } else if (t.getDueDate() != null && t.getDueDate().toLocalDate().isBefore(today)
                        && !"COMPLETED".equalsIgnoreCase(t.getStatus())) {
                    items.add(new ActivityItem("OVERDUE", "err",
                            "Task overdue",
                            t.getTitle() + " · due " + t.getDueDate(), when));
                } else {
                    items.add(new ActivityItem("ASSIGNED", "info",
                            "Task assigned",
                            t.getTitle() + (t.getAssignedToName() == null ? "" : " → " + t.getAssignedToName()), when));
                }
            }
        }

        items.sort(Comparator.comparing(ActivityItem::getWhen).reversed());
        if (items.size() > 12) return new ArrayList<>(items.subList(0, 12));
        return items;
    }

    // suppress unused-import warning
    @SuppressWarnings("unused")
    private void touch(LocalTime t) { }
}
