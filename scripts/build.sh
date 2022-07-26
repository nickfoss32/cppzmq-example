#!/bin/bash

## Environment ##
REPO_ROOT=`git rev-parse --show-toplevel`
REPO_NAME=`basename $REPO_ROOT`
CONTAINER_NAME=$USER-$REPO_NAME

################################################################################
# Help                                                                         #
################################################################################
Help()
{
   echo "This project's build script."
   echo
   echo "Syntax: ./build.sh [-i|-t|-v|-h]"
   echo "Options:"
   echo "-i|--build-image  Docker image to use for building (<imageName> or <imageName>:<version>)."
   echo "-t|--build-type   Indicate a specific build type (Debug, Release, RelWithDebInfo, MinSizeRel)."
   echo "-v|--verbose      Enables verbose output."
   echo "-h|--help         Prints this usage."
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
      -i|--build-image)
         BUILD_IMAGE=$2

         # check if this image exists
         docker image inspect $BUILD_IMAGE &> /dev/null
         if [ $? -ne 0 ]; then
            echo "Provided build image: $BUILD_IMAGE does not exist. Exiting..."
            echo
            Help
            exit
         fi

         shift
         shift
         ;;
      -t|--build-type)
         if [ "$2" != "Debug" ] && [ "$2" != "Release" ] && [ "$2" != "RelWithDebInfo" ] && [ "$2" != "MinSizeRel" ]; then
            echo "Invalid build type provided. Must be one of the following:"
            echo "   Debug, Release, RelWithDebInfo, MinSizeRel"
            Help
            exit
         fi

         BUILD_TYPE=$2
         shift
         shift
         ;;
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

## User must provide build image to use ##
if [ ! -v BUILD_IMAGE ]; then
   echo "A build image must be provided. Exiting..."
   echo
   Help
   exit
fi

## exit if any build container setup fails ##
set -e

## spin up a new build container if one doesn't exist ##
if [ ! "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
   if [ "$(docker ps -aq -f status=exited -f name=$CONTAINER_NAME)" ]; then
      # remove old container if one existed
      docker rm $CONTAINER_NAME &> /dev/null
   fi
   # run a new container
   docker run -d -it --name $CONTAINER_NAME $BUILD_IMAGE &> /dev/null
fi

## create a directory in the container for sources ##
docker exec -it -w /tmp $CONTAINER_NAME bash -c "mkdir -p $REPO_NAME"

## copy sources to build container ##
docker cp $REPO_ROOT/apps $CONTAINER_NAME:/tmp/$REPO_NAME/
docker cp $REPO_ROOT/CMakeLists.txt $CONTAINER_NAME:/tmp/$REPO_NAME/
docker cp $REPO_ROOT/CMakePresets.json $CONTAINER_NAME:/tmp/$REPO_NAME/

## list of build targets ##
declare -a targets=(
   "x86_64-redhat-linux"
)

## list of target build types ##
declare -a types=(
   "Debug"
   "Release"
)

## if user indicated to only build specific type ##
if [[ -v BUILD_TYPE ]]; then
   types=("$BUILD_TYPE")
fi

## unset -e to allow us to loop through all of the builds regardless of fail status ##
unset e

for target in "${targets[@]}"; do
   for type in "${types[@]}"; do
      ## Create build directories ##
      docker exec -it -w /tmp/$REPO_NAME $CONTAINER_NAME mkdir -p build/$target/$type

      ## Configure and generate build environment with CMake ##
      docker exec -it -w /tmp/$REPO_NAME $CONTAINER_NAME cmake --preset=$target -DCMAKE_BUILD_TYPE=$type -S . -B build/$target/$type

      ## build ##
      docker exec -it -w /tmp/$REPO_NAME $CONTAINER_NAME cmake --build build/$target/$type -- VERBOSE=$VERBOSE

      ## install to container ##
      docker exec -it -w /tmp/$REPO_NAME $CONTAINER_NAME cmake --install build/$target/$type --prefix /usr/local
   done
done

## copy build artifacts back to local machine ##
docker cp $CONTAINER_NAME:/tmp/$REPO_NAME/build $REPO_ROOT/

# stop the build container
docker stop $CONTAINER_NAME &> /dev/null
