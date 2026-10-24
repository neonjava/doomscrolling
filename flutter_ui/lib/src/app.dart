import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design.dart';
import 'platform_settings.dart';

class DoomscrollingApp extends StatefulWidget {
  const DoomscrollingApp({super.key, required this.controller});
  final ProtectionController controller;
  @override
  State<DoomscrollingApp> createState() => _DoomscrollingAppState();
}

class _DoomscrollingAppState extends State<DoomscrollingApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.controller.refresh();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => MaterialApp(
      title: 'Doomscrolling',
      debugShowCheckedModeBanner: false,
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      themeMode: appearance(widget.controller.state.themeMode),
      home: AppHome(controller: widget.controller),
    ),
  );
}

class AppHome extends StatefulWidget {
  const AppHome({super.key, required this.controller});
  final ProtectionController controller;
  @override
  State<AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  int page = 0;
  Future<void> explainAccess() async {
    final allow = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your phone. Your control.'),
        content: const SingleChildScrollView(
          child: Text(
            'Doomscrolling uses accessibility access to recognize Shorts and Reels and intercept video swipes. Screen structure is processed on your phone; viewing content is not saved or sent.\n\nSelect Doomscrolling in Android Settings and enable it. You can turn it off at any time.\n\nIf Android shows “Restricted setting”, open App info → menu → Allow restricted settings, then return to Accessibility.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
    if (allow == true) await widget.controller.openAccessibility();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: c.loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 540),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const AppMark(size: 34),
                              const SizedBox(width: 10),
                              const Text(
                                'Doomscrolling',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -.5,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'Appearance settings',
                                onPressed: () => setState(() => page = 1),
                                icon: Icon(
                                  dark
                                      ? CupertinoIcons.moon
                                      : CupertinoIcons.sun_max,
                                  size: 21,
                                ),
                              ),
                            ],
                          ),
                          if (c.error != null) ...[
                            const SizedBox(height: 16),
                            Panel(
                              color: lavender,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.error!),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: c.refresh,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          if (page == 0)
                            FocusDashboard(
                              state: c.state,
                              busy: c.busy,
                              onProtection: c.error == null
                                  ? c.setProtection
                                  : null,
                              onApp: c.error == null ? c.setApp : null,
                              onAccess: explainAccess,
                            )
                          else
                            SettingsDashboard(
                              state: c.state,
                              busy: c.busy,
                              onTheme: c.setTheme,
                              onAccess: explainAccess,
                              onSource: c.openSource,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 0, 40, 14),
            child: Center(
              heightFactor: 1,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 340),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: ink,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
                  children: [
                    for (final item in [
                      (0, 'Focus', CupertinoIcons.pause_circle),
                      (1, 'Settings', CupertinoIcons.slider_horizontal_3),
                    ])
                      Expanded(
                        child: Semantics(
                          selected: page == item.$1,
                          child: TextButton(
                            onPressed: () => setState(() => page = item.$1),
                            style: TextButton.styleFrom(
                              backgroundColor: page == item.$1
                                  ? mint
                                  : Colors.transparent,
                              foregroundColor: page == item.$1
                                  ? ink
                                  : Colors.white70,
                              minimumSize: const Size(48, 48),
                              shape: const StadiumBorder(),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(item.$3, size: 18),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    item.$2,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FocusDashboard extends StatelessWidget {
  const FocusDashboard({
    super.key,
    required this.state,
    this.busy = false,
    this.onProtection,
    this.onApp,
    this.onAccess,
  });
  final ProtectionState state;
  final bool busy;
  final ValueChanged<bool>? onProtection;
  final void Function(String, bool)? onApp;
  final VoidCallback? onAccess;
  String get status => !state.engineAvailable
      ? 'Engine unavailable'
      : !state.enabled
      ? 'Protection paused'
      : !state.serviceEnabled
      ? 'One small step left'
      : !state.youtube && !state.instagram
      ? 'Choose your apps'
      : 'Protection is on';
  String get detail => !state.engineAvailable
      ? 'Reinstall the app to reconnect Rust.'
      : !state.enabled
      ? 'Turn it on when you’re ready.'
      : !state.serviceEnabled
      ? 'Enable accessibility to get started.'
      : !state.youtube && !state.instagram
      ? 'Enable Shorts or Reels below.'
      : 'Your next video swipe is covered.';
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Eyebrow('A little more intention'),
      const SizedBox(height: 8),
      Text(
        'Less scrolling.\nMore living.',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: 24),
      Panel(
        color: mint,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow(
                    'One video. Your choice.',
                    color: Color(0xFF4B623A),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enjoy the moment.\nSkip the spiral.',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(color: ink, fontSize: 25),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The video plays.\nThe next swipe waits.',
                    style: TextStyle(
                      color: Color(0xFF4B623A),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: ink,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(CupertinoIcons.arrow_up, color: mint, size: 22),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Panel(
        color: ink,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: state.ready ? mint : lavender,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: Color(0xFFB2BBB0),
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Semantics(
              label: 'Protection',
              child: CupertinoSwitch(
                value: state.enabled,
                activeTrackColor: mint,
                thumbColor: Colors.white,
                onChanged: busy ? null : onProtection,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const Eyebrow('Your apps, your boundaries'),
      const SizedBox(height: 12),
      Panel(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        child: Column(
          children: [
            _appRow(
              context,
              'YouTube',
              'Shorts only',
              'youtube',
              CupertinoIcons.play_fill,
              mint,
              state.youtube,
            ),
            const Divider(height: 1),
            _appRow(
              context,
              'Instagram',
              'Reels only',
              'instagram',
              CupertinoIcons.camera,
              lavender,
              state.instagram,
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      if (!state.serviceEnabled)
        Panel(
          color: lavender,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Give your scroll a boundary.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'One permission. Everything stays on your phone.',
                style: TextStyle(fontSize: 12, color: Color(0xFF5D5774)),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onAccess,
                icon: const Icon(CupertinoIcons.arrow_up_right, size: 17),
                label: const Text('Enable accessibility'),
              ),
            ],
          ),
        )
      else
        Text(
          'Normal feeds and comments stay yours to explore.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
            height: 1.6,
          ),
        ),
    ],
  );
  Widget _appRow(
    BuildContext context,
    String title,
    String subtitle,
    String key,
    IconData icon,
    Color tint,
    bool checked,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 13),
    child: Row(
      children: [
        TintedIcon(icon: icon, tint: tint),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Semantics(
          label: '$title protection',
          child: CupertinoSwitch(
            value: checked,
            activeTrackColor: Theme.of(context).brightness == Brightness.dark
                ? mint
                : const Color(0xFF597F41),
            onChanged: busy || onApp == null
                ? null
                : (value) => onApp!(key, value),
          ),
        ),
      ],
    ),
  );
}

class SettingsDashboard extends StatelessWidget {
  const SettingsDashboard({
    super.key,
    required this.state,
    required this.busy,
    required this.onTheme,
    required this.onAccess,
    required this.onSource,
  });
  final ProtectionState state;
  final bool busy;
  final ValueChanged<String> onTheme;
  final VoidCallback onAccess, onSource;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Make it yours.', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 8),
      Text(
        'A little control goes a long way.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 28),
      const Eyebrow('Appearance'),
      const SizedBox(height: 12),
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Light, dark, or in sync.',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
            ),
            const SizedBox(height: 8),
            const Text(
              'Follow your phone, or choose your own look.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 18),
            ThemePicker(
              mode: state.themeMode,
              onChanged: busy ? null : onTheme,
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      const Eyebrow('Connected to your phone'),
      const SizedBox(height: 12),
      Panel(
        padding: const EdgeInsets.all(8),
        child: ListTile(
          leading: const TintedIcon(
            icon: CupertinoIcons.hand_raised,
            tint: lavender,
          ),
          title: const Text(
            'Accessibility',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            state.serviceEnabled
                ? 'Enabled · manage in Settings'
                : 'Not enabled · set up protection',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
          onTap: onAccess,
        ),
      ),
      const SizedBox(height: 22),
      Panel(
        color: aqua,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('Private by design', color: Color(0xFF496A63)),
            const SizedBox(height: 12),
            Text(
              'Your attention is\nyour business.',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(color: ink, fontSize: 26),
            ),
            const SizedBox(height: 12),
            const Text(
              'No accounts. No viewing-history collection. Screen structure is processed on your device by the Rust engine.',
              style: TextStyle(
                color: Color(0xFF405C56),
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onSource,
              icon: const Icon(CupertinoIcons.arrow_up_right, size: 16),
              label: const Text('Explore the source'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      Text(
        'Doomscrolling ${state.version} · AGPL-3.0-only\nFlutter interface. Rust at heart.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          height: 1.8,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}
