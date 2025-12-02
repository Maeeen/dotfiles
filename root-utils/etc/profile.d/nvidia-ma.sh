if lsmod | awk '{print $1}' | grep -q ^nvidia$; then
  export LIBVA_DRIVER_NAME=nvidia
  export GBM_BACKEND=nvidia-drm
  export __GLX_VENDOR_LIBRARY_NAME=nvidia
  export XDG_SESSION_TYPE=wayland
  export AQ_DRM_DEVICES=/dev/dri/card1:/dev/dri/card0
  export NVIDIA_DETECTED=Y

fi

