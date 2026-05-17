package com.ems.model;

public class PerformanceBreakdown {

    private int userId;
    private int completedTasks;
    private int totalTasks;
    private int attendanceDays;
    private int workingDays;
    private int lateDays;

    private double attendancePercentage;
    private double taskCompletionRate;
    private double latePenalty;
    private double finalScore;

    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }

    public int getCompletedTasks() { return completedTasks; }
    public void setCompletedTasks(int completedTasks) { this.completedTasks = completedTasks; }

    public int getTotalTasks() { return totalTasks; }
    public void setTotalTasks(int totalTasks) { this.totalTasks = totalTasks; }

    public int getAttendanceDays() { return attendanceDays; }
    public void setAttendanceDays(int attendanceDays) { this.attendanceDays = attendanceDays; }

    public int getWorkingDays() { return workingDays; }
    public void setWorkingDays(int workingDays) { this.workingDays = workingDays; }

    public int getLateDays() { return lateDays; }
    public void setLateDays(int lateDays) { this.lateDays = lateDays; }

    public double getAttendancePercentage() { return attendancePercentage; }
    public void setAttendancePercentage(double attendancePercentage) { this.attendancePercentage = attendancePercentage; }

    public double getTaskCompletionRate() { return taskCompletionRate; }
    public void setTaskCompletionRate(double taskCompletionRate) { this.taskCompletionRate = taskCompletionRate; }

    public double getLatePenalty() { return latePenalty; }
    public void setLatePenalty(double latePenalty) { this.latePenalty = latePenalty; }

    public double getFinalScore() { return finalScore; }
    public void setFinalScore(double finalScore) { this.finalScore = finalScore; }

    public String getBadge() {
        if (finalScore >= 85) return "Excellent";
        if (finalScore >= 70) return "Strong";
        if (finalScore >= 50) return "Steady";
        if (finalScore >= 30) return "Needs Focus";
        return "At Risk";
    }

    public String getBadgeTone() {
        if (finalScore >= 70) return "ok";
        if (finalScore >= 50) return "info";
        if (finalScore >= 30) return "warn";
        return "err";
    }
}
