#!/bin/bash

###############################################################################
# Docker Hub Push Script
# Part-I: Push Docker Images to Docker Hub
# 
# This script builds and pushes Docker images to Docker Hub
###############################################################################

set -e

echo "=========================================="
echo "Docker Hub Push Script"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Get Docker Hub username
read -p "Enter your Docker Hub username: " DOCKER_HUB_USERNAME

if [ -z "$DOCKER_HUB_USERNAME" ]; then
    echo "Error: Docker Hub username is required"
    exit 1
fi

echo ""
print_info "Docker Hub Username: $DOCKER_HUB_USERNAME"
echo ""

# Login to Docker Hub
echo "Logging in to Docker Hub..."
docker login

# Build and push backend
echo ""
echo "Building backend image..."
cd backend
docker build -t $DOCKER_HUB_USERNAME/mern-backend:latest .
print_success "Backend image built"

echo "Pushing backend image to Docker Hub..."
docker push $DOCKER_HUB_USERNAME/mern-backend:latest
print_success "Backend image pushed"

# Build and push frontend
echo ""
echo "Building frontend image..."
cd ../frontend
docker build -t $DOCKER_HUB_USERNAME/mern-frontend:latest .
print_success "Frontend image built"

echo "Pushing frontend image to Docker Hub..."
docker push $DOCKER_HUB_USERNAME/mern-frontend:latest
print_success "Frontend image pushed"

cd ..

echo ""
echo "=========================================="
echo "Images pushed successfully! 🎉"
echo "=========================================="
echo ""
echo "Backend Image:  $DOCKER_HUB_USERNAME/mern-backend:latest"
echo "Frontend Image: $DOCKER_HUB_USERNAME/mern-frontend:latest"
echo ""
echo "View your images at:"
echo "https://hub.docker.com/r/$DOCKER_HUB_USERNAME/mern-backend"
echo "https://hub.docker.com/r/$DOCKER_HUB_USERNAME/mern-frontend"
echo ""
