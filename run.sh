#! /usr/bin/env bash
set -exu
(( $# == 0 ))
cd "`dirname "$(readlink -f "$0")"`"

command -v docker ||
curl https://raw.githubusercontent.com/InnovAnon-Inc/repo/master/get-docker.sh | bash

trap 'docker-compose down' 0

sudo             -- \
nice -n +20      -- \
sudo -u `whoami` -- \
docker-compose up --build --force-recreate

docker-compose push
( #git pull
git add .
git commit -m "auto commit by $0"
git push ) || :

