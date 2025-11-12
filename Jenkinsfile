/* 
 * Part-II: Jenkins Pipeline for MERN Auth Application
 * This pipeline automates the build phase using Docker containers
 * It fetches code from GitHub and builds the application in a containerized environment
 */

pipeline {
    agent any
    
    environment {
        // GitHub Repository Configuration
        GIT_REPO = 'https://github.com/TahaBukhari-011/Dev-ops-Assignment-2.git'
        GIT_BRANCH = 'main'
        
        // Docker Configuration
        DOCKER_COMPOSE_FILE = 'docker-compose-jenkins.yml'
        
        // Application Configuration
        PROJECT_NAME = 'mern-auth-jenkins'
    }
    
    stages {
        stage('Checkout Code') {
            steps {
                script {
                    echo '================================================'
                    echo 'Stage 1: Fetching Code from GitHub'
                    echo '================================================'
                }
                
                // Clean workspace before checkout
                deleteDir()
                
                // Checkout code from GitHub
                git branch: "${GIT_BRANCH}",
                    url: "${GIT_REPO}"
                
                script {
                    echo 'Code successfully fetched from GitHub repository'
                    echo "Repository: ${GIT_REPO}"
                    echo "Branch: ${GIT_BRANCH}"
                }
            }
        }
        
        stage('Verify Environment') {
            steps {
                script {
                    echo '================================================'
                    echo 'Stage 2: Verifying Build Environment'
                    echo '================================================'
                }
                
                // Verify Docker is installed and running
                sh '''
                    echo "Checking Docker installation..."
                    docker --version
                    docker-compose --version
                    echo "Docker is ready for containerized build"
                '''
                
                // List project files
                sh '''
                    echo "Project structure:"
                    ls -la
                '''
            }
        }
        
        stage('Cleanup Previous Builds') {
            steps {
                script {
                    echo '================================================'
                    echo 'Stage 3: Cleaning Up Previous Builds'
                    echo '================================================'
                }
                
                // Stop and remove previous containers
                sh """
                    echo "Stopping and removing previous containers..."
                    docker-compose -f ${DOCKER_COMPOSE_FILE} down -v || true
                    
                    echo "Removing unused Docker resources..."
                    docker system prune -f || true
                """
            }
        }
        
        stage('Build Backend in Container') {
            steps {
                script {
                    echo '================================================'
                    echo 'Stage 4: Building Backend in Docker Container'
                    echo '================================================'
                }
                
                // Build backend service using Docker
                sh """
                    echo "Building backend application in containerized environment..."
                    docker-compose -f ${DOCKER_COMPOSE_FILE} up -d mongodb-jenkins
                    
                    echo "Waiting for MongoDB to be ready..."
                    sleep 10
                    
                    echo "Installing backend dependencies..."
                    docker-compose -f ${DOCKER_COMPOSE_FILE} run --rm backend-jenkins sh -c "npm install"
                    
                    echo "Backend build completed successfully"
                """
            }
        }
        
        stage('Build Frontend in Container') {
            steps {
                script {
                    echo '================================================'
                    echo 'Stage 5: Building Frontend in Docker Container'
                    echo '================================================'
                }
                
                // Build frontend service using Docker
                sh """
                    echo "Building frontend application in containerized environment..."
                    
                    echo "Installing frontend dependencies..."
                    docker-compose -f ${DOCKER_COMPOSE_FILE} run --rm frontend-jenkins sh -c "npm install"
                    
                    echo "Building production-ready frontend..."
                    docker-compose -f ${DOCKER_COMPOSE_FILE} run --rm frontend-jenkins sh -c "npm run build"
                    
                    echo "Frontend build completed successfully"
                """
            }
        }
        
        stage('Run Application in Containers') {
            steps {
                script {
                    echo '================================================'
                    echo 'Stage 6: Launching Application Containers'
                    echo '================================================'
                }
                
                // Start all services using docker-compose
                sh """
                    echo "Starting all application services..."
                    docker-compose -f ${DOCKER_COMPOSE_FILE} up -d
                    
                    echo "Waiting for services to be healthy..."
                    sleep 15
                    
                    echo "Checking container status..."
                    docker-compose -f ${DOCKER_COMPOSE_FILE} ps
                """
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    echo '================================================'
                    echo 'Stage 7: Performing Health Checks'
                    echo '================================================'
                }
                
                // Verify services are running
                sh """
                    echo "Checking backend health..."
                    docker-compose -f ${DOCKER_COMPOSE_FILE} exec -T backend-jenkins wget -q -O- http://localhost:5000/api/health || echo "Backend health check failed"
                    
                    echo "Listing running containers..."
                    docker ps --filter "name=mern-*-jenkins"
                    
                    echo "Checking container logs..."
                    docker-compose -f ${DOCKER_COMPOSE_FILE} logs --tail=20 backend-jenkins
                """
            }
        }
        
        stage('Generate Build Report') {
            steps {
                script {
                    echo '================================================'
                    echo 'Stage 8: Generating Build Report'
                    echo '================================================'
                }
                
                sh """
                    echo "Build Summary:"
                    echo "=============="
                    echo "Project: ${PROJECT_NAME}"
                    echo "Build Time: \$(date)"
                    echo "Git Repository: ${GIT_REPO}"
                    echo "Git Branch: ${GIT_BRANCH}"
                    echo ""
                    echo "Container Status:"
                    docker-compose -f ${DOCKER_COMPOSE_FILE} ps
                    echo ""
                    echo "Application URLs:"
                    echo "- Backend API: http://localhost:5001"
                    echo "- Frontend: http://localhost:3001"
                    echo "- Nginx Proxy: http://localhost:81"
                    echo "- MongoDB: mongodb://localhost:27018"
                """
            }
        }
    }
    
    post {
        success {
            echo '================================================'
            echo 'BUILD SUCCESSFUL!'
            echo '================================================'
            echo 'The MERN application has been successfully built'
            echo 'and deployed in containerized environment.'
            echo ''
            echo 'Access the application at:'
            echo '- Frontend: http://localhost:3001'
            echo '- Backend API: http://localhost:5001/api/health'
            echo '- Nginx Proxy: http://localhost:81'
            echo '================================================'
        }
        
        failure {
            echo '================================================'
            echo 'BUILD FAILED!'
            echo '================================================'
            echo 'Please check the logs above for error details.'
            echo 'Common issues:'
            echo '1. Docker daemon not running'
            echo '2. Port conflicts (5001, 3001, 81, 27018)'
            echo '3. Network connectivity issues'
            echo '4. Insufficient system resources'
            echo '================================================'
            
            // Cleanup on failure
            sh """
                echo "Cleaning up failed build..."
                docker-compose -f ${DOCKER_COMPOSE_FILE} down -v || true
            """
        }
        
        always {
            echo '================================================'
            echo 'Pipeline Execution Completed'
            echo '================================================'
            
            // Archive build artifacts (optional)
            sh """
                echo "Build completed at: \$(date)"
                echo "Workspace: ${WORKSPACE}"
            """
        }
    }
}
