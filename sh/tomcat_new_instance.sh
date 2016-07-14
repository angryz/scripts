#!/bin/bash

# Version: 2016-05-18
#
# 1. Give New_Instance
# 2. Run this script
# 3. Modify conf/server.xml

Java_Home=/usr/java/jdk1.8.0_51
Tomcat_Home=/usr/local/tomcat/apache-tomcat-7.0.63
Tomcat_User=tomcat
New_Instance=/usr/local/tomcat/$1
echo "Java_Home="$Java_Home
echo "Tomcat_Home="$Tomcat_Home
echo "New_Instance="$New_Instance

if [ ! -d $New_Instance ];then
  mkdir -p $New_Instance
else
  echo "The parh alreadly exists..."
  exit
fi

id $Tomcat_User 2&> /dev/null && useradd -r $Tomcat_User

cp -r $Tomcat_Home/conf $New_Instance
mkdir -p $New_Instance/{logs,temp,webapps/ROOT,work}

cat > $New_Instance/tomcat.sh << EOF
#!/bin/sh

JAVA_HOME=`echo $Java_Home`
JAVA_OPTS="-Xms1024m -Xmx1024m -XX:+PrintGC -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCApplicationStoppedTime -Xloggc:$New_Instance/logs/gc.log -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=$New_Instance/logs/"
CATALINA_HOME=`echo $Tomcat_Home`
CATALINA_BASE=`echo $New_Instance`
export JAVA_HOME JAVA_OPTS CATALINA_HOME CATALINA_BASE

su `echo $Tomcat_User` \$CATALINA_HOME/bin/catalina.sh \$1
EOF

cat > $New_Instance/webapps/ROOT/index.jsp << EOF
<html><body><center>
<h1>This is a new tomcat instance!</h1></br>
Now time is: <%=new java.util.Date()%>
</center></body></html>
EOF

chown $Tomcat_User:$Tomcat_User -R $New_Instance
chmod ug+x $New_Instance/tomcat.sh
