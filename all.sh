#! /usr/bin/env bash
set -euxo pipefail

down () {
  local k
  for k in netselect cksum verify tlrz stego acng ; do (
    cd "$k"
    docker-compose down  || :
    docker stack rm "$k" || :
    docker-compose down  || :
  ) ; done
  #return $?
  return 0
}
down

# test on host
for k in netselect cksum verify tlrz stego acng ; do (
  cd "$k"
  ./test.sh
) ; done

# build container
for k in netselect cksum verify tlrz stego acng ; do (
  cd "$k"
  docker-compose build "$k"
) ; done

# bring up container
for k in netselect cksum verify tlrz stego acng ; do (
  cd "$k"
  docker-compose up --force-recreate "$k"
) ; done

# TODO test

down

# deploy to swarm
for k in netselect cksum verify tlrz stego acng ; do (
  cd "$k"
  docker stack deploy --compose-file "$k"
) ; done

# release it
for k in netselect cksum verify tlrz stego acng ; do (
  cd "$k"
  docker-compose push "$k"
) ; done

##git pull
#git add .
#git commit -m "auto commit by $0"
#git push

