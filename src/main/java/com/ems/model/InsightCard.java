package com.ems.model;

/**
 * Lightweight insight card surfaced on the analytics dashboard.
 * Tone drives the colour band: ok / info / warn / err.
 */
public class InsightCard {
    private final String title;
    private final String value;
    private final String detail;
    private final String tone;

    public InsightCard(String title, String value, String detail, String tone) {
        this.title  = title;
        this.value  = value;
        this.detail = detail;
        this.tone   = tone;
    }

    public String getTitle()  { return title; }
    public String getValue()  { return value; }
    public String getDetail() { return detail; }
    public String getTone()   { return tone; }
}
