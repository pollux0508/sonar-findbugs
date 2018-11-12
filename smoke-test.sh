#!/usr/bin/env bash

set -eu

# make sure we have jar file to COPY into docker image
mvn package -B

docker build  -t sonar-findbugs .
CONTAINER_ID=$(docker container run -p 9000:9000 -d sonar-findbugs)
mvn sonar:sonar -B \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=admin -Dsonar.password=admin
docker container stop $CONTAINER_ID
