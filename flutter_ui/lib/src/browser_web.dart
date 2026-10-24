import 'dart:js_interop';

@JS('localStorage.getItem')
external JSString? _read(JSString key);
@JS('localStorage.setItem')
external void _write(JSString key, JSString value);
@JS('window.location.assign')
external void _navigate(JSString url);
String readTheme() {
  try {
    final mode = _read('doomscrolling-theme'.toJS)?.toDart;
    return ['system', 'light', 'dark'].contains(mode) ? mode! : 'system';
  } catch (_) {
    return 'system';
  }
}

void saveTheme(String mode) {
  try {
    _write('doomscrolling-theme'.toJS, mode.toJS);
  } catch (_) {}
}

void openUrl(String url) => _navigate(url.toJS);
