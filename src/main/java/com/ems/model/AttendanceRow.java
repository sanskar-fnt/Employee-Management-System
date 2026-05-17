package com.ems.model;

import java.sql.Time;

public class AttendanceRow {
    private int employeeId;
    private Integer userId;          // FK to users.id; null if absent from join
    private String name;
    private String email;
    private String department;
    private String attendanceStatus;
    private boolean onLeave;          // transient — populated by LeaveService
    private Time checkInTime;
    private Time checkOutTime;
    private java.sql.Date workDate;

    public Integer getUserId()              { return userId; }
    public void    setUserId(Integer userId){ this.userId = userId; }

    public boolean isOnLeave()              { return onLeave; }
    public void    setOnLeave(boolean v)    { this.onLeave = v; }

    public int getEmployeeId() {
        return employeeId;
    }

    public void setEmployeeId(int employeeId) {
        this.employeeId = employeeId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getDepartment() {
        return department;
    }

    public void setDepartment(String department) {
        this.department = department;
    }

    public String getAttendanceStatus() {
        return attendanceStatus;
    }

    public void setAttendanceStatus(String attendanceStatus) {
        this.attendanceStatus = attendanceStatus;
    }

    public Time getCheckInTime() {
        return checkInTime;
    }

    public void setCheckInTime(Time checkInTime) {
        this.checkInTime = checkInTime;
    }

    public Time getCheckOutTime() {
        return checkOutTime;
    }

    public void setCheckOutTime(Time checkOutTime) {
        this.checkOutTime = checkOutTime;
    }

    public java.sql.Date getWorkDate() {
        return workDate;
    }

    public void setWorkDate(java.sql.Date workDate) {
        this.workDate = workDate;
    }
}