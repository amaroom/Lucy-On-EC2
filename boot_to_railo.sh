#!/bin/bash

# This boot script will install Railo 4.0.4 in a server configuration on an Amazon
# EC2 Amazon Linux instance. To use this script, start your preferred method of 
# launching a new Amazon Linux instance. Make sure to add this line to the 
# "User Data" section of your command or launch screen.
#
#      #include
#      https://raw.github.com/amaroom/railo-ec2/master/boot_to_railo.sh
# 
# You could also copy the script to your own repo or instance available path.
# The new instance will book and install Tomcat and Railo, ready to run. Just drop your 
# code in /usr/share/tomcat7/webapps/ROOT or drop a WAR file in webapps. 
#
# Git is also installed, so you can add your own script on a new line in the "#Include"
# block to pull code, or do anything else you'd like.
#
# Be sure to check this repos wiki for more information and changes as they come in.
#
# '@Amaroom'

yum -y update

# install Tomcat and git
yum -y install tomcat8 tomcat-native git

# set Tomcat service to start on reboot
chkconfig tomcat8 on

# Railo jars will live in the lib of Tomcat
mkdir /usr/share/tomcat8/lucee

# Download the Railo jars to a temp folder and expand. This path can be changed to any 
# other paths as needed. 
wget -O /tmp/lucee.zip "https://bitbucket.org/lucee/lucee/downloads/lucee-4.5.2.018-jars.zip"
unzip /tmp/lucee.zip -d /tmp/lucee

# Place the jars in our new tomcat lib sub-folder.
mv -t /usr/share/tomcat8/lucee/ /tmp/lucee/*
chown -R tomcat.tomcat /usr/share/tomcat8/lucee/

# For tomcat to find the Jars, we need to include their path in the common loader path.
cp /etc/tomcat8/catalina.properties  /etc/tomcat8/catalina.orig
sed -i 's|common.loader=\([^ ]*\)|common.loader=\1,"${catalina.home}/lucee/*.jar"|' /etc/tomcat8/catalina.properties

# Web.xml
# For the Lucee servlet to be available to your files, and for tomcat to know that
# the file extensions "cfm,cfml,cfc" should go through the Railo servlet, we need to 
# include the Railo servlet definition and it's mapping to Web.xml.
# Here, we are adding to Tomcat's top level Web.xml file, which is global. Any WAR or
# app folders you place on the server will service files for Lucee ColdFusion.
# 
# Optionally, you may want to only include the servlet declarations in your projects own 
# Web.xml file. This gives you control over which apps on this Tomcat instance service
# CF calls, or not. By setting it here in the global Web.xml, all apps will service CF.
#
# Web.xml: add railo servlet
cp /etc/tomcat8/web.xml  /etc/tomcat8/web.xml.orig
sed -i '365a\
<!-- ===================================================================== -->\
<!-- Lucee CFML Servlet - this is the main Lucee servlet                   -->\
<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->\
<servlet id="Lucee">\
<description>Lucee Engine</description>\
<servlet-name>CFMLServlet</servlet-name>\
<servlet-class>lucee.loader.servlet.CFMLServlet</servlet-class>\
<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->\
<!-- to specify the location of the Lucee Server config and libraries,   -->\
<!-- uncomment the init-param below.  make sure that the param-value     -->\
<!-- points to a valid folder, and that the process that runs Lucee has  -->\
<!-- write permissions to that folder.  leave commented for defaults.    -->\
<!--\
<init-param>\
<param-name>lucee-server-directory</param-name>\
<param-value>/var/Lucee/config/server/</param-value>\
<description>Lucee Server configuration directory (for Server-wide configurations, settings, and libraries)</description>\
</init-param>\
!-->\
<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->\
<!-- to specify the location of the Web Contexts'' config and libraries,  -->\
<!-- uncomment the init-param below.  make sure that the param-value     -->\
<!-- points to a valid folder, and that the process that runs Lucee has  -->\
<!-- write permissions to that folder.  the {web-context-label} can be   -->\
<!-- set in Lucee Server Admin homepage.  leave commented for defaults.  -->\
<!--\
<init-param>\
<param-name>lucee-web-directory</param-name>\
<param-value>/var/Lucee/config/web/{web-context-label}/</param-value>\
<description>Lucee Web Directory (for Website-specific configurations, settings, and libraries)</description>\
</init-param>\
!-->\
<load-on-startup>6</load-on-startup>\
</servlet>\
\
<!-- ===================================================================== -->\
<!-- Lucee REST Servlet - handles Lucee''s RESTful web services             -->\
<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->\
<servlet id="RESTServlet">\
<description>Lucee Servlet for RESTful services</description>\
<servlet-name>RESTServlet</servlet-name>\
<servlet-class>lucee.loader.servlet.RestServlet</servlet-class>\
<load-on-startup>7</load-on-startup>\
</servlet>\
\
\
' /etc/tomcat8/web.xml

# Web.xml: add servlet mapping
sed -i '451a\
<servlet-mapping>\
<servlet-name>CFMLServlet</servlet-name>\
<url-pattern>*.cfc</url-pattern>\
<url-pattern>*.cfm</url-pattern>\
<url-pattern>*.cfml</url-pattern>\
<url-pattern>/index.cfc/*</url-pattern>\
<url-pattern>/index.cfm/*</url-pattern>\
<url-pattern>/index.cfml/*</url-pattern>\
\
<!-- url-pattern>*.cfm/*</url-pattern !-->\
<!-- url-pattern>*.cfml/*</url-pattern !-->\
<!-- url-pattern>*.cfc/*</url-pattern !-->\
<!-- url-pattern>*.htm</url-pattern !-->\
<!-- url-pattern>*.jsp</url-pattern !-->\
</servlet-mapping>\
\
<servlet-mapping>\
<servlet-name>RESTServlet</servlet-name>\
<url-pattern>/rest/*</url-pattern>\
</servlet-mapping>\
\
' /etc/tomcat8/web.xml

# Web.xml: add welcome files for CF
sed -i 's|<welcome-file-list>|<welcome-file-list> \
        <welcome-file>index.cfm</welcome-file>\
        <welcome-file>index.cfml</welcome-file>\
|' /etc/tomcat8/web.xml


# Lets build a basic "hello world" cfm page to get things started.
mkdir /usr/share/tomcat8/webapps/ROOT

bash -c 'cat > /usr/share/tomcat8/webapps/ROOT/index.cfm' <<EOF
<html>
<head><title>Hello</title></head>
<body>
<h4>Hello.</h4>
<p>Git installed.</p>
<p>Ready for WAR files or git deployment.</p>
<p><cfoutput>#timeformat(now())#</cfoutput></p>
</body>
</html>
EOF

chown -R tomcat.tomcat /usr/share/tomcat8/webapps/ROOT/

# Restart server
shutdown -r now

# Done. From here you can write your own scripts to copy Wars, or copy code.
# Don't forget to log into the Railo manager and change the default passwords.
