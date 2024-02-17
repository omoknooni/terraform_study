#!/bin/bash
echo "[*] Install Tomcat"
apt update
apt upgrade -y

echo "[*] Download Tomcat"
wget "https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.85/bin/apache-tomcat-9.0.85.tar.gz"
tar -xvf apache-tomcat-9.0.85.tar.gz
mv apache-tomcat-9.0.85 /opt/tomcat
rm apache-tomcat-9.0.85.tar.gz

cd /opt/tomcat
echo "[*] Start Tomcat"
./bin/startup.sh