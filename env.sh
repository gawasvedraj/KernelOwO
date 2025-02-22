#!/usr/bin/env bash

UBUNTU_VERSION=$(lsb_release -sr)

# Remove FireFox
apt remove firefox
apt autoremove

# Environment Setup
apt-get update && apt-get upgrade -y

# Install python2 if Ubuntu version is lower than 24.04
if [[ $UBUNTU_VERSION != "24.04" ]]; then
    apt install python2
fi
