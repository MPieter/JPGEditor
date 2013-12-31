/*
 * Sampling.cpp
 *
 *  Created on: Dec 16, 2013
 *      Author: pieter
 */

#include "Matrix.h"
#include "Sampling.h"
#include <iostream>

void UpSampleY() {
	std::vector<int> input; // Vector for 8x8 elements
	std::vector<int> output(256); // vector for 16x16 elements

	// initialize input
	for (int i = 0; i < 8; i++) {
		for (int j = 0; j < 8; j++) {
			input.push_back(2*(i + 1));
		}
	}
	PrintInput(input);

	int offset;

	offset = 0;
	UpSampleYBlock(input, offset, output);

	offset = 8;
	UpSampleYBlock(input, offset, output);

	offset = 128;
	UpSampleYBlock(input, offset, output);

	offset = 136;
	UpSampleYBlock(input, offset, output);

	PrintResult(output);
}

void UpSampleYBlock(std::vector<int> & input, int offset, std::vector<int> & output) {
	for (int i = 0; i < 8; i++) {
		for (int j = 0; j < 8; j++) {
			output[offset] = input[i*8 + j];
			offset++;
		}
		offset = offset + 8;
	}

}

void PrintInput(std::vector<int> & input) {
	for (unsigned int i = 0; i < input.size(); i++) {
		std::cout << input[i] << " ";
		if ((i + 1) % 8 == 0) {
			std::cout << std::endl;
		}
	}

	std::cout << std::endl;
}

void PrintResult(std::vector<int> & output) {
	for (unsigned int i = 0; i < output.size(); i++) {
		std::cout << output[i] << " ";
		if ((i + 1) % 16 == 0) {
			std::cout << std::endl;
		}
	}

	std::cout << std::endl;
}


