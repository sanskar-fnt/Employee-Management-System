# EMS (Jakarta Servlet)

This project targets Apache Tomcat 10.1+ (Jakarta EE 9/10 namespace).

## Requirements
- JDK 17+ (matching your Tomcat 10.1 setup)
- MySQL 8.x
- Apache Tomcat 10.1+

## Database setup
Run the SQL script:
```
mysql -u root -p < setup.sql
```

## Deploy on Tomcat (Eclipse)
1. Add the project to your Tomcat 10.1 server in Eclipse.
2. Ensure `WEB-INF/lib` contains:
   - `jakarta.servlet.jsp.jstl-api-2.0.0.jar`
   - `jakarta.servlet.jsp.jstl-2.0.0.jar`
   - MySQL Connector/J jar
3. Start Tomcat and open:
   `http://localhost:8080/ems/login`

Default login from `setup.sql`:
- Username: admin
- Password: admin
