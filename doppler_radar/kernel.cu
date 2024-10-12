
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <cufft.h>
#include <helper_cuda.h>
#include <helper_functions.h>
#include "kernel.h"


void __global__  fftshift(Complex*, int);

void my_CUFFT(json& data, size_t new_size, json& outPutJson) {


	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	const size_t mem_size = sizeof(Complex) * new_size;


	std::cout << "CUFFT is starting..." << std::endl;


	// Allocate host memory for the signal
	Complex* h_signal =
		reinterpret_cast<Complex*>(malloc(sizeof(Complex) * new_size));

	Complex* h_outPut =
		reinterpret_cast<Complex*>(malloc(sizeof(Complex) * new_size));



	// Initialize the memory for the signal
	for (unsigned int i = 0; i < new_size; ++i) {
		h_signal[i].x = data["real"][i];

		h_signal[i].y = data["imag"][i];
	}




	// Allocate device memory for signal
	Complex* d_signal;
	checkCudaErrors(cudaMalloc(reinterpret_cast<void**>(&d_signal), mem_size));
	//checkCudaErrors(cudaMalloc(&d_signal, mem_size));

	Complex* d_outPut;
	checkCudaErrors(cudaMalloc(reinterpret_cast<void**>(&d_outPut), mem_size));

	cudaEventRecord(start);

	// Copy host memory to device
	checkCudaErrors(
		cudaMemcpy(d_signal, h_signal, mem_size, cudaMemcpyHostToDevice));

	// CUFFT plan 
	cufftHandle plan;
	checkCudaErrors(cufftPlan1d(&plan, new_size, CUFFT_C2C, 1));

	//cudaEventRecord(start);


	// Transform signal and kernel
	std::cout << "Transforming signal cufftExecC2C" << std::endl;
	checkCudaErrors(cufftExecC2C(plan, reinterpret_cast<cufftComplex*>(d_signal),
		reinterpret_cast<cufftComplex*>(d_outPut),
		CUFFT_FORWARD));

	/*cudaDeviceSynchronize();*/
	// Destroy CUFFT context
	checkCudaErrors(cufftDestroy(plan));

	const int block_size=256;

	const int grid_size = (new_size + block_size - 1)/block_size;


	fftshift << <grid_size, block_size >> > (d_outPut, new_size);


	getLastCudaError("Kernel execution failed [ fftshift ]");
	//cudaEventRecord(stop);


	checkCudaErrors(
		cudaMemcpy(h_outPut, d_outPut, mem_size, cudaMemcpyDeviceToHost));

	cudaEventRecord(stop);

	cudaEventSynchronize(stop);
	float milliseconds = 0;
	cudaEventElapsedTime(&milliseconds, start, stop);

	printf("cufft和fftshift共耗时 %f 毫秒", milliseconds);

	cudaDeviceSynchronize();

	//-----------------------------------------------------------------------------------


	for (unsigned int i = 0; i < new_size; ++i) {

		outPutJson["magnitude"].push_back(my_getMagnitude(h_outPut[i].x, h_outPut[i].y, 20));

	}


	//my_fftShift1D(outPutJson["magnitude"], new_size);
	//-----------------------------------------------------------------------------------

	free(h_signal);
	free(h_outPut);
	checkCudaErrors(cudaFree(d_signal));
	checkCudaErrors(cudaFree(d_outPut));



}


void my_fftShift1D(json& myData, size_t N)
{
	const unsigned int halfLength = N / 2;
	float tempFloat;



	for (size_t i = 0; i < N; i++)
	{
		if (i < halfLength)
		{
			tempFloat = myData[i];
			myData[i] = myData[halfLength + i];
			myData[halfLength + i] = tempFloat;


		}

	}
}

float my_getMagnitude(float x, float y, int scale) {

	return scale * log10f(sqrtf(x * x + y * y));
}

static void __global__  fftshift(Complex* data, int N)
{
	int i = blockDim.x * blockIdx.x + threadIdx.x;

	Complex temp;

	if (i < N / 2)
	{
		temp.x = data[i].x;
		temp.y = data[i].y;

		data[i].x = data[i + N / 2].x;
		data[i].y = data[i + N / 2].y;

		data[i + N / 2].x = temp.x;
		data[i + N / 2].y = temp.y;
	}
}
