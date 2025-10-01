pipeline {
    agent any

    environment {
        APP_NAME = "my-flask-app"
        IMAGE_TAG = "latest"

        // SKALA 내부 레지스트리 (Harbor)
        REGISTRY = "amdp-registry.skala-ai.com"
        REPO = "${REGISTRY}/skala25a/${APP_NAME}"
        DOCKER_CREDENTIALS_ID = "skala-image-registry-id"

        // Git Repo
        GIT_URL = "https://github.com/seo-youngjae/sample-app.git"
        GIT_BRANCH = "main"

        // K8s Namespace (교육용 네임스페이스)
        K8S_NAMESPACE = "skala-practice"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: "${GIT_BRANCH}", url: "${GIT_URL}"
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -f app.Dockerfile -t ${REPO}:${IMAGE_TAG} ."
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                    echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin ${REGISTRY}
                    docker push ${REPO}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Deploy to K8s') {
            steps {
                sh "kubectl apply -f k8s/ -n ${K8S_NAMESPACE}"
            }
        }
    }

    post {
        success { echo 'Pipeline success 🎉' }
        failure { echo 'Pipeline failed 💥' }
        always  { echo 'Pipeline finished ✅' }
    }
}
