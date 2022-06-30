# Automated-Provisioning-Project-2
This Project is to Automate Provisioning of Jenkins, Nexus &amp; SonarQube
## Prerequisite - 3 AWS EC2 Instances
### 1. Jenkins Server 
+   AMI - Ubuntu 20.04 LTS
+   Instance type - t2 small - 1 vCPU - 2 GB Memory
+   Security Group,
    * Allow **port 22**, source: **My IP** - to ssh into jenkins server from My IP
    * Allow **port 8080**, source: **My IP** - to access jenkins on web from My IP
    * Allow **port 80**, source: **SonarQube-Server-IP** - for sonarqube to connect with jenkins for quality check


### 2. Nexus Server 
+   AMI - CentOS7 LTS
+   Instance type - t2 medium - 2 vCPU - 4 GB Memory
+   Security Group,
    * Allow **port 22**, source: **My IP** - to ssh into nexus server from My IP
    * Allow **port 8081**, source: **Jenkins-Security-Group-only** - to access nexus on web from My IP and also for jenkins to access it on command line


### 3. SonarQube Server  
+   AMI - Ubuntu 20.04 LTS
+   Instance type - t2 medium - 2 vCPU - 4 GB Memory
+   Security Group,
    * Allow **port 22**, source: **My IP** - to ssh into sonarqube server from My IP
    * Allow **port 9000**, source: **My IP** - to access sonarqube on web from My IP
    * Allow **port 80**, source: **My IP** - to access sonarqube on web from My IP (this is through ngnix reverse proxy)
