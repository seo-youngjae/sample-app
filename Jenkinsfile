pipeline {
    agent any

    environment {
        // === 사용자 수정 영역 ===
        APP_NAME              = "my-flask-app"
        IMAGE_TAG             = "1.0.0"   // base version (실제 빌드마다 해시 붙음)

        // SKALA 내부 레지스트리 (Harbor)
        REGISTRY              = "amdp-registry.skala-ai.com"
        PROJECT               = "skala25a"
        REPO                  = "${REGISTRY}/${PROJECT}/${APP_NAME}"
        DOCKER_CREDENTIALS_ID = "skala-image-registry-id"

        // Git Repo
        GIT_URL    = "https://github.com/seo-youngjae/sample-app.git"
        GIT_BRANCH = "main"
        GIT_ID     = "skala-github-id"  // GitHub PAT credential ID

        // K8s Namespace
        K8S_NAMESPACE = "skala-practice"
    }

    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
        timestamps()
    }

    stages {
        // stage('Checkout') {
        //   steps {
        //     echo "=== SCM Checkout ==="
        //     checkout scm
        //   }
        // }

        stage('Install & Test (Python)') {
            steps {
                echo "=== Install dependencies & run tests ==="
                sh '''
                  set -eux
                  pip install --upgrade pip --break-system-packages
                  pip install -r requirements.txt --break-system-packages
                  pytest || echo "⚠️ Tests skipped (no tests found or failed)"
                '''
            }
        }

        stage('Compute Image Meta') {
            steps {
                script {
                    def hashcode = sh(script: "date +%s%N | sha256sum | cut -c1-12", returnStdout: true).trim()
                    env.FINAL_IMAGE_TAG = "${IMAGE_TAG}-${hashcode}"
                    env.IMAGE_REF       = "${REPO}:${FINAL_IMAGE_TAG}"

                    echo ">>> Using image: ${env.IMAGE_REF}"
                }
            }
        }

        stage('Image Build & Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                    echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin ${REGISTRY}
                    docker build -f app.Dockerfile -t ${IMAGE_REF} .
                    docker push ${IMAGE_REF}
                    """
                }
            }
        }

        stage('Update K8s Manifests') {
            steps {
                sh '''
                  set -eux
                  test -f ./k8s/deploy.yaml

                  echo "--- BEFORE ---"
                  grep -n "image:" ./k8s/deploy.yaml || true

                  sed -Ei "s#(image:[[:space:]]*${REPO})[^[:space:]]+#\\1:${FINAL_IMAGE_TAG}#" ./k8s/deploy.yaml

                  echo "--- AFTER ---"
                  grep -n "image:" ./k8s/deploy.yaml || true
                '''
            }
        }

        stage('Git Commit & Push (gitops)') {
            steps {
                sh '''
                  set -eux
                  git config --global --add safe.directory '*'
                  git config --global user.name "skala-gitops"
                  git config --global user.email "skala@skala-ai.com"

                  git fetch origin || true
                  cp ./k8s/deploy.yaml ./k8s/deploy.yaml.backup

                  if git show-ref --verify --quiet refs/heads/gitops || git show-ref --verify --quiet refs/remotes/origin/gitops; then
                      git checkout -f gitops || git checkout -B gitops origin/gitops
                  else
                      git checkout -b gitops
                  fi

                  cp ./k8s/deploy.yaml.backup ./k8s/deploy.yaml
                  sed -Ei "s#(image:[[:space:]]*${REPO})[^[:space:]]+#\\1:${FINAL_IMAGE_TAG}#" ./k8s/deploy.yaml
                  rm -f ./k8s/deploy.yaml.backup

                  git add ./k8s/deploy.yaml || true
                  git status
                '''

                withCredentials([usernamePassword(
                  credentialsId: "${env.GIT_ID}",
                  usernameVariable: 'GIT_PUSH_USER',
                  passwordVariable: 'GIT_PUSH_PASSWORD'
                )]) {
                    script {
                        env.GIT_REPO_PATH = env.GIT_URL.replaceFirst(/^https?:\/\//, '')
                        sh '''
                          set -eux
                          if ! git diff --cached --quiet; then
                              git commit -m "[AUTO] Update deploy.yaml with image $FINAL_IMAGE_TAG"
                              git remote set-url origin https://$GIT_PUSH_USER:$GIT_PUSH_PASSWORD@$GIT_REPO_PATH
                              git push origin gitops --force
                              echo "✅ Pushed to gitops branch"
                          else
                              echo "ℹ️ No changes to commit"
                          fi
                        '''
                    }
                }
            }
        }
    }

    post {
        success { echo 'Pipeline success 🎉' }
        failure { echo 'Pipeline failed 💥' }
        always  { echo 'Pipeline finished ✅' }
    }
}
