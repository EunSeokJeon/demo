pipeline {
  agent any

  parameters {
    booleanParam(name : 'BUILD_DOCKER_IMAGE', defaultValue : true, description : 'BUILD_DOCKER_IMAGE')
    booleanParam(name : 'RUN_TEST', defaultValue : false, description : 'RUN_TEST')
    booleanParam(name : 'PUSH_DOCKER_IMAGE', defaultValue : true, description : 'PUSH_DOCKER_IMAGE')
  }

  environment {
    REGION = "ap-northeast-2"
  }
  stages {
    stage('============ Build Docker Image ============') {
        when { expression { return params.BUILD_DOCKER_IMAGE } }
        steps {
            dir("${env.WORKSPACE}") { // /var/lib/jenkins/workspace/demo
                sh 'sudo docker build -t test:1 .'
            }
        }
        post {
            always {
                echo "Docker build success!"
            }
        }
    }
    stage('============ Push Docker Image ============') {
        when { expression { return params.PUSH_DOCKER_IMAGE } }
        agent { label 'build' }
        steps {
            echo "Push Docker Image to ECR"
            sh'''
                aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REPOSITORY}
                docker push ${ECR_DOCKER_IMAGE}:${ECR_DOCKER_TAG}
            '''
        }
    }
    stage('Prompt for deploy') {
        when { expression { return params.PROMPT_FOR_DEPLOY } }
        agent { label 'deploy' }
        steps {
            script {
                env.APPROAL_NUM = input message: 'Please enter the approval number',
                                  parameters: [string(defaultValue: '',
                                               description: '',
                                               name: 'APPROVAL_NUM')]
            }
            echo "${env.APPROAL_NUM}"
        }
    }
    stage('============ Deploy workload ============') {
        when { expression { return params.DEPLOY_WORKLOAD } }
        agent { label 'deploy' }
        steps {
            sshagent (credentials: ['aws_ec2_user_ssh']) {
                sh """#!/bin/bash
                    scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
                        deploy/docker-compose.yml \
                        ${params.TARGET_SVR_USER}@${params.TARGET_SVR}:${params.TARGET_SVR_PATH};
                    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
                        ${params.TARGET_SVR_USER}@${params.TARGET_SVR} \
                        'aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REPOSITORY}; \
                         export IMAGE=${ECR_DOCKER_IMAGE}; \
                         export TAG=${ECR_DOCKER_TAG}; \
                         docker-compose -f docker-compose.yml down;
                         docker-compose -f docker-compose.yml up -d';
                """
            }
        }
    }
  }

  post {
    failure {
      slackSend(
        channel: "#jenkins_test",
        color: "danger",
        message: "[Failed] Job:${env.JOB_NAME}, Build num:#${env.BUILD_NUMBER} @channel (<${env.RUN_DISPLAY_URL}|open job detail>)"
      )
    }
  }
}
