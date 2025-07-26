pipeline {
  agent any

  environment {
    TF_WORK_DIR = 'infrastructure/'  // or your .tf folder
  }

  parameters {
    string(name: 'ENV', defaultValue: 'dev', description: 'Deployment environment')
  }

  stages {

    stage('Terraform Init') {
      steps {
        dir("${TF_WORK_DIR}") {
          script {
            sh """
              echo "Initializing Terraform for ${params.ENV}..."
              terraform init -backend-config="key=${params.ENV}/terraform.tfstate"
            """
          }
        }
      }
    }

    stage('Terraform Validate') {
      steps {
        dir("${TF_WORK_DIR}") {
          sh 'terraform validate'
        }
      }
    }

    stage('Terraform Plan') {
      steps {
        dir("${TF_WORK_DIR}") {
          sh """
            echo "Planning Terraform deployment for ${params.ENV}..."
            terraform plan -var-file="${params.ENV}.tfvars" -out=tfplan
          """
        }
      }
    }

    stage('Terraform Apply') {
      when {
        beforeAgent true
        expression { return params.ENV == 'prod' || input message: "Apply Terraform to ${params.ENV}?", ok: 'Apply' }
      }
      steps {
        dir("${TF_WORK_DIR}") {
          sh """
            echo "Applying Terraform changes for ${params.ENV}..."
            terraform apply -auto-approve tfplan
          """
        }
      }
    }

    stage('Terraform Output') {
      steps {
        dir("${TF_WORK_DIR}") {
          sh 'terraform output'
        }
      }
    }
  }

  post {
    failure {
      echo "Terraform failed for ${params.ENV}"
    }
    success {
      echo "Terraform successfully applied for ${params.ENV}"
    }
  }
}