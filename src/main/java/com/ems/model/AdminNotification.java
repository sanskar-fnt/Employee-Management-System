package com.ems.model;

import java.sql.Timestamp;

public class AdminNotification {

    private long id;
    private String  type;
    private String  severity;     // info | ok | warn | err
    private String  title;
    private String  message;
    private String  href;
    private String  dedupeKey;
    private Timestamp createdAt;
    private Timestamp readAt;

    public long getId()                  { return id; }
    public void setId(long id)           { this.id = id; }

    public String getType()              { return type; }
    public void setType(String v)        { this.type = v; }

    public String getSeverity()          { return severity; }
    public void setSeverity(String v)    { this.severity = v; }

    public String getTitle()             { return title; }
    public void setTitle(String v)       { this.title = v; }

    public String getMessage()           { return message; }
    public void setMessage(String v)     { this.message = v; }

    public String getHref()              { return href; }
    public void setHref(String v)        { this.href = v; }

    public String getDedupeKey()         { return dedupeKey; }
    public void setDedupeKey(String v)   { this.dedupeKey = v; }

    public Timestamp getCreatedAt()      { return createdAt; }
    public void setCreatedAt(Timestamp v){ this.createdAt = v; }

    public Timestamp getReadAt()         { return readAt; }
    public void setReadAt(Timestamp v)   { this.readAt = v; }

    public boolean isUnread()            { return readAt == null; }
}
