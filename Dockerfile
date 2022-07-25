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

## https://github.com/zeromq/cppzmq ##
# build libzmq
RUN \
   git clone https://github.com/zeromq/libzmq.git /tmp/libzmq && \
   mkdir /tmp/libzmq/build && \
   cmake -S /tmp/libzmq -B /tmp/libzmq/build && \
   make -C /tmp/libzmq/build -j4 install && \
   rm -rf /tmp/libzmq

# build cppzmq
RUN \
   git clone https://github.com/zeromq/cppzmq.git /tmp/cppzmq && \
   mkdir /tmp/cppzmq/build && \
   cmake -S /tmp/cppzmq -B /tmp/cppzmq/build && \
   make -C /tmp/cppzmq/build -j4 install && \
   rm -rf /tmp/cppzmq
