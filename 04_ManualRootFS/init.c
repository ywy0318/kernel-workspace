#include <stdio.h>
#include <unistd.h>
#include <sys/mount.h>

int main(void)
{
    // 挂载 proc/sysfs 文件系统
    mount("proc", "/proc", "proc", 0, NULL);
    mount("sysfs", "/sys", "sysfs", 0, NULL);

    // 执行 /bin/sh，修正 execve 参数
    char *argv[] = {"/bin/sh", NULL};
    execve("/bin/sh", argv, NULL);

    return 0;
}
