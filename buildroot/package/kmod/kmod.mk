################################################################################
#
# kmod
#
################################################################################

KMOD_VERSION = 19
KMOD_SOURCE = kmod-$(KMOD_VERSION).tar.xz
KMOD_SITE = $(BR2_KERNEL_MIRROR)/linux/utils/kernel/kmod
KMOD_INSTALL_STAGING = YES
# For kmod-0002-add-backup-implementation-of-be32toh.patch
KMOD_AUTORECONF = YES
KMOD_DEPENDENCIES = host-pkgconf
HOST_KMOD_DEPENDENCIES = host-pkgconf

# license info for libkmod only, conditionally add more below
KMOD_LICENSE = LGPLv2.1+
KMOD_LICENSE_FILES = libkmod/COPYING

# static linking not supported, see
# https://git.kernel.org/cgit/utils/kernel/kmod/kmod.git/commit/?id=b7016153ec8
KMOD_CONF_OPTS = --disable-static --enable-shared

KMOD_CONF_OPTS += --disable-manpages
HOST_KMOD_CONF_OPTS = --disable-manpages

ifeq ($(BR2_PACKAGE_ZLIB),y)
KMOD_DEPENDENCIES += zlib
KMOD_CONF_OPTS += --with-zlib
endif

ifeq ($(BR2_PACKAGE_XZ),y)
KMOD_DEPENDENCIES += xz
KMOD_CONF_OPTS += --with-xz
endif

ifeq ($(BR2_PACKAGE_PYTHON)$(BR2_PACKAGE_PYTHON3),y)
KMOD_DEPENDENCIES += $(if $(BR2_PACKAGE_PYTHON),python,python3)
KMOD_CONF_OPTS += --enable-python
endif

# --gc-sections triggers a bug in the current Xtensa binutils
ifeq ($(BR2_xtensa),y)
KMOD_CONF_ENV += cc_cv_LDFLAGS__Wl___gc_sections=no
endif

ifeq ($(BR2_PACKAGE_KMOD_TOOLS),y)

# add license info for kmod tools
KMOD_LICENSE += GPLv2+
KMOD_LICENSE_FILES += COPYING

# take precedence over busybox implementation
KMOD_DEPENDENCIES += $(if $(BR2_PACKAGE_BUSYBOX),busybox)

define KMOD_INSTALL_TOOLS
	for i in depmod insmod lsmod modinfo modprobe rmmod; do \
		ln -sf ../usr/bin/kmod $(TARGET_DIR)/sbin/$$i; \
	done
endef

KMOD_POST_INSTALL_TARGET_HOOKS += KMOD_INSTALL_TOOLS
else
KMOD_CONF_OPTS += --disable-tools
endif

ifeq ($(BR2_PACKAGE_BASH),)
KMOD_CONF_OPTS += --with-bashcompletiondir=
endif

# We only install depmod, since that's the only tool used for the
# host.
define HOST_KMOD_INSTALL_TOOLS
	mkdir -p $(HOST_DIR)/sbin/
	ln -sf ../usr/bin/kmod $(HOST_DIR)/sbin/depmod
endef

HOST_KMOD_POST_INSTALL_HOOKS += HOST_KMOD_INSTALL_TOOLS

$(eval $(autotools-package))
$(eval $(host-autotools-package))
