package com.ems.model;

public class Notification {

    private final String id;
    private final String type;
    private final String severity;
    private final String title;
    private final String message;
    private final String href;

    public Notification(String id, String type, String severity, String title, String message, String href) {
        this.id = id;
        this.type = type;
        this.severity = severity;
        this.title = title;
        this.message = message;
        this.href = href;
    }

    public String getId() { return id; }
    public String getType() { return type; }
    public String getSeverity() { return severity; }
    public String getTitle() { return title; }
    public String getMessage() { return message; }
    public String getHref() { return href; }
}
