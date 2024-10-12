#pragma once

#include <cuda_runtime.h>
#include "oatpp/web/server/HttpConnectionHandler.hpp"

#include "oatpp/network/Server.hpp"
#include "oatpp/network/tcp/server/ConnectionProvider.hpp"
#include <cstddef> 
#include <iostream>
#include <string>
#include <typeinfo>
#include <vector>
#include "json.hpp"


using json = nlohmann::json;

// Complex data type
typedef float2 Complex;


void my_fftShift1D(json&, size_t);

void my_CUFFT(json&, size_t,json&);

float my_getMagnitude(float , float ,int );