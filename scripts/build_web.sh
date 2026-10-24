#!/usr/bin/env bash
# Build the Flutter website and retain existing downloads/marketing assets.
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
flutter_version="$(tr -d '[:space:]' < "$repo_root/.flutter-version")"
if command -v flutter >/dev/null 2>&1 && flutter --version | head -1 | grep -q "Flutter $flutter_version "; then
  flutter_bin="$(command -v flutter)"
else
  sdk_cache="${FLUTTER_SDK_CACHE:-$repo_root/.vercel/cache/flutter-$flutter_version}"
  if [[ ! -x "$sdk_cache/bin/flutter" ]]; then
    git clone --depth 1 --branch "$flutter_version" https://github.com/flutter/flutter.git "$sdk_cache"
  fi
  flutter_bin="$sdk_cache/bin/flutter"
fi
cd "$repo_root/flutter_ui"
"$flutter_bin" pub get --enforce-lockfile
"$flutter_bin" build web --target lib/main_web.dart --no-web-resources-cdn --no-wasm-dry-run
output_dir="$repo_root/flutter_ui/build/web"
cp -R "$repo_root/web/assets/." "$output_dir/assets/"
cp -R "$repo_root/web/product-images" "$output_dir/"
cp "$repo_root/web/promo.mp4" "$output_dir/promo.mp4"
for apk in "$repo_root"/web/*.apk; do cp "$apk" "$output_dir/"; done
printf 'Flutter website built in %s\n' "$output_dir"
