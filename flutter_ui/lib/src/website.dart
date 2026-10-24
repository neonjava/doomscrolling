import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'browser.dart' as browser;
import 'design.dart';
import 'platform_settings.dart';

class DoomscrollingWebsite extends StatefulWidget {
  const DoomscrollingWebsite({super.key, this.initialTheme, this.openUrl});
  final String? initialTheme;
  final ValueChanged<String>? openUrl;
  @override
  State<DoomscrollingWebsite> createState() => _DoomscrollingWebsiteState();
}

class _DoomscrollingWebsiteState extends State<DoomscrollingWebsite> {
  late String mode = widget.initialTheme ?? browser.readTheme();
  void changeTheme(String value) {
    setState(() => mode = value);
    browser.saveTheme(value);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Doomscrolling — One video. Your choice.',
    debugShowCheckedModeBanner: false,
    theme: appTheme(Brightness.light),
    darkTheme: appTheme(Brightness.dark),
    themeMode: appearance(mode),
    routes: {
      for (final route in ['/', '/open-source', '/privacy'])
        route: (_) => SitePage(
          route: route,
          themeMode: mode,
          onTheme: changeTheme,
          open: widget.openUrl ?? browser.openUrl,
        ),
    },
    onUnknownRoute: (_) => MaterialPageRoute<void>(
      builder: (_) => SitePage(
        route: '/not-found',
        themeMode: mode,
        onTheme: changeTheme,
        open: widget.openUrl ?? browser.openUrl,
      ),
    ),
  );
}

class SitePage extends StatelessWidget {
  const SitePage({
    super.key,
    required this.route,
    required this.themeMode,
    required this.onTheme,
    required this.open,
  });
  final String route, themeMode;
  final ValueChanged<String> onTheme, open;
  void go(BuildContext context, String path) {
    if (path != route) Navigator.pushNamed(context, path);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.sizeOf(context).width < 700 ? 22 : 44,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(context),
                if (route == '/') ...[
                  _hero(context),
                  _principles(context),
                  _how(context),
                  _sourceBanner(context),
                  _install(context),
                ] else
                  _document(context),
                _footer(context),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Widget _header(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 750;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Flexible(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => go(context, '/'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const AppMark(size: 34),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Doomscrolling',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: wide ? 18 : 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          if (wide) ...[
            TextButton(
              onPressed: () => go(context, '/open-source'),
              child: const Text('Open source'),
            ),
            const SizedBox(width: 24),
            ThemePicker(mode: themeMode, onChanged: onTheme),
          ] else
            PopupMenuButton<String>(
              tooltip: 'Appearance and navigation',
              icon: const Icon(CupertinoIcons.slider_horizontal_3),
              initialValue: themeMode,
              onSelected: (value) {
                if (value == 'source') {
                  go(context, '/open-source');
                } else {
                  onTheme(value);
                }
              },
              itemBuilder: (_) => [
                for (final entry in [
                  ('system', 'System theme'),
                  ('light', 'Light theme'),
                  ('dark', 'Dark theme'),
                  ('source', 'Open source'),
                ])
                  PopupMenuItem(value: entry.$1, child: Text(entry.$2)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 48, bottom: 72),
    child: LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 820;
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('A little less scroll. A little more you.'),
            const SizedBox(height: 24),
            Text(
              'One video.\nYour choice.',
              style: TextStyle(
                fontSize: wide ? 82 : 57,
                height: 1.02,
                fontWeight: FontWeight.w600,
                letterSpacing: wide ? -4.5 : -3,
              ),
            ),
            const SizedBox(height: 26),
            Text(
              'You came for a video.\nYou don’t have to stay for the spiral.',
              style: TextStyle(
                fontSize: wide ? 22 : 19,
                height: 1.5,
                letterSpacing: -.4,
              ),
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Text(
                'Watch the Short or Reel you chose. Doomscrolling stops the swipe into the next one, while your regular feeds stay usable.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.8,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 14,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => open('/download'),
                  icon: const Icon(CupertinoIcons.arrow_down_to_line, size: 18),
                  label: const Text('Download for Android'),
                ),
                TextButton(
                  onPressed: () => open('/promo.mp4'),
                  child: const Text('Watch the 30s promo'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Free & open source · Android 11+ · Alpha',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 30),
            const Wrap(
              spacing: 22,
              runSpacing: 12,
              children: [
                _AppTag('YouTube Shorts', CupertinoIcons.play_fill, mint),
                _AppTag('Instagram Reels', CupertinoIcons.camera, lavender),
              ],
            ),
          ],
        );
        return wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 11, child: copy),
                  const SizedBox(width: 40),
                  const Expanded(flex: 9, child: _PhonePreview()),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  copy,
                  const SizedBox(height: 52),
                  const Center(child: _PhonePreview()),
                ],
              );
      },
    ),
  );
  Widget _principles(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 26),
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: Theme.of(context).dividerColor),
        bottom: BorderSide(color: Theme.of(context).dividerColor),
      ),
    ),
    child: const Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 28,
      runSpacing: 20,
      children: [
        _Principle(CupertinoIcons.play_circle, 'Your first video still plays'),
        _Principle(
          CupertinoIcons.arrow_up_arrow_down,
          'Normal feeds still scroll',
        ),
        _Principle(CupertinoIcons.lock, 'Everything stays on your phone'),
      ],
    ),
  );
  Widget _how(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 82),
    child: LayoutBuilder(
      builder: (context, box) {
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('A small pause in an endless feed'),
            const SizedBox(height: 18),
            Text(
              'Keep the good part.\nPut a pause on the rest.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 18),
            Text(
              'No countdowns. No account. A gentle boundary where one video becomes an endless stream.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 30),
            for (final step in [
              (
                '01',
                'Choose something worth watching.',
                'Open a Short or Reel from a feed, search, link, or tab.',
              ),
              (
                '02',
                'Enjoy that video.',
                'Playback taps and comments stay within reach.',
              ),
              (
                '03',
                'Swipe, and take a breath.',
                'The video stays put. A short reminder gives you a moment to choose.',
              ),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.$1,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.$2,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            step.$3,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              height: 1.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
        return box.maxWidth >= 780
            ? Row(
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: 90),
                  const Expanded(child: ReminderDemo()),
                ],
              )
            : Column(
                children: [
                  copy,
                  const SizedBox(height: 22),
                  const ReminderDemo(),
                ],
              );
      },
    ),
  );
  Widget _sourceBanner(BuildContext context) => Panel(
    color: lavender,
    padding: const EdgeInsets.all(32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('Open by design', color: Color(0xFF605573)),
        const SizedBox(height: 16),
        Text(
          'Your attention shouldn’t\nbe somebody’s business.',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(color: ink, fontSize: 34),
        ),
        const SizedBox(height: 16),
        const Text(
          'No trackers, account, or viewing-history collection.\nA Flutter interface. A Rust engine. Source you can inspect.',
          style: TextStyle(color: Color(0xFF504B61), height: 1.8),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            FilledButton(
              onPressed: () => go(context, '/open-source'),
              child: const Text('Explore the project'),
            ),
            TextButton(
              onPressed: () => open(githubUrl),
              style: TextButton.styleFrom(foregroundColor: ink),
              child: const Text('Read the code on GitHub'),
            ),
          ],
        ),
      ],
    ),
  );
  Widget _install(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 82),
    child: LayoutBuilder(
      builder: (context, box) {
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('Make room for yourself'),
            const SizedBox(height: 18),
            Text(
              'A calmer next swipe\nstarts here.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: () => open('/download'),
              icon: const Icon(CupertinoIcons.arrow_down, size: 18),
              label: const Text('Get the Android app'),
            ),
            const SizedBox(height: 16),
            Text(
              'Android 11+ · AGPL-3.0-only\nARM64, ARMv7, x86_64',
              style: TextStyle(
                fontSize: 12,
                height: 1.8,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => open('$githubUrl/releases'),
              child: const Text('Release notes & downloads'),
            ),
          ],
        );
        final steps = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set up in a minute',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const ExpansionTile(
              tilePadding: EdgeInsets.zero,
              initiallyExpanded: true,
              title: Text(
                '1. Download and install',
                style: TextStyle(fontSize: 15),
              ),
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 18),
                  child: Text(
                    'Open the APK on your Android phone. If asked, allow your browser to install this app. You can turn that permission off afterward.',
                    style: TextStyle(fontSize: 13, height: 1.8),
                  ),
                ),
              ],
            ),
            const ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                '2. Enable accessibility access',
                style: TextStyle(fontSize: 15),
              ),
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 18),
                  child: Text(
                    'In Doomscrolling, enable accessibility access and select its service in Android Settings. If Android shows “Restricted setting”, use App info → menu → Allow restricted settings, then return to Accessibility. Screen structure stays on your device.',
                    style: TextStyle(fontSize: 13, height: 1.8),
                  ),
                ),
              ],
            ),
            const ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('3. Make it yours', style: TextStyle(fontSize: 15)),
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 18),
                  child: Text(
                    'Choose YouTube Shorts, Instagram Reels, or both. Pick System, Light, or Dark in Settings. Open a video and try swiping.',
                    style: TextStyle(fontSize: 13, height: 1.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Early release. App layout updates may affect detection. See the verification record for tested versions and limitations.',
              style: TextStyle(
                fontSize: 11,
                height: 1.8,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            TextButton(
              onPressed: () =>
                  open('$githubUrl/blob/main/docs/VERIFICATION.md'),
              child: const Text('Compatibility & limits'),
            ),
          ],
        );
        return box.maxWidth >= 780
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: 80),
                  Expanded(child: steps),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [copy, const SizedBox(height: 36), steps],
              );
      },
    ),
  );
  Widget _document(BuildContext context) {
    final source = route == '/open-source';
    final privacy = route == '/privacy';
    final sections = source
        ? [
            (
              'Flutter on the outside. Rust at heart.',
              'Flutter renders the Android app and this website with a shared visual system. Android hosts the accessibility service and settings. Rust handles viewer detection, gesture decisions, and warning timing.',
            ),
            (
              'Strong copyleft: AGPL-3.0-only',
              'The project uses the GNU Affero General Public License version 3 only. Read the full license for the terms that apply when you copy, modify, distribute, or run modified versions over a network.',
            ),
            (
              'Help make the boundary better.',
              'Report detection issues with your Android and app versions, improve the app adapters, or contribute a focused change. Keep private screenshots and credentials out of public issues.',
            ),
            (
              'Early, and honest about it.',
              'This is alpha software. Third-party layouts and Android accessibility behavior can change. Unsupported layouts are left usable. Review the verification record for what was actually tested.',
            ),
          ]
        : [
            (
              'What the app reads',
              'With accessibility access enabled, the service checks the foreground app and reads relevant screen structure in YouTube and Instagram. Element identifiers and bounds help it recognize viewers and intercept video swipes.',
            ),
            (
              'What stays on your phone',
              'UI snapshots are processed in memory. Screen content and viewing history are not written to app storage or sent to a server. The Android release does not request Internet permission. Only protection and appearance preferences are saved locally.',
            ),
            (
              'Your controls',
              'Pause protection, turn off individual apps, or revoke accessibility access in Android Settings. Uninstalling removes local preferences.',
            ),
            (
              'This website and downloads',
              'This website has no analytics or advertising scripts. Your appearance preference is stored in browser local storage. Hosting providers may process normal request information. External source and release links go to GitHub, which has its own privacy policy.',
            ),
          ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Eyebrow(
                source
                    ? 'The project'
                    : privacy
                    ? 'Privacy notes'
                    : 'Page not found',
              ),
              const SizedBox(height: 20),
              Text(
                source
                    ? 'Open source.\nOn your side.'
                    : privacy
                    ? 'Your screen stays\non your phone.'
                    : 'Let’s head home.',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 28),
              if (source || privacy) ...[
                for (final section in sections)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.$1,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          section.$2,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            height: 1.9,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton(
                      onPressed: () => open(githubUrl),
                      child: const Text('View source'),
                    ),
                    OutlinedButton(
                      onPressed: () => open(
                        '$githubUrl/blob/main/${source ? 'LICENSE' : 'SECURITY.md'}',
                      ),
                      child: Text(
                        source ? 'Read the license' : 'Security policy',
                      ),
                    ),
                    if (source)
                      OutlinedButton(
                        onPressed: () =>
                            open('$githubUrl/blob/main/CONTRIBUTING.md'),
                        child: const Text('Contribute'),
                      ),
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  'Independent project. Not affiliated with YouTube, Instagram, or Apple.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ] else
                FilledButton(
                  onPressed: () => go(context, '/'),
                  child: const Text('Back to home'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 28),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 30,
      runSpacing: 16,
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppMark(size: 28),
            SizedBox(width: 10),
            Text(
              'Doomscrolling',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Wrap(
          spacing: 12,
          children: [
            TextButton(
              onPressed: () => go(context, '/open-source'),
              child: const Text('Open source'),
            ),
            TextButton(
              onPressed: () => go(context, '/privacy'),
              child: const Text('Privacy'),
            ),
            TextButton(
              onPressed: () => open('$githubUrl/issues'),
              child: const Text('Feedback'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _AppTag extends StatelessWidget {
  const _AppTag(this.label, this.icon, this.tint);
  final String label;
  final IconData icon;
  final Color tint;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      TintedIcon(icon: icon, tint: tint, size: 34),
      const SizedBox(width: 9),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

class _Principle extends StatelessWidget {
  const _Principle(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 10),
      Flexible(child: Text(label, style: const TextStyle(fontSize: 12))),
    ],
  );
}

class _PhonePreview extends StatelessWidget {
  const _PhonePreview();
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Semantics(
        label: 'Preview of the Flutter Android interface',
        child: ExcludeSemantics(
          child: IgnorePointer(
            child: Container(
              width: 318,
              height: 690,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border.all(color: const Color(0xFF313A32), width: 6),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .12),
                    blurRadius: 40,
                    offset: const Offset(0, 22),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: SizedBox(
                    width: 390,
                    height: 860,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onSurface,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Row(
                              children: [
                                AppMark(size: 30),
                                SizedBox(width: 9),
                                Text(
                                  'Doomscrolling',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            FocusDashboard(
                              state: const ProtectionState(
                                engineAvailable: true,
                                serviceEnabled: true,
                              ),
                              onProtection: (_) {},
                              onApp: (_, _) {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 22),
      const Eyebrow('Flutter app · Interface preview'),
    ],
  );
}

class ReminderDemo extends StatefulWidget {
  const ReminderDemo({super.key});
  @override
  State<ReminderDemo> createState() => _ReminderDemoState();
}

class _ReminderDemoState extends State<ReminderDemo> {
  bool visible = false;
  Timer? timer;
  void remind() {
    timer?.cancel();
    setState(() => visible = true);
    timer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => visible = false);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420),
    child: Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Eyebrow('Interactive preview'),
          const SizedBox(height: 18),
          GestureDetector(
            onVerticalDragEnd: (_) => remind(),
            child: Container(
              height: 340,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: aqua,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 48,
                    left: 30,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5EAC2),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -130,
                    right: -100,
                    child: Transform.rotate(
                      angle: -.4,
                      child: Container(
                        width: 460,
                        height: 320,
                        decoration: BoxDecoration(
                          color: const Color(0xFF94B6A2),
                          borderRadius: BorderRadius.circular(150),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -180,
                    left: -120,
                    child: Transform.rotate(
                      angle: .4,
                      child: Container(
                        width: 440,
                        height: 330,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4D796B),
                          borderRadius: BorderRadius.circular(150),
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 24,
                    bottom: 28,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Eyebrow(
                          'The video you chose',
                          color: Color(0xFFDFEEDC),
                        ),
                        SizedBox(height: 9),
                        Text(
                          'Stay for the moment.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            letterSpacing: -.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (visible)
                    Positioned(
                      top: 18,
                      left: 14,
                      right: 14,
                      child: Semantics(
                        container: true,
                        liveRegion: true,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: ink,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'You are doom scrolling',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: remind,
            icon: const Icon(CupertinoIcons.arrow_up, size: 18),
            label: const Text('Try the reminder'),
          ),
          const SizedBox(height: 12),
          Text(
            'An illustration of the reminder, not a live video.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}
