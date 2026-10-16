# 交叉编译配置
ARCH ?= arm64
CROSS_COMPILE ?= aarch64-linux-gnu-
# ========== 重点！这里填你的build输出目录 ==========
KERNELDIR ?= /home/ubuntu/workspace/02_LinuxKernel/build-gcc
PWD := $(shell pwd)

obj-m += main.o

all:
	$(MAKE) -C $(KERNELDIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) modules

clean:
	$(MAKE) -C $(KERNELDIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) clean

