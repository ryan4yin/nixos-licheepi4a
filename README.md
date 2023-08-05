# NixOS on LicheePi 4A

> work in progress.

[[中文]](./README.zh.md)

This repo contains the code to get NixOS running on LicheePi 4A.

![](./_img/nixos-licheepi-neofetch.webp)

## TODO

- [ ] release an image

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

LicheePi 4A use RevyOS officially.

RevyOS's kernel, u-boot and opensbi:

- https://github.com/revyos/thead-kernel.git
- https://github.com/revyos/thead-u-boot.git
- https://github.com/revyos/thead-opensbi.git

RevyOS's prebuilt binaries download link:

- https://mirror.iscas.ac.cn/revyos/extra/images/lpi4a/

Official article(Chinese): https://wiki.sipeed.com/hardware/zh/lichee/th1520/lpi4a/7_develop_revyos.html

the basic idea is to use revyos's kernel, u-boot and opensbi, with a NixOS rootfs, to get NixOS running on LicheePi 4A.

We need 3 parts of images:

- u-boot-with-spl-lpi4a.bin: the u-boot-loader which will be flashed into spl partition, not related to NixOS
- boot.ext4: the boot partition, contains dtb, kernel image, opensbi, etc, we need to build it with NixOS,
- rootfs.ext4: the rootfs partition, we need to build it with NixOS

We can download the prebuilt u-boot-with-spl-lpi4a.bin from here:

- https://mirror.iscas.ac.cn/revyos/extra/images/lpi4a/

## Build boot & rootfs

Build sdImage(which may take a long time, about 2 hours on my machine):

```shell
nix build .#nixosConfigurations.lp4a.config.system.build.sdImage --keep-failed
```

Extrace rootfs from sdImage:

```shell
# mount the image
sudo losetup -P --show -f $(ls result/sd-image/nixos-*-riscv64-linux.img)

# extract the rootfs partition
sudo dd if=/dev/loop0p2 of=rootfs.ext4 bs=1M status=progress

# umount the image
sudo losetup -d /dev/loop0
```

## Flash images

> Official Docs: https://wiki.sipeed.com/hardware/zh/lichee/th1520/lpi4a/4_burn_image.html

> The internal test development board does not support booting from SD card, we should flash images into the board's eMMC.

According to the official docs, the flash process of the internal test version LP4A hardware is as follows:

1. Press and hold the BOOT button on the board, then plug in the USB-C cable to power on (the other end of the cable is connected to the PC), and you can enter the USB burning mode (fastboot).
   1. the command `lsusb | grep T-HEAD` should print `ID 2345:7654 T-HEAD USB download gadget`
2. Then use the following command to flash the image into the board's eMMC.
   1. The fastboot program can be downloaded directly from [Android Platform Tools](https://developer.android.com/tools/releases/platform-tools), or installed from the package manager.

```shell
# flash u-boot into spl partition
sudo fastboot flash ram u-boot-with-spl.bin
sudo fastboot reboot
# flash uboot partition
sudo fastboot flash uboot u-boot-with-spl.bin

# flash nixos's rootfs partition
sudo fastboot flash root rootfs.ext4
```

## Debug with QEMU

Generate the image for QEMU:

```shell
nix build .#nixosConfigurations.qemu.config.system.build.sdImage --keep-failed
```

## See Also

There are other efforts to bring NixOS to RISC-V:

- https://github.com/zhaofengli/nixos-riscv64
- https://github.com/NickCao/nixos-riscv
