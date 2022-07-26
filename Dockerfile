FROM redhat/ubi8

# install cmake
RUN \
   curl -L -o /tmp/cmake-install.sh https://github.com/Kitware/CMake/releases/download/v3.24.0-rc4/cmake-3.24.0-rc4-linux-x86_64.sh && \
   chmod +x /tmp/cmake-install.sh && \
   mkdir /usr/bin/cmake && \
   /tmp/cmake-install.sh --skip-license --prefix=/usr/bin/cmake && \
   rm /tmp/cmake-install.sh

ENV PATH="/usr/bin/cmake/bin:${PATH}"

# install make
RUN yum install -y make

# install gcc (version 8) and c++ libs
RUN yum install -y gcc
RUN yum install -y gcc-c++
RUN yum install -y libstdc++

# install git
RUN yum install -y git

## install zeroMQ ##
## https://github.com/zeromq/cppzmq ##

# build & install libzmq
RUN \
   cd /tmp && \
   curl -L -O https://github.com/zeromq/libzmq/releases/download/v4.3.4/zeromq-4.3.4.tar.gz && \
   tar -xzf zeromq-4.3.4.tar.gz && \
   mkdir /tmp/zeromq-4.3.4/build && \
   cmake -S /tmp/zeromq-4.3.4 -B /tmp/zeromq-4.3.4/build && \
   make -C /tmp/zeromq-4.3.4/build -j4 install && \
   rm -rf /tmp/zeromq*

# build & install cppzmq
RUN \
   cd /tmp && \
   curl -L -o /tmp/cppzmq-4.8.1.tar.gz https://github.com/zeromq/cppzmq/archive/refs/tags/v4.8.1.tar.gz && \
   tar -xzf cppzmq-4.8.1.tar.gz && \
   mkdir /tmp/cppzmq-4.8.1/build && \
   cmake -S /tmp/cppzmq-4.8.1 -B /tmp/cppzmq-4.8.1/build && \
   make -C /tmp/cppzmq-4.8.1/build -j4 install && \
   rm -rf /tmp/cppzmq*

## build & install protobuf compiler ##
## https://github.com/protocolbuffers/protobuf/tree/main/src ##
RUN \
   cd /tmp && \
   curl -L -o /tmp/protobuf-cpp-3.21.4.tar.gz https://github.com/protocolbuffers/protobuf/releases/download/v21.4/protobuf-cpp-3.21.4.tar.gz && \
   tar -xzf protobuf-cpp-3.21.4.tar.gz && \
   cd /tmp/protobuf-3.21.4 && \
   ./configure && \
   make -j `nproc` && \
   make install && \
   ldconfig && \
   rm -rf /tmp/protobuf*
