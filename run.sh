#! /usr/bin/env bash
set -exu
(( ! $# ))
#cd "`dirname "$(readlink -f "$0")"`"
cd "`dirname "$0"`"
[[ "$(readlink -f "$PWD")" != "$(dirname "$(readlink -f "$0")")" ]]

command -v docker ||
curl https://raw.githubusercontent.com/InnovAnon-Inc/repo/master/get-docker.sh | bash

[[ -e invalidate.cache ]] ||
touch invalidate.cache

#trap 'docker-compose down' 0

CMAKE_BUILD_PARALLEL_LEVEL="${CMAKE_BUILD_PARALLEL_LEVEL:-"$(nproc)"}"
MAKEFLAGS="${MAKEFLAGS:-"-j $CMAKE_BUILD_PARALLEL_LEVEL"}"
TEST="${TEST:-}"
export MAKEFLAGS CMAKE_BUILD_PARALLEL_LEVEL TEST

sudo             -- \
nice -n +20      -- \
sudo -u "$USER" -- \
docker-compose build
#docker-compose up --build --force-recreate

docker-compose push

#trap "docker stack rm "$(basename "$PWD")"" 0
docker stack rm "$(basename "$PWD")"
docker stack deploy --compose-file docker-compose.yaml "$(basename "$PWD")"

( cd ..
  #git pull
  git add .
  git commit -m "auto commit by $0"
  git push ) || :

