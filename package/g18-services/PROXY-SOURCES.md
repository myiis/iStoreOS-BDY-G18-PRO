# Passwall / OpenClash sources

Pinned upstream commits and imported package directories are recorded in PROXY-SOURCES.json. Imported package files are unchanged and retain upstream copyright and license notices. Existing feed versions of sing-box, xray-core, microsocks, haproxy and other available dependencies are reused; the feeds are not replaced.

- Passwall: 26.10.4, including its simplified Chinese translation. The current option INCLUDE_Geoview replaces the historical INCLUDE_V2ray_Geoview preset option. Nftables transparent proxy is selected for firewall4.
- OpenClash: 0.48.002, with its bundled Chinese translation.
- openclash-core: local integration of the upstream MetaCubeX/mihomo v1.19.32 ARM64 release. The gzip download has a pinned SHA256 verified against GitHub release metadata. It installs to /etc/openclash/core/clash_meta. Runtime license: GPL-3.0-only; upstream source: https://github.com/MetaCubeX/mihomo/tree/v1.19.32 .

All missing selected dependency packages are vendored in this repository for fresh checkouts. config/g18-pro.config explicitly retains both applications, the core and their added dependency closure. The native build script rejects configurations missing these default applications/core instead of silently omitting them.

Both services require user configuration/subscription before use. Do not enable both transparent proxies at the same time. Device runtime behavior remains to be verified on hardware. No MT7615E, mt76, mac80211, calibration or board files are changed.

Compatibility pins: geoview 0.1.10 and v2ray-plugin 5.25.0 support the existing Go 1.23 toolchain; shadowsocks-rust 1.24.0 requires Rust 1.88 and is compatible with the existing Rust 1.90 toolchain. Their individual packaging commits are recorded in compatibility_packages. Newer versions require Go 1.24/1.25 or Rust 1.91, so they are deliberately not imported.
