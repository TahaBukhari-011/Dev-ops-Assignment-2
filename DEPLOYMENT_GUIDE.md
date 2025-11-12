# MERN Authentication App - DevOps Assignment 2

This project demonstrates containerized deployment and CI/CD automation of a MERN (MongoDB, Express, React, Node.js) authentication application using Docker and Jenkins.

## 📋 Assignment Overview

### Part-I: Containerized Deployment (4+1)
Deploy a MERN application on AWS EC2 using Docker with:
- Dockerfiles for backend and frontend
- Docker Compose for orchestration
- Persistent MongoDB volume
- Images pushed to Docker Hub

### Part-II: Jenkins CI/CD Pipeline (4+1)
Automate build phase using Jenkins with:
- GitHub integration
- Docker Pipeline for containerized builds
- Volume-mounted code (no Dockerfile)
- Different ports and container names

---

## 🏗️ Project Structure

```
mern-auth-app/
├── backend/
│   ├── Dockerfile              # Part-I: Backend container definition
│   ├── server.js               # Express server with authentication
│   └── package.json            # Node.js dependencies
├── frontend/
│   ├── Dockerfile              # Part-I: Frontend multi-stage build
│   ├── nginx.conf              # Nginx configuration
│   ├── package.json            # React dependencies
│   └── src/                    # React components
├── docker-compose.yml          # Part-I: Production deployment
├── docker-compose-jenkins.yml  # Part-II: Jenkins build configuration
├── Jenkinsfile                 # Part-II: CI/CD pipeline script
└── README.md                   # This file
```

---

## 🚀 Part-I: Containerized Deployment

### Prerequisites
- AWS EC2 instance (Ubuntu 22.04 recommended)
- Docker and Docker Compose installed
- Docker Hub account
- Ports: 80 (frontend), 5000 (backend), 27017 (MongoDB)

### Step 1: Setup AWS EC2

```bash
# Connect to EC2 instance
ssh -i your-key.pem ubuntu@56.228.10.255

# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installations
docker --version
docker-compose --version
```

### Step 2: Clone Repository

```bash
git clone https://github.com/TahaBukhari-011/mern-auth-app.git
cd mern-auth-app
```

### Step 3: Build and Push Docker Images

```bash
# Login to Docker Hub
docker login

# Build backend image
cd backend
docker build -t yourusername/mern-backend:latest .
docker push yourusername/mern-backend:latest

# Build frontend image
cd ../frontend
docker build -t yourusername/mern-frontend:latest .
docker push yourusername/mern-frontend:latest

cd ..
```

### Step 4: Deploy with Docker Compose

```bash
# Start all services
docker-compose up -d

# Check container status
docker-compose ps

# View logs
docker-compose logs -f

# Check backend health
curl http://localhost:5000/api/health
```

### Step 5: Configure EC2 Security Group

Open the following ports in AWS Security Group:
- Port 80 (HTTP) - Frontend
- Port 5000 - Backend API
- Port 22 (SSH) - Remote access

### Step 6: Access Application

- Frontend: `http://56.228.10.255`
- Backend API: `http://56.228.10.255:5000/api/health`

### Data Persistence

MongoDB data is stored in a Docker volume named `mongodb_data`:
```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect mern-auth-app_mongodb_data

# Backup volume
docker run --rm -v mern-auth-app_mongodb_data:/data -v $(pwd):/backup alpine tar czf /backup/mongodb-backup.tar.gz /data
```

---

## 🔄 Part-II: Jenkins CI/CD Pipeline

### Prerequisites
- Jenkins server on AWS EC2
- Git plugin installed
- Docker Pipeline plugin installed
- Docker installed on Jenkins server
- GitHub repository access

### Step 1: Setup Jenkins on EC2

```bash
# Install Java
sudo apt update
sudo apt install -y openjdk-11-jdk

# Install Jenkins
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update
sudo apt install -y jenkins

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Allow Jenkins to use Docker
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Step 2: Configure Jenkins

1. Open Jenkins: `http://56.228.10.255:8080`
2. Complete initial setup wizard
3. Install required plugins:
   - Git plugin
   - Pipeline plugin
   - Docker Pipeline plugin
   - GitHub Integration plugin

### Step 3: Create Jenkins Pipeline

1. Click "New Item"
2. Enter name: "MERN-Auth-CI-CD"
3. Select "Pipeline" and click OK
4. Under "Pipeline" section:
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: `https://github.com/TahaBukhari-011/mern-auth-app.git`
   - Branch: `main`
   - Script Path: `Jenkinsfile`
5. Click "Save"

### Step 4: Run Pipeline

```bash
# Click "Build Now" in Jenkins UI
# Or trigger via webhook from GitHub
```

### Step 5: Access Jenkins Build

- Frontend: `http://56.228.10.255:3001`
- Backend API: `http://56.228.10.255:5001/api/health`
- Nginx Proxy: `http://56.228.10.255:81`
- MongoDB: `mongodb://56.228.10.255:27018`

### Pipeline Stages

The Jenkinsfile automates the following stages:

1. **Checkout Code** - Fetch code from GitHub
2. **Verify Environment** - Check Docker installation
3. **Cleanup Previous Builds** - Remove old containers
4. **Build Backend** - Install dependencies in container
5. **Build Frontend** - Build React app in container
6. **Run Application** - Start all services
7. **Health Check** - Verify services are running
8. **Generate Report** - Create build summary

### Key Differences from Part-I

| Aspect | Part-I | Part-II |
|--------|--------|---------|
| **Deployment Method** | Dockerfile build | Volume-mounted code |
| **Container Names** | mern-* | mern-*-jenkins |
| **Frontend Port** | 80 | 3001, 81 (Nginx) |
| **Backend Port** | 5000 | 5001 |
| **MongoDB Port** | 27017 | 27018 |
| **Use Case** | Production deployment | CI/CD automation |

---

## 🔧 Configuration Files

### docker-compose.yml (Part-I)
- Builds images from Dockerfiles
- Uses ports: 80, 5000, 27017
- Container names: mern-mongodb, mern-backend, mern-frontend
- Persistent MongoDB volume

### docker-compose-jenkins.yml (Part-II)
- Uses volume mounts instead of building images
- Uses ports: 81, 5001, 3001, 27018
- Container names: mern-*-jenkins
- Suitable for Jenkins automation

### Jenkinsfile
- Declarative pipeline syntax
- Fetches code from GitHub
- Builds in containerized environment
- Health checks and reporting

---

## 📊 Management Commands

### Part-I Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# View logs
docker-compose logs -f [service-name]

# Rebuild specific service
docker-compose up -d --build backend

# Scale services
docker-compose up -d --scale backend=3
```

### Part-II Commands

```bash
# Start Jenkins build environment
docker-compose -f docker-compose-jenkins.yml up -d

# Stop Jenkins environment
docker-compose -f docker-compose-jenkins.yml down

# View Jenkins logs
docker-compose -f docker-compose-jenkins.yml logs -f

# Rebuild after code changes
docker-compose -f docker-compose-jenkins.yml restart
```

---

## 🐛 Troubleshooting

### Common Issues

#### Port Conflicts
```bash
# Check what's using a port
sudo netstat -tulpn | grep :5000

# Kill process using port
sudo kill -9 $(sudo lsof -t -i:5000)
```

#### Container Won't Start
```bash
# Check logs
docker logs container-name

# Inspect container
docker inspect container-name

# Check resources
docker stats
```

#### MongoDB Connection Issues
```bash
# Test MongoDB connection
docker exec -it mern-mongodb mongosh

# Check MongoDB logs
docker logs mern-mongodb

# Verify network
docker network inspect mern-auth-app_mern-network
```

#### Jenkins Permission Issues
```bash
# Fix Docker permissions
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

# Check Jenkins logs
sudo journalctl -u jenkins -f
```

---

## 🔒 Security Best Practices

1. **Environment Variables**
   - Use `.env` file for secrets (not committed to Git)
   - Rotate JWT secrets regularly
   - Use strong MongoDB passwords in production

2. **Network Security**
   - Configure EC2 security groups properly
   - Use HTTPS in production (add SSL/TLS)
   - Limit MongoDB port exposure

3. **Container Security**
   - Run containers as non-root user
   - Keep images updated
   - Scan images for vulnerabilities

---

## 📈 Monitoring and Logs

```bash
# View all container logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f backend

# Follow last 100 lines
docker-compose logs -f --tail=100

# Export logs
docker-compose logs > application.log
```

---

## 🧪 Testing

### Backend Health Check
```bash
curl http://localhost:5000/api/health
```

### Test Registration
```bash
curl -X POST http://localhost:5000/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "password123"
  }'
```

### Test Login
```bash
curl -X POST http://localhost:5000/api/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

---

## 📝 Assignment Requirements Checklist

### Part-I ✅
- [x] Dockerfile for backend
- [x] Dockerfile for frontend
- [x] docker-compose.yml file
- [x] Persistent MongoDB volume
- [x] Deployed on AWS EC2
- [x] Images pushed to Docker Hub

### Part-II ✅
- [x] Jenkinsfile with pipeline script
- [x] Git integration
- [x] Docker Pipeline plugin usage
- [x] Volume-mounted code (no Dockerfile)
- [x] Different ports (5001, 3001, 81, 27018)
- [x] Different container names (*-jenkins)
- [x] Containerized build environment

---

## 👥 Team Members

- **Taha Bukhari** - 011

---

## 📚 References

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [MongoDB Docker Image](https://hub.docker.com/_/mongo)
- [Node.js Docker Best Practices](https://github.com/nodejs/docker-node/blob/main/docs/BestPractices.md)

---

## 📄 License

This project is for educational purposes as part of DevOps course assignment.

---

## 🆘 Support

For issues or questions:
1. Check troubleshooting section above
2. Review container logs: `docker-compose logs -f`
3. Verify all prerequisites are installed
4. Ensure all ports are available
5. Check AWS security group settings

---

**Last Updated**: November 12, 2025
