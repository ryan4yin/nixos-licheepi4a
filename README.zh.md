# NixOS on LicheePi 4A

> :warning: WIP 项目仍在开发中，请自行评估使用风险...

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

Projects & Docs related to LicheePi 4A:

- official repo: https://github.com/sipeed/LicheePi4A/tree/pre-view
  - it uses revyos's kernel, u-boot and opensbi:
    - https://github.com/revyos/thead-kernel.git
    - https://github.com/revyos/thead-u-boot.git
    - https://github.com/revyos/thead-opensbi.git
  - revyos's prebuilt binaries download link:
    - https://mirror.iscas.ac.cn/revyos/extra/images/lpi4a/
  - official article(Chinese): https://wiki.sipeed.com/hardware/zh/lichee/th1520/lpi4a/7_develop_revyos.html
- thead's repo, a demo project from thead:
  - https://gitee.com/thead-yocto/light_deploy_images
  - https://gitee.com/thead-yocto/xuantie-yocto
  - https://gitee.com/thead-yocto/documents
  - official article(Chinese): https://wiki.sipeed.com/hardware/zh/lichee/th1520/lpi4a/7_develop_thead.html
- unofficial armbian/ubuntu/fedora:
  - https://github.com/chainsx/fedora-riscv-builder
  - https://github.com/chainsx/armbian-riscv-build
- unofficial deepin & openkylin
  - https://github.com/aiminickwong/licheepi4a-images
- unofficial u-boot
  - https://github.com/dlan17/u-boot/tree/th1520
  - https://github.com/chainsx/thead-u-boot/tree/lpi4a
- other docs
  - https://github.com/plctlab/PLCT-Weekly/blob/master/2023/2023-06-01.md

已知信息：

- 平头哥官方提供的工具链基于 Linux 5.10 内核: https://gitee.com/thead-yocto
- 根据如上 LicheePi 4A 相关文档，应该有三个分区镜像：
  - u-boot-with-spl-lpi4a.bin: 刷入到 spl 分区的 u-boot 引导程序，与 NixOS 无关
  - boot.ext4: boot 分区，包含 dtb、kernel image、opensbi 等文件，与 NixOS 同样无关
  - rootfs.ext4: rootfs 分区，包含 NixOS 的根文件系统，只有这个分区与 NixOS 有关
- u-boot-with-spl-lpi4a.bin 与 boot.ext4 都可直接从这里下载由中科院软件研究所提供的二进制文件：
  - https://mirror.iscas.ac.cn/revyos/extra/images/lpi4a/

那么，只要我们能构建出 NixOS 可用的 rootfs.ext4 分区，就可以在 LicheePi 4A 上运行 NixOS 了。

## rootfs 构建

构建前，需要先在宿主机启用 riscv64-linux 模拟，以 NixOS 为例，系统配置中添加如下一行：

```nix
boot.binfmt.emulatedSystems = [ "riscv64-linux" ];
```

然后使用如下命令执行构建：

```shell
# build sdImage
nix build .#nixosConfigurations.lp4a.config.system.build.sdImage
# TODO get rootfs from sdImage
```

构建用时：5 + 00:16 =>

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

## 将 gcc 工具链替换为 T-Head 官方的

最近遇到的各种问题，很多都是因为使用了 NixOS 的标准工具链导致的，到目前也没解决。

通过 devShell 创建了一个 FHS 环境，用 T-Head 提供的工具链编译，发现完全不报错，但切换回 NixOS 的工具链就会有错误。

所以还是决定直接使用 T-Head 提供的工具链，这样也能保证与官方的开发环境一致。

那么现在的问题就是，如何替换掉 nixpkgs 中的交叉编译工具链？

这里找到个配置 https://github.com/tattvam/nix-polarfire/blob/master/icicle-kit/default.nix

```nix
with import <nixpkgs> {
  crossSystem = {
    config = "riscv64-unknown-linux-gnu";
  };
  overlays = [ (self: super: { gcc = self.gcc11; }) ];
};
rec {

  uboot-polarfire-icicle-kit = callPackage ./uboot { defconfig = "microchip_mpfs_icicle"; };
  linux-polarfire-icicle-kit = callPackage ./linux { };
}
```

通过 `nix repl` 验证了确实是 work 的：

```shell
› nix repl -f '<nixpkgs>'
Welcome to Nix 2.13.3. Type :? for help.

Loading installable ''...
Added 17755 variables.

# 通过 overlays 替换掉 gcc
nix-repl> a = import <nixpkgs> {   crossSystem = {     config = "riscv64-unknown-linux-gnu";   };   overlays = [ (self: super: { gcc = self.gcc12; }) ]; }

# 查看下 gcc 版本，确实改成 12.2 了
nix-repl> a.pkgsCross.riscv64.stdenv.cc
«derivation /nix/store/jjvvwnf3hzk71p65x1n8bah3hrs08bpf-riscv64-unknown-linux-gnu-stage-final-gcc-wrapper-12.2.0.drv»

# 再看下未修改的 gcc 版本，还是 11.3
nix-repl> pkgs.pkgsCross.riscv64.stdenv.cc
«derivation /nix/store/pq3g0wq3yfc4hqrikr03ixmhqxbh35q7-riscv64-unknown-linux-gnu-stage-final-gcc-wrapper-11.3.0.drv»
```

那么如果我们要将 T-Head 的工具链使用上述 overlays 方式替换进来，现在得考虑下如何将 T-Head 工具链打包成一个 derivation。

T-Head 的工具链用的是 gcc 10，查看下 gcc 10 的 derivation：

https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/compilers/gcc/10/default.nix

那么直接 override 掉 src 跟 version 咋样？看看效果：

```nix
pkgs-thead = import <nixpkgs> {
  crossSystem = {
    config = "riscv64-unknown-linux-gnu";
  };
  overlays = [
    (self: super: {
      gcc = self.gcc10.overrideAttrs {
        version = "10.2.0";
        src = fetchurl {
          url = "https://occ-oss-prod.oss-cn-hangzhou.aliyuncs.com/resource/1663142514282/Xuantie-900-gcc-linux-5.10.4-glibc-x86_64-V2.6.1-20220906.tar.gz";
          sha256 = "";  # 先不填，这样 Nix 会报错并提示正确的 sha256 值，然后 copy 过来就行。
        };
      };
    })
  ];
}
```

最后还是失败了，t-head 只提供了二进制包，不是源代码，所以上面这种方法行不通。问了 NixOS 人形自动回答机器人 Nick Cao 大佬，结论是需要自己完全复现 gcc-unwrapper 的文件夹结构，非常繁琐麻烦，所以还是放弃了。

## See Also

There are other efforts to bring NixOS to RISC-V:

- https://github.com/zhaofengli/nixos-riscv64
- https://github.com/NickCao/nixos-riscv
