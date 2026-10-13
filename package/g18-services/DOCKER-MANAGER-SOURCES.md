# Docker Manager v0.1.1

Imported package definitions and integration files, retaining upstream copyright and license notices:

- `dockermanager` 0.1.1-2 and `linkease-app-entry` 3.0.22-1: https://github.com/linkease/nas-packages/tree/bece182ee8d07dc3a51e48e788a1dba930764ae1/network/services
- `luci-app-dockermanager` 0.1.1-3 and `luci-lib-linkeaseauth` 1.2.1-1: https://github.com/linkease/nas-packages-luci/tree/5003317787cc9a0d47fd4d2569ad8f4c195f46b4/luci
- `app-meta-dockermanager` 0.1.1-4 and `docker-manager-meta.mk`: https://github.com/linkease/openwrt-app-meta/tree/7a1557cf73b3c5cda1003ca004a3bc6a24fff050

The metadata Makefile's relative include path is adapted to this repository layout. Runtime downloads use the original upstream URLs and SHA256 hashes. The package contains prebuilt runtime binaries; the packaging license notices do not establish the runtime binary's license.

Docker Manager is separate from the existing `luci-app-dockerman`. Docker Manager and its dependencies are explicitly selected in config/g18-pro.config; the existing DockerMan remains selected in the preset. Device runtime behavior must be verified on hardware after building the firmware.
