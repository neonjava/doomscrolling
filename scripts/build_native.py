#!/usr/bin/env python3
"""Build locked Rust dependencies into Android libraries without global configuration."""
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sdk = os.environ.get("ANDROID_SDK_ROOT") or os.environ.get("ANDROID_HOME")
if not sdk:
    sys.exit("Set ANDROID_SDK_ROOT to your Android SDK directory")
ndk = Path(sdk) / "ndk" / "28.2.13676358" / "toolchains/llvm/prebuilt/linux-x86_64/bin"
if not ndk.is_dir():
    sys.exit(f"Install Android NDK 28.2.13676358: {ndk} is missing")
targets = {
    "arm64-v8a": ("aarch64-linux-android", "aarch64-linux-android26-clang"),
    "armeabi-v7a": ("armv7-linux-androideabi", "armv7a-linux-androideabi26-clang"),
    "x86_64": ("x86_64-linux-android", "x86_64-linux-android26-clang"),
}
for abi, (target, compiler) in targets.items():
    env = os.environ.copy()
    env[f"CARGO_TARGET_{target.upper().replace('-', '_')}_LINKER"] = str(ndk / compiler)
    env["RUSTFLAGS"] = "-C link-arg=-Wl,-z,max-page-size=16384"
    subprocess.run(["cargo", "build", "--locked", "--release", "--target", target, "-p", "doomscrolling-core"], cwd=ROOT, env=env, check=True)
    dest = ROOT / "app/build/rustJniLibs" / abi
    dest.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / "target" / target / "release/libdoomscrolling_core.so", dest)
