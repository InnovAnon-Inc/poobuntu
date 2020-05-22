#! /bin/bash
set -exu

./run.sh
./run.sh 18.04
#./run.sh 17.04 || :
./run.sh 16.04
#./run.sh 15.04 || :
#./run.sh 14.04 || :

