#!/bin/bash
set -x

echo -e "\n[INFO]: BUILD STARTED..!\n"

export WDIR="$(pwd)"
mkdir -p "${WDIR}/dist"

# Init submodules
git submodule init && git submodule update

# Install the requirements for building the kernel when running the script for the first time
if [ ! -f ".requirements" ]; then
    echo -e "\n[INFO]: INSTALLING REQUIREMENTS..!\n"
    {
        sudo apt update
        sudo apt install -y rsync python2
    } && touch .requirements
fi
