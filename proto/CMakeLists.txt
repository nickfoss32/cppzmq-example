## https://cmake.org/cmake/help/latest/module/FindProtobuf.html ##
find_package(Protobuf REQUIRED)
protobuf_generate_cpp(PROTO_SRC PROTO_HDRS messages.proto)

add_library(internalMsgs ${PROTO_HDRS} ${PROTO_SRC})

# PUBLIC scope so anyone who links against this library will inherit protobuf libs
target_link_libraries(internalMsgs
   PUBLIC
      ${Protobuf_LIBRARIES})

# PUBLIC scope so anyone who links against this library will inherit protoc generated headers via 
# "proto/messages.pb.h" and protobuf headers
target_include_directories(internalMsgs
   PUBLIC
      ${Protobuf_INCLUDE_DIRS}
      ${CMAKE_CURRENT_BINARY_DIR}/../)
