@Library('local-trusted-library') _

pipeline {
    agent any

    environment {
        IMAGE_NAME = 'eugenius1025/ubc-flask'
        IMAGE_TAG = "${IMAGE_NAME}:${env.BUILD_NUMBER}"
    }

    stages {
        // Set up Python virtual environment
        stage('Setup') {
            steps {
                sh '''
                    if [ ! -d "venv" ]; then
                        python3 -m venv venv
                    fi
                '''
            }
        }

        // Install Python dependencies
        stage('Install Dependencies') {
            steps {
                sh  '''
                    ./venv/bin/pip install --upgrade pip

                    ./venv/bin/pip install -r requirements.txt
                '''
            }
        }

        // Run unit tests
        stage('Unit Tests') {
            steps {
                sh './venv/bin/python3 -m unittest discover tests'
            }
        }

        // Exit virtual environment and build Docker image
        stage('Build Docker Image') {
            steps {
                sh """
                    printenv
                    docker build -t ${IMAGE_TAG} .
                """
            }
        }

        // Scan Docker image for vulnerabilities using Trivy
        stage('Trivy Scan') {
            steps {
                script {
                    trivyScan.containerVulnerabilities("${IMAGE_TAG}")
                }
            }
        }

        // Push Docker image to Docker Hub
        stage('Upload Image to Registry') {
            steps {
                withDockerRegistry(credentialsId: 'dockercreds', url: "") {
                    sh "docker push ${IMAGE_TAG}"
                }
            }
        }

        // Run the aplication locally as a Docker container
        stage('Deploy Locally with Docker') {
            steps {
                sh "docker run --name sample-flask-app -p 5000:5000 -d ${IMAGE_TAG}"
            }
        }

        // Manual approval before deploying to AWS Lambda
        stage('Lambda Deployment Approval') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    input message: 'Approve deployment to AWS Lambda?', ok: 'Deploy'
                }
            }
        }

        // Clean up local Docker deployment
        stage('Cleanup Local Deployment') {
            steps {
                sh '''
                    docker stop sample-flask-app
                    docker rm sample-flask-app
                '''
            }
        }

        // Deploy the application to AWS Lambda using SAM CLI
        stage('AWS Lambda Deployment') {
            steps {
                withAWS(credentials: 'awscreds', region: 'us-east-1') {
                    sh """
                        sam build

                        sam deploy --stack-name ubc-sample-flask-app \
                        --capabilities CAPABILITY_IAM \
                        --no-confirm-changeset \
                        --no-fail-on-empty-changeset
                    """
                }
            }
        }
    }

    post {
        always {
            script {
                trivyScan.reportsConversion()
            }
            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: "./", reportFiles: "trivy-report-lowmedhigh.html", reportName: "Trivy_Image_LowMedHigh_Vuln_Report", reportTitles: "", useWrapperFileDirectly: true])
            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: "./", reportFiles: "trivy-report-critical.html", reportName: "Trivy_Image_Critical_Vuln_Report", reportTitles: "", useWrapperFileDirectly: true])
        }
    }
}