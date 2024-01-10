#include <stdio.h>

// int main() {
//     // Write C code here
//     printf("Hello world");

//     return 0;
// }


void foo(int* x) {
   *x = 42;
}

void bug(int* y){
    if (*y>66){
    int *q = NULL;
    foo(q);
    *y = 55;}
    *y = 56;
}