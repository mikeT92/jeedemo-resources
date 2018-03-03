rem setup-glassfish-domain.cmd
rem --------------------------------------------------------------------------
rem Creates a new glassfish server domain (i.e. instance) in the specified 
rem domain folder with the specified domain name starting with the given
rem port base.
rem --------------------------------------------------------------------------
rem @echo off
setlocal

set GLASSFISH_DOMAIN_ROOT=z:\data\glassfish\domains
set GLASSFISH_DEFAULT_DOMAIN_NAME=GFFP50_JEEDEMO_DEV
set GLASSFISH_DOMAIN_NAME=%1

rem use default domain name if no one is given
if not defined GLASSFISH_DOMAIN_NAME (
	set GLASSFISH_DOMAIN_NAME=%GLASSFISH_DEFAULT_DOMAIN_NAME%
)
 
set GLASSFISH_DOMAIN_PATH=%GLASSFISH_DOMAIN_ROOT%\%GLASSFISH_DOMAIN_NAME%

rem check if domain exists
if not exist "%GLASSFISH_DOMAIN_PATH%" goto create
echo "glassfish domain %GLASSFISH_DOMAIN_PATH% already exists"
set /p choice="delete? (y/n)"
if "%choice%" == "y" rmdir /s /q %GLASSFISH_DOMAIN_PATH%

:create
call asadmin create-domain --domaindir %GLASSFISH_DOMAIN_ROOT% --portbase 8000 --checkports true --nopassword %GLASSFISH_DOMAIN_NAME%

rem copy drivers etc to glassfish lib folder
copy z:\tools\lib\jdbc\mysql*.jar %GLASSFISH_DOMAIN_PATH%\lib

rem start glassfish domain to setup server instance
call asadmin start-domain --domaindir %GLASSFISH_DOMAIN_ROOT% %GLASSFISH_DOMAIN_NAME%

rem create database resources
call asadmin --port 8048 create-jdbc-connection-pool --datasourceclassname com.mysql.jdbc.jdbc2.optional.MysqlDataSource --restype javax.sql.DataSource --ping --wrapjdbcobjects true --isolationlevel read-committed --property portNumber=3306:password=fwpss2018:user=jeedemo:serverName=192.168.99.100:databaseName=jeedemo_db JEEDEMO_POOL
call asadmin --port 8048 create-jdbc-resource --connectionpoolid JEEDEMO_POOL jdbc/JEEDEMO_DATASOURCE

rem enable default principal to role mapping
call asadmin --port 8048 set configs.config.server-config.security-service.activate-default-principal-to-role-mapping=true

rem create custom file realm 
call asadmin --port 8048 create-auth-realm --classname com.sun.enterprise.security.auth.realm.file.FileRealm --property file=${com.sun.aas.instanceRoot}/config/jeedemoKeyFile:jaas-context=fileRealm JEEDEMO_REALM

rem create file realm user for component tests
call asadmin --port 8048 --passwordfile .\fwparqln-password.txt create-file-user --groups JEEDEMO_USER:JEEDEMO_ADMIN --authrealmname JEEDEMO_REALM fwparqln

rem create file realm users for demos
call asadmin --port 8048 --passwordfile .\fwpdemo-password.txt create-file-user --groups JEEDEMO_USER:JEEDEMO_ADMIN --authrealmname JEEDEMO_REALM fwpdemo

call asadmin --port 8048 stop-domain --domaindir %GLASSFISH_DOMAIN_ROOT% %GLASSFISH_DOMAIN_NAME%
endlocal