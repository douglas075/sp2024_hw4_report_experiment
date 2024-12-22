#include <stdio.h>
#include <stdlib.h>

// #define NUM_ROW_COL 1000
// #define NUM_MATRIX 20
#define NUM_WORK 1000
#define ENTRY_RANGE 100
#define RAND_MOD (2 * ENTRY_RANGE + 1)

int main(int argc, char **argv)
{
	if (argc != 3) {
		fprintf(stderr, "usage: ./gen <size_of_matrix> <num_of_matrix>\n");
		return 0;
	}
	int size_of_matrix = atoi(argv[1]);
	int num_of_matrix = atoi(argv[2]);

	FILE *fp = fopen("testcase", "w");
	if (fp == NULL) {
		perror("file open failed");
		return 0;
	}
	fprintf(fp, "%d\n%d\n",size_of_matrix, num_of_matrix);
	
	srand(1);
	for (int mat = 0; mat < num_of_matrix; mat++) {
		for (int j = 0; j < 2; j++) {
			for (int row = 0; row < size_of_matrix; row++) {
				for (int col = 0; col < size_of_matrix; col++) {
					fprintf(fp, "%d", (rand() % RAND_MOD) - ENTRY_RANGE);
					fprintf(fp, "%c", (col == size_of_matrix - 1)?'\n':' ');
				}
			}
		}
		fprintf(fp, "%d\n", NUM_WORK);
	}
	fclose(fp);
	fprintf(stderr, "successful generate %d matrix multiplications of size %d\n", num_of_matrix, size_of_matrix);
	return 0;
}
