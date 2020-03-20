#ifndef _C_SWIFT_ANDROID_GLUE_H
#define _C_SWIFT_ANDROID_GLUE_H

#include "android_native_app_glue.h"

#ifdef __cplusplus
extern "C" {
#endif

extern void* create_custom_native_activity(void* nativeApp);

#ifdef __cplusplus
}
#endif

#endif // _C_SWIFT_ANDROID_GLUE_H
