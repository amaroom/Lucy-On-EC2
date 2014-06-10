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

# install Tomcat and git
yum -y install tomcat7 tomcat-native git

# set Tomcat service to start on reboot
chkconfig tomcat7 on

# Railo jars will live in the lib of Tomcat
mkdir /usr/share/tomcat7/lib/railo4

# Download the Railo jars to a temp folder and expand. This path can be changed to any 
# other paths as needed. 
curl -silent http://www.getrailo.org/railo/remote/download/4.0.4.001/custom/all/railo-4.0.4.001-jars.zip -o /tmp/railo.zip
unzip /tmp/railo.zip -d /tmp/railo4

# Place the jars in our new tomcat lib sub-folder.
mv -t /usr/share/tomcat7/lib/railo4/ /tmp/railo4/railo-4.0.4.001-jars/*
chown -R tomcat.tomcat /usr/share/tomcat7/lib/railo4/

# For tomcat to find the Jars, we need to include their path in the common loader path.
cp /etc/tomcat7/catalina.properties  /etc/tomcat7/catalina.orig
sed -i 's|common.loader=\([^ ]*\)|common.loader=\1,${catalina.home}/lib/railo4,${catalina.home}/lib/railo4/*.jar|' /etc/tomcat7/catalina.properties

# Web.xml
# For the Railo servlet to be available to your files, and for tomcat to know that
# the file extensions "cfm,cfml,cfc" should go through the Railo servlet, we need to 
# include the Railo servlet definition and it's mapping to Web.xml.
# Here, we are adding to Tomcat's top level Web.xml file, which is global. Any WAR or
# app folders you place on the server will service files for Railo ColdFusion. 
# 
# Optionally, you may want to only include the servlet declarations in your projects own 
# Web.xml file. This gives you control over which apps on this Tomcat instance service
# CF calls, or not. By setting it here in the global Web.xml, all apps will service CF.
#
# Web.xml: add railo servlet
sed -i '348a\
\
\
  <!-- ===================================================================  -->\
  <!-- Invoke the Railo Servlet                                             -->\
  <!-- ===================================================================  -->\
\
  <servlet>\
    <servlet-name>GlobalCFMLServlet</servlet-name>\
    <description>CFML runtime Engine</description>\
    <servlet-class>railo.loader.servlet.CFMLServlet</servlet-class>\
    <init-param>\
        <param-name>configuration</param-name>\
        <param-value>/WEB-INF/railo/</param-value>\
        <description>Configuraton directory</description>\
    </init-param>   \
    <load-on-startup>4</load-on-startup>\
  </servlet>\
  <!-- <servlet>\
    <servlet-name>GlobalAMFServlet</servlet-name>\
    <description>AMF Servlet for flash remoting</description>\
    <servlet-class>railo.loader.servlet.AMFServlet</servlet-class>\
    <load-on-startup>4</load-on-startup>\
  </servlet> -->\
\
\
' /etc/tomcat7/web.xml

# Web.xml: add servlet mapping
sed -i '413a\
\
  <!-- The mapping for the Railo servlet -->\
  <servlet-mapping>\
    <servlet-name>GlobalCFMLServlet</servlet-name>\
    <url-pattern>*.cfm</url-pattern>\
  </servlet-mapping>\
  <servlet-mapping>\
    <servlet-name>GlobalCFMLServlet</servlet-name>\
    <url-pattern>/index.cfm/*</url-pattern>\
  </servlet-mapping>\
  <servlet-mapping>\
    <servlet-name>GlobalCFMLServlet</servlet-name>\
    <url-pattern>*.cfml</url-pattern>\
  </servlet-mapping>\
  <servlet-mapping>\
    <servlet-name>GlobalCFMLServlet</servlet-name>\
    <url-pattern>*.cfc</url-pattern>\
  </servlet-mapping>\
  <!-- <servlet-mapping>\
    <servlet-name>GlobalAMFServlet</servlet-name>\
    <url-pattern>/flashservices/gateway/*</url-pattern>\
  </servlet-mapping> -->\
\
' /etc/tomcat7/web.xml

# Web.xml: add welcome files for CF
sed -i 's|</welcome-file-list>|    <welcome-file>index.cfm</welcome-file>\
        <welcome-file>index.cfml</welcome-file>\
    </welcome-file-list>|' /etc/tomcat7/web.xml


# Lets build a basic "hello world" cfm page to get things started.
mkdir /usr/share/tomcat7/webapps/ROOT

bash -c 'cat > /usr/share/tomcat7/webapps/ROOT/index.cfm' <<EOF
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

chown -R tomcat.tomcat /usr/share/tomcat7/webapps/ROOT/

# Start Tomcat
service tomcat7 start

# Done. From here you can write your own scripts to copy Wars, or copy code.
# Don't forget to log into the Railo manager and change the default passwords.
