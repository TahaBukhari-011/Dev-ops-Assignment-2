#!/bin/bash

###############################################################################
# Jenkins Setup Script for AWS EC2
# Part-II: CI/CD Pipeline Setup
# 
# This script automates the installation and configuration of Jenkins
# on AWS EC2 for the MERN Auth App CI/CD pipeline
###############################################################################

set -e  # Exit on any error

echo "=========================================="
echo "MERN Auth App - Jenkins Setup Script"
echo "Part-II: CI/CD Pipeline Configuration"
echo "=========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    print_error "Please do not run this script as root"
    exit 1
fi

echo "Step 1: Updating System Packages"
echo "-----------------------------------"
sudo apt update && sudo apt upgrade -y
print_success "System updated successfully"
echo ""

echo "Step 2: Installing Java (Required for Jenkins)"
echo "------------------------------------------------"
sudo apt install -y openjdk-11-jdk
java -version
print_success "Java installed successfully"
echo ""

echo "Step 3: Installing Jenkins"
echo "---------------------------"
# Add Jenkins repository key
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -

# Add Jenkins repository
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

# Update package list and install Jenkins
sudo apt update
sudo apt install -y jenkins

# Start Jenkins service
sudo systemctl start jenkins
sudo systemctl enable jenkins

print_success "Jenkins installed and started successfully"
echo ""

echo "Step 4: Installing Docker"
echo "--------------------------"
# Remove old Docker versions
sudo apt remove -y docker docker-engine docker.io containerd runc || true

# Install Docker using convenience script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm get-docker.sh

# Add current user to docker group
sudo usermod -aG docker $USER

# Add jenkins user to docker group (critical for pipeline)
sudo usermod -aG docker jenkins

print_success "Docker installed successfully"
echo ""

echo "Step 5: Installing Docker Compose"
echo "-----------------------------------"
# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
print_success "Docker Compose installed successfully"
echo ""

echo "Step 6: Installing Git"
echo "-----------------------"
sudo apt install -y git
git --version
print_success "Git installed successfully"
echo ""

echo "Step 7: Configuring Firewall"
echo "------------------------------"
# Install UFW if not present
sudo apt install -y ufw

# Configure firewall rules
sudo ufw allow 8080/tcp  # Jenkins
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 5001/tcp  # Backend (Jenkins)
sudo ufw allow 3001/tcp  # Frontend (Jenkins)
sudo ufw allow 81/tcp    # Nginx (Jenkins)
sudo ufw allow 27018/tcp # MongoDB (Jenkins)

print_info "Firewall rules configured (not enabled to avoid SSH lockout)"
echo ""

echo "Step 8: Restarting Services"
echo "----------------------------"
sudo systemctl restart jenkins
sudo systemctl restart docker
print_success "Services restarted successfully"
echo ""

echo "Step 9: Verifying Installations"
echo "---------------------------------"
echo "Docker version:"
docker --version
echo ""
echo "Docker Compose version:"
docker-compose --version
echo ""
echo "Java version:"
java -version
echo ""
echo "Git version:"
git --version
echo ""
echo "Jenkins status:"
sudo systemctl status jenkins --no-pager | head -n 5
echo ""

echo "=========================================="
echo "Jenkins Setup Complete! 🎉"
echo "=========================================="
echo ""
print_info "IMPORTANT: Next Steps"
echo ""
echo "1. Get Jenkins Initial Admin Password:"
echo "   sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
echo ""
echo "2. Access Jenkins Web Interface:"
echo "   http://$(curl -s ifconfig.me):8080"
echo ""
echo "3. Complete Jenkins Setup Wizard:"
echo "   - Enter the initial admin password"
echo "   - Install suggested plugins"
echo "   - Install additional plugins:"
echo "     * Git plugin"
echo "     * Pipeline plugin"
echo "     * Docker Pipeline plugin"
echo "     * GitHub Integration plugin"
echo ""
echo "4. Configure AWS EC2 Security Group:"
echo "   - Port 8080 (Jenkins)"
echo "   - Port 5001 (Backend)"
echo "   - Port 3001 (Frontend)"
echo "   - Port 81 (Nginx)"
echo "   - Port 27018 (MongoDB)"
echo ""
echo "5. Re-login or restart your session for Docker group changes:"
echo "   newgrp docker"
echo ""
echo "6. Clone your repository:"
echo "   git clone https://github.com/TahaBukhari-011/mern-auth-app.git"
echo ""
echo "7. Create Jenkins Pipeline:"
echo "   - New Item → Pipeline"
echo "   - Configure Git repository"
echo "   - Set Script Path to 'Jenkinsfile'"
echo ""
print_success "Your Jenkins CI/CD server is ready!"
echo ""
echo "=========================================="
echo "Initial Admin Password:"
echo "=========================================="
sudo cat /var/lib/jenkins/secrets/initialAdminPassword || print_error "Could not read initial password"
echo ""
echo "=========================================="
