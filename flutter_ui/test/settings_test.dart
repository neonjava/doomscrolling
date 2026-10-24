import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doomscrolling_ui/src/platform_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Android bridge preserves settings and sends typed changes', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AndroidSettings.channel, (call) async {
          calls.add(call);
          return {
            'enabled': false,
            'youtube': true,
            'instagram': false,
            'themeMode': 'dark',
            'engineAvailable': true,
            'serviceEnabled': true,
            'version': '0.2.0',
          };
        });
    const gateway = AndroidSettings();
    final result = await gateway.read();
    expect(result.enabled, false);
    expect(result.instagram, false);
    expect(result.themeMode, 'dark');
    expect(result.ready, false);
    await gateway.setApp('instagram', true);
    expect(calls.last.method, 'setAppEnabled');
    expect(calls.last.arguments, {'app': 'instagram', 'enabled': true});
    await gateway.setTheme('light');
    expect(calls.last.arguments, {'mode': 'light'});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AndroidSettings.channel, null);
  });
  test('failed writes keep previous state and can be retried', () async {
    final gateway = FakeSettings();
    final controller = ProtectionController(gateway);
    await controller.refresh();
    expect(controller.state.ready, true);
    gateway.fail = true;
    await controller.setProtection(false);
    expect(controller.state.enabled, true);
    expect(controller.error, isNotNull);
    expect(controller.busy, false);
    gateway.fail = false;
    await controller.setProtection(false);
    expect(controller.state.enabled, false);
    expect(controller.error, isNull);
    controller.dispose();
  });
}

class FakeSettings implements SettingsGateway {
  ProtectionState state = const ProtectionState(
    engineAvailable: true,
    serviceEnabled: true,
  );
  bool fail = false;
  @override
  Future<ProtectionState> read() async {
    if (fail) throw StateError('offline');
    return state;
  }

  ProtectionState update({
    bool? enabled,
    bool? youtube,
    bool? instagram,
    String? themeMode,
  }) => state = ProtectionState(
    enabled: enabled ?? state.enabled,
    youtube: youtube ?? state.youtube,
    instagram: instagram ?? state.instagram,
    themeMode: themeMode ?? state.themeMode,
    engineAvailable: true,
    serviceEnabled: true,
  );
  @override
  Future<ProtectionState> setProtection(bool enabled) async {
    if (fail) throw StateError('offline');
    return update(enabled: enabled);
  }

  @override
  Future<ProtectionState> setApp(String app, bool enabled) async =>
      app == 'youtube' ? update(youtube: enabled) : update(instagram: enabled);
  @override
  Future<ProtectionState> setTheme(String mode) async =>
      update(themeMode: mode);
  @override
  Future<void> openAccessibility() async {}
  @override
  Future<void> openSource() async {}
}
