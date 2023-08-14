# NixOS on LicheePi 4A

This repo contains the code to get NixOS running on LicheePi 4A.

![](./_img/nixos-licheepi-neofetch.webp)

Default user: `lp4a`, default password: `lp4a`.

## TODO

- [x] release an image
- [x] build opensbi from source
- [x] build u-boot from source
- [ ] support flashing rootfs into emmc
- [ ] debug with qemu
- [ ] verify all the hardware features available by th1520
    - [x] ethernet (rj45)
    - wifi/bluetooth
    - audio
    - [x] gpio
    - [x] uart/ttl
    - gpu
    - npu
    - ...

## Build u-boot & sdImage

> You can skip this step if you just want to flash the prebuilt image.


Build u-boot:

```shell
nix build .#uboot -L --show-trace
```

After the build is complete, the u-boot will be in `result/u-boot-with-spl.bin`, please copy it to another place for later use.

Build sdImage(which may take a long time, about 2 hours on my machine):

```shell
nix build .#sdImage -L --show-trace
```

After the build is complete, the image will be in `result/sd-image/nixos-licheepi4a-sd-image-xxx-riscv64-linux.img`.

The image has some problem currently, we need to fix the partition size by the following commands:

```bash
cp result/sd-image/nixos-licheepi4a-sd-image-xxx-riscv64-linux.img nixos-lp4a.img

# increase img's file size
dd if=/dev/zero bs=1M count=16 >> nixos-lp4a.img
sudo losetup --find --partscan nixos-lp4a.img

# check rootfs's status, it's broken.
sudo fsck /dev/loop0p2

echo w | sudo fdisk /dev/loop0
# increase the rootfs's partition size & file system size
nix shell nixpkgs#cloud-utils
sudo growpart /dev/loop0 2

# check rootfs's status again, it should be normal now.
sudo fsck /dev/loop0p2

# umount the image file
sudo losetup -d /dev/loop0
```

## Flash into SD card

> Official Docs: https://wiki.sipeed.com/hardware/en/lichee/th1520/lpi4a/4_burn_image.html

According to the official docs, the flash process of LicheePi 4A is as follows:

1. Press and hold the BOOT button on the board, then plug in the USB-C cable to power on (the other end of the cable is connected to the PC), and you can enter the USB burning mode (fastboot).
   1. the command `lsusb | grep T-HEAD` should print `ID 2345:7654 T-HEAD USB download gadget`
2. Then use the following command to flash the image into the board's eMMC.
   1. The fastboot program can be downloaded directly from [Android Platform Tools](https://developer.android.com/tools/releases/platform-tools), or installed from the package manager.

So first, download the prebuilt `u-boot-with-spl.bin` & `nixos-licheepi4a-sd-image-xxx-riscv64-linux.img.zst` from [releases](https://github.com/ryan4yin/nixos-licheepi4a/releases), or build them by yourself.

Then, flash into the board's spl partition and uboot partition:

```bash
# flash u-boot into spl partition
sudo fastboot flash ram u-boot-with-spl.bin
sudo fastboot reboot
# flash uboot partition
sudo fastboot flash uboot u-boot-with-spl.bin
```

Finally, flash boot & rootfs into SD card:

```bash
mv nixos-licheepi4a-sd-image-xxx-riscv64-linux.img.zst nixos-lp4a.img.zst
zstd -d nixos-lp4a.img.zst
# please replace `/dev/sdX` with your SD card's device name
sudo dd if=nixos-lp4a.img of=/dev/sdX bs=4M status=progress

# fix the wrong physical sector size
sudo parted /dev/sdb
```

Now insert the SD card into the board, and power on, you should see NixOS booting.

## Flash into eMMC

> :warning: TODO work in prgress, not working yet.

```shell
nix build .#boot -L --show-trace
cp result boot.ext4

nix build .#rootfs -L --show-trace
cp result rootfs.ext4
```

Flash boot and rootfs partition into eMMC:

```bash
# flash u-boot into spl partition
sudo fastboot flash ram u-boot-with-spl.bin
sudo fastboot reboot
# flash uboot partition
sudo fastboot flash uboot u-boot-with-spl.bin

# flash nixos's boot partition
sudo fastboot flash boot boot.ext4
# flash nixos's rootfs partition
sudo fastboot flash root rootfs.ext4
```

All the partitions are predefined in the u-boot, so we have to flash the partitions into the right place.

## Debug

See [Debug.md](./Debug.md)

## Deploy

See [Deploy.md](./Deploy.md)

## How this repo works

LicheePi 4A use RevyOS officially.
The basic idea of this repo is to use revyos's kernel, u-boot and opensbi, with a NixOS rootfs, to get NixOS running on LicheePi 4A.

## See Also

RevyOS's kernel, u-boot and opensbi:

- https://github.com/revyos/thead-kernel.git
- https://github.com/revyos/thead-u-boot.git
- https://github.com/revyos/thead-opensbi.git

And other efforts to bring Fedora to LicheePi 4A:

- https://github.com/chainsx/fedora-riscv-builder

And other efforts to bring NixOS to RISC-V:

- https://github.com/zhaofengli/nixos-riscv64
- https://github.com/NickCao/nixos-riscv

Special thanks to @NickCao,  @revyos, @chainsx and @zhaofengli.

