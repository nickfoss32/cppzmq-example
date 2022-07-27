cmake_minimum_required(VERSION 3.23)

project(cppzmq-example)

find_package(Boost 1.79 REQUIRED COMPONENTS program_options)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_SKIP_BUILD_RPATH FALSE)
set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

add_subdirectory(proto)

add_executable(request-reply-client apps/request-reply-client.cpp)
add_executable(request-reply-server apps/request-reply-server.cpp)
add_executable(pub-sub-publisher apps/pub-sub-publisher.cpp)
add_executable(pub-sub-subscriber apps/pub-sub-subscriber.cpp)

set_target_properties(request-reply-client PROPERTIES DEBUG_POSTFIX "-dbg")
set_target_properties(request-reply-server PROPERTIES DEBUG_POSTFIX "-dbg")
set_target_properties(pub-sub-publisher PROPERTIES DEBUG_POSTFIX "-dbg")
set_target_properties(pub-sub-subscriber PROPERTIES DEBUG_POSTFIX "-dbg")

target_include_directories(request-reply-client
   PRIVATE
      ${Boost_INCLUDE_DIRS})

target_include_directories(request-reply-server
   PRIVATE
      ${Boost_INCLUDE_DIRS})

target_include_directories(pub-sub-publisher
   PRIVATE
      ${Boost_INCLUDE_DIRS})

target_include_directories(pub-sub-subscriber
   PRIVATE
      ${Boost_INCLUDE_DIRS})

add_library(libzmq SHARED IMPORTED)
set_target_properties(libzmq PROPERTIES IMPORTED_LOCATION "/usr/local/lib64/libzmq.so")

target_link_libraries(request-reply-client
   PRIVATE
      internalMsgs
      libzmq
      Boost::program_options)

target_link_libraries(request-reply-server
   PRIVATE
      internalMsgs
      libzmq
      Boost::program_options)

target_link_libraries(pub-sub-publisher
   PRIVATE
      internalMsgs
      libzmq
      Boost::program_options)

target_link_libraries(pub-sub-subscriber
   PRIVATE
      internalMsgs
      libzmq
      Boost::program_options)

install(
   TARGETS
      request-reply-client
      request-reply-server
      pub-sub-publisher
      pub-sub-subscriber
   RUNTIME DESTINATION 
      bin)
