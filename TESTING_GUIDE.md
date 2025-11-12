# Testing Guide for MERN Auth App

This document provides comprehensive testing procedures for both Part-I and Part-II of the assignment.

---

## 📋 Table of Contents

1. [Part-I Testing (Docker Deployment)](#part-i-testing)
2. [Part-II Testing (Jenkins Pipeline)](#part-ii-testing)
3. [API Testing](#api-testing)
4. [Database Testing](#database-testing)
5. [Common Issues](#common-issues)

---

## Part-I Testing (Docker Deployment)

### Pre-Deployment Checks

```bash
# Check Docker installation
docker --version
docker-compose --version

# Check Docker daemon
docker ps

# Check available ports
# Linux/Mac:
sudo netstat -tulpn | grep -E ':(80|5000|27017)'

# Windows PowerShell:
netstat -ano | findstr -E ":(80|5000|27017)"
```

### Deployment Testing

#### 1. Build and Start Services

```bash
# Build images
docker-compose build

# Start services
docker-compose up -d

# Check container status
docker-compose ps

# Expected output:
# NAME              STATUS         PORTS
# mern-backend      Up             0.0.0.0:5000->5000/tcp
# mern-frontend     Up             0.0.0.0:80->80/tcp
# mern-mongodb      Up             0.0.0.0:27017->27017/tcp
```

#### 2. Container Health Checks

```bash
# Check if all containers are running
docker ps --filter "name=mern-"

# Check container logs
docker-compose logs backend
docker-compose logs frontend
docker-compose logs mongodb

# Check backend health endpoint
curl http://localhost:5000/api/health

# Expected response:
{
  "message": "Server is running with MongoDB!",
  "timestamp": "2025-11-12T...",
  "environment": "production",
  "database": "MongoDB Atlas"
}
```

#### 3. Volume Persistence Testing

```bash
# Check volume existence
docker volume ls | grep mongodb_data

# Inspect volume
docker volume inspect mern-auth-app_mongodb_data

# Test data persistence
# 1. Register a user via API
curl -X POST http://localhost:5000/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "password123"
  }'

# 2. Stop containers
docker-compose down

# 3. Start containers again
docker-compose up -d

# 4. Verify user still exists (login should work)
curl -X POST http://localhost:5000/api/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'

# If login succeeds, data persistence is working
```

#### 4. Network Testing

```bash
# Check network
docker network ls | grep mern-network
docker network inspect mern-auth-app_mern-network

# Test inter-container communication
docker exec -it mern-backend sh -c "ping -c 3 mongodb"
```

#### 5. Docker Hub Testing

```bash
# Tag images
docker tag mern-auth-app_backend:latest yourusername/mern-backend:latest
docker tag mern-auth-app_frontend:latest yourusername/mern-frontend:latest

# Push to Docker Hub
docker push yourusername/mern-backend:latest
docker push yourusername/mern-frontend:latest

# Verify on Docker Hub
# Visit: https://hub.docker.com/r/yourusername/mern-backend
# Visit: https://hub.docker.com/r/yourusername/mern-frontend

# Pull and test images
docker pull yourusername/mern-backend:latest
docker pull yourusername/mern-frontend:latest
```

---

## Part-II Testing (Jenkins Pipeline)

### Pre-Pipeline Checks

```bash
# Check Jenkins is running
sudo systemctl status jenkins

# Check Docker permissions for Jenkins
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

# Verify Jenkins can use Docker
sudo -u jenkins docker ps
```

### Jenkins Pipeline Testing

#### 1. Pipeline Creation

1. Open Jenkins: `http://56.228.10.255:8080`
2. Create new Pipeline job
3. Configure Git repository
4. Set Jenkinsfile path
5. Save configuration

#### 2. Manual Pipeline Execution

```bash
# Trigger build manually
# Click "Build Now" in Jenkins UI

# Monitor build progress
# Watch console output in Jenkins

# Expected stages:
# ✓ Checkout Code
# ✓ Verify Environment
# ✓ Cleanup Previous Builds
# ✓ Build Backend in Container
# ✓ Build Frontend in Container
# ✓ Run Application in Containers
# ✓ Health Check
# ✓ Generate Build Report
```

#### 3. Jenkins Build Verification

```bash
# SSH to Jenkins server
ssh -i your-key.pem ubuntu@jenkins-ec2-ip

# Check containers created by Jenkins
docker ps --filter "name=mern-*-jenkins"

# Expected containers:
# mern-backend-jenkins    (port 5001)
# mern-frontend-jenkins   (port 3001)
# mern-mongodb-jenkins    (port 27018)
# mern-nginx-jenkins      (port 81)

# Test Jenkins build endpoints
curl http://localhost:5001/api/health
curl http://localhost:3001
curl http://localhost:81
```

#### 4. Volume Mount Testing

```bash
# Verify code is mounted, not built from Dockerfile
docker exec -it mern-backend-jenkins ls -la /app

# Check if changes reflect immediately
# 1. Modify server.js
# 2. Restart container
docker-compose -f docker-compose-jenkins.yml restart backend-jenkins
# 3. Changes should be visible immediately (no rebuild needed)
```

#### 5. Port Conflict Testing

```bash
# Verify different ports are used
docker ps --format "table {{.Names}}\t{{.Ports}}"

# Part-I ports: 80, 5000, 27017
# Part-II ports: 81, 5001, 3001, 27018

# Test both deployments can run simultaneously
docker-compose up -d
docker-compose -f docker-compose-jenkins.yml up -d
docker ps
```

---

## API Testing

### Using cURL

#### 1. Health Check

```bash
curl http://localhost:5000/api/health
```

#### 2. User Registration

```bash
curl -X POST http://localhost:5000/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password123"
  }'

# Expected response:
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "...",
    "name": "John Doe",
    "email": "john@example.com"
  },
  "message": "Registration successful!"
}
```

#### 3. User Login

```bash
curl -X POST http://localhost:5000/api/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123"
  }'

# Expected response:
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "...",
    "name": "John Doe",
    "email": "john@example.com"
  },
  "message": "Login successful!"
}
```

#### 4. Invalid Credentials

```bash
curl -X POST http://localhost:5000/api/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "wrongpassword"
  }'

# Expected response:
{
  "message": "Invalid credentials"
}
```

### Using Postman

1. Import collection from `postman_collection.json` (if available)
2. Test all endpoints
3. Verify response codes
4. Check error handling

### Frontend Testing

```bash
# Open browser
http://localhost         # Part-I
http://localhost:3001    # Part-II
http://localhost:81      # Part-II (Nginx)

# Test workflows:
1. Register new user
2. Login with credentials
3. View dashboard
4. Logout
5. Login again (verify session)
```

---

## Database Testing

### MongoDB Connection Test

```bash
# Connect to MongoDB container
docker exec -it mern-mongodb mongosh

# Or for Jenkins build:
docker exec -it mern-mongodb-jenkins mongosh

# Switch to database
use mern-auth

# List collections
show collections

# Count users
db.users.countDocuments()

# Find all users
db.users.find().pretty()

# Find specific user
db.users.findOne({ email: "john@example.com" })

# Exit
exit
```

### Database Persistence Test

```bash
# 1. Create test data
curl -X POST http://localhost:5000/api/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@test.com","password":"test123"}'

# 2. Verify data exists
docker exec -it mern-mongodb mongosh --eval 'db.getSiblingDB("mern-auth").users.countDocuments()'

# 3. Stop containers
docker-compose down

# 4. Start containers
docker-compose up -d

# 5. Verify data still exists
docker exec -it mern-mongodb mongosh --eval 'db.getSiblingDB("mern-auth").users.countDocuments()'

# 6. Test login with previous user
curl -X POST http://localhost:5000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123"}'
```

---

## Common Issues

### Issue 1: Port Already in Use

**Symptoms:**
```
Error starting userland proxy: listen tcp4 0.0.0.0:80: bind: address already in use
```

**Solution:**
```bash
# Find process using port
# Linux/Mac:
sudo lsof -i :80
sudo kill -9 <PID>

# Windows PowerShell:
netstat -ano | findstr :80
taskkill /PID <PID> /F

# Or change port in docker-compose.yml
ports:
  - "8080:80"
```

### Issue 2: MongoDB Connection Failed

**Symptoms:**
```
MongoServerError: connect ECONNREFUSED
```

**Solution:**
```bash
# Check MongoDB is running
docker ps | grep mongodb

# Check MongoDB logs
docker logs mern-mongodb

# Restart MongoDB
docker-compose restart mongodb

# Wait for MongoDB to be ready
sleep 10
```

### Issue 3: Jenkins Can't Access Docker

**Symptoms:**
```
permission denied while trying to connect to Docker daemon
```

**Solution:**
```bash
# Add Jenkins to docker group
sudo usermod -aG docker jenkins

# Restart Jenkins
sudo systemctl restart jenkins

# Verify
sudo -u jenkins docker ps
```

### Issue 4: Volume Not Persisting Data

**Symptoms:**
Data disappears after `docker-compose down`

**Solution:**
```bash
# Don't use -v flag (removes volumes)
docker-compose down        # ✓ Correct
docker-compose down -v     # ✗ Wrong (removes volumes)

# Check volume exists
docker volume ls | grep mongodb_data

# Restore from backup
docker run --rm \
  -v mern-auth-app_mongodb_data:/data \
  -v $(pwd)/backups:/backup \
  alpine tar xzf /backup/mongodb-backup-*.tar.gz -C /
```

### Issue 5: Build Fails in Jenkins

**Symptoms:**
Pipeline fails at build stage

**Solution:**
```bash
# Check Jenkins logs
sudo journalctl -u jenkins -f

# Check container logs
docker logs mern-backend-jenkins

# Verify Jenkinsfile syntax
# Use Jenkins Pipeline Syntax validator

# Check workspace permissions
ls -la /var/lib/jenkins/workspace/
```

---

## Performance Testing

### Load Testing with Apache Bench

```bash
# Install Apache Bench
sudo apt install apache2-utils

# Test backend
ab -n 1000 -c 10 http://localhost:5000/api/health

# Test frontend
ab -n 1000 -c 10 http://localhost/
```

### Monitor Resource Usage

```bash
# Container resource usage
docker stats

# Container logs
docker-compose logs -f --tail=100

# System resources
htop
```

---

## Automated Testing Script

```bash
#!/bin/bash
# test-deployment.sh

echo "Testing MERN Auth App Deployment..."

# Test backend health
if curl -f http://localhost:5000/api/health > /dev/null 2>&1; then
    echo "✓ Backend health check passed"
else
    echo "✗ Backend health check failed"
    exit 1
fi

# Test user registration
RESPONSE=$(curl -s -X POST http://localhost:5000/api/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@test.com","password":"test123"}')

if echo "$RESPONSE" | grep -q "token"; then
    echo "✓ User registration passed"
else
    echo "✗ User registration failed"
    exit 1
fi

# Test MongoDB
MONGO_COUNT=$(docker exec mern-mongodb mongosh --quiet --eval 'db.getSiblingDB("mern-auth").users.countDocuments()')
if [ "$MONGO_COUNT" -gt 0 ]; then
    echo "✓ MongoDB persistence passed"
else
    echo "✗ MongoDB persistence failed"
    exit 1
fi

echo "All tests passed! ✓"
```

---

## Checklist for Submission

### Part-I Checklist
- [ ] Dockerfile for backend exists and works
- [ ] Dockerfile for frontend exists and works
- [ ] docker-compose.yml configured correctly
- [ ] MongoDB volume is persistent
- [ ] Images pushed to Docker Hub
- [ ] Application deployed on AWS EC2
- [ ] All services accessible via public IP
- [ ] Screenshots of running containers
- [ ] Screenshots of Docker Hub images

### Part-II Checklist
- [ ] Jenkinsfile exists and works
- [ ] Git integration configured
- [ ] Docker Pipeline plugin installed
- [ ] docker-compose-jenkins.yml uses volumes
- [ ] Different ports used (5001, 3001, 81, 27018)
- [ ] Different container names (*-jenkins)
- [ ] Pipeline successfully fetches from GitHub
- [ ] Build completes in containerized environment
- [ ] All stages complete successfully
- [ ] Screenshots of Jenkins pipeline
- [ ] Screenshots of running Jenkins containers

---

**Last Updated**: November 12, 2025
