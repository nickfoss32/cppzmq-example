#include <string>
#include <iostream>

#include <boost/program_options.hpp>

#include <zmq.hpp>

#include "proto/messages.pb.h"

int main (int argc, char** argv)
{
   // parse command line arguments
   boost::program_options::options_description desc("Allowed options");
   desc.add_options()
      ("help", "Prints program usage.")
      ("ip", boost::program_options::value<std::string>(), "IP address of the server to connect to.")
      ("port", boost::program_options::value<std::string>(), "Port the server is listening on.");

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
   zmq::context_t context (1);
   zmq::socket_t socket (context, zmq::socket_type::req);

   std::cout << "Connecting to hello world server at " << vm["ip"].as<std::string>() << ":" << vm["port"].as<std::string>() << "..." << std::endl;
   socket.connect ("tcp://" + vm["ip"].as<std::string>() + ":" + vm["port"].as<std::string>());
   std::cout << "Connected!" << std::endl;

   //  Do 10 requests, waiting each time for a response
   for (int request_nbr = 0; request_nbr != 10; request_nbr++)
   {
      // build the proto object to send to the server
      messages::Message requestMsg;
      requestMsg.set_text("Hello");

      // serialize the proto object into binary data (stored in std::string)
      std::string binaryData;
      requestMsg.SerializeToString(&binaryData);

      // send the request to the server
      std::cout << std::endl << "Sending request[" << request_nbr << "]: " << requestMsg.text() << "..." << std::endl;
      socket.send (zmq::buffer(binaryData), zmq::send_flags::none);

      // Wait for the server to reply
      zmq::message_t reply;
      std::cout << "Awaiting reply..." << std::endl;
      socket.recv(reply, zmq::recv_flags::none);

      // deserialize binary data into proto object
      messages::Message replyMsg;
      replyMsg.ParseFromArray(reply.data(), reply.size());

      std::cout << "Received reply: " << replyMsg.text() << std::endl;
   }

   return 0;
}