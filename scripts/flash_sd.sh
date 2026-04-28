
set -e

CURRENT_DIR=$(dirname "$(readlink -f "$0")")
source "${CURRENT_DIR}/fdisk_helper.sh"
source "${CURRENT_DIR}/img_helper.sh"

fdisk_check_version

select_img

echo
lsblk

echo "Choose flash target(e.g. sdb):"
read TARGET

if ! [ -b "/dev/${TARGET}" ]; then
  echo "No such devices: /dev/${TARGET}"
  exit 1
fi

echo
echo "Unmounting /dev/${TARGET}*"
for i in $(lsblk -l | grep "${TARGET}" | awk '{print $1}'); do
  echo "Unmounting /dev/${i}"
  sudo umount "/dev/${i}" || true
done

echo
echo "Flashing /dev/${TARGET} using ${IMAGE}"
sudo dd if="${IMAGE}" of="/dev/${TARGET}" bs=4MB status=progress

echo
echo "Fixing disk section size"
fdisk_resize_last_section "/dev/${TARGET}"

echo
echo "Fsck"
sudo fsck "/dev/${TARGET}2"

echo
echo "Resizing fs"
sudo resize2fs "/dev/${TARGET}2"

echo
echo "Done"
