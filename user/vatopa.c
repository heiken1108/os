#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"


int main(int argc, char const *argv[])
{
    if (argc == 2) {
        uint64 viradr = atoi(argv[1]);
        int pid = getpid();
        uint64 phyadr = va2pa(viradr, pid);
        printf("0x%x\n", phyadr);
    } else if (argc == 3) {
        uint64 viradr = atoi(argv[1]);
        int pid = atoi(argv[2]);
        uint64 phyadr = va2pa(viradr, pid);
        printf("0x%x\n", phyadr);
    } else {
        printf("Usage: vatopa virtual_address [pid]\n");
    }
    return 0;
}
