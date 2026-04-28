fdisk_check_version() {
  local version=$(fdisk --version | grep -oP '\d+\.\d+')
  local major=$(echo "${version}" | cut -d '.' -f 1)
  local minor=$(echo "${version}" | cut -d '.' -f 2)
  if [ "${major}" -lt 2 ] || { [ "${major}" -eq 2 ] && [ "${minor}" -lt 40 ]; }; then
    echo "Error: this script requires fdisk version 2.40 or higher, you have ${version}."
    exit 1
  fi
}

fdisk_resize_last_section() {
  local dev=$1
  # 1. print
  # 2. resize last section
  #    NOTE: command 'e' is added to fdisk 2.40,
  #          we cannot use `d` and `n`, as `Keeping fs signature` must from keyboard input
  # 3. print
  # 4. write & quit
  echo "p
e


p
w
" | sudo fdisk "${dev}"
}
