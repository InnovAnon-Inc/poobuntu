#! /usr/bin/env bash
set -exu
(( ! $# ))
renice -n +19 "$$"

#cd "`dirname "$(readlink -f "$0")"`"
cd "`dirname "$0"`" # change to the script's directory (not the dir it links to)

P="$(readlink -f "$PWD")"
PROJECT="$(basename "$P")"
#PARENT="$(dirname "$P")"
#[[ "$PROJECT" != "$PARENT" ]] # sanity check

if false ; then

command -v docker ||
curl https://raw.githubusercontent.com/InnovAnon-Inc/repo/master/get-docker.sh | bash

[[ -e invalidate.cache ]] ||
touch invalidate.cache

#trap 'docker-compose down' 0

CMAKE_BUILD_PARALLEL_LEVEL="${CMAKE_BUILD_PARALLEL_LEVEL:-"$(nproc)"}"
MAKEFLAGS="${MAKEFLAGS:-"-j $CMAKE_BUILD_PARALLEL_LEVEL"}"
TEST="${TEST:-}"
export MAKEFLAGS CMAKE_BUILD_PARALLEL_LEVEL TEST

docker-compose build # build image

docker-compose push # push image

#trap "docker stack rm "$(basename "$PWD")"" 0
docker stack rm "$PROJECT" # remove existing containers

fi

if (( "${0%%*-client.sh}" )) ; then
  sudo nice -n 20 -- \
  sudo -u $USER -- \
  docker-compose up -d --force-recreate
else
  docker-compose down || : # wtf
  docker stack deploy --compose-file docker-compose.yaml "$PROJECT" # deploy container
fi

( cd ..
  #git pull
  git add .
  git commit -m "auto commit by $0"
  git push ) || : # hey, it compiles... ship it! 

