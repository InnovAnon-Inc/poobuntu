# poobuntu
Parallelization-hack-enabled Ubuntu

# Usage
`./run.sh`
`./run.sh 18.06`
`./run.sh 16.04`

# Cleaning up all the poo in your child Dockerfile
WORKDIR /
RUN ./poobuntu-clean.sh
RUN rm -v poobuntu-clean.sh

