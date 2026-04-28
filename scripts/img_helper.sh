select_img() {
    local DEFAULT_IMAGE=$(find ./result/sd-image -type f || true)
    echo "Choose image to flash(${DEFAULT_IMAGE}):"
    read IMAGE

    IMAGE=${IMAGE:-${DEFAULT_IMAGE}}
    if [ ! -f "${IMAGE}" ]; then
      echo "No such image: ${IMAGE}"
      exit 1
    fi

    export IMAGE
}
