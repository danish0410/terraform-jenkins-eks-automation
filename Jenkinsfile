pipeline {
  agent any

  parameters {
    choice(name: 'ENV', choices: ['dev', 'stage', 'prod'], description: 'Choose the environment to deploy')
  }

  environment {
    TF_VAR_env = "${params.ENV}"
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
        sh 'terraform init -backend-config=03 backend.tf'
      }
    }

    stage('Terraform Validate') {
      steps {
        sh 'terraform validate'
      }
    }

    stage('Terraform Plan') {
      steps {
        sh 'terraform plan -var-file=05 terraform.tfvars -var-file=06 dev.tfvars'
      }
    }

    stage('Approval for Production') {
      when {
        expression { return params.ENV == 'prod' }
      }
      steps {
        input message: "You are about to deploy to PRODUCTION. Are you sure you want to continue?"
      }
    }

    stage('Terraform Apply') {
      steps {
        script {
          def tfvars = "05 terraform.tfvars -var-file=06 ${params.ENV}.tfvars"
          sh "terraform apply -auto-approve -var-file=${tfvars}"
        }
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
