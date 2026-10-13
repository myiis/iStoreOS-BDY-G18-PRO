include $(TOPDIR)/rules.mk
PKG_NAME:=app-meta-modem
PKG_VERSION:=1.4.4
PKG_RELEASE:=20240513
include $(INCLUDE_DIR)/package.mk
define Package/app-meta-modem
  SECTION:=meta
  CATEGORY:=Extra packages
  TITLE:=iStore metadata for Modem
  PKGARCH:=all
  DEPENDS:=+luci-app-modem +luci-i18n-modem-zh-cn +quectel-CM-5G +sms-tool
endef
define Build/Compile
endef
define Package/app-meta-modem/install
	$(CP) ./files/* $(1)/
endef
$(eval $(call BuildPackage,app-meta-modem))
