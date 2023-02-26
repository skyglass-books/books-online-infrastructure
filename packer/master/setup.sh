#!/bin/bash

# Install Updated packages on linux machine
yum update –y
yum install -y wget
wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
yum upgrade
#yum install jenkins java-1.8.0-openjdk-devel -y
yum install git -y
wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo
sed -i s/\$releasever/6/g /etc/yum.repos.d/epel-apache-maven.repo
yum install -y apache-maven

echo "Install AWS CLI"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" 
yum install unzip
unzip awscliv2.zip  
./aws/install

echo "Install kubectl"
curl -o kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.23.7/2022-06-29/bin/linux/amd64/kubectl
chmod +x ./kubectl
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$PATH:$HOME/bin
cp kubectl /usr/local/bin/

echo "Install Helm 3.8.2 (compatible with kubernetes 1.23)"
curl -L https://git.io/get_helm.sh | bash -s -- --version v3.8.2

yum install jenkins -y
chkconfig jenkins on

echo "Setup SSH key"
mkdir /var/lib/jenkins/.ssh
touch /var/lib/jenkins/.ssh/known_hosts
chown -R jenkins:jenkins /var/lib/jenkins/.ssh
chmod 700 /var/lib/jenkins/.ssh
mv /tmp/id_rsa /var/lib/jenkins/.ssh/id_rsa
chmod 600 /var/lib/jenkins/.ssh/id_rsa
chown -R jenkins:jenkins /var/lib/jenkins/.ssh/id_rsa

echo "Configure Jenkins"
mkdir -p /var/lib/jenkins/init.groovy.d
mv /tmp/scripts/*.groovy /var/lib/jenkins/init.groovy.d/
chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d
mv /tmp/config/jenkins /etc/sysconfig/jenkins
chmod +x /tmp/config/install-plugins.sh
bash /tmp/config/install-plugins.sh

systemctl daemon-reload
systemctl start jenkins
systemctl status jenkins

echo "Install Docker engine"
yum install docker -y
systemctl daemon-reload
systemctl restart docker
systemctl enable docker
usermod -a -G docker jenkins
# chmod 777 /var/run/docker.sock
