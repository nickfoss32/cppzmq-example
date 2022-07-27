#include <string>
#include <iostream>
#include <unistd.h>

#include <boost/program_options.hpp>

#include <zmq.hpp>

#include "proto/messages.pb.h"

int main (int argc, char** argv) {
   // parse command line arguments
   boost::program_options::options_description desc("Allowed options");
   desc.add_options()
      ("help", "Prints program usage.")
      ("ip", boost::program_options::value<std::string>(), "IP address to use for the server.")
      ("port", boost::program_options::value<std::string>(), "Port for server to listen on.");

   boost::program_options::variables_map vm;
   boost::program_options::store(boost::program_options::parse_command_line(argc, argv, desc), vm);
   boost::program_options::notify(vm);

   if (vm.count("help")) 
   {
      std::cout << desc << "\n";
      return 0;
   }

   if (!vm.count("ip"))
   {
      std::cout << "Server IP address was not provided.\n";
      return 1;
   }

   if (!vm.count("port"))
   {
      std::cout << "Server listening port was not provided.\n";
      return 1;
   }

   // Verify that the version of the library that we linked against is
   // compatible with the version of the headers we compiled against.
   GOOGLE_PROTOBUF_VERIFY_VERSION;

   //  Prepare our context and socket
   zmq::context_t context (2);
   zmq::socket_t socket (context, zmq::socket_type::rep);

   std::cout << "Standing up hello world server listening on " << vm["ip"].as<std::string>() << ":" << vm["port"].as<std::string>() << std::endl;
   socket.bind ("tcp://" + vm["ip"].as<std::string>() + ":" + vm["port"].as<std::string>());

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
