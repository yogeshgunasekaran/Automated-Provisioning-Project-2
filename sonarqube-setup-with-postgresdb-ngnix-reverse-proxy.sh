#!/bin/bash

# Modify Kernel System Limits
# Take a backup of the default sysctl configuration file
cp /etc/sysctl.conf /root/sysctl.conf_backup

# Set the system defaults
cat <<EOT> /etc/sysctl.conf
vm.max_map_count=262144
fs.file-max=65536
ulimit -n 65536
ulimit -u 4096
EOT

# Take a backup of the default sysctl configuration file
cp /etc/security/limits.conf /root/sec_limit.conf_backup

# Set resource limits for sonarqube' database
cat <<EOT> /etc/security/limits.conf
sonarqube   -   nofile   65536
sonarqube   -   nproc    409
EOT

# Refresh server’s local package index
sudo apt update -y

# Install OpenJDK 11
sudo apt install openjdk-11-jdk -y

# Update the alternatives config for JRE/JDK installations
sudo update-alternatives --config java
java -version

# Add the PostgreSQL signing key
sudo wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -

# Add the PostgreSQL repository
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'

# Install PostgreSQL with additional extensions & utilities
sudo apt install postgresql postgresql-contrib -y

# Enable and Start the database server
sudo systemctl enable postgresql.service
sudo systemctl start  postgresql.service

# Set password for user 'postgres' with passwd 'admin123'
sudo echo "postgres:admin123" | chpasswd

# Create a user 'sonar' in postgres database 
# runuser = run a command with substitute user and group ID
# -l = login ; -c = command
runuser -l postgres -c "createuser sonar"

# Set a password for the sonar user. Use a strong password in place of 'admin123'
sudo -i -u postgres psql -c "ALTER USER sonar WITH ENCRYPTED PASSWORD 'admin123';"

# Create a database 'sonarqube' with its owner as 'sonar' user
sudo -i -u postgres psql -c "CREATE DATABASE sonarqube OWNER sonar;"

# Grant 'sonar' user full control over a 'sonarqube' database
sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE sonarqube to sonar;"

# Restart the 'postgresql' database server
systemctl restart  postgresql

# Create 'sonarqube' directory and cd into it
sudo mkdir -p /sonarqube/
cd /sonarqube/

# Download SonarQube
sudo curl -O https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-8.3.0.34182.zip

# Install zip & unzip and extract the downloaded zip file in /opt/ directory
sudo apt-get install zip unzip -y
sudo unzip -o sonarqube-8.3.0.34182.zip -d /opt/

# Rename the unzipped file as sonarqube
sudo mv /opt/sonarqube-8.3.0.34182/ /opt/sonarqube

# Create a group 'sonar'
sudo groupadd sonar

# Create a user 'sonar' and set '/opt/sonarqube' as the home directory and group as 'sonar'
# -c = comment ; -d = home directory ; -g = group
sudo useradd -c "SonarQube - User" -d /opt/sonarqube/ -g sonar sonar

# Grant the 'sonar' user access to the '/opt/sonarqube directory'
sudo chown sonar:sonar /opt/sonarqube/ -R

# Copy the default SonarQube Configuration file to '/root' (root home directory) as a backup
cp /opt/sonarqube/conf/sonar.properties /root/sonar.properties_backup

# Now update the SonarQube configuration with the following lines
cat <<EOT>> /opt/sonarqube/conf/sonar.properties
sonar.jdbc.username=sonar
sonar.jdbc.password=admin123
sonar.jdbc.url=jdbc:postgresql://localhost/sonarqube
sonar.web.host=0.0.0.0
sonar.web.port=9000
sonar.web.javaAdditionalOpts=-server
sonar.search.javaOpts=-Xmx512m -Xms512m -XX:+HeapDumpOnOutOfMemoryError
sonar.log.level=INFO
sonar.path.logs=logs
EOT

# Setup Systemd service for SonarQube service
cat <<EOT>> /etc/systemd/system/sonarqube.service
[Unit]
Description=SonarQube service
After=syslog.target network.target
[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonar
Group=sonar
Restart=always
LimitNOFILE=65536
LimitNPROC=4096
[Install]
WantedBy=multi-user.target
EOT

# Enable the SonarQube service to run at system startup
systemctl daemon-reload
systemctl enable sonarqube.service

# Install Ngnix server
# Ngnix server is installed to act as a reverse proxy server to sonarqube 
# Ngnix service listen on port 80 and route the requests to sonarqube in localhost on port 9000
# This allows in the integration of nexus to sonarqube through port 80
apt-get install nginx -y

# Remove the default Nginx config files
rm -rf /etc/nginx/sites-enabled/default
rm -rf /etc/nginx/sites-available/default

# Configure ngnix to listen on port 80 and route the request to sonarqube on port 9000 locally by adding the following lines
cat <<EOT>> /etc/nginx/sites-available/sonarqube
server{
    listen      80;
    server_name sonarqube.groophy.in;
    access_log  /var/log/nginx/sonar.access.log;
    error_log   /var/log/nginx/sonar.error.log;
    proxy_buffers 16 64k;
    proxy_buffer_size 128k;
    location / {
        proxy_pass  http://127.0.0.1:9000;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_redirect off;
              
        proxy_set_header    Host            \$host;
        proxy_set_header    X-Real-IP       \$remote_addr;
        proxy_set_header    X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header    X-Forwarded-Proto http;
    }
}
EOT

# Create Symbolic link to activate the ngnix proxy server
ln -s /etc/nginx/sites-available/sonarqube /etc/nginx/sites-enabled/sonarqube

# Enable ngnix to start at runtime
systemctl enable nginx.service

# Allow the following ports in Ubuntu firewall and reboot system
sudo ufw allow 80,9000,9001/tcp
echo "System reboot in 30 sec"
sleep 30
reboot