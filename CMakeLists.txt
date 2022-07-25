cmake_minimum_required(VERSION 3.23)

project(cppzmq-example)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_SKIP_BUILD_RPATH FALSE)
set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

add_executable(hello_world apps/hello_world.cpp)
add_executable(multipart_messages apps/multipart_messages.cpp)
add_executable(pubsub_multithreaded_inproc apps/pubsub_multithreaded_inproc.cpp)

set_target_properties(hello_world PROPERTIES DEBUG_POSTFIX "-dbg")
set_target_properties(multipart_messages PROPERTIES DEBUG_POSTFIX "-dbg")
set_target_properties(pubsub_multithreaded_inproc PROPERTIES DEBUG_POSTFIX "-dbg")

add_library(libzmq SHARED IMPORTED)
set_target_properties(libzmq PROPERTIES IMPORTED_LOCATION "/usr/local/lib64/libzmq.so.5")

target_link_libraries(hello_world
   PRIVATE
      libzmq)

target_link_libraries(multipart_messages
   PRIVATE
      libzmq)

target_link_libraries(pubsub_multithreaded_inproc
   PRIVATE
      libzmq
      pthread)

install(
   TARGETS
      hello_world
      multipart_messages
      pubsub_multithreaded_inproc
   RUNTIME DESTINATION 
      bin)
