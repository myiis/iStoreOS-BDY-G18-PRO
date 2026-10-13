include $(TOPDIR)/rules.mk

PKG_NAME:=quectel-cm
PKG_VERSION:=1.6.7
PKG_RELEASE:=1

PKG_SOURCE:=quectel-cm-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/quectel-open-source/Quectel_QConnectManager_Linux/tar.gz
PKG_SOURCE_URL_FILE:=4dd7951dd9cbd078fbe50221d93ed098f7e38289
PKG_HASH:=56b7f1334197029be20bf5a4dd1db6d11496f66a6ddc228fdc6f4ef81662fa3b
PKG_BUILD_DIR:=$(BUILD_DIR)/quectel-cm-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/quectel-CM-5G
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Quectel dial program
  DEPENDS:=+libpthread
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(TAR) -xzf $(DL_DIR)/$(PKG_SOURCE) --strip-components=1 -C $(PKG_BUILD_DIR)
endef

define Package/quectel-CM-5G/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/quectel-CM $(1)/usr/bin
endef

$(eval $(call BuildPackage,quectel-CM-5G))