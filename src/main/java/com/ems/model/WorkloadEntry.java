package com.ems.model;

public class WorkloadEntry {

    private int employeeId;
    private int userId;
    private String name;
    private String department;

    private int totalAssignedTasks;
    private int completedTasks;
    private int pendingTasks;
    private int activeTasks;
    private int overdueTasks;

    private int workloadScore;
    private double completionRate;
    private double productivityScore;

    public int getEmployeeId() { return employeeId; }
    public void setEmployeeId(int v) { this.employeeId = v; }

    public int getUserId() { return userId; }
    public void setUserId(int v) { this.userId = v; }

    public String getName() { return name; }
    public void setName(String v) { this.name = v; }

    public String getDepartment() { return department; }
    public void setDepartment(String v) { this.department = v; }

    public int getTotalAssignedTasks() { return totalAssignedTasks; }
    public void setTotalAssignedTasks(int v) { this.totalAssignedTasks = v; }

    public int getCompletedTasks() { return completedTasks; }
    public void setCompletedTasks(int v) { this.completedTasks = v; }

    public int getPendingTasks() { return pendingTasks; }
    public void setPendingTasks(int v) { this.pendingTasks = v; }

    public int getActiveTasks() { return activeTasks; }
    public void setActiveTasks(int v) { this.activeTasks = v; }

    public int getOverdueTasks() { return overdueTasks; }
    public void setOverdueTasks(int v) { this.overdueTasks = v; }

    public int getWorkloadScore() { return workloadScore; }
    public void setWorkloadScore(int v) { this.workloadScore = v; }

    public double getCompletionRate() { return completionRate; }
    public void setCompletionRate(double v) { this.completionRate = v; }

    public double getProductivityScore() { return productivityScore; }
    public void setProductivityScore(double v) { this.productivityScore = v; }

    public String getWorkloadStatus() {
        if (workloadScore >= 13) return "Overloaded";
        if (workloadScore >= 6)  return "Balanced";
        return "Low";
    }

    public String getWorkloadTone() {
        if (workloadScore >= 13) return "err";
        if (workloadScore >= 6)  return "ok";
        return "info";
    }
}
