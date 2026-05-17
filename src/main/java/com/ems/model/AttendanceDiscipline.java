package com.ems.model;

public class AttendanceDiscipline {

    private int userId;
    private int totalDays;
    private int lateCount;
    private int earlyLeaveCount;
    private int onTimeCount;
    private double attendanceDisciplineScore;

    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }

    public int getTotalDays() { return totalDays; }
    public void setTotalDays(int totalDays) { this.totalDays = totalDays; }

    public int getLateCount() { return lateCount; }
    public void setLateCount(int lateCount) { this.lateCount = lateCount; }

    public int getEarlyLeaveCount() { return earlyLeaveCount; }
    public void setEarlyLeaveCount(int earlyLeaveCount) { this.earlyLeaveCount = earlyLeaveCount; }

    public int getOnTimeCount() { return onTimeCount; }
    public void setOnTimeCount(int onTimeCount) { this.onTimeCount = onTimeCount; }

    public double getAttendanceDisciplineScore() { return attendanceDisciplineScore; }
    public void setAttendanceDisciplineScore(double v) { this.attendanceDisciplineScore = v; }

    public String getDisciplineLabel() {
        if (attendanceDisciplineScore >= 90) return "Disciplined";
        if (attendanceDisciplineScore >= 75) return "Consistent";
        if (attendanceDisciplineScore >= 60) return "Improving";
        if (attendanceDisciplineScore >= 40) return "Inconsistent";
        return "Low Discipline";
    }

    public String getDisciplineTone() {
        if (attendanceDisciplineScore >= 75) return "ok";
        if (attendanceDisciplineScore >= 60) return "info";
        if (attendanceDisciplineScore >= 40) return "warn";
        return "err";
    }
}
