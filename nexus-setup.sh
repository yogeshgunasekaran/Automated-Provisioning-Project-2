#!/bin/bash

# Refresh server’s local package index
sudo yum update -y

# Install java, wget, rsync 
sudo yum install java-1.8.0-openjdk.x86_64 wget rsync -y   

# Create a directory 'nexus' in '/tmp' and '/opt'
sudo mkdir -p /opt/nexus/   
sudo mkdir -p /tmp/nexus/   

# Cd into '/tmp/nexus' directory                       
sudo cd /tmp/nexus/

# Assign the latest URL of the Nexus Repository Manager from the official website to a variable
NEXUSURL="https://download.sonatype.com/nexus/3/latest-unix.tar.gz"

# Download it using wget as 'nexus.tar.gz'
sudo wget $NEXUSURL -O nexus.tar.gz

# Extract the downloaded tarball with a variable
EXTOUT=`tar xzvf nexus.tar.gz`

# Assign the extracted top level directory name to a variable
NEXUSDIR=`echo $EXTOUT | cut -d '/' -f1`

# Remove the tarball as it is not needed anymore
sudo rm -rf /tmp/nexus/nexus.tar.gz

# Sync all the files in '/tmp/nexus/' to '/opt/nexus/'
sudo rsync -avzh /tmp/nexus/ /opt/nexus/

# Add a system user 'nexus'
sudo useradd nexus

# Set user and group ownership to the '/opt/nexus' directory with user 'nexus'
sudo chown -R nexus.nexus /opt/nexus 

# Create a systemd service file in '/etc/systemd/system/nexus.service' to use systemctl commands
sudo cat <<EOT>> /etc/systemd/system/nexus.service
[Unit]                                                                          
Description=nexus service                                                       
After=network.target                                                            
                                                                  
[Service]                                                                       
Type=forking                                                                    
LimitNOFILE=65536                                                               
ExecStart=/opt/nexus/$NEXUSDIR/bin/nexus start                                  
ExecStop=/opt/nexus/$NEXUSDIR/bin/nexus stop                                    
User=nexus                                                                      
Restart=on-abort                                                                
                                                                  
[Install]                                                                       
WantedBy=multi-user.target                                                      

EOT

# Add the following line in nexus.rc
sudo echo 'run_as_user="nexus"' > /opt/nexus/$NEXUSDIR/bin/nexus.rc

# Reload systemctl, start and enable the 'nexus' service
sudo systemctl daemon-reload
sudo systemctl start nexus
sudo systemctl enable nexus
