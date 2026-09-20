#!/bin/bash
# SPDX-License-Identifier: GPL-3.0

export DEBIAN_FRONTEND=noninteractive
sudo apt purge firefox
sudo apt update -y && apt upgrade -y
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
sudo apt update -y
sudo apt install -y aria2 jq rclone sshpass python-is-python3 wget python3 lz4 xz-utils device-tree-compiler zlib1g-dev gcc g++ libc6 libstdc++6 python3-pip dialog libgtk-3-dev aapt busybox zip erofs-utils unzip p7zip-full zipalign zstd bc android-sdk-libsparse-utils xmlstarlet
pip3 install --no-cache-dir ConfigObj telebot setuptools
sudo apt clean && sudo rm -rf /var/lib/apt/lists/*