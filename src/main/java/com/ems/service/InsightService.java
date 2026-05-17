package com.ems.service;

import com.ems.model.DepartmentInsight;
import com.ems.model.InsightCard;
import com.ems.model.WorkloadEntry;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Aggregates already-computed signals from WorkloadService / PerformanceService /
 * AttendanceService into headline insight cards and per-department rollups.
 *
 * Pure orchestration — no SQL of its own, no duplicated logic.
 */
public class InsightService {

    /** Headline cards for the analytics page hero strip. */
    public List<InsightCard> buildHeadline(List<WorkloadEntry> workloads,
                                           int totalEmployees,
                                           int activeNow,
                                           int overdueTotal,
                                           double avgProductivity) {
        List<InsightCard> out = new ArrayList<>();

        int overloaded = 0;
        int healthyPerformers = 0;
        for (WorkloadEntry w : workloads) {
            if ("Overloaded".equalsIgnoreCase(w.getWorkloadStatus())) overloaded++;
            if (w.getProductivityScore() >= 70) healthyPerformers++;
        }

        // 1) Productivity headline
        String prodTone = avgProductivity >= 70 ? "ok"
                        : avgProductivity >= 50 ? "info"
                        : avgProductivity >= 30 ? "warn" : "err";
        out.add(new InsightCard(
                "Average productivity",
                fmt1(avgProductivity) + " / 100",
                healthyPerformers + " of " + workloads.size() + " above 70",
                prodTone));

        // 2) Overload headline
        String loadTone = overloaded == 0 ? "ok" : overloaded <= 2 ? "warn" : "err";
        out.add(new InsightCard(
                "Overloaded employees",
                String.valueOf(overloaded),
                overloaded == 0 ? "Workload is balanced" : "Consider rebalancing tasks",
                loadTone));

        // 3) Overdue headline
        String overdueTone = overdueTotal == 0 ? "ok" : overdueTotal <= 3 ? "warn" : "err";
        out.add(new InsightCard(
                "Overdue tasks",
                String.valueOf(overdueTotal),
                overdueTotal == 0 ? "All deadlines on track" : "Across the organization",
                overdueTone));

        // 4) Active now headline
        int idle = Math.max(0, totalEmployees - activeNow);
        out.add(new InsightCard(
                "Currently checked in",
                activeNow + " / " + totalEmployees,
                idle + " not active right now",
                "info"));

        return out;
    }

    /** Per-department aggregation. Department key is "—" when null/empty. */
    public List<DepartmentInsight> buildDepartmentInsights(List<WorkloadEntry> workloads) {
        Map<String, DepartmentInsight> map = new LinkedHashMap<>();
        Map<String, double[]> sums = new LinkedHashMap<>(); // [productivity, completion]

        for (WorkloadEntry w : workloads) {
            String dept = (w.getDepartment() == null || w.getDepartment().trim().isEmpty())
                    ? "—" : w.getDepartment().trim();
            DepartmentInsight d = map.get(dept);
            double[] s = sums.get(dept);
            if (d == null) {
                d = new DepartmentInsight();
                d.setDepartment(dept);
                map.put(dept, d);
                s = new double[]{0.0, 0.0};
                sums.put(dept, s);
            }
            d.setHeadcount(d.getHeadcount() + 1);
            if ("Overloaded".equalsIgnoreCase(w.getWorkloadStatus())) {
                d.setOverloaded(d.getOverloaded() + 1);
            }
            d.setOverdueTasks(d.getOverdueTasks() + w.getOverdueTasks());
            s[0] += w.getProductivityScore();
            s[1] += w.getCompletionRate();
        }
        for (Map.Entry<String, DepartmentInsight> e : map.entrySet()) {
            DepartmentInsight d = e.getValue();
            double[] s = sums.get(e.getKey());
            if (d.getHeadcount() > 0) {
                d.setAvgProductivity(round1(s[0] / d.getHeadcount()));
                d.setAvgCompletion (round1(s[1] / d.getHeadcount()));
            }
        }
        return new ArrayList<>(map.values());
    }

    private double round1(double v) { return Math.round(v * 10.0) / 10.0; }
    private String fmt1(double v) {
        return v == Math.floor(v) ? String.valueOf((int) v) : String.format("%.1f", v);
    }
}
