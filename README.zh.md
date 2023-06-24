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
- boot.ext4: boot 分区，包含 dtb、kernel image、opensbi 等文件，需要与 NixOS 一起构建
- rootfs.ext4: rootfs 分区，包含 NixOS 的根文件系统，只有这个分区与 NixOS 有关

u-boot-with-spl-lpi4a.bin 可直接从这里下载由中科院软件研究所提供的二进制文件：

- https://mirror.iscas.ac.cn/revyos/extra/images/lpi4a/

那么，只要我们能构建出 NixOS 可用的 boot.ext4 跟 rootfs.ext4 分区，就可以在 LicheePi 4A 上运行 NixOS 了。

## 构建 boot 与 rootfs

Build sdImage(wich may take a long time, about 2 hours on my machine):

```shell
nix build .#nixosConfigurations.lp4a.config.system.build.sdImage --keep-failed
```

Extrace rootfs from sdImage:

方法一：

```shell
# mount the image
sudo losetup -P --show -f result/sd-image/nixos-sd-image-23.05.20230624.3ef8b37-riscv64-linux.img

# extract the boot partition
sudo dd if=/dev/loop0p2 of=boot.ext4 bs=1M status=progress

# extract the rootfs partition
sudo dd if=/dev/loop0p3 of=rootfs.ext4 bs=1M status=progress

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

构建好 boot 跟 rootfs 后我们就拥有了完整的三部分镜像，根据官方文档，内测版 LP4A 硬件的刷入流程如下：

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

## 记录下一些分析流程

rootfs 已经成功构建完成，内容如下：

```shell
╭───┬───────────────────────┬──────┬──────────┬──────────────╮
│ # │         name          │ type │   size   │   modified   │
├───┼───────────────────────┼──────┼──────────┼──────────────┤
│ 0 │ boot                  │ dir  │   4.1 KB │ 53 years ago │
│ 1 │ lost+found            │ dir  │  16.4 KB │ 53 years ago │
│ 2 │ nix                   │ dir  │   4.1 KB │ 53 years ago │
│ 3 │ nix-path-registration │ file │ 242.7 KB │ 53 years ago │
╰───┴───────────────────────┴──────┴──────────┴──────────────╯
```

可以看到 NixOS 对系统真的是清理得很彻底，整个根目录下一共就两个文件夹 `/boot` 跟 `/nix/store`.

仔细看下 `/boot` 的内容，因为现在要对它进行修改：

```shell
› tree
.
├── extlinux
│   └── extlinux.conf
└── nixos
    ├── rzc42b6qjxy10wb1wkfmrxjcxsw52015-linux-riscv64-unknown-linux-gnu-5.10.113-thead-1520-dtbs
    │   ├── sifive
    │   │   └── hifive-unleashed-a00.dtb
    │   └── thead
    │       ├── fire-emu-crash.dtb
    │       ├── fire-emu.dtb
    │       ├── fire-emu-gpu-dpu-dsi0.dtb
    │       ├── fire-emu-soc-base.dtb
    │       ├── fire-emu-soc-c910x4.dtb
    │       ├── fire-emu-vi-dsp-vo.dtb
    │       ├── fire-emu-vi-vp-vo.dtb
    │       ├── ice.dtb
    │       ├── light-ant-discrete-crash.dtb
    │       ├── light-ant-discrete.dtb
    │       ├── light-ant-ref-crash.dtb
    │       ├── light-ant-ref.dtb
    │       ├── light-a-product.dtb
    │       ├── light-a-ref-dsi0.dtb
    │       ├── light-a-ref-dsi0-hdmi.dtb
    │       ├── light-a-ref.dtb
    │       ├── light-a-val-android.dtb
    │       ├── light-a-val-audio.dtb
    │       ├── light-a-val-audio-hdmi.dtb
    │       ├── light-a-val-crash.dtb
    │       ├── light-a-val-ddr1G.dtb
    │       ├── light-a-val-ddr2G.dtb
    │       ├── light-a-val-dpi0-dpi1.dtb
    │       ├── light-a-val-dpi0.dtb
    │       ├── light-a-val-dsi0-dsi1.dtb
    │       ├── light-a-val-dsi0.dtb
    │       ├── light-a-val-dsi0-hdmi.dtb
    │       ├── light-a-val-dsi1.dtb
    │       ├── light-a-val.dtb
    │       ├── light-a-val-full.dtb
    │       ├── light-a-val-gpio-keys.dtb
    │       ├── light-a-val-hdmi.dtb
    │       ├── light-a-val-iso7816.dtb
    │       ├── light-a-val-khv.dtb
    │       ├── light-a-val-miniapp-hdmi.dtb
    │       ├── light-a-val-nand.dtb
    │       ├── light-a-val-npu-fce.dtb
    │       ├── light-a-val-sec.dtb
    │       ├── light-a-val-sv.dtb
    │       ├── light-a-val-wcn.dtb
    │       ├── light-beagle.dtb
    │       ├── light-b-power.dtb
    │       ├── light-b-product-crash.dtb
    │       ├── light-b-product-ddr1G.dtb
    │       ├── light-b-product.dtb
    │       ├── light-b-product-miniapp-hdmi.dtb
    │       ├── light-b-ref.dtb
    │       ├── light-fm-emu-audio.dtb
    │       ├── light-fm-emu-dsi0-hdmi.dtb
    │       ├── light-fm-emu-dsp.dtb
    │       ├── light-fm-emu.dtb
    │       ├── light-fm-emu-gpu.dtb
    │       ├── light-fm-emu-hdmi.dtb
    │       ├── light-fm-emu-npu-fce.dtb
    │       ├── light-lpi4a-ddr2G.dtb
    │       ├── light-lpi4a.dtb
    │       └── light_mpw.dtb
    ├── rzc42b6qjxy10wb1wkfmrxjcxsw52015-linux-riscv64-unknown-linux-gnu-5.10.113-thead-1520-Image
    └── vh8624bjxdpxh7ds3nqvqbx992yx63hp-initrd-linux-riscv64-unknown-linux-gnu-5.10.113-thead-1520-initrd

5 directories, 61 files
```

对照一下 revyos 官方的 boot 分区内容，应该就比较能理解，需要添加些啥了：

```shell
› tree
.
├── config-5.10.113-gfac22a756532
├── fw_dynamic.bin
├── Image
├── kernel-commitid
├── light_aon_fpga.bin
├── light_c906_audio.bin
├── light-lpi4a.dtb
├── System.map-5.10.113-gfac22a756532
└── vmlinuz-5.10.113-gfac22a756532
```

其中几个固件名称很熟悉，看了下果然这里就有： https://github.com/chainsx/fedora-riscv-builder/tree/main/firmware

现在要解决的就是，把 NixOS 的 `/boot` 单独拆分成一个分区，`/` 中只留一个空文件夹作为挂载点，然后参照 revyos 的 boot 分区，将相关的驱动文件复制到新的 boot 分区中。

还有就是，NixOS 的 Image 跟 initrd 文件名称都非常长，可能要研究下怎么配置 uboot 使它能够识别到。

看这里有说，好像可以通过在 boot 分区建一个 `config.txt` 解决问题：

https://github.com/chainsx/armbian-riscv-build/blob/f66314b1eb02736fcb665fbd4047fc207a91fac5/doc/licheepi-4a-install-guide.md?plain=1#L38

```shell
fdt_file=light-lpi4a.dtb
kernel_file=Image
bootargs=console=ttyS0,115200 root=/dev/mmcblk0p3 rootfstype=ext4 rootwait rw earlycon clk_ignore_unused loglevel=7 eth=$ethaddr rootrwoptions=rw,noatime rootrwreset=yes init=/lib/systemd/systemd
```

## See Also

There are other efforts to bring NixOS to RISC-V:

- https://github.com/zhaofengli/nixos-riscv64
- https://github.com/NickCao/nixos-riscv
