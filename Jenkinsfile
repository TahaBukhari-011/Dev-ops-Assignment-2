/* 
 * Part-II: Jenkins Pipeline for MERN Auth Application
 * This pipeline pulls pre-built images from Docker Hub and deploys them
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
                
                // Clean workspace before checkout using shell command
                sh 'rm -rf ./*'
                
                // Checkout code from GitHub
                git branch: "${GIT_BRANCH}",
                    url: "${GIT_REPO}",
                    credentialsId: '89b7d431-b2e0-49a5-980a-1171f4e1c2f7'
                
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
                    echo 'Stage 3: Cleaning Up Previous Deployment'
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
        
        stage('Pull Images from Docker Hub') {
            steps {
                script {
                    echo '================================================'
                    echo 'Stage 4: Pulling Images from Docker Hub'
                    echo '================================================'
                }
                
                // Pull latest images from Docker Hub
                sh """
                    echo "Pulling backend image from Docker Hub..."
                    docker pull tahabukhari/mern-backend:latest
                    
                    echo "Pulling frontend image from Docker Hub..."
                    docker pull tahabukhari/mern-frontend:latest
                    
                    echo "Images pulled successfully"
                """
            }
        }
        
        stage('Run Application in Containers') {
            steps {
                script {
                    echo '================================================'
                    echo 'Stage 5: Launching Application Containers'
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
                    echo "Waiting for services to be healthy..."
                    sleep 15
                    
                    echo "Listing running containers..."
                    docker ps --filter "name=jenkins-mern-*"
                    
                    echo "Checking container logs..."
                    docker-compose -f ${DOCKER_COMPOSE_FILE} logs --tail=20
                """
            }
        }
        
        stage('Generate Build Report') {
            steps {
                script {
                    echo '================================================'
                    echo 'Stage 6: Generating Deployment Report'
                    echo '================================================'
                }
                
                sh """
                    echo "Deployment Summary:"
                    echo "==================="
                    echo "Project: ${PROJECT_NAME}"
                    echo "Deployment Time: \$(date)"
                    echo "Git Repository: ${GIT_REPO}"
                    echo "Git Branch: ${GIT_BRANCH}"
                    echo ""
                    echo "Container Status:"
                    docker-compose -f ${DOCKER_COMPOSE_FILE} ps
                    echo ""
                    echo "Application URLs:"
                    echo "- Backend API: http://56.228.10.255:5001"
                    echo "- Frontend: http://56.228.10.255:81"
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
            echo 'The MERN application has been successfully deployed'
            echo ''
            echo 'Access the application at:'
            echo '- Frontend: http://56.228.10.255:81'
            echo '- Backend API: http://56.228.10.255:5001'
            echo '================================================'
        }
        
        failure {
            echo '================================================'
            echo 'BUILD FAILED!'
            echo '================================================'
            echo 'Please check the logs above for error details.'
            echo 'Common issues:'
            echo '1. Docker daemon not running'
            echo '2. Port conflicts (5001, 81, 27018)'
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
            
            sh """
                echo "Build completed at: \$(date)"
                echo "Workspace: ${WORKSPACE}"
            """
        }
    }
}
