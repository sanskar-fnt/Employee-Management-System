package com.ems.model;

public class PerformanceEntry {
    private int employeeId;
    private int userId;
    private String name;
    private int completedTasks;
    private int attendanceDays;
    private int lateDays;
    private int score;

    public int getEmployeeId() {
        return employeeId;
    }

    public void setEmployeeId(int employeeId) {
        this.employeeId = employeeId;
    }

    public int getUserId() {
        return userId;
    }

    public void setUserId(int userId) {
        this.userId = userId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getCompletedTasks() {
        return completedTasks;
    }

    public void setCompletedTasks(int completedTasks) {
        this.completedTasks = completedTasks;
    }

    public int getAttendanceDays() {
        return attendanceDays;
    }

    public void setAttendanceDays(int attendanceDays) {
        this.attendanceDays = attendanceDays;
    }

    public int getLateDays() {
        return lateDays;
    }

    public void setLateDays(int lateDays) {
        this.lateDays = lateDays;
    }

    public int getScore() {
        return score;
    }

    public void setScore(int score) {
        this.score = score;
    }
}
