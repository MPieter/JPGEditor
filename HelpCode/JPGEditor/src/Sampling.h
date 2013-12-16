/*
 * Sampling.h
 *
 *  Created on: Dec 16, 2013
 *      Author: pieter
 */

#ifndef SAMPLING_H_
#define SAMPLING_H_

#include <vector>

void UpSampleY();

void UpSampleYBlock(std::vector<int> & input, int offset, std::vector<int> & output);

void PrintResult(std::vector<int> & output);


#endif /* SAMPLING_H_ */
