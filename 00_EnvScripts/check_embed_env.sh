
#!/bin/bash
echo "====================嵌入式环境校验开始===================="
error_cnt=0

# 1.AArch64交叉编译工具链
echo -e "\n[1/7] 校验AArch64交叉编译器（Uboot/Kernel编译）"
if command -v aarch64-linux-gnu-gcc &> /dev/null;then
    aarch64-linux-gnu-gcc --version | head -n1
else
    echo "❌ aarch64-linux-gnu-gcc 未安装"
    ((error_cnt++))
fi
if command -v aarch64-linux-gnu-g++ &> /dev/null;then
    aarch64-linux-gnu-g++ --version | head -n1
else
    echo "❌ aarch64-linux-gnu-g++ 未安装"
    ((error_cnt++))
fi

# 2.GCC + Clang/LLVM
echo -e "\n[2/7] 校验GCC、Clang、LLVM"
if command -v gcc &> /dev/null;then
    gcc --version | head -n1
else
    echo "❌ gcc未安装"
    ((error_cnt++))
fi
if command -v clang &> /dev/null;then
    clang --version | head -n1
else
    echo "❌ clang未安装"
    ((error_cnt++))
fi
if command -v llvm-config &> /dev/null;then
    llvm-config --version
else
    echo "❌ llvm未安装"
    ((error_cnt++))
fi
if command -v lld &> /dev/null;then
    lld --version | head -n1
else
    echo "❌ lld未安装"
    ((error_cnt++))
fi

#3.QEMU全套虚拟机
echo -e "\n[3/7] 校验QEMU仿真环境"
if command -v qemu-system-aarch64 &> /dev/null;then
    qemu-system-aarch64 --version | head -n1
else
    echo "❌ qemu-system-aarch64缺失"
    ((error_cnt++))
fi
if command -v qemu-system-x86_64 &> /dev/null;then
    qemu-system-x86_64 --version | head -n1
else
    echo "❌ qemu-system-x86缺失"
    ((error_cnt++))
fi
if command -v qemu-img &> /dev/null;then
    qemu-img --version | head -n1
else
    echo "❌ qemu-utils缺失"
    ((error_cnt++))
fi

#4.DTS设备树dtc
echo -e "\n[4/7] 校验设备树编译工具dtc"
if command -v dtc &> /dev/null;then
    dtc -v
else
    echo "❌ dtc(设备树编译器)未安装"
    ((error_cnt++))
fi

#5.内核调试 gdb / crash
echo -e "\n[5/7] 校验内核调试gdb、crash"
if command -v gdb-multiarch &> /dev/null;then
    gdb-multiarch --version | head -n1
else
    echo "❌ gdb-multiarch缺失"
    ((error_cnt++))
fi
if command -v crash &> /dev/null;then
    crash -v | head -n1
else
    echo "❌ crash调试工具缺失"
    ((error_cnt++))
fi

#6.BusyBox/Buildroot/Yocto依赖（打包工具）
echo -e "\n[6/7] 校验文件系统构建依赖(unzip/bzip2/cpio/rsync)"
for bin in unzip bzip2 cpio rsync;do
    if command -v $bin &> /dev/null;then
        echo "✅ $bin 正常"
    else
        echo "❌ $bin 缺失"
        ((error_cnt++))
    fi
done

#7.Oops/Panic调试依赖 libdw libunwind(通过dpkg校验包)
echo -e "\n[7/7] 校验Oops/Panic调试库 libdw-dev libunwind-dev"
for pkg in libdw-dev libunwind-dev;do
    if dpkg -s $pkg &> /dev/null;then
        echo "✅ $pkg 已安装"
    else
        echo "❌ $pkg 未安装"
        ((error_cnt++))
    fi
done

# 汇总结果
echo -e "\n====================校验结束===================="
if [ $error_cnt -eq 0 ];then
    echo "✅ 全部组件安装正常，嵌入式开发环境就绪！"
else
    echo "❌ 共计${error_cnt}项缺失，需要重新安装对应依赖"
fi
