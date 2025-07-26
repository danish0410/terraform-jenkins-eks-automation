pipeline {
  agent any

  parameters {
    choice(name: 'ENV', choices: ['dev', 'stage', 'prod'], description: 'Choose environment')
  }

  environment {
    TFVARS_FILE = "${params.ENV}.tfvars"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Terraform Init') {
      steps {
        bat 'terraform init'
      }
    }

    stage('Terraform Validate') {
      steps {
        bat 'terraform validate'
      }
    }

    stage('Terraform Plan') {
      steps {
        bat "terraform plan -var-file=terraform.tfvars -var-file=${env.TFVARS_FILE}"
      }
    }

    stage('Approval for Production') {
      when {
        expression { return params.ENV == 'prod' }
      }
      steps {
        input message: "You are about to deploy to PRODUCTION. Continue?"
      }
    }

    stage('Terraform Apply') {
      steps {
        bat "terraform apply -auto-approve -var-file=terraform.tfvars -var-file=${env.TFVARS_FILE}"
      }
    }
  }

  post {
    failure {
      echo 'Terraform deployment failed!'
    }
    success {
      echo 'Terraform deployment completed successfully!'
    }
  }
}
