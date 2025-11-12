#!/bin/bash

###############################################################################
# Docker Deployment Script for AWS EC2
# Part-I: Containerized Deployment
# 
# This script automates the deployment of MERN Auth App using Docker
###############################################################################

set -e  # Exit on any error

echo "=========================================="
echo "MERN Auth App - Docker Deployment Script"
echo "Part-I: Containerized Deployment"
echo "=========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_step() {
    echo -e "${BLUE}➜ $1${NC}"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    print_error "Please do not run this script as root"
    exit 1
fi

# Configuration
DOCKER_HUB_USERNAME="${DOCKER_HUB_USERNAME:-yourusername}"
PROJECT_DIR="$(pwd)"

echo "Step 1: Verifying Prerequisites"
echo "---------------------------------"
print_step "Checking Docker installation..."
if command -v docker &> /dev/null; then
    docker --version
    print_success "Docker is installed"
else
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

print_step "Checking Docker Compose installation..."
if command -v docker-compose &> /dev/null; then
    docker-compose --version
    print_success "Docker Compose is installed"
else
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

print_step "Checking Docker daemon..."
if docker ps &> /dev/null; then
    print_success "Docker daemon is running"
else
    print_error "Docker daemon is not running. Please start Docker."
    exit 1
fi
echo ""

echo "Step 2: Cleaning Up Previous Deployments"
echo "------------------------------------------"
print_step "Stopping existing containers..."
docker-compose down -v 2>/dev/null || print_info "No previous deployment found"

print_step "Removing unused Docker resources..."
docker system prune -f
print_success "Cleanup completed"
echo ""

echo "Step 3: Building Docker Images"
echo "--------------------------------"
print_step "Building backend image..."
docker-compose build backend
print_success "Backend image built successfully"

print_step "Building frontend image..."
docker-compose build frontend
print_success "Frontend image built successfully"
echo ""

echo "Step 4: Tagging Images for Docker Hub"
echo "---------------------------------------"
print_info "Docker Hub Username: $DOCKER_HUB_USERNAME"

print_step "Tagging backend image..."
docker tag mern-auth-app_backend:latest $DOCKER_HUB_USERNAME/mern-backend:latest
print_success "Backend image tagged"

print_step "Tagging frontend image..."
docker tag mern-auth-app_frontend:latest $DOCKER_HUB_USERNAME/mern-frontend:latest
print_success "Frontend image tagged"
echo ""

echo "Step 5: Docker Hub Login"
echo "-------------------------"
print_info "Please login to Docker Hub to push images"
docker login || {
    print_error "Docker Hub login failed"
    exit 1
}
print_success "Logged in to Docker Hub"
echo ""

echo "Step 6: Pushing Images to Docker Hub"
echo "--------------------------------------"
print_step "Pushing backend image..."
docker push $DOCKER_HUB_USERNAME/mern-backend:latest
print_success "Backend image pushed successfully"

print_step "Pushing frontend image..."
docker push $DOCKER_HUB_USERNAME/mern-frontend:latest
print_success "Frontend image pushed successfully"
echo ""

echo "Step 7: Starting Application Services"
echo "---------------------------------------"
print_step "Starting MongoDB..."
docker-compose up -d mongodb
sleep 5
print_success "MongoDB started"

print_step "Starting Backend..."
docker-compose up -d backend
sleep 5
print_success "Backend started"

print_step "Starting Frontend..."
docker-compose up -d frontend
sleep 5
print_success "Frontend started"
echo ""

echo "Step 8: Verifying Deployment"
echo "-----------------------------"
print_step "Checking container status..."
docker-compose ps
echo ""

print_step "Checking container health..."
echo ""
docker ps --filter "name=mern-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

print_step "Waiting for services to be ready..."
sleep 10

print_step "Testing backend health endpoint..."
if curl -f http://localhost:5000/api/health &> /dev/null; then
    print_success "Backend is responding"
    curl http://localhost:5000/api/health | jq . 2>/dev/null || curl http://localhost:5000/api/health
else
    print_error "Backend health check failed"
fi
echo ""

echo "Step 9: Displaying Container Logs (Last 20 lines)"
echo "---------------------------------------------------"
print_step "Backend logs:"
docker-compose logs --tail=20 backend
echo ""

print_step "Frontend logs:"
docker-compose logs --tail=20 frontend
echo ""

echo "Step 10: Creating MongoDB Backup"
echo "----------------------------------"
BACKUP_DIR="$PROJECT_DIR/backups"
mkdir -p $BACKUP_DIR
BACKUP_FILE="$BACKUP_DIR/mongodb-backup-$(date +%Y%m%d-%H%M%S).tar.gz"

print_step "Creating MongoDB volume backup..."
docker run --rm \
    -v mern-auth-app_mongodb_data:/data \
    -v $BACKUP_DIR:/backup \
    alpine tar czf /backup/mongodb-backup-$(date +%Y%m%d-%H%M%S).tar.gz /data

print_success "Backup created at: $BACKUP_FILE"
echo ""

echo "=========================================="
echo "Deployment Complete! 🎉"
echo "=========================================="
echo ""
print_info "Application URLs:"
echo ""
echo "  Frontend:    http://localhost"
echo "  Backend API: http://localhost:5000/api/health"
echo "  MongoDB:     mongodb://localhost:27017/mern-auth"
echo ""
if [ -n "$EC2_PUBLIC_IP" ]; then
    echo "  Public Frontend:    http://$EC2_PUBLIC_IP"
    echo "  Public Backend API: http://$EC2_PUBLIC_IP:5000/api/health"
    echo ""
fi
print_info "Docker Hub Images:"
echo ""
echo "  Backend:  $DOCKER_HUB_USERNAME/mern-backend:latest"
echo "  Frontend: $DOCKER_HUB_USERNAME/mern-frontend:latest"
echo ""
print_info "Management Commands:"
echo ""
echo "  View logs:        docker-compose logs -f [service-name]"
echo "  Stop services:    docker-compose down"
echo "  Restart services: docker-compose restart"
echo "  View containers:  docker-compose ps"
echo ""
print_info "MongoDB Persistence:"
echo ""
echo "  Volume name:      mern-auth-app_mongodb_data"
echo "  Backup location:  $BACKUP_DIR"
echo "  View volume:      docker volume inspect mern-auth-app_mongodb_data"
echo ""
echo "=========================================="
print_success "Your MERN application is now running!"
echo "=========================================="
echo ""

# Optional: Open browser (if on desktop)
if command -v xdg-open &> /dev/null; then
    read -p "Would you like to open the application in your browser? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        xdg-open http://localhost
    fi
fi
