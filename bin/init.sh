#!/bin/bash

export CONTAINER_NAME="ansible"

PATH_TO_SSH_KEY="$PWD/keys/id_rsa"

UNAME_OUTPUT=$( uname -s )

case "$UNAME_OUTPUT" in
  Linux*)
    HOST_OS=Linux
    ;;
  Darwin*)
    HOST_OS=Mac
    ;;
  CYGWIN*)
    HOST_OS=Windows
    PWD=$( cygpath --dos $PWD )
    PATH_TO_SSH_KEY=$( cygpath --dos $PATH_TO_SSH_KEY )
    ;;
  MINGW*)
    HOST_OS=Windows
    ;;
  *) HOST_OS="UNKNOWN:${UNAME_OUTPUT}"
esac

export HOST_OS

if [ "$( docker container inspect -f '{{.State.Running}}' $CONTAINER_NAME )" != "true" ]
then 

  docker run \
    --detach \
    --name $CONTAINER_NAME \
    --env HOST_OS=$HOST_OS \
    --network=host \
    --rm \
    -it \
    -v $PWD:/app \
    jmacdonald/ansible

  docker exec -it $CONTAINER_NAME sh -c "mkdir /home/ansible/.ssh && chmod 700 /home/ansible/.ssh"
  docker cp $PATH_TO_SSH_KEY $CONTAINER_NAME:/home/ansible/.ssh/id_rsa
  docker exec -it $CONTAINER_NAME sh -c "chmod 400 /home/ansible/.ssh/id_rsa && chown ansible:ansible -R /home/ansible"
fi

docker exec -it $CONTAINER_NAME sh -c "rsync -a /app/ansible* /home/ansible/src/ && chown ansible:ansible -R /home/ansible/src"
docker exec -it $CONTAINER_NAME sh -c "find /home/ansible/src -type d -exec chmod 755 {} \; && find /home/ansible/src/ -type f -exec chmod 644 {} \;"
