package com.ems.model;

import java.time.LocalDateTime;

public class ActivityItem {
    private final String type;
    private final String tone;
    private final String title;
    private final String detail;
    private final LocalDateTime when;

    public ActivityItem(String type, String tone, String title, String detail, LocalDateTime when) {
        this.type = type;
        this.tone = tone;
        this.title = title;
        this.detail = detail;
        this.when = when;
    }

    public String getType()   { return type; }
    public String getTone()   { return tone; }
    public String getTitle()  { return title; }
    public String getDetail() { return detail; }
    public LocalDateTime getWhen() { return when; }
}
