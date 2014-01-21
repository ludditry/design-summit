#include <stdio.h>


int main(int argc, char *argv[])
{
    if (argc > 1) {
        int i = 0;
        printf("stdout: ");
        fprintf(stderr, "stderr: ");
        for (i = 1; i < argc; i++) {
            printf("%s ", argv[i]);
            fprintf(stderr, "%s ", argv[i]);
        }
        printf("\n");
        fprintf(stderr, "\n");
    }
    else {
        fprintf(stderr, "You must type a message to echo!\n");
    }

    return 0;
}
