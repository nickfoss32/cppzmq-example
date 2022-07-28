#include <iostream>
#include <string>
#include <unistd.h>

#include <boost/program_options.hpp>
#include <google/protobuf/text_format.h>
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

   //  Prepare our context and publisher
   zmq::context_t context;
   zmq::socket_t publisher (context, zmq::socket_type::pub);

   std::cout << "Standing up ZMQ publisher publishing data on " << vm["ip"].as<std::string>() << ":" << vm["port"].as<std::string>() << std::endl;
   publisher.bind("tcp://" + vm["ip"].as<std::string>() + ":" + vm["port"].as<std::string>());

   unsigned int msgCount = 0;
   while (true)
   {
      messages::Message msg;
      
      if (msgCount % 5 == 0)
      {
         msg.set_msgtype("C");
         msg.set_text("This is a type C message.");
      }
      else if (msgCount % 2 == 0) {
         msg.set_msgtype("A");
         msg.set_text("This is a type A message.");
      }
      else
      {
         msg.set_msgtype("B");
         msg.set_text("This is a type B message.");
      }

      // serialize the proto object into binary data (stored in std::string)
      std::string binaryData;
      msg.SerializeToString(&binaryData);

      // send the request out to all interested parties
      std::string printableData;
      google::protobuf::TextFormat::PrintToString(msg, &printableData);
      std::cout << "Publishing msg[" << msgCount << "]: " << std::endl << printableData << std::endl;
      publisher.send(zmq::buffer(binaryData), zmq::send_flags::none);

      // log the message was sent
      msgCount++;

      // wait 1 second to slow things down
      sleep(1);
   }
   
   return 0;
}
