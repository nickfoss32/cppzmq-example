#!/bin/bash

## Environment ##
REPO_ROOT=`git rev-parse --show-toplevel`
REPO_NAME=`basename $REPO_ROOT`
CONTAINER_NAME=$USER-$REPO_NAME

# exit if any command fails
set -e

################################################################################
# Help                                                                         #
################################################################################
Help()
{
   echo "This project's build script."
   echo
   echo "Syntax: ./build.sh [-v|-h]"
   echo "Options:"
   echo "-v|--verbose Enables verbose output."
   echo "-h|--help	Prints this usage."
   echo
}


################################################################################
################################################################################
# Main program                                                                 #
################################################################################
################################################################################

## Parse command line arguments ##
POSITIONAL=()
while [[ $# -gt 0 ]]; do
   key="$1"

   case $key in
      -v|--verbose)
         set -x
         VERBOSE=1
         shift
         ;;
      -h|--help)
         Help
         shift
         exit
         ;;
      *)    # unknown option
         shift
         ;;
   esac
done

## spin up a new build container if one doesn't exist ##
if [ ! "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
   if [ "$(docker ps -aq -f status=exited -f name=$CONTAINER_NAME)" ]; then
      # remove old container if one existed
      docker rm $CONTAINER_NAME
   fi
   # run a new container
   docker run -d -it --name $CONTAINER_NAME $USER/redhat-dev
fi

## create a directory in the container for sources ##
docker exec -it -w /tmp $CONTAINER_NAME bash -c "mkdir -p $REPO_NAME"

## copy sources to build container ##
docker cp $REPO_ROOT/apps $CONTAINER_NAME:/tmp/$REPO_NAME/
docker cp $REPO_ROOT/CMakeLists.txt $CONTAINER_NAME:/tmp/$REPO_NAME/
docker cp $REPO_ROOT/CMakePresets.json $CONTAINER_NAME:/tmp/$REPO_NAME/

## list of build variants ##
declare -a targets=(
   "Debug"
   "Release"
)

## unset -e to allow us to loop through all of the builds regardless of fail status ##
unset e

for target in "${targets[@]}"; do
   ## Create build directories ##
   docker exec -it -w /tmp/$REPO_NAME $CONTAINER_NAME mkdir -p build/$target

   ## Configure and generate build environment with CMake ##
   docker exec -it -w /tmp/$REPO_NAME $CONTAINER_NAME cmake --preset=$target -S . -B build/$target

   ## build ##
   docker exec -it -w /tmp/$REPO_NAME $CONTAINER_NAME cmake --build build/$target -- VERBOSE=$VERBOSE

   ## install to container ##
   docker exec -it -w /tmp/$REPO_NAME $CONTAINER_NAME cmake --install build/$target --prefix /usr/local
done

## turn set -e back on for cleanup ##
set -e

## copy build artifacts back to local machine ##
docker cp $CONTAINER_NAME:/tmp/$REPO_NAME/build $REPO_ROOT/

# stop the build container
docker stop $CONTAINER_NAME
