# Samsung Galaxy A16 4G Kernel

A custom kernel build for the Samsung Galaxy A16 4G (SM-A165F) series, built with upstream kernel sources from Samsung, featuring KernelSU-Next and Droidspaces support.

## Features

* Upstream source: Samsung OSRC (version 5.10.226 - from A165FXXU3BYE6)
* KernelSU-Next: v3.3.0
* SuSFS: v2.2.0
* Droidspaces, LXC and Docker support
* Baseband Guard support
* NTsync support
* BBRv3 TCP congestion control
* CAKE queue discipline
* Single boot image compilation
* Stable ABI: Supports OneUI 6.1 - OneUI 7.0

## Links

* [KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next/releases/download/v3.3.0/KernelSU_Next_v3.3.0_33214-release.apk)
* [Droidspaces](https://github.com/ravindu644/Droidspaces-OSS)
* [Baseband Guard](https://github.com/vc-teahouse/Baseband-guard)

## Requirements

* Samsung Galaxy A16 4G (SM-A165F - Helio G99) with an unlocked bootloader
* OneUI 6.1 - 7.0 firmware

## Installation

1. Download the latest zip file from the releases section.
2. Extract the zip file to obtain the `.tar` archive.
3. Boot the phone into Download Mode.
4. Flash the `.tar` archive using the AP slot in Odin.

## Notes

* Stock vendor images: The installation requires stock `vendor_boot.img` and `vendor_dlkm.img` files. If these partitions have been modified previously, you must restore the stock images first.
