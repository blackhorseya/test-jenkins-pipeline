#!/usr/bin/env groovy

pipeline {
    options {
        buildDiscarder(logRotator(numToKeepStr: '5'))
        preserveStashes(buildCount: 5)
        disableConcurrentBuilds()
        parallelsAlwaysFailFast()
    }
    parameters {
        booleanParam(name: 'DEBUG_BUILD', defaultValue: true, description: 'if true, never create release')
        text(name: 'RELEASE_NOTE', defaultValue: """
### feature

- new feature 1

### fix

- modify config
""", description: '')
}
    triggers {
        pollSCM('H H(20-21) * * *')
    }
    environment {
        // application settings
        APP_NAME = "test-jenkins-pipeline"
        VERSION = "1.0.0"
        FULL_VERSION = "${VERSION}.${BUILD_ID}"
    }
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: builder
    image: blackhorseya/dotnet-builder:3.1-alpine
    command: ['cat']
    tty: true
  - name: docker
    image: docker:latest
    command: ['cat']
    tty: true
    volumeMounts:
    - name: dockersock
      mountPath: /var/run/docker.sock
  - name: helm
    image: alpine/helm:3.1.0
    command: ['cat']
    tty: true
  volumes:
  - name: dockersock
    hostPath:
      path: /var/run/docker.sock
"""
        }
    }
    stages {
        stage('Prepare') {
            steps {
                script {
                    def causes = currentBuild.getBuildCauses()
                    echo "causes: ${causes}"

                    def commitChangeset = sh(
                            label: "get changeset", 
                            returnStdout: true, 
                            script: 'git diff-tree --no-commit-id --name-status -r HEAD'
                        ).trim()
                    echo "changeset: ${commitChangeset}"
                }

                sh label: "print all environment variable", script: """
                printenv | sort
                """

                container('builder') {
                    sh label: "print dotnet info", script: """
                    dotnet --info
                    """
                }

                container('docker') {
                    sh label: "print docker info and version", script: """
                    docker info
                    docker version
                    """
                }

                container('helm') {
                    script {
                        sh label: "print helm info", script: """
                        helm version
                        """
                    }
                }
            }
        }

        stage('Build') {
            steps {
                container('builder') {
                    echo "dotnet build"
                }
            }
        }

        stage('Test') {
            parallel {
                stage('Unit Test') {
                    steps {
                        container('builder') {
                            echo "dotnet test"
                        }
                    }
                }
                stage('Regression Test') {
                    when {
                        branch 'release/*'
                        triggeredBy cause: "UserIdCause"
                        expression { return !params.DEBUG_BUILD } 
                    }
                    steps {
                        container('builder') {
                            echo "regression test success"
                        }
                    }
                }
            }
        }

        stage('Static Code Analysis') {
            when {
                anyOf {
                    allOf {
                        branch 'develop'
                        triggeredBy 'TimerTrigger'
                    }
                    allOf {
                        triggeredBy cause: "UserIdCause"
                    }
                }
            }
            steps {
                echo "static code analysis"
            }
        }

        stage('Build and push docker image') {
            when {
                anyOf {
                    allOf {
                        branch 'develop'
                        triggeredBy 'TimerTrigger'
                    }
                    allOf {
                        triggeredBy cause: "UserIdCause"
                    }
                }
            }
            steps {
                container('docker') {
                    echo "docker build and push image"
                }
            }
        }

        stage("Deploy") {
            when {
                anyOf {
                    allOf {
                        branch 'develop'
                        triggeredBy 'TimerTrigger'
                    }
                    allOf {
                        triggeredBy cause: "UserIdCause"
                    }
                }
            }
            steps {
                echo "deploy to env"
            }
        }
    }

    post {
        always {
            echo "done"
        }
    }
}
