cmake_minimum_required(VERSION 3.23)

project(cppzmq-example)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_SKIP_BUILD_RPATH FALSE)
set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

add_executable(cppzmq-demo apps/main.cpp)
set_target_properties(cppzmq-demo PROPERTIES DEBUG_POSTFIX "d")

add_library(libzmq SHARED IMPORTED)
set_target_properties(libzmq PROPERTIES IMPORTED_LOCATION "/usr/local/lib64/libzmq.so.5")

target_link_libraries(cppzmq-demo
   PRIVATE
      libzmq)

install(TARGETS cppzmq-demo
   RUNTIME DESTINATION bin
   LIBRARY DESTINATION lib)
