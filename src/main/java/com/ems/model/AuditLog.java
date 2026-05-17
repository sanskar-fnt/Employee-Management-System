package com.ems.model;

import java.sql.Timestamp;

public class AuditLog {

    private long id;
    private Integer actorUserId;
    private String  actorUsername;   // joined for display, may be null
    private String  action;
    private String  entityType;
    private Integer entityId;
    private String  details;
    private Timestamp createdAt;

    public long getId()                    { return id; }
    public void setId(long id)             { this.id = id; }

    public Integer getActorUserId()        { return actorUserId; }
    public void setActorUserId(Integer v)  { this.actorUserId = v; }

    public String getActorUsername()       { return actorUsername; }
    public void setActorUsername(String v) { this.actorUsername = v; }

    public String getAction()              { return action; }
    public void setAction(String v)        { this.action = v; }

    public String getEntityType()          { return entityType; }
    public void setEntityType(String v)    { this.entityType = v; }

    public Integer getEntityId()           { return entityId; }
    public void setEntityId(Integer v)     { this.entityId = v; }

    public String getDetails()             { return details; }
    public void setDetails(String v)       { this.details = v; }

    public Timestamp getCreatedAt()        { return createdAt; }
    public void setCreatedAt(Timestamp v)  { this.createdAt = v; }
}
