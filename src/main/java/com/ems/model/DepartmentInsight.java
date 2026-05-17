package com.ems.model;

public class DepartmentInsight {
    private String department;
    private int    headcount;
    private int    overloaded;
    private int    overdueTasks;
    private double avgProductivity;
    private double avgCompletion;

    public String getDepartment() { return department; }
    public void   setDepartment(String v) { this.department = v; }

    public int  getHeadcount() { return headcount; }
    public void setHeadcount(int v) { this.headcount = v; }

    public int  getOverloaded() { return overloaded; }
    public void setOverloaded(int v) { this.overloaded = v; }

    public int  getOverdueTasks() { return overdueTasks; }
    public void setOverdueTasks(int v) { this.overdueTasks = v; }

    public double getAvgProductivity() { return avgProductivity; }
    public void   setAvgProductivity(double v) { this.avgProductivity = v; }

    public double getAvgCompletion() { return avgCompletion; }
    public void   setAvgCompletion(double v) { this.avgCompletion = v; }

    public String getProductivityTone() {
        if (avgProductivity >= 70) return "ok";
        if (avgProductivity >= 50) return "info";
        if (avgProductivity >= 30) return "warn";
        return "err";
    }
}
