#!/usr/bin/env bash

set -eu

# make sure we have jar file to COPY into docker image
mvn package -B

docker build  -t sonar-findbugs .
CONTAINER_ID=$(docker container run -p 9000:9000 -d sonar-findbugs)

echo -n waiting SonarQube
until $(curl --output /dev/null -s --fail http://localhost:9000); do
    echo -n '.'
    sleep 5
done
echo SonarQube has been launched.

count=0
until mvn sonar:sonar -B -Dsonar.host.url=http://localhost:9000 -Dsonar.login=admin -Dsonar.password=admin; do
    count=$[$count+1]
    if [ $count -ge 5 ]; then
      echo Sonar fails to scan 5 times!
      docker container stop $CONTAINER_ID
      exit 1
    fi
    echo SonarQube is not ready to scan project, wait 5 sec
    sleep 5
done
docker container stop $CONTAINER_ID
