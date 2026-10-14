# SPDX-License-Identifier: GPL-3.0-only
include $(TOPDIR)/rules.mk

PKG_NAME:=openclash-core
PKG_VERSION:=1.19.32
PKG_RELEASE:=1
PKG_SOURCE:=mihomo-linux-arm64-v$(PKG_VERSION).gz
PKG_SOURCE_URL:=https://github.com/MetaCubeX/mihomo/releases/download/v$(PKG_VERSION)
PKG_HASH:=9dd862e28b46ff7d775f169cceebc28deccaa0a9e804237d421cd2571e0caba0
PKG_LICENSE:=GPL-3.0-only

include $(INCLUDE_DIR)/package.mk

define Package/openclash-core
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=Pinned ARM64 Mihomo core for OpenClash
  URL:=https://github.com/MetaCubeX/mihomo
  DEPENDS:=@aarch64
endef

define Build/Prepare
	$(INSTALL_DIR) $(PKG_BUILD_DIR)
	gzip -dc $(DL_DIR)/$(PKG_SOURCE) > $(PKG_BUILD_DIR)/clash_meta
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/openclash-core/install
	$(INSTALL_DIR) $(1)/etc/openclash/core
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/clash_meta $(1)/etc/openclash/core/clash_meta
endef

$(eval $(call BuildPackage,openclash-core))
