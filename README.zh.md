# NixOS on LicheePi 4A

> WIP 目前还没有成功启动

This repo contains the code to get NixOS running on LicheePi 4A.

## Parameters

<table>
<thead>
<tr>
  <th colspan=2>Main Chip</th>
</tr>
</thead>
<tbody>
<tr>
  <td>Name</td>
  <td>TH1520</td>
</tr>
<tr>
  <td>CPU</td>
  <td>
    RISC-V 64GCV C910*4@2GHz <br>
    · Each core contains 64KB I cache amd 64KB D Cache <br>
    · Shared 1MB L2 Cache <br>
    · Support TEE and REE, configered at core booting<br>
    · Support multi-core debugging framework of custom and RISC-V compatible interface<br>
    · Independent power domain, supports DVFS
  </td>
</tr>
<tr>
  <td>GPU</td>
  <td>
    · OpenCL 1.1/1.2/2.0<br>
    · OpenGL ES 3.0/3.1/3.2<br>
    · Vulkan 1.1/1.2<br>
    · Android NN HAL
  </td>
</tr>
<tr>
  <td>NPU</td>
  <td>
    Support 4TOPS@INT8, up to 1GHz <br>
    · Support TensorFlow、ONNX、Caffe <br>
    · Support CNN、RNN、DNN
  </td>
</tr>
</tbody>
</table>

## References

LicheePi 4A 官方主要支持 RevyOS，根据火哥文章介绍，它也是目前唯一且确实能够启用板载 GPU 的系统，
该操作系统项目基于 Debian 开发，默认提供了两个 rootfs 镜像，一个是基本功能的镜像，没有桌面环境；
另一个默认提供了 xfce4 桌面环境的系统镜像，为用户提供 RISC-V 下 XFCE4 的桌面操作体验。

RevyOS 的内核、u-boot 和 opensbi 代码仓库：

- https://github.com/revyos/thead-kernel.git
- https://github.com/revyos/thead-u-boot.git
- https://github.com/revyos/thead-opensbi.git

RevyOS 的预构建镜像下载地址

- https://mirror.iscas.ac.cn/revyos/extra/images/lpi4a/

LicheePi 4A 的官方教程：

- https://wiki.sipeed.com/hardware/zh/lichee/th1520/lpi4a/7_develop_revyos.html

根据如上 LicheePi 4A 相关文档，应该有三个分区镜像：

- u-boot-with-spl-lpi4a.bin: 刷入到 spl 分区的 u-boot 引导程序，与 NixOS 无关
- boot.ext4: boot 分区，包含 dtb、kernel image、opensbi 等文件，与 NixOS 同样无关
- rootfs.ext4: rootfs 分区，包含 NixOS 的根文件系统，只有这个分区与 NixOS 有关

u-boot-with-spl-lpi4a.bin 与 boot.ext4 都可直接从这里下载由中科院软件研究所提供的二进制文件：

- https://mirror.iscas.ac.cn/revyos/extra/images/lpi4a/

那么，只要我们能构建出 NixOS 可用的 rootfs.ext4 分区，就可以在 LicheePi 4A 上运行 NixOS 了。

## build rootfs

Before building, we need to enable riscv64-linux emulation on the host machine, for example, on NixOS, add the following line to system configuration:

```nix
boot.binfmt.emulatedSystems = [ "riscv64-linux" ];
```

Build sdImage(wich may take a long time, about 2 hours on my machine):

```shell
nix build .#nixosConfigurations.lp4a.config.system.build.sdImage --keep-failed
```

Extrace rootfs from sdImage:

方法一：

```shell
# mount the image
sudo losetup -P --show -f result/sd-image/nixos-sd-image-23.05.20230624.3ef8b37-riscv64-linux.img

# extract the rootfs partition
sudo dd if=/dev/loop0p2 of=rootfs.ext4 bs=1M status=progress

# umount the image
sudo losetup -d /dev/loop0
```

方法二：

```shell
IMG_FILE=$(result/sd-image/nixos-sd-image-*.img)

# check the partition of sdImage
› fdisk -lu ${IMG_FILE}
Disk result/sd-image/nixos-sd-image-23.05.20230624.3ef8b37-riscv64-linux.img: 1.81 GiB, 1940246528 bytes, 3789544 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x2178694e

Device                                                                   Boot Start     End Sectors  Size Id Type
result/sd-image/nixos-sd-image-23.05.20230624.3ef8b37-riscv64-linux.img1      16384   77823   61440   30M  b W95 FAT32
result/sd-image/nixos-sd-image-23.05.20230624.3ef8b37-riscv64-linux.img2 *    77824 3789543 3711720  1.8G 83 Linux

# extract the rootfs partition
# the rootfs' partition start from 77824 sector, and each sector is 512 bytes
# the command's format is
#    dd if=[image] of=[partition] bs=512 skip=Start count=Sectors
dd if=${IMG_FILE} of=rootfs.ext4 bs=512 skip=77824 count=3711720
```

得到的内容应该都是一样的。

## 镜像烧录到 eMMC

> 官方文档：https://wiki.sipeed.com/hardware/zh/lichee/th1520/lpi4a/4_burn_image.html

> 内核开发板不支持从 SD 卡启动，只能从 eMMC 启动！

构建好 rootfs 后我们就拥有了完整的三部分镜像，根据官方文档，内测版 LP4A 硬件的刷入流程如下：

1. 按住板上的 BOOT 按键不放，然后插入 USB-C 线缆上电（线缆另一头接 PC ），即可进入 USB 烧录模式（fastboot）。
   1. 在 Linux 下，使用 `lsusb` 查看设备，会显示以下设备： `ID 2345:7654 T-HEAD USB download gadget`
2. 接下来使用如下指令分别烧录镜像：
3. fastboot 程序直接从 [Android Platform Tools](https://developer.android.com/tools/releases/platform-tools) 下载，或者从包管理器安装都行。

```shell
# flash u-boot into spl partition
sudo fastboot flash ram u-boot-with-spl-lpi4a-20230510.bin
sudo fastboot reboot

# flash uboot partition
sudo fastboot flash uboot u-boot-with-spl-lpi4a-20230510.bin
# flash boot partition
sudo fastboot flash boot  boot-20230510-230240.ext4
# flash rootfs partition
sudo fastboot flash root rootfs.ext4
```

系统启动后，第一件事应该是扩容 rootfs 分区，因为默认情况下系统没有任何空闲空间：

```shell
sudo parted -s /dev/mmcblk0 "resizepart 3 -0"
sudo resize2fs /dev/mmcblk0p3
```

## See Also

There are other efforts to bring NixOS to RISC-V:

- https://github.com/zhaofengli/nixos-riscv64
- https://github.com/NickCao/nixos-riscv
