#!/bin/bash

# Install Docker and Artifactory OSS on Ubuntu
set -e

# Update package index
apt-get update -y

# Install required packages
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
apt-get update -y

# Install Docker
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Create directory for Artifactory data
mkdir -p /opt/artifactory/data
chown -R 1030:1030 /opt/artifactory/data

# Create docker-compose file for Artifactory
cat <<EOF > /opt/artifactory/docker-compose.yml
version: '3.8'
services:
  artifactory:
    image: docker.bintray.io/jfrog/artifactory-oss:latest
    container_name: artifactory
    restart: unless-stopped
    ports:
      - "8082:8082"
      - "8081:8081"
    volumes:
      - /opt/artifactory/data:/var/opt/jfrog/artifactory
    environment:
      - JF_SHARED_DATABASE_TYPE=derby
    ulimits:
      nproc: 65535
      nofile:
        soft: 32000
        hard: 40000
EOF

# Start Artifactory using docker-compose
cd /opt/artifactory
docker-compose up -d

# Wait for Artifactory to start
echo "Waiting for Artifactory to start..."
sleep 60

# Create a systemd service for Artifactory
cat <<EOF > /etc/systemd/system/artifactory.service
[Unit]
Description=Artifactory Docker Compose Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/artifactory
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl enable artifactory.service
systemctl start artifactory.service

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install jq for JSON processing
apt-get install -y jq

# Create sample container image build script
cat <<'EOF' > /home/ubuntu/build-sample-image.sh
#!/bin/bash

# Build a simple sample container image for testing
mkdir -p /tmp/sample-app
cd /tmp/sample-app

# Create a simple Dockerfile
cat <<DOCKER > Dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY . /app
EXPOSE 80
CMD ["python", "-c", "print('Hello from Contoso Lab Container!'); import time; time.sleep(3600)"]
DOCKER

# Create a dummy application file
echo "print('Sample ML model placeholder')" > app.py

# Build the image
docker build -t localhost:8082/contoso-lab/sample-ml-model:latest .

echo "Sample container image built successfully!"
echo "To push to Artifactory, run: docker push localhost:8082/contoso-lab/sample-ml-model:latest"
EOF

chmod +x /home/ubuntu/build-sample-image.sh
chown ubuntu:ubuntu /home/ubuntu/build-sample-image.sh

echo "Artifactory installation completed!"
echo "Access Artifactory at: http://$(hostname -I | cut -d' ' -f1):8082"
echo "Default credentials: admin/password"