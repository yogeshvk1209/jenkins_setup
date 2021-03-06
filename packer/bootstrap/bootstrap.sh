#!/bin/sh
set -x
echo "Enabling and Changing Docker permissions"
systemctl enable docker
groupadd docker
usermod -a -G docker ec2-user
echo "Modifying /etc/docker/daemon.json for dockerroot for centos user"
echo > /etc/docker/daemon.json
tee -a /etc/docker/daemon.json > /dev/null <<EOT
{
    "live-restore": true,
    "group": "docker"
}
EOT
systemctl restart docker
chown -R 1000:1000 /var/run/docker.sock

## Creating Docker images for master and slave jenkins
echo "Downloading Files from git"
cd /opt/bootstrap/
wget --no-check-certificate --content-disposition -O /opt/bootstrap/master/Dockerfile  https://raw.githubusercontent.com/yogeshvk1209/jenkins_setup/master/packer/bootstrap/master/Dockerfile
wget --no-check-certificate --content-disposition -O /opt/bootstrap/master/plugins.txt https://raw.githubusercontent.com/yogeshvk1209/jenkins_setup/master/packer/bootstrap/master/plugins.txt
wget --no-check-certificate --content-disposition -O /opt/bootstrap/master/security.groovy https://raw.githubusercontent.com/yogeshvk1209/jenkins_setup/master/packer/bootstrap/master/security.groovy
wget --no-check-certificate --content-disposition -O /opt/bootstrap/slave/Dockerfile  https://raw.githubusercontent.com/yogeshvk1209/jenkins_setup/master/packer/bootstrap/slave/Dockerfile

echo "Building jenkins master Docker Image"
docker build -t jenkins-master /opt/bootstrap/master/

sleep 10
echo "Running Jenkins Docker container"
docker run --name jenkins-master -d -p 8080:8080 -p 9080:9080 -v jenkins_data:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock jenkins-master

echo "Building jenkins slave Docker Image"
docker build -t jenkins-slave /opt/bootstrap/slave/
