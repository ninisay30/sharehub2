# alwaysdata Deployment Checklist

This checklist is for deploying ShareHub as a JSP/Servlet/Tomcat/MySQL application on alwaysdata.

## 1. Create MySQL Database

In alwaysdata admin:

1. Open Databases > MySQL.
2. Create a database.
3. Create or note the database user and password.
4. Note the host, usually:

```text
mysql-[account].alwaysdata.net
```

The JDBC URL should look like:

```text
jdbc:mysql://mysql-[account].alwaysdata.net:3306/[database_name]?useSSL=false&serverTimezone=UTC
```

## 2. Import Database

Export the local ShareHub database from phpMyAdmin or MySQL Workbench, then import it into the alwaysdata database.

Also run the module SQL files in `database/` if they are not already included in the export.

## 3. Create Upload Folder

Create a persistent upload directory in the alwaysdata account, for example:

```text
/home/[account]/sharehub_uploads
```

Set this value as `SHAREHUB_UPLOAD_DIR`.

## 4. Configure Environment Variables

Set these variables in the Java site configuration:

```text
SHAREHUB_DB_URL=jdbc:mysql://mysql-[account].alwaysdata.net:3306/[database_name]?useSSL=false&serverTimezone=UTC
SHAREHUB_DB_USER=[database_user]
SHAREHUB_DB_PASSWORD=[database_password]
SHAREHUB_UPLOAD_DIR=/home/[account]/sharehub_uploads

SHAREHUB_SMTP_HOST=smtp.gmail.com
SHAREHUB_SMTP_PORT=587
SHAREHUB_SMTP_USER=[gmail_address]
SHAREHUB_SMTP_APP_PASSWORD=[gmail_app_password]
SHAREHUB_SMTP_FROM=[gmail_address]
SHAREHUB_SMTP_FROM_NAME=ShareHub
```

Do not commit real passwords to GitHub.

## 5. Build WAR

From the project root, build or prepare:

```text
dist/sharehub2.war
```

The WAR should not include runtime uploaded images. Upload images belong in `SHAREHUB_UPLOAD_DIR`.

## 6. Create Java Site

In alwaysdata admin:

1. Open Web > Sites.
2. Add a site.
3. Choose Java.
4. Set the application path to the uploaded `sharehub2.war`.
5. Add the environment variables.
6. Restart the site.

## 7. Test

Test these flows after deployment:

1. Register.
2. Login.
3. Donate item with photo upload.
4. Admin approve donation.
5. Request item.
6. Admin approve request.
7. Schedule pickup.
8. Confirm received and handover.
9. Send forgot-password email.
10. Generate monthly report.
11. Run Donation Aging Check from Admin Dashboard.

## Troubleshooting

- Database connection failed: check `SHAREHUB_DB_URL`, user, password, and database permissions.
- Images upload but do not show: check `SHAREHUB_UPLOAD_DIR` and folder permissions.
- Email not sending: check Gmail app password and SMTP environment variables.
- 404 after deploy: check site path/context path and whether the WAR was uploaded correctly.
- 500 error: check alwaysdata site logs for the Java/Tomcat stack trace.
