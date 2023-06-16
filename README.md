# NixOS on LicheePi 4A

> :warning: Work in progress, use at your own risk...

[[中文]](./README.zh.md)

This repo contains the code to get NixOS running on LicheePi 4A.

## TODO

- [ ] fix `Error: unrecognized opcode 'csrr a5,0xc01', , it seems I need to enable the riscv64's zicsr extension`
  - added `gcc.arch = "rv64gc";`, but still not working...
  - some issues may related to this error
    - https://github.com/NixOS/nixpkgs/issues/235179
    - https://github.com/NixOS/nixpkgs/issues/101651

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
- unofficial kernel
  - https://github.com/kangaroo/linux-lpi4a/tree/master
- other docs
  - https://github.com/plctlab/PLCT-Weekly/blob/master/2023/2023-06-01.md

the basic idea is to use revyos's kernel, u-boot and opensbi, with a NixOS rootfs, to get NixOS running on LicheePi 4A.

We need 3 parts of images:

- u-boot-with-spl-lpi4a.bin: the u-boot-loader which will be flashed into spl partition, not related to NixOS
- boot.ext4: the boot partition, contains dtb, kernel image, opensbi, etc, not related to NixOS
- rootfs.ext4: the rootfs partition, we need to build it with NixOS

we can download the prebuilt u-boot-with-spl-lpi4a.bin and boot.ext4 from here:

- https://mirror.iscas.ac.cn/revyos/extra/images/lpi4a/

## build rootfs

Before building, we need to enable riscv64-linux emulation on the host machine, for example, on NixOS, add the following line to system configuration:

```nix
boot.binfmt.emulatedSystems = [ "riscv64-linux" ];
```

Then run the following command to build:

```shell
# build sdImage
nix build .#nixosConfigurations.lp4a-cross.config.system.build.sdImage
# TODO get rootfs from sdImage
```

## flash images

> Official Docs: https://wiki.sipeed.com/hardware/zh/lichee/th1520/lpi4a/4_burn_image.html

> The internal test development board does not support booting from SD card, we should flash images into the board's eMMC.

According to the official docs, the flash process of the internal test version LP4A hardware is as follows:

1. Press and hold the BOOT button on the board, then plug in the USB-C cable to power on (the other end of the cable is connected to the PC), and you can enter the USB burning mode (fastboot).
   1. the command `lsusb | grep T-HEAD` should print `ID 2345:7654 T-HEAD USB download gadget`
2. Then use the following command to flash the image into the board's eMMC.
   1. The fastboot program can be downloaded directly from [Android Platform Tools](https://developer.android.com/tools/releases/platform-tools), or installed from the package manager.

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

After boot the system, the first thing to do is to expand the rootfs partition, because by default the system has no free space:

```shell
sudo parted -s /dev/mmcblk0 "resizepart 3 -0"
sudo resize2fs /dev/mmcblk0p3
```

## See Also

There are other efforts to bring NixOS to RISC-V:

- https://github.com/zhaofengli/nixos-riscv64
- https://github.com/NickCao/nixos-riscv
