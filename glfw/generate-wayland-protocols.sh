#!/bin/sh
# modified from https://github.com/go-gl/glfw/blob/master/scripts/generate-wayland-protocols.sh
set -ex

TMP_CLONE_DIR="/tmp/wayland-protocols"
GLFW_SRC="upstream/glfw/src"

rm -rf $TMP_CLONE_DIR
git clone https://github.com/wayland-project/wayland-protocols $TMP_CLONE_DIR

generate() {
  HEADER=$1
  VER=$2

  if [ "$VER" = "stable" ]; then
    NAME="$HEADER"
    GROUP="stable"
  else
    NAME="$HEADER"-unstable-$VER
    GROUP="unstable"
  fi

  rm -f "$GLFW_SRC/wayland-$NAME"-client-protocol.{h,c}

  wayland-scanner private-code $TMP_CLONE_DIR/"$GROUP"/"$HEADER"/"$NAME".xml "$GLFW_SRC"/wayland-"$NAME"-client-protocol.c
  wayland-scanner client-header $TMP_CLONE_DIR/"$GROUP"/"$HEADER"/"$NAME".xml "$GLFW_SRC"/wayland-"$NAME"-client-protocol.h
}

generate "xdg-shell" "stable"
generate "xdg-decoration" "v1"
generate "viewporter" "stable"
generate "pointer-constraints" "v1"
generate "relative-pointer" "v1"
generate "idle-inhibit" "v1"

sed -i 's/#include "wayland-xdg-decoration-client-protocol.h"/#include "wayland-xdg-decoration-unstable-v1-client-protocol.h"/g' "$GLFW_SRC"/wl_platform.h