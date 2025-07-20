
set -e

CURRENT_DIR=$(dirname "$(readlink -f "$0")")
source "${CURRENT_DIR}/fdisk_helper.sh"
source "${CURRENT_DIR}/img_helper.sh"

fdisk_check_version

select_img

mkdir -p ./release

IMAGE=${IMAGE:-${DEFAULT_IMAGE}}
IMAGE_NAME=$(basename "${IMAGE}")

echo
echo "Creating writeable image copy"
cp -i "${IMAGE}" "./release/${IMAGE_NAME}"
IMAGE=./release/${IMAGE_NAME}
chmod +w "${IMAGE}"
dd if=/dev/zero >> "${IMAGE}" bs=1M count=16

echo
echo "Setting up loop device"
DEV=$(sudo losetup --find --partscan --show "${IMAGE}")

echo
echo "Fixing disk section size"
fdisk_resize_last_section "${DEV}"

echo
echo "Fsck"
sudo fsck "${DEV}p2"

echo
echo "Resizing fs"
sudo resize2fs "${DEV}p2"

echo
echo "Deleting loop device"
sudo losetup -d "${DEV}"

echo
echo "Creating archive"
tar -I "zstd -T0 -9" -cvf "./release/${IMAGE_NAME}.tar.zst" "${IMAGE}"

echo
echo "Cleaning up"
rm -f "${IMAGE}"

echo
echo "Done"
