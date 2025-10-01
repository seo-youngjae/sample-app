#!/bin/bash
set -eux

IMAGE_NAME="custom-jenkins"
VERSION="1.1"
CPU_PLATFORM=${1:-amd64}

docker run -d \
  --name sample-jenkins \
  -p 8888:8080 \
  -p 50000:50000 \
  -v $(pwd)/jenkins_home:/var/jenkins_home \
  -v $(pwd)/jenkins.yaml:/var/jenkins_config/jenkins.yaml \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e CASC_JENKINS_CONFIG=/var/jenkins_config/jenkins.yaml \
  -e JAVA_OPTS="-Djenkins.install.runSetupWizard=false" \
  --privileged \
  ${IMAGE_NAME}-${CPU_PLATFORM}:${VERSION}
