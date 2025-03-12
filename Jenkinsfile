pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_KEY')
    }

    stages {
        stage('Terraform Init') {
            steps {
                script {
                    docker.image('hashicorp/terraform:latest').inside {
                        sh 'terraform init'
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    docker.image('hashicorp/terraform:latest').inside {
                        sh 'terraform plan -out=tfplan'
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    docker.image('hashicorp/terraform:latest').inside {
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }
    }
}
