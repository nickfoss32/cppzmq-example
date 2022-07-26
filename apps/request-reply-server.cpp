#include <zmq.hpp>
#include <string>
#include <iostream>
#include <unistd.h>

#include "proto/messages.pb.h"

int main () {
   // Verify that the version of the library that we linked against is
   // compatible with the version of the headers we compiled against.
   GOOGLE_PROTOBUF_VERIFY_VERSION;

   //  Prepare our context and socket
   zmq::context_t context (2);
   zmq::socket_t socket (context, zmq::socket_type::rep);

   std::cout << "Standing up hello world server..." << std::endl;
   socket.bind ("tcp://*:5555");

   while (true) {
      zmq::message_t request;

      //  Wait for next request from client
      socket.recv (request, zmq::recv_flags::none);

      // deserialize binary data into proto object
      messages::Message requestMsg;
      requestMsg.ParseFromArray(request.data(), request.size());

      std::cout << std::endl << "Received: " << requestMsg.text() << std::endl;

      //  Do some 'work'
      sleep(1);

      // build the proto object to send back to the client
      messages::Message replyMsg;
      replyMsg.set_msgtype(messages::Message_MessageType_A);
      replyMsg.set_text("World");

      // serialize the proto object into binary data (stored in std::string)
      std::string binaryData;
      replyMsg.SerializeToString(&binaryData);

      // send the request to the server
      std::cout << "Sending: " << replyMsg.text() <<  "..." << std::endl;
      socket.send (zmq::buffer(binaryData), zmq::send_flags::none);
   }
   
   return 0;
}
