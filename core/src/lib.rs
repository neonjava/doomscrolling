//! Platform-independent protection engine and Android JNI boundary.
use jni::{objects::JClass, sys::jint, JNIEnv};

#[no_mangle]
pub extern "system" fn Java_dev_neonjava_doomscrolling_NativeBridge_protocolVersion(
    _env: JNIEnv,
    _class: JClass,
) -> jint {
    1
}
