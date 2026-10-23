//! Platform-independent protection engine and a bounded, fail-open Android JNI boundary.
pub mod engine;
use engine::{detect, Decision, Engine, Snapshot};
use jni::{
    objects::{JClass, JString},
    sys::{jfloat, jint, jlong, jstring},
    JNIEnv,
};
use std::{
    panic::{catch_unwind, AssertUnwindSafe},
    sync::{LazyLock, Mutex},
};
static ENGINE: LazyLock<Mutex<Engine>> = LazyLock::new(|| Mutex::new(Engine::default()));

fn evaluate(input: &str) -> Decision {
    if input.len() > 262_144 {
        return Decision::default();
    }
    serde_json::from_str::<Snapshot>(input)
        .map(|s| detect(&s))
        .unwrap_or_default()
}
#[no_mangle]
pub extern "system" fn Java_dev_neonjava_doomscrolling_NativeBridge_protocolVersion(
    _env: JNIEnv,
    _class: JClass,
) -> jint {
    1
}
#[no_mangle]
pub extern "system" fn Java_dev_neonjava_doomscrolling_NativeBridge_evaluate(
    mut env: JNIEnv,
    _class: JClass,
    snapshot: JString,
) -> jstring {
    let result = catch_unwind(AssertUnwindSafe(|| {
        let input: String = env
            .get_string(&snapshot)
            .map(|s| s.into())
            .unwrap_or_default();
        let decision = evaluate(&input);
        if let Ok(mut e) = ENGINE.lock() {
            e.set_active(decision.active);
        }
        serde_json::to_string(&decision).unwrap_or_else(|_| "{\"active\":false}".into())
    }))
    .unwrap_or_else(|_| "{\"active\":false}".into());
    env.new_string(result)
        .map(|s| s.into_raw())
        .unwrap_or(std::ptr::null_mut())
}
#[no_mangle]
pub extern "system" fn Java_dev_neonjava_doomscrolling_NativeBridge_touch(
    _env: JNIEnv,
    _class: JClass,
    action: jint,
    x: jfloat,
    y: jfloat,
    time: jlong,
    slop: jfloat,
) -> jint {
    catch_unwind(|| {
        ENGINE
            .lock()
            .map(|mut e| e.touch(action, x, y, time, slop))
            .unwrap_or(0)
    })
    .unwrap_or(0)
}
#[no_mangle]
pub extern "system" fn Java_dev_neonjava_doomscrolling_NativeBridge_reset(
    _env: JNIEnv,
    _class: JClass,
) {
    let _ = catch_unwind(|| {
        if let Ok(mut e) = ENGINE.lock() {
            e.set_active(false);
        }
    });
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn malformed_input_is_inactive() {
        assert!(!evaluate("{}").active);
        assert!(!evaluate("broken").active);
    }
    #[test]
    fn input_size_is_bounded() {
        assert!(!evaluate(&" ".repeat(262_145)).active);
    }
}
