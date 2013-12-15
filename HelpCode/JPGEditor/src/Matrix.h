/*
 * Matrix.h
 *
 *  Created on: Dec 15, 2013
 *      Author: pieter
 */

#ifndef MATRIX_H_
#define MATRIX_H_

#include <iostream>
#include <vector>

void createWordData() {
	int input[] = { -415, -26, -58, 33, 56, -24, -2, 0,
			4, -16, -50, 11, 11, -7, -6, 4,
			-45, 6, 70, -28, -28, 11, 4, -5,
			-59, 13, 39, -21, -12, 9, 2, 2,
			12, -6, -13, -5, -2, 2, -3, 3,
			-10, 3, 3, -9, -3, 1, 5, 2,
			0, 0, 0, -2, -1, -4, 4, -1,
			-1, 0, -1, -5, -1, 0, 0, 1 };
	std::vector<int> vectInput(input, input + sizeof(input) / sizeof(int));

	for (int i = 0; i < 64; i++) {
		if (i % 8 == 0) {
			std::cout << "	; Row" << std::endl;
		}
		std::cout << "	mov ax, " << vectInput[i] << std::endl;
		std::cout << "	stosw" << std::endl;
	}
}

void createByteData() {
	std::vector<int> vect;

	for (int i = 0; i < 64; i++) {
		vect.push_back(2);
	}

	for (int i = 0; i < 64; i++) {
		if (i % 8 == 0) {
			std::cout << "	; Row" << std::endl;
		}
		std::cout << "	mov ax, " << vect[i] << std::endl;
		std::cout << "	stosb" << std::endl;
	}
}



#endif /* MATRIX_H_ */
