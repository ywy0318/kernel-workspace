#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include <netinet/in.h>
#include <netinet/ip_icmp.h>
#include <net/route.h>
#include <net/if.h>
#include <arpa/inet.h>

#define IFNAME "eth0"
#define PING_PACKET_SIZE 64
static int ping_stop = 0;

// -------------------------- 网关设置 gw_add 功能 --------------------------
static in_addr_t ip2addr(const char *ip)
{
    unsigned int a, b, c, d;
    sscanf(ip, "%u.%u.%u.%u", &a, &b, &c, &d);
    return (a << 24) | (b << 16) | (c << 8) | d;
}

static int gw_add_main(int argc, char *argv[])
{
    if (argc != 2)
    {
        fprintf(stderr, "用法：%s gw_add <网关IP>\n", argv[0]);
        return 1;
    }
    int sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0) return 1;
    struct rtentry rt;
    memset(&rt, 0, sizeof(rt));
    ((struct sockaddr_in *)&rt.rt_dst)->sin_family = AF_INET;
    ((struct sockaddr_in *)&rt.rt_dst)->sin_addr.s_addr = 0;
    ((struct sockaddr_in *)&rt.rt_gateway)->sin_family = AF_INET;
    ((struct sockaddr_in *)&rt.rt_gateway)->sin_addr.s_addr = ip2addr(argv[1]);
    strncpy(rt.rt_dev, IFNAME, IFNAMSIZ - 1);
    rt.rt_flags = RTF_GATEWAY | RTF_UP;
    ioctl(sockfd, SIOCADDRT, &rt);
    close(sockfd);
    printf("默认网关 %s 添加成功\n", argv[1]);
    return 0;
}

// -------------------------- ifconfig 网卡配置功能 --------------------------
static void print_if_info(const char *ifname)
{
    int fd = socket(AF_INET, SOCK_DGRAM, 0);
    struct ifreq ifr;
    memset(&ifr, 0, sizeof(ifr));
    strncpy(ifr.ifr_name, ifname, IFNAMSIZ - 1);
    printf("网卡：%s\n", ifname);
    if (ioctl(fd, SIOCGIFADDR, &ifr) == 0)
    {
        struct sockaddr_in *addr = (struct sockaddr_in *)&ifr.ifr_addr;
        printf("  IP地址：%s\n", inet_ntoa(addr->sin_addr));
    }
    if (ioctl(fd, SIOCGIFNETMASK, &ifr) == 0)
    {
        struct sockaddr_in *mask = (struct sockaddr_in *)&ifr.ifr_netmask;
        printf("  子网掩码：%s\n", inet_ntoa(mask->sin_addr));
    }
    ioctl(fd, SIOCGIFFLAGS, &ifr);
    printf("  状态：%s\n", (ifr.ifr_flags & IFF_UP) ? "UP 已启用" : "DOWN 已关闭");
    close(fd);
}

static void set_if_addr(const char *ifname, const char *ip, const char *netmask)
{
    int fd = socket(AF_INET, SOCK_DGRAM, 0);
    struct ifreq ifr;
    memset(&ifr, 0, sizeof(ifr));
    strncpy(ifr.ifr_name, ifname, IFNAMSIZ - 1);
    struct sockaddr_in sin;
    sin.sin_family = AF_INET;
    sin.sin_addr.s_addr = inet_addr(ip);
    memcpy(&ifr.ifr_addr, &sin, sizeof(sin));
    ioctl(fd, SIOCSIFADDR, &ifr);
    sin.sin_addr.s_addr = inet_addr(netmask);
    memcpy(&ifr.ifr_netmask, &sin, sizeof(sin));
    ioctl(fd, SIOCSIFNETMASK, &ifr);
    ioctl(fd, SIOCGIFFLAGS, &ifr);
    ifr.ifr_flags |= IFF_UP;
    ioctl(fd, SIOCSIFFLAGS, &ifr);
    close(fd);
    printf("网卡 %s 配置完成 IP:%s 掩码:%s\n", ifname, ip, netmask);
}

static int ifconfig_main(int argc, char *argv[])
{
    if (argc == 2)
    {
        print_if_info(argv[1]);
    }
    else if (argc == 4)
    {
        set_if_addr(argv[1], argv[2], argv[3]);
    }
    else
    {
        fprintf(stderr, "用法：\n");
        fprintf(stderr, "  查看网卡：%s ifconfig eth0\n", argv[0]);
        fprintf(stderr, "  设置地址：%s ifconfig eth0 10.0.2.15 255.255.255.0\n", argv[0]);
        return 1;
    }
    return 0;
}

// -------------------------- ping 连通测试功能 --------------------------
static void ping_sigint(int sig)
{
    (void)sig;
    ping_stop = 1;
}

static unsigned short icmp_checksum(unsigned short *buf, int len)
{
    unsigned int sum = 0;
    while (len > 1)
    {
        sum += *buf++;
        len -= 2;
    }
    if (len == 1)
        sum += *(unsigned char *)buf;
    sum = (sum >> 16) + (sum & 0xffff);
    sum += (sum >> 16);
    return ~sum;
}

static int ping_main(int argc, char *argv[])
{
    if (argc != 2)
    {
        fprintf(stderr, "用法：%s ping 目标IP\n", argv[0]);
        return 1;
    }
    signal(SIGINT, ping_sigint);
    int sock = socket(AF_INET, SOCK_RAW, IPPROTO_ICMP);
    if (sock < 0)
    {
        perror("socket");
        return 1;
    }
    struct sockaddr_in dest;
    memset(&dest, 0, sizeof(dest));
    dest.sin_family = AF_INET;
    dest.sin_addr.s_addr = inet_addr(argv[1]);
    if (dest.sin_addr.s_addr == INADDR_NONE)
    {
        fprintf(stderr, "无效IP地址\n");
        close(sock);
        return 1;
    }
    char packet[PING_PACKET_SIZE];
    struct icmphdr *icmp = (struct icmphdr *)packet;
    int seq = 0;
    // 修复 %d 格式警告，强转为int
    printf("PING %s (%s) %d bytes data\n", argv[1], inet_ntoa(dest.sin_addr), (int)(PING_PACKET_SIZE - sizeof(struct icmphdr)));
    while (!ping_stop)
    {
        memset(packet, 0, PING_PACKET_SIZE);
        icmp->type = ICMP_ECHO;
        icmp->code = 0;
        icmp->un.echo.id = getpid() & 0xffff;
        icmp->un.echo.sequence = seq++;
        icmp->checksum = icmp_checksum((unsigned short *)packet, PING_PACKET_SIZE);
        struct timeval send_tv;
        gettimeofday(&send_tv, NULL);
        sendto(sock, packet, PING_PACKET_SIZE, 0, (struct sockaddr *)&dest, sizeof(dest));
        char recv_buf[128];
        socklen_t addr_len = sizeof(dest);
        int ret = recvfrom(sock, recv_buf, sizeof(recv_buf), MSG_DONTWAIT, (struct sockaddr *)&dest, &addr_len);
        if (ret > 0)
        {
            struct timeval recv_tv;
            gettimeofday(&recv_tv, NULL);
            long ms = (recv_tv.tv_sec - send_tv.tv_sec) * 1000 + (recv_tv.tv_usec - send_tv.tv_usec) / 1000;
            printf("%d bytes from %s  seq=%d  time=%ldms\n", ret - 20, argv[1], seq - 1, ms);
        }
        usleep(1000000);
    }
    close(sock);
    printf("\nping 已终止\n");
    return 0;
}

// -------------------------- 主入口 分发功能 --------------------------
int main(int argc, char *argv[])
{
    if (argc < 2)
    {
        fprintf(stderr, "网络工具三合一程序，支持三个子命令：\n");
        fprintf(stderr, "  %s gw_add <网关IP>      添加默认网关\n", argv[0]);
        fprintf(stderr, "  %s ifconfig eth0        查看网卡信息\n", argv[0]);
        fprintf(stderr, "  %s ifconfig eth0 IP 掩码 设置网卡地址\n", argv[0]);
        fprintf(stderr, "  %s ping <IP>            连通性测试\n", argv[0]);
        return 1;
    }
    // 把子命令偏移，传给对应功能函数
    char *subcmd = argv[1];
    int new_argc = argc - 1;
    char **new_argv = argv + 1;
    if (strcmp(subcmd, "gw_add") == 0)
        return gw_add_main(new_argc, new_argv);
    else if (strcmp(subcmd, "ifconfig") == 0)
        return ifconfig_main(new_argc, new_argv);
    else if (strcmp(subcmd, "ping") == 0)
        return ping_main(new_argc, new_argv);
    else
    {
        fprintf(stderr, "未知子命令：%s\n", subcmd);
        return 1;
    }
}
