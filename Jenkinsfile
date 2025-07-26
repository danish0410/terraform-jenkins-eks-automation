pipeline {
    agent any

    environment {
        TF_ENV = 'dev' // Change to 'stage' or 'prod' as needed
        TF_VAR_FILE = "${TF_ENV}.tfvars"
        BACKEND_FILE = '03 backend.tf'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                bat "terraform --version"
                bat "terraform init -input=false"
            }
        }

        stage('Terraform Validate') {
            steps {
                bat "terraform validate"
            }
        }

        stage('Terraform Plan') {
            steps {
                bat "terraform plan -var-file=${TF_VAR_FILE} -input=false"
            }
        }

        stage('Approval for Production') {
            when {
                expression { env.TF_ENV == 'prod' }
            }
            steps {
                input message: "Approve deployment to PRODUCTION?"
            }
        }

        stage('Terraform Apply') {
            steps {
                bat "terraform apply -auto-approve -var-file=${TF_VAR_FILE} -input=false"
            }
        }
    }

    post {
        failure {
            echo "Terraform deployment failed!"
        }
        success {
            echo "Terraform deployment succeeded!"
        }
    }
}
