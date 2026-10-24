import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

@immutable
class ProtectionState {
  const ProtectionState({
    this.enabled = true,
    this.youtube = true,
    this.instagram = true,
    this.themeMode = 'system',
    this.engineAvailable = false,
    this.serviceEnabled = false,
    this.version = '0.2.0',
  });
  factory ProtectionState.fromMap(Map<Object?, Object?> value) =>
      ProtectionState(
        enabled: value['enabled'] == true,
        youtube: value['youtube'] == true,
        instagram: value['instagram'] == true,
        themeMode: value['themeMode'] as String? ?? 'system',
        engineAvailable: value['engineAvailable'] == true,
        serviceEnabled: value['serviceEnabled'] == true,
        version: value['version'] as String? ?? '0.2.0',
      );
  final bool enabled, youtube, instagram, engineAvailable, serviceEnabled;
  final String themeMode, version;
  bool get ready =>
      enabled && engineAvailable && serviceEnabled && (youtube || instagram);
}

abstract class SettingsGateway {
  Future<ProtectionState> read();
  Future<ProtectionState> setProtection(bool enabled);
  Future<ProtectionState> setApp(String app, bool enabled);
  Future<ProtectionState> setTheme(String mode);
  Future<void> openAccessibility();
  Future<void> openSource();
}

class AndroidSettings implements SettingsGateway {
  const AndroidSettings();
  static const channel = MethodChannel('dev.neonjava.doomscrolling/settings');
  Future<ProtectionState> _state(
    String method, [
    Map<String, Object>? args,
  ]) async {
    final value = await channel.invokeMapMethod<Object?, Object?>(method, args);
    if (value == null) throw const FormatException('Missing Android settings');
    return ProtectionState.fromMap(value);
  }

  @override
  Future<ProtectionState> read() => _state('getState');
  @override
  Future<ProtectionState> setProtection(bool enabled) =>
      _state('setProtection', {'enabled': enabled});
  @override
  Future<ProtectionState> setApp(String app, bool enabled) =>
      _state('setAppEnabled', {'app': app, 'enabled': enabled});
  @override
  Future<ProtectionState> setTheme(String mode) =>
      _state('setThemeMode', {'mode': mode});
  @override
  Future<void> openAccessibility() =>
      channel.invokeMethod<void>('openAccessibility');
  @override
  Future<void> openSource() => channel.invokeMethod<void>('openSource');
}

class ProtectionController extends ChangeNotifier {
  ProtectionController(this.gateway);
  final SettingsGateway gateway;
  ProtectionState state = const ProtectionState();
  bool loading = true;
  bool busy = false;
  String? error;
  bool _disposed = false;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> refresh() async {
    if (busy) return;
    try {
      state = await gateway.read();
      error = null;
    } catch (_) {
      error = 'Could not read Android settings. Tap retry to reconnect.';
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> _change(Future<ProtectionState> Function() action) async {
    if (busy || loading) return;
    busy = true;
    _notify();
    try {
      state = await action();
      error = null;
    } catch (_) {
      error = 'That change could not be saved. Your previous settings are still shown.';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> setProtection(bool value) =>
      _change(() => gateway.setProtection(value));
  Future<void> setApp(String app, bool value) =>
      _change(() => gateway.setApp(app, value));
  Future<void> setTheme(String mode) => _change(() => gateway.setTheme(mode));
  Future<void> openAccessibility() async {
    try {
      await gateway.openAccessibility();
    } catch (_) {
      error = 'Could not open Settings. Open Android Settings → Accessibility manually.';
      _notify();
    }
  }

  Future<void> openSource() async {
    try {
      await gateway.openSource();
    } catch (_) {
      error = 'Could not open a browser. The source is at github.com/neonjava/doomscrolling.';
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
