

//#include "oatpp/web/server/HttpConnectionHandler.hpp"
//
//#include "oatpp/network/Server.hpp"
//#include "oatpp/network/tcp/server/ConnectionProvider.hpp"
//#include <iostream>
//#include <string>
//#include <typeinfo>
//#include <vector>
//#include "json.hpp"

#include "kernel.h"


/**
 * Custom Request Handler
 */
class Handler : public oatpp::web::server::HttpRequestHandler {
public:

    /**
     * Handle incoming request and return outgoing response.
     */
    std::shared_ptr<OutgoingResponse> handle(const std::shared_ptr<IncomingRequest>& request) override {

        auto temp = request->readBodyToString();
        std::string strTemp = temp;


        json strTempJson = json::parse(strTemp);



        std::cout << "strTempJson[real].size()---->>>>" << strTempJson["real"].size() << std::endl;



        json outPutJson = json::object();
        json empty_array_magnitude = json::array();
        outPutJson["magnitude"] = empty_array_magnitude;



        my_CUFFT(strTempJson, strTempJson["real"].size(), outPutJson);






        return ResponseFactory::createResponse(Status::CODE_200, outPutJson.dump());


    }

};

void run() {

    /* Create Router for HTTP requests routing */
    auto router = oatpp::web::server::HttpRouter::createShared();

    /* Route GET - "/hello" requests to Handler */
    router->route("POST", "/getData", std::make_shared<Handler>());

    /* Create HTTP connection handler with router */
    auto connectionHandler = oatpp::web::server::HttpConnectionHandler::createShared(router);

    /* Create TCP connection provider */
    auto connectionProvider = oatpp::network::tcp::server::ConnectionProvider::createShared({ "localhost", 8086, oatpp::network::Address::IP_4 });

    /* Create server which takes provided TCP connections and passes them to HTTP connection handler */
    oatpp::network::Server server(connectionProvider, connectionHandler);

    /* Priny info about server port */
    OATPP_LOGI("MyApp", "Server running on port %s", connectionProvider->getProperty("port").getData());

    /* Run server */
    server.run();
}

int main() {

    /* Init oatpp Environment */
    oatpp::base::Environment::init();

    /* Run App */
    run();

    /* Destroy oatpp Environment */
    oatpp::base::Environment::destroy();

    return 0;

}