#include <zmq.hpp>
#include <string>
#include <iostream>

#include "proto/messages.pb.h"

int main ()
{
   // Verify that the version of the library that we linked against is
   // compatible with the version of the headers we compiled against.
   GOOGLE_PROTOBUF_VERIFY_VERSION;

   //  Prepare our context and socket
   zmq::context_t context (1);
   zmq::socket_t socket (context, zmq::socket_type::req);

   std::cout << "Connecting to hello world server..." << std::endl;
   socket.connect ("tcp://localhost:5555");
   std::cout << "Connected!" << std::endl;

   //  Do 10 requests, waiting each time for a response
   for (int request_nbr = 0; request_nbr != 10; request_nbr++) {
      std::cout << std::endl << "Request number: " << request_nbr << std::endl;

      // build the proto object to send to the server
      messages::Message requestMsg;
      requestMsg.set_msgtype(messages::Message_MessageType_A);
      requestMsg.set_text("Hello");

      // serialize the proto object into binary data (stored in std::string)
      std::string binaryData;
      requestMsg.SerializeToString(&binaryData);

      // send the request to the server
      std::cout << "Sending: " << requestMsg.text() <<  "..." << std::endl;
      socket.send (zmq::buffer(binaryData), zmq::send_flags::none);

      // Wait for the server to reply
      zmq::message_t reply;
      socket.recv(reply, zmq::recv_flags::none);

      // deserialize binary data into proto object
      messages::Message replyMsg;
      replyMsg.ParseFromArray(reply.data(), reply.size());

      std::cout << "Received: " << replyMsg.text() << std::endl;
   }

   return 0;
}