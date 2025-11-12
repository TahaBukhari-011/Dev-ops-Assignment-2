# PowerShell Deployment Script for Windows
# Part-I: Containerized Deployment
# MERN Auth App - Docker Deployment

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "MERN Auth App - Docker Deployment Script" -ForegroundColor Cyan
Write-Host "Part-I: Containerized Deployment" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Function to print colored output
function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Yellow
}

function Write-Step {
    param([string]$Message)
    Write-Host "➜ $Message" -ForegroundColor Blue
}

# Check if Docker is installed
Write-Host "Step 1: Verifying Prerequisites" -ForegroundColor White
Write-Host "---------------------------------" -ForegroundColor White
Write-Step "Checking Docker installation..."

try {
    $dockerVersion = docker --version
    Write-Host $dockerVersion
    Write-Success "Docker is installed"
} catch {
    Write-ErrorMsg "Docker is not installed. Please install Docker Desktop first."
    exit 1
}

Write-Step "Checking Docker Compose installation..."
try {
    $composeVersion = docker-compose --version
    Write-Host $composeVersion
    Write-Success "Docker Compose is installed"
} catch {
    Write-ErrorMsg "Docker Compose is not installed."
    exit 1
}

Write-Step "Checking Docker daemon..."
try {
    docker ps | Out-Null
    Write-Success "Docker daemon is running"
} catch {
    Write-ErrorMsg "Docker daemon is not running. Please start Docker Desktop."
    exit 1
}
Write-Host ""

# Get Docker Hub username
Write-Host "Step 2: Docker Hub Configuration" -ForegroundColor White
Write-Host "----------------------------------" -ForegroundColor White
$DOCKER_HUB_USERNAME = Read-Host "Enter your Docker Hub username"
if ([string]::IsNullOrWhiteSpace($DOCKER_HUB_USERNAME)) {
    $DOCKER_HUB_USERNAME = "yourusername"
    Write-Info "Using default username: $DOCKER_HUB_USERNAME"
}
Write-Host ""

# Clean up previous deployments
Write-Host "Step 3: Cleaning Up Previous Deployments" -ForegroundColor White
Write-Host "------------------------------------------" -ForegroundColor White
Write-Step "Stopping existing containers..."
docker-compose down -v 2>$null
Write-Step "Removing unused Docker resources..."
docker system prune -f
Write-Success "Cleanup completed"
Write-Host ""

# Build images
Write-Host "Step 4: Building Docker Images" -ForegroundColor White
Write-Host "--------------------------------" -ForegroundColor White
Write-Step "Building backend image..."
docker-compose build backend
Write-Success "Backend image built successfully"

Write-Step "Building frontend image..."
docker-compose build frontend
Write-Success "Frontend image built successfully"
Write-Host ""

# Tag images
Write-Host "Step 5: Tagging Images for Docker Hub" -ForegroundColor White
Write-Host "---------------------------------------" -ForegroundColor White
Write-Info "Docker Hub Username: $DOCKER_HUB_USERNAME"

Write-Step "Tagging backend image..."
docker tag mern-auth-app_backend:latest "$DOCKER_HUB_USERNAME/mern-backend:latest"
Write-Success "Backend image tagged"

Write-Step "Tagging frontend image..."
docker tag mern-auth-app_frontend:latest "$DOCKER_HUB_USERNAME/mern-frontend:latest"
Write-Success "Frontend image tagged"
Write-Host ""

# Docker Hub login
Write-Host "Step 6: Docker Hub Login" -ForegroundColor White
Write-Host "-------------------------" -ForegroundColor White
Write-Info "Please login to Docker Hub to push images"
docker login
if ($LASTEXITCODE -ne 0) {
    Write-ErrorMsg "Docker Hub login failed"
    exit 1
}
Write-Success "Logged in to Docker Hub"
Write-Host ""

# Push images
Write-Host "Step 7: Pushing Images to Docker Hub" -ForegroundColor White
Write-Host "--------------------------------------" -ForegroundColor White
Write-Step "Pushing backend image..."
docker push "$DOCKER_HUB_USERNAME/mern-backend:latest"
Write-Success "Backend image pushed successfully"

Write-Step "Pushing frontend image..."
docker push "$DOCKER_HUB_USERNAME/mern-frontend:latest"
Write-Success "Frontend image pushed successfully"
Write-Host ""

# Start services
Write-Host "Step 8: Starting Application Services" -ForegroundColor White
Write-Host "---------------------------------------" -ForegroundColor White
Write-Step "Starting MongoDB..."
docker-compose up -d mongodb
Start-Sleep -Seconds 5
Write-Success "MongoDB started"

Write-Step "Starting Backend..."
docker-compose up -d backend
Start-Sleep -Seconds 5
Write-Success "Backend started"

Write-Step "Starting Frontend..."
docker-compose up -d frontend
Start-Sleep -Seconds 5
Write-Success "Frontend started"
Write-Host ""

# Verify deployment
Write-Host "Step 9: Verifying Deployment" -ForegroundColor White
Write-Host "-----------------------------" -ForegroundColor White
Write-Step "Checking container status..."
docker-compose ps
Write-Host ""

Write-Step "Waiting for services to be ready..."
Start-Sleep -Seconds 10

Write-Step "Testing backend health endpoint..."
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5000/api/health" -UseBasicParsing
    Write-Success "Backend is responding"
    Write-Host $response.Content
} catch {
    Write-ErrorMsg "Backend health check failed"
}
Write-Host ""

# Display logs
Write-Host "Step 10: Displaying Container Logs (Last 20 lines)" -ForegroundColor White
Write-Host "---------------------------------------------------" -ForegroundColor White
Write-Step "Backend logs:"
docker-compose logs --tail=20 backend
Write-Host ""

Write-Step "Frontend logs:"
docker-compose logs --tail=20 frontend
Write-Host ""

# Create backup
Write-Host "Step 11: Creating MongoDB Backup" -ForegroundColor White
Write-Host "----------------------------------" -ForegroundColor White
$BACKUP_DIR = Join-Path $PSScriptRoot "backups"
if (-not (Test-Path $BACKUP_DIR)) {
    New-Item -ItemType Directory -Path $BACKUP_DIR | Out-Null
}
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BACKUP_FILE = Join-Path $BACKUP_DIR "mongodb-backup-$timestamp.tar.gz"

Write-Step "Creating MongoDB volume backup..."
docker run --rm `
    -v mern-auth-app_mongodb_data:/data `
    -v ${BACKUP_DIR}:/backup `
    alpine tar czf /backup/mongodb-backup-$timestamp.tar.gz /data

Write-Success "Backup created at: $BACKUP_FILE"
Write-Host ""

# Summary
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete! 🎉" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Info "Application URLs:"
Write-Host ""
Write-Host "  Frontend:    http://localhost" -ForegroundColor White
Write-Host "  Backend API: http://localhost:5000/api/health" -ForegroundColor White
Write-Host "  MongoDB:     mongodb://localhost:27017/mern-auth" -ForegroundColor White
Write-Host ""
Write-Info "Docker Hub Images:"
Write-Host ""
Write-Host "  Backend:  $DOCKER_HUB_USERNAME/mern-backend:latest" -ForegroundColor White
Write-Host "  Frontend: $DOCKER_HUB_USERNAME/mern-frontend:latest" -ForegroundColor White
Write-Host ""
Write-Info "Management Commands:"
Write-Host ""
Write-Host "  View logs:        docker-compose logs -f [service-name]" -ForegroundColor Gray
Write-Host "  Stop services:    docker-compose down" -ForegroundColor Gray
Write-Host "  Restart services: docker-compose restart" -ForegroundColor Gray
Write-Host "  View containers:  docker-compose ps" -ForegroundColor Gray
Write-Host ""
Write-Info "MongoDB Persistence:"
Write-Host ""
Write-Host "  Volume name:      mern-auth-app_mongodb_data" -ForegroundColor Gray
Write-Host "  Backup location:  $BACKUP_DIR" -ForegroundColor Gray
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Success "Your MERN application is now running!"
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Ask to open browser
$openBrowser = Read-Host "Would you like to open the application in your browser? (y/n)"
if ($openBrowser -eq 'y' -or $openBrowser -eq 'Y') {
    Start-Process "http://localhost"
}
