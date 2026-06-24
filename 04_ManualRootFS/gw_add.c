#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <linux/route.h>
#include <unistd.h>

static in_addr_t ip2addr(const char *ip)
{
    unsigned int a, b, c, d;
    sscanf(ip, "%u.%u.%u.%u", &a, &b, &c, &d);
    return (a << 24) | (b << 16) | (c << 8) | d;
}

int main(int argc, char *argv[])
{
    if (argc != 2)
    {
        fprintf(stderr, "Usage: %s <gateway_ip>\n", argv[0]);
        return 1;
    }

    int sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0)
        return 1;

    struct rtentry rt;
    memset(&rt, 0, sizeof(rt));

    ((struct sockaddr_in *)&rt.rt_dst)->sin_family = AF_INET;
    ((struct sockaddr_in *)&rt.rt_dst)->sin_addr.s_addr = 0;

    ((struct sockaddr_in *)&rt.rt_gateway)->sin_family = AF_INET;
    ((struct sockaddr_in *)&rt.rt_gateway)->sin_addr.s_addr = ip2addr(argv[1]);

    // 直接使用 IFNAMSIZ，由 linux/route.h 依赖的头文件提供
    strncpy(rt.rt_dev, "eth0", IFNAMSIZ - 1);
    rt.rt_flags = RTF_GATEWAY | RTF_UP;

    ioctl(sockfd, SIOCADDRT, &rt);
    close(sockfd);
    return 0;
}
