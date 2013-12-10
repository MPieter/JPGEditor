
// CPP code voor het transponeren van een matrix

#include <vector>

void transpose (std::vector<int>* input, std::vector<int>* output) {

	int width = 8;

	for (int i = 0; i < 8; i++) {
		for (int j = 0; j < 8; j++) {
			output[j*8 + i] = input[i*8 + j];

		}
	}

	// Shorter version
	for (int i = 63; i >= 0; i--) {
		output[(i % 8)*8 + i / 8] = input[i];
	}
}