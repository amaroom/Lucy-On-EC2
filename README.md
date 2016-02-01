Launch Lucee in EC2 in one step
=====

So, you want to launch a new server instance in Amazon AWS's EC2 service on linux. The script in this repo will install and configure Lucee for you automatically. 

## Install

### Using the Amazon Console

- Click on _Launch Instance_ and select a new Amazon Linux AMI, then select an instance type.
- In the _Configure Instance Details_ section, expand the _Advanced Details_ section. Paste the following text in the __user data__ text box:

	```
	#include
	https://raw.githubusercontent.com/amaroom/Lucy-On-EC2/master/boot_to_lucee.sh
	```

- Complete the rest of the startup options.

That's it. Your new Linux instance will launch and install Tomcat8 and Lucee. After a few minute you can browse to `http://<server-ip>:8080/` to see a welcome page. From this point, you can use git to bring in your ColdFusion code, or drop a WAR file with your CF code ( in the path `/usr/share/tomcat8/webapps` ), or just add files to the ROOT folder. 

If you're using the **AWS CLI**, can pass this with the `--user-data` argument.

### What it does

This script does the following:

- Update the instance with the latest patches.
- Installs Tomcat 8, Tomcat Native Libraries and GIT.
- Downloads Lucee Jars and places them in the Tomcat folder. (Lucee 4.5.2.018)
- Modifies `catalina.properties` to add the Lucee jars to the _common loader_ path.
- Modifies the global Tomcat Web.xml file to include the Lucee Servlet's and their mappings. 
- Generate's simple "Hello" `index.cfm` file and places it in the ROOT web context.
- Sets proper permissions on files and folders.
- Sets Tomcat 8 to start on boot as a service.
- Reboots instance when it's done.