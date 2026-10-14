# Quickstart package sources

- quickstart 0.13.0-1: https://github.com/linkease/nas-packages/tree/bece182ee8d07dc3a51e48e788a1dba930764ae1/network/services/quickstart
- luci-app-quickstart 1.0.2-20230817 (user-selected source): https://github.com/animegasan/luci-app-quickstart/tree/f722fb4393257861d8d15e9b079c2ea3ac06fd82

Package files retain upstream copyright and license notices. Local changes translate frontend display strings in htdocs/luci-static/quickstart/index.js into simplified Chinese; translations.zh-cn.json records the English-to-Chinese mapping. A local po/zh-cn/quickstart.po translates LuCI menu entries. API paths, request keys and vendor.js remain unchanged. Runtime download uses the upstream URL and SHA256. Its binary license is separate from the packaging notices.

config/g18-pro.config explicitly selects the interface, simplified Chinese translation, backend and missing direct/transitive dependencies. Existing preset selections supply the other dependencies. The package definitions live in this repository so a fresh checkout does not require an extra feed for these two packages.

The user-selected LuCI package depends on quickstart and luci-app-nlbwmon. The Quickstart backend remains from the separately recorded nas-packages source; nlbwmon and its interface are already explicitly selected in the default preset.
