package com.ems.model;

import java.sql.Date;
import java.sql.Timestamp;

public class LeaveRequest {

    public static final String PENDING  = "PENDING";
    public static final String APPROVED = "APPROVED";
    public static final String REJECTED = "REJECTED";

    private int    id;
    private int    userId;
    private String username;     // joined for display
    private String employeeName; // joined for display
    private String leaveType;
    private Date   startDate;
    private Date   endDate;
    private String reason;
    private String status;
    private Integer   decidedBy;
    private Timestamp decidedAt;
    private Timestamp createdAt;

    public int getId()                      { return id; }
    public void setId(int id)               { this.id = id; }

    public int getUserId()                  { return userId; }
    public void setUserId(int v)            { this.userId = v; }

    public String getUsername()             { return username; }
    public void setUsername(String v)       { this.username = v; }

    public String getEmployeeName()         { return employeeName; }
    public void setEmployeeName(String v)   { this.employeeName = v; }

    public String getLeaveType()            { return leaveType; }
    public void setLeaveType(String v)      { this.leaveType = v; }

    public Date getStartDate()              { return startDate; }
    public void setStartDate(Date v)        { this.startDate = v; }

    public Date getEndDate()                { return endDate; }
    public void setEndDate(Date v)          { this.endDate = v; }

    public String getReason()               { return reason; }
    public void setReason(String v)         { this.reason = v; }

    public String getStatus()               { return status; }
    public void setStatus(String v)         { this.status = v; }

    public Integer getDecidedBy()           { return decidedBy; }
    public void setDecidedBy(Integer v)     { this.decidedBy = v; }

    public Timestamp getDecidedAt()         { return decidedAt; }
    public void setDecidedAt(Timestamp v)   { this.decidedAt = v; }

    public Timestamp getCreatedAt()         { return createdAt; }
    public void setCreatedAt(Timestamp v)   { this.createdAt = v; }

    public int getDays() {
        if (startDate == null || endDate == null) return 0;
        long ms = endDate.getTime() - startDate.getTime();
        if (ms < 0) return 0;
        return (int) (ms / (24L * 3600L * 1000L)) + 1;
    }
}
