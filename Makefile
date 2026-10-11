TARGET = iphone:clang:latest:15.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MoveSleepAlarm
MoveSleepAlarm_FILES = Tweak.xm
MoveSleepAlarm_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += movesleepalarmprefs
include $(THEOS_MAKE_PATH)/aggregate.mk