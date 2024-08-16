#!/bin/bash
apt update -y
apt install openjdk-17-jdk maven git vim curl wget unzip ruby -y
echo "[*] Install AWS CLI"
cd /home/ubuntu
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
echo "[*] Code apply for TEST"
git clone https://github.com/omoknooni/CICD-GithubActions.git
cd CICD-GithubActions/spring-demo
chmod +x mvnw
./mvnw package
# mvn -B package
nohup java -jar target/*.jar 1> ./deploy.log 2>&1 &
mkdir /home/ubuntu/spring-demo
echo "[*] Install CodeDeploy Agent"
cd /home/ubuntu
wget https://aws-codedeploy-ap-northeast-2.s3.ap-northeast-2.amazonaws.com/latest/install
chmod +x ./install
./install auto