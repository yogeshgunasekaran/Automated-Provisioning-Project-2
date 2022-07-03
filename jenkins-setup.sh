#!/bin/bash
# Install Java
sudo apt update
sudo apt install openjdk-8-jdk -y

# Install the ca-certificates package, a tool which allows SSL-based applications to check for the authenticity of SSL connections
sudo apt install ca-certificates -y

# Install maven, git, wget and unzip
sudo apt install maven git wget unzip -y

# Add the framework repository key
sudo curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Add a Jenkins apt repository entry
sudo echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update local package index, then finally install Jenkins
sudo apt-get update
sudo apt-get install jenkins -y

