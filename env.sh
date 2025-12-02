#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only

UBUNTU_VERSION=$(lsb_release -sr)

# Remove FireFox
apt remove firefox
apt autoremove

# Environment Setup
apt-get update && apt-get upgrade -y
