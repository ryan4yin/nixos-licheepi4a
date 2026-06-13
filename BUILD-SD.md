# Building & Booting NixOS on the LicheePi 4A (SD-card path)

A from-source, narrative-plus-runbook guide for taking this repo from
`git clone` to a NixOS login prompt on a Sipeed **LicheePi 4A (16 GB)**
booting from a microSD card.

Companion to [`README.md`](./README.md) and [`Debug.md`](./Debug.md). Where
the README is terse, this document explains the *why* and gathers the
real-world gotchas reported by other users of the board.

---

## 1. What this repo produces

This flake cross-compiles, on an `x86_64-linux` host, a complete riscv64
NixOS system for the LicheePi 4A:

- **Kernel** — RevyOS's [`revyos/linux`](https://github.com/revyos/linux.git)
  branch `revyos/7.0.y` (~v5.10.113), built with TH1520 patches.
- **Bootloader** — RevyOS's
  [`thead-u-boot`](https://github.com/revyos/thead-u-boot.git) +
  [`thead-opensbi`](https://github.com/revyos/thead-opensbi.git).
- **Rootfs** — minimal NixOS (sshd enabled, single user, no GUI).

Two flake outputs matter:

| Output | Build command | Result |
| --- | --- | --- |
| `uboot` | `nix build .#uboot` | `result/u-boot-with-spl.bin` (~500 KB) |
| `sdImage` | `nix build .#sdImage` | `result/sd-image/nixos-licheepi4a-sd-image-*-riscv64-linux.img` |

The cross target is `riscv64-unknown-linux-gnu` with `-march=rv64gc
-mabi=lp64d`. The C910 supports vector v0.7, but GCC 13/14 only emit v0.11
or v1.0, so vectors are disabled at build time (see `flake.nix`).

## 2. Hardware overview

For context — what you actually have in front of you:

- **SoC**: T-Head TH1520
  - 4× XuanTie C910 RISC-V cores @ 1.85 GHz
  - 64 KB I/D L1 per core, 1 MB shared L2, DVFS
  - PowerVR GPU (OpenGL ES 3.x, Vulkan 1.x, OpenCL 1.x/2.0) — **works**
  - 4-TOPS INT8 NPU — **no public Linux driver** (per upstream and Sipeed)
- **RAM**: 8 GB or 16 GB LPDDR4X (this guide assumes the **16 GB** variant)
- **Storage**: optional eMMC (8 / 32 / 128 GB) + microSD slot
- **I/O**: 4× USB 3.0, 1× USB 2.0, 2× GbE (one PoE), HDMI 2.0, MIPI DSI
  (4-lane, dual-4K capable), 3× MIPI CSI, 3.5 mm audio, GPIO (UART/I²C/SPI)

> If you have an **8 GB** board, change `hardware.deviceTree.name` in
> `modules/licheepi4a.nix` from `thead/th1520-lichee-pi-4a-16g.dtb` back to
> `thead/th1520-lichee-pi-4a.dtb` *before* `nix build .#sdImage`.

## 3. Boot flow (and why eMMC matters even for SD booting)

The TH1520 BootROM does **not** boot from SD card. The chain is:

```
BootROM (mask ROM in TH1520)
   └─► SPL  (read from eMMC offset 0)
        └─► U-Boot  (read from eMMC's `uboot` GPT partition)
             └─► reads extlinux.conf from the SD card's FAT32 /boot
                  └─► loads kernel + DTB + initrd
                       └─► mounts ext4 rootfs on the SD card
```

Implication: even though *all* of NixOS lives on the SD card, you must flash
U-Boot to the eMMC's `uboot` partition once via USB-C fastboot mode. After
that one-time setup, you can swap SD cards freely — no further eMMC writes
required.

(Formal/production boards have a DIP switch on the underside that selects
boot source. We never touch it; fastboot mode is forced via the BOOT button
regardless of DIP position.)

## 4. Pre-flight: host & board prep

### 4.1 On the host (x86_64 NixOS / Linux)

- `nix` with flakes enabled (already true if you cloned this repo).
- `fastboot` from Android platform-tools. On NixOS:
  ```bash
  nix-shell -p android-tools
  ```
  Verify it's recent:
  ```bash
  fastboot --version
  ```
  > Per the Sipeed FAQ, image variants from late 2023 onward require a
  > recent fastboot to handle large image transfers. Modern
  > `android-tools` is fine; if you're on a years-old distro `fastboot`,
  > update it before flashing.
- A USB-C cable that carries **data**, not just power. Many bundled phone
  cables are power-only and will silently fail the fastboot step.
- A microSD card (≥ 4 GB; image is small, but `resize2fs` expands the rootfs
  to fill the card on first flash).

### 4.2 Power

- **Minimum**: 5 V / 2 A.
- **Recommended**: 5 V / 3 A USB-C, or 12 V DC barrel jack.
- Computer USB ports (especially front panel, laptop, hubs) are typically
  **insufficient** and cause flash failures or boot loops.
- If the LED next to the USB silkscreen blinks, the rail is unstable — fix
  the supply before doing anything else.
- During flashing, plug into a **rear motherboard USB port**, not a hub or
  front-panel header.

### 4.3 Serial console (optional but strongly recommended)

The first time you boot from SD you'll want to see the boot chain in case
something goes wrong. UART0 is on the side pins, labelled `U0-RX` and
`U0-TX`. Baud: **115200 8N1**.

> ⚠️ **Voltage warning.** The SoC pins are natively **1.8 V**. The board
> includes a voltage divider on RX, so a 3.3 V adapter *can* drive it, but
> the high-level threshold is marginal — some 3.3 V FTDI clones are
> unreliable. Sipeed sells a matched 1.8 V adapter. **A 5 V FTDI will
> damage the board.** See [`Debug.md`](./Debug.md) for the pinout.

## 5. Build

Run from the repo root.

```bash
# U-Boot — small, ~minutes
nix build .#uboot -L --show-trace
cp result/u-boot-with-spl.bin ~/lp4a-u-boot-with-spl.bin
# (Each subsequent `nix build` replaces ./result, so stash the binary now.)

# SD image — full cross-toolchain + kernel build; first run can be slow
nix build .#sdImage -L --show-trace
ls result/sd-image/
# expected: nixos-licheepi4a-sd-image-<version>-riscv64-linux.img
```

Notes:

- **No binfmt / qemu-user needed.** This is a pure nix cross-build.
- The output `.img` is **uncompressed** (per
  `modules/sd-image/sd-image-lp4a.nix`).
- Partition layout in the image: 200 MiB FAT32 `/boot` (OpenSBI, DTB,
  `extlinux.conf`) + ext4 root (UUID
  `14e19a7b-0ae0-484d-9d54-43bd6fdc20c7`).

## 6. Flash

### 6.1 Enter fastboot (USB download) mode

The board powers up into fastboot if you hold BOOT during power-on:

1. Make sure the board is powered off and disconnected.
2. Press and **hold** the BOOT button.
3. While holding BOOT, plug the USB-C cable into the port **next to the
   BOOT button**.
4. Continue holding BOOT for ~2 seconds, then release.

Verify on the host:

```bash
lsusb | grep T-HEAD
# expected: Bus ... ID 2345:7654 T-HEAD USB download gadget

sudo fastboot devices
# expected: a single device ID followed by 'fastboot'
```

If `lsusb` shows nothing, the most common causes (in order):

1. Power-only USB cable → swap it.
2. Front-panel / hub USB port → use a rear motherboard port.
3. BOOT button not held long enough → repeat with the cable already in
   the host end, only the board end being inserted while you hold BOOT.

### 6.2 Flash U-Boot to eMMC (one-time)

```bash
sudo fastboot flash ram   ~/lp4a-u-boot-with-spl.bin
sudo fastboot reboot
# Board reboots back into fastboot but now running freshly-loaded U-Boot.
sudo fastboot flash uboot ~/lp4a-u-boot-with-spl.bin
```

Each command should end with `OKAY` and a millisecond timing.

> The `flash ram` + `reboot` step isn't decorative: it makes U-Boot
> *check and create* the eMMC partition table before the persistent
> `flash uboot` write. Sipeed's official docs note that skipping this
> turns the persistent write very slow.

This is a **one-time** setup. You don't repeat steps 6.1–6.2 unless the
U-Boot binary itself changes.

### 6.3 Flash the SD card

Insert the SD card on the host. Identify its block device with `lsblk`
(e.g. `sdb`, `mmcblk0`). Then:

```bash
scripts/flash_sd.sh
```

The script prompts you for:

1. The image path (it auto-detects `result/sd-image/*.img`).
2. The target device (just the name, e.g. `sdb` — no `/dev/`).

It then:

1. `umount`s any mounted partitions on the target.
2. `dd if=... of=/dev/<target> bs=4MB status=progress`.
3. Resizes the last partition with `fdisk` to fill the card.
4. Runs `fsck` and `resize2fs` on the new rootfs.

> ⚠️ Double-check the target before confirming — `dd` will overwrite
> *anything* you point at, including your laptop's NVMe.

> The README's note that you must "resize the rootfs manually after the
> first boot" is stale — `flash_sd.sh` already does it (and the TODO is
> checked off in `README.md`).

## 7. First boot

1. Power off, unplug USB-C.
2. Insert the SD card.
3. Power on (normal — do **not** hold BOOT this time).
4. Either:
   - Watch the serial console (115200 8N1) — you'll see OpenSBI → U-Boot
     → Linux messages ending at a `nixos login:` prompt.
   - Or wait ~30–60 s and find the board on the LAN; sshd is enabled in
     the default image.

Default credentials (also in `README.md`):

| Field | Value |
| --- | --- |
| Username | `user` |
| Password | `lp4a` |

**Change the password immediately.** The recent commit
[`d595356`](https://github.com/moeleak/nixos-licheepi4a) removed the
hard-coded SSH public key, but the password is still well-known.

```bash
ssh user@<board-ip>
passwd       # change immediately
```

## 8. Customizing & re-deploying

You have three options, in increasing order of iteration speed:

1. **Edit `modules/licheepi4a.nix`, rebuild, re-flash.** Slow loop but
   guaranteed clean.
2. **`nixos-rebuild switch` on the board.** Works, but the C910 is not
   fast — kernel/system-set builds take a long time.
3. **Remote deploy** from your host using the pattern in
   [`demo/`](./demo/). Avoids rebuilding the image and preserves
   `/home/user`.

## 9. Optional: move to eMMC later

Once SD boot works and you're happy, you can mirror the same image to the
eMMC and free the SD slot. From the booted board:

```bash
# on host
scp result/sd-image/nixos-licheepi4a-sd-image-*.img user@<board-ip>:~/nixos-lp4a.img

# on board
sudo dd if=~/nixos-lp4a.img of=/dev/mmcblk0 bs=4M status=progress
```

`mmcblk0` is the eMMC; `mmcblk1` is the SD card. Reboot, remove the SD
card, you're booting from eMMC. (See `README.md` §"Flash into eMMC".)

## 10. Troubleshooting

| Symptom | Likely cause / fix |
| --- | --- |
| `< waiting for any device >` from fastboot | Cable is power-only, or hub/front-port is undersupplying. Swap cable, use rear USB port. On Windows, reinstall the T-HEAD USB driver. |
| Random kernel panics / spontaneous reboots | Insufficient power. Upgrade to 5 V / 3 A USB-C or 12 V DC. The "USB silkscreen LED blinking" indicator confirms this. |
| SD card flashes fine, board doesn't boot | The card may be non-UHS. Some non-UHS cards fail at the default SD bus frequency. Workaround documented by Sipeed: lower the SD `max-frequency` device-tree property from `0xbcd3d80` (≈ 198 MHz) to `100000000` (100 MHz). Easier path: try a Samsung/Sandisk UHS-I card. |
| Serial garbled, partial chars | Wrong voltage (5 V FTDI — stop, the board may be damaged) or wrong baud (must be 115200) or your adapter is borderline at 3.3 V (use Sipeed's 1.8 V module). |
| Wi-Fi / Bluetooth not detected after warm reboot | Cold-boot — pull all power for several seconds, then power on. Some users report the radio stays in a wedged state across warm reboots. |
| `fastboot flash` succeeds but later writes are glacial | You skipped the `flash ram` + `reboot` priming step in §6.2. Re-run the full sequence. |
| Large image transfer fails or stalls | `fastboot` is too old. `fastboot --version` must be recent (≥ Android platform-tools late 2023). |
| Built image won't recognise full 16 GB | Make sure `hardware.deviceTree.name` is `thead/th1520-lichee-pi-4a-16g.dtb` (the default in this repo) — the non-suffixed DTB caps memory on some images. |

## 11. References

- This repo:
  - [`README.md`](./README.md) — official short build/flash notes
  - [`Debug.md`](./Debug.md) — serial console pinout (read before wiring)
  - [`demo/`](./demo/) — remote-deploy example
- Sipeed wiki:
  - [LPI4A intro](https://wiki.sipeed.com/hardware/en/lichee/th1520/lpi4a/1_intro.html)
  - [Burn image](https://wiki.sipeed.com/hardware/en/lichee/th1520/lpi4a/4_burn_image.html)
  - [Peripheral guide](https://wiki.sipeed.com/hardware/en/lichee/th1520/lpi4a/6_peripheral.html)
  - [FAQ](https://wiki.sipeed.com/hardware/en/lichee/th1520/lpi4a/12_faq.html)
- Upstream RevyOS sources:
  - [revyos/linux](https://github.com/revyos/linux)
  - [revyos/thead-u-boot](https://github.com/revyos/thead-u-boot)
  - [revyos/thead-opensbi](https://github.com/revyos/thead-opensbi)
