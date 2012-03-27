#include <stdio.h>

extern void bsort(size_t len, long *array);
extern void msort(size_t len, long *array);

void parray(size_t len, long *array) {
    int i;
    for (i = 0; i < len; i++) {
        printf("%d,", array[i]);
    }
    printf("\n");
}

int main(int argc, char **argv) {

    long x[] = { 6,1,3,7,124,7,23,6,7,23,7,4,12,6,1 };
    size_t len = sizeof(x) / sizeof(x[0]);

    parray(len, x);

    msort(len, x);
    parray(len, x);

    return 0;
}
