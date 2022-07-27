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
   echo "Syntax: ./build.sh [-i|-t|-n|-a|-c|-v|-h]"
   echo "Required:"
   echo "   -i|--build-image     Docker image to use for building (<imageName> or <imageName>:<version>)."
   echo
   echo "Options:"
   echo "   -t|--build-type      Indicate a specific build type (Debug, Release, RelWithDebInfo, MinSizeRel)."
   echo "   -n|--container-name  Name of application container."
   echo "   -a|--ip-address      IP address to assign to the container."
   echo "   -c|--clean           Performs a clean build."
   echo "   -v|--verbose         Enables verbose output."
   echo "   -h|--help            Prints this usage."
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
            echo "Invalid build type provided: $2. Must be one of the following:"
            echo "   Debug, Release, RelWithDebInfo, MinSizeRel"
            Help
            exit
         fi

         BUILD_TYPE=$2
         shift
         shift
         ;;
      -n|--container-name)
         CONTAINER_NAME=$2
         shift
         shift
         ;;
      -a|--ip-address)
         if [[ $2 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            IP_ADDR=--ip $2
         else
            echo "Error - malformed IP string provided: $2"
            echo
            Help
            exit
         fi
         shift
         shift
         ;;
      -c|--clean)
         CLEAN_BUILD=1
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

## check if the requested container already exists ##
if docker inspect $CONTAINER_NAME &> /dev/null; then

   ## if a clean build was requested on an already-existing container, stop it, remove it, then spin up a new one ##
   if [ -v CLEAN_BUILD ]; then
      docker stop $CONTAINER_NAME &> /dev/null
      docker rm $CONTAINER_NAME &> /dev/null
      docker run -d -it $IP_ADDR --name $CONTAINER_NAME $BUILD_IMAGE &> /dev/null
   
   ## if a clean build wasn't requested, we need to check if it is stopped or not ##
   else
      ## check if requested container is stopped ##
      if [[ "exited" == `docker inspect $CONTAINER_NAME | grep Status | cut -d ':' -f 2 | sed 's/,//' | xargs` ]]; then
         docker start $CONTAINER_NAME &> /dev/null
      fi
   fi

## requested container doesnt exist - spin up a new one ##
else
   docker run -d -it $IP_ADDR --name $CONTAINER_NAME $BUILD_IMAGE &> /dev/null
fi

## exit if any build container setup fails ##
set -e

## create a directory in the container for sources ##
docker exec -it -w /tmp $CONTAINER_NAME bash -c "mkdir -p $REPO_NAME"

## copy sources to build container ##
docker cp $REPO_ROOT/apps $CONTAINER_NAME:/tmp/$REPO_NAME/
docker cp $REPO_ROOT/proto $CONTAINER_NAME:/tmp/$REPO_NAME/
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
