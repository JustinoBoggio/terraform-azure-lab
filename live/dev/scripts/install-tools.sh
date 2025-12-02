#!/bin/bash
# Update and install basic dependencies
apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release unzip

# ---------------------------------------------------------
# 1. Install Docker (Required for building container images)
# ---------------------------------------------------------
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add default user to docker group to run without sudo
usermod -aG docker azureuser

# ---------------------------------------------------------
# 2. Install Azure CLI (Required for logging in to ACR/AKS)
# ---------------------------------------------------------
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# ---------------------------------------------------------
# 3. Install Kubectl (Required for interacting with the cluster)
# ---------------------------------------------------------
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl