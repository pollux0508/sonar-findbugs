#!/usr/bin/env bash

set -eu

function launch_container() {
  # make sure we have jar file to COPY into docker image
  mvn package -B

  docker build -t sonar-findbugs .
  CONTAINER_ID=$(docker container run -p 9000:9000 -d sonar-findbugs)
}

# 1st param... The git URL to clone
# 2nd param... The tag name to check out
function download_target_project() {
  DIR_NAME=smoke_test_$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 6)
  mkdir -p /tmp/$DIR_NAME
  cd /tmp/$DIR_NAME
  git clone "$1" target_repo
  cd target_repo
  git checkout "$2"
}

function run_smoke_test() {
  echo -n waiting SonarQube
  until $(curl --output /dev/null -s --fail http://localhost:9000); do
      echo -n '.'
      sleep 5
  done
  echo SonarQube has been launched.

  count=0
  until SONAR_SCANNER_HOME="" mvn compile sonar:sonar -B -Dsonar.host.url=http://localhost:9000 -Dsonar.login=admin -Dsonar.password=admin; do
      count=$[ $count + 1 ]
      if [ $count -ge 5 ]; then
        echo Sonar fails to scan 5 times!
        docker container stop $CONTAINER_ID
        exit 1
      fi
      echo SonarQube is not ready to scan project, wait 5 sec
      sleep 5
  done
}

launch_container
download_target_project 'https://github.com/spotbugs/sonar-findbugs.git' '3.9.0'
run_smoke_test
docker container stop $CONTAINER_ID
