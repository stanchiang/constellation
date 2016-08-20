LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

OPENCV_INSTALL_MODULES:=on
OPENCV_CAMERA_MODULES:=off

include ../../sdk/native/jni/OpenCV.mk
LOCAL_CFLAGS := -Werror -O3 -ffast-math
LOCAL_ARM_MODE := arm
LOCAL_C_INCLUDES:= ../..//sdk/native/jni/include
LOCAL_C_INCLUDES += $(LOCAL_PATH)
LOCAL_C_INCLUDES += $(LOCAL_PATH)/include 
LOCAL_MODULE    := nonfree
LOCAL_SRC_FILES := src/nonfree_init.cpp  src/sift.cpp src/surf.cpp 
LOCAL_LDLIBS +=  -L$(LOCAL_PATH)/lib -llog

include $(BUILD_SHARED_LIBRARY)



#LOCAL_C_INCLUDES:= ../../sdk/native/jni/include