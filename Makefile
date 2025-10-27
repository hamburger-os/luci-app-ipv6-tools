#
# Copyright (C) 2025
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=IPv6 Tools - OpenClash Auto Control
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+luci +luci-lib-nixio
LUCI_DESCRIPTION:=LuCI support for IPv6 Tools package with OpenClash automatic control
LUCI_URL:=https://github.com/openwrt/luci

# 包维护者信息
PKG_MAINTAINER:=Your Name <your.email@example.com>

# 包版本
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

# 包许可证
PKG_LICENSE:=GPL-3.0+
PKG_LICENSE_FILES:=LICENSE

include ../../luci.mk

# call BuildPackage - OpenWrt buildroot signature