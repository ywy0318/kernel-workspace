#!/bin/bash
# 内核调试工具子目录一键创建脚本
# 存放路径：13_KernelDebugTools/13_00_createdirs_kerneldebug_tool.sh

# 获取脚本所在根目录
TOOL_ROOT=$(cd "$(dirname "$0")" && pwd)
echo "内核调试工具根目录：${TOOL_ROOT}"

# 所有调试工具对应子目录清单
DIR_LIST=(
    printk_dmesg
    addr2line
    gdb_kernel
    readelf
    size_binutil
    perf
    ftrace_tracecmd
    KASAN
    strace
    bpftool_ebpf
    bpftrace
    kgdb
    kexec_kdump
    KCSAN
    crash
    LLVM
    checkpatch
    kmemleak
    LockDep
    blktrace
    io_uring
    devmem
)

# 批量创建目录
for dir in "${DIR_LIST[@]}"; do
    mkdir -p "${TOOL_ROOT}/${dir}"
    echo "已创建目录：${TOOL_ROOT}/${dir}"
done

# 生成目录对应说明文档 tool_dir_explain.txt
EXPLAIN_TXT="${TOOL_ROOT}/tool_dir_explain.txt"
# 纯echo追加写入说明文本，无cat重定向
echo "===================== 内核调试工具目录对应说明 =====================" > "${EXPLAIN_TXT}"
echo "1. printk_dmesg        存放printk、dmesg日志分析、Oops崩溃解析脚本与文档" >> "${EXPLAIN_TXT}"
echo "2. addr2line           存放内核栈地址符号解析addr2line实操案例" >> "${EXPLAIN_TXT}"
echo "3. gdb_kernel          内核GDB远程调试脚本、断点调试案例" >> "${EXPLAIN_TXT}"
echo "4. readelf             ELF内核镜像、ko驱动文件解析实操" >> "${EXPLAIN_TXT}"
echo "5. size_binutil        size工具分析内核镜像各段占用大小" >> "${EXPLAIN_TXT}"
echo "6. perf                perf性能采样、CPU/IO调度调优脚本与案例" >> "${EXPLAIN_TXT}"
echo "7. ftrace_tracecmd     ftrace、tracecmd内核函数追踪脚本" >> "${EXPLAIN_TXT}"
echo "8. KASAN               KASAN内核内存越界检测实验代码与日志" >> "${EXPLAIN_TXT}"
echo "9. strace              strace用户态程序系统调用跟踪实操" >> "${EXPLAIN_TXT}"
echo "10. bpftool_ebpf       bpftool操作eBPF程序、映射相关脚本" >> "${EXPLAIN_TXT}"
echo "11. bpftrace           bpftrace高性能追踪脚本案例" >> "${EXPLAIN_TXT}"
echo "12. kgdb               kgdb内核远程调试配置与实操" >> "${EXPLAIN_TXT}"
echo "13. kexec_kdump        kexec-tools、kdump内核崩溃转储捕获配置" >> "${EXPLAIN_TXT}"
echo "14. KCSAN              KCSAN并发数据竞争检测实验" >> "${EXPLAIN_TXT}"
echo "15. crash              crash工具分析kdump生成的内核转储文件" >> "${EXPLAIN_TXT}"
echo "16. LLVM               LLVM/Clang编译内核相关配置、实操文档" >> "${EXPLAIN_TXT}"
echo "17. checkpatch         checkpatch内核代码规范检查脚本与规则" >> "${EXPLAIN_TXT}"
echo "18. kmemleak           kmemleak内核内存泄漏检测日志与案例" >> "${EXPLAIN_TXT}"
echo "19. LockDep            LockDep内核死锁检测调试案例" >> "${EXPLAIN_TXT}"
echo "20. blktrace           blktrace块设备IO追踪、性能分析" >> "${EXPLAIN_TXT}"
echo "21. io_uring           io_uring异步IO框架测试脚本与文档" >> "${EXPLAIN_TXT}"
echo "22. devmem             devmem读写物理寄存器调试实操案例" >> "${EXPLAIN_TXT}"
echo "==================================================================" >> "${EXPLAIN_TXT}"

echo -e "\n✅ 全部工具目录创建完成"
echo "📄 目录说明文档已生成：${EXPLAIN_TXT}"
ls -d "${TOOL_ROOT}"/*/