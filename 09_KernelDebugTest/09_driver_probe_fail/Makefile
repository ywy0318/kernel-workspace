obj-m += panic_demo.o
# ========= 这里改成你的构建输出目录，不是源码目录！=========
KDIR ?= /home/ubuntu/workspace/02_LinuxKernel/build-gcc
# 改成你的目标架构，比如arm64
ARCH ?= arm64
# 你的交叉编译器前缀
CROSS_COMPILE ?= aarch64-linux-gnu-
# ======================================================
PWD := $(shell pwd)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

