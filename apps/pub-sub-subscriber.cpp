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
      ("help,h", "Prints program usage.")
      ("ip,a", boost::program_options::value<std::string>(), "IP address of the server to connect to.")
      ("port,p", boost::program_options::value<std::string>(), "Port the server is listening on.")
      ("types,t", boost::program_options::value<std::vector<std::string>>()->multitoken(), "Space-separated list of msg types to subscribe to.");

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
   zmq::socket_t subscriber (context, zmq::socket_type::sub);

   //subscribe to messages we care about
   if (!vm.count("types"))
   {
      std::cout << "No subscription requests were provided. Subscribing to all messages.\n";
      subscriber.set(zmq::sockopt::subscribe, "");
   }
   else
   {
      for (std::vector<std::string>::const_iterator it = vm["types"].as<std::vector<std::string>>().begin(); it != vm["types"].as<std::vector<std::string>>().end(); ++it)
      {
         subscriber.set(zmq::sockopt::subscribe, *it);
         std::cout << "Subscribed to msg type: " << *it << "" << std::endl;
      }
   }

   sleep(1);

   std::cout << "Connecting to server at " << vm["ip"].as<std::string>() << ":" << vm["port"].as<std::string>() << "..." << std::endl;
   subscriber.connect("tcp://" + vm["ip"].as<std::string>() + ":" + vm["port"].as<std::string>());
   std::cout << "Connected!" << std::endl;

   unsigned int msgCount = 0;
   while (true)
   {
      zmq::message_t msg;

      //  Wait for next msg to arrive from the server
      std::cout << std::endl << "Waiting for a msg..." << std::endl;
      subscriber.recv(msg, zmq::recv_flags::none);

      // deserialize binary data into proto object
      messages::Message msgData;
      msgData.ParseFromArray(msg.data(), msg.size());

      // log what was received
      std::string printableData;
      google::protobuf::TextFormat::PrintToString(msgData, &printableData);
      std::cout << "Received msg[" << msgCount << "]:" << std::endl << printableData << std::endl;

      // log the msg was received
      msgCount++;
   }
   
   return 0;
}
