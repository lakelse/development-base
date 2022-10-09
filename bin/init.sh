#!/bin/bash

export CONTAINER_NAME="ansible"

PATH_TO_SSH_KEY="$PWD/keys/id_rsa"

case "$( uname -s )" in
  CYGWIN*)
    PWD=$( cygpath --dos $PWD )
    PATH_TO_SSH_KEY=$( cygpath --dos $PATH_TO_SSH_KEY )
    ;;
esac

if [ "$( docker container inspect -f '{{.State.Running}}' $CONTAINER_NAME )" != "true" ]
then 

  docker run \
    -d \
    --name $CONTAINER_NAME \
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