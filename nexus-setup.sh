#!/bin/bash

# Install java, wget, rsync 
yum install java-1.8.0-openjdk.x86_64 wget -y   

# Create a directory 'nexus' in '/tmp' and '/opt'
mkdir -p /opt/nexus/   
mkdir -p /tmp/nexus/   

# Cd into '/tmp/nexus' directory                       
cd /tmp/nexus/

# Assign the latest URL of the Nexus Repository Manager from the official website to a variable
NEXUSURL="https://download.sonatype.com/nexus/3/latest-unix.tar.gz"

# Download it using wget as 'nexus.tar.gz'
wget $NEXUSURL -O nexus.tar.gz

# Extract the downloaded tarball with a variable
EXTOUT=`tar xzvf nexus.tar.gz`

# Assign the extracted top level directory name to a variable
NEXUSDIR=`echo $EXTOUT | cut -d '/' -f1`

# Remove the tarball as it is not needed anymore
rm -rf /tmp/nexus/nexus.tar.gz

# Sync all the files in '/tmp/nexus/' to '/opt/nexus/'
rsync -avzh /tmp/nexus/ /opt/nexus/

# Add a system user 'nexus'
useradd nexus

# Set user and group ownership to the '/opt/nexus' directory with user 'nexus'
chown -R nexus.nexus /opt/nexus 

# Create a systemd service file in '/etc/systemd/system/nexus.service' to use systemctl commands
cat <<EOT>> /etc/systemd/system/nexus.service
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
echo 'run_as_user="nexus"' > /opt/nexus/$NEXUSDIR/bin/nexus.rc

# Reload systemctl, start and enable the 'nexus' service
systemctl daemon-reload
systemctl start nexus
systemctl enable nexus
