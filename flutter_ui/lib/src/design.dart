import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const mint = Color(0xFFD7F5B1);
const lavender = Color(0xFFE2DDFB);
const aqua = Color(0xFFD1EAE6);
const ink = Color(0xFF202321);
const githubUrl = 'https://github.com/neonjava/doomscrolling';

ThemeMode appearance(String mode) => switch (mode) {
  'light' => ThemeMode.light,
  'dark' => ThemeMode.dark,
  _ => ThemeMode.system,
};
ThemeData appTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'DoomSans',
  );
  return base.copyWith(
    scaffoldBackgroundColor: dark
        ? const Color(0xFF101311)
        : const Color(0xFFF5F5F0),
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF506D37),
          brightness: brightness,
        ).copyWith(
          primary: dark ? mint : const Color(0xFF3F5B2D),
          onPrimary: dark ? ink : Colors.white,
          surface: dark ? const Color(0xFF1D211E) : Colors.white,
          onSurface: dark ? const Color(0xFFF2F5ED) : ink,
          onSurfaceVariant: dark
              ? const Color(0xFFAAB2A8)
              : const Color(0xFF657063),
          outlineVariant: dark
              ? const Color(0xFF343B34)
              : const Color(0xFFE4E8DE),
        ),
    textTheme: base.textTheme
        .apply(fontFamily: 'DoomSans')
        .copyWith(
          headlineLarge: const TextStyle(
            fontSize: 40,
            height: 1.08,
            fontWeight: FontWeight.w600,
            letterSpacing: -1.8,
          ),
          headlineMedium: const TextStyle(
            fontSize: 29,
            height: 1.13,
            fontWeight: FontWeight.w600,
            letterSpacing: -1.1,
          ),
          titleLarge: const TextStyle(
            fontSize: 21,
            height: 1.2,
            fontWeight: FontWeight.w600,
            letterSpacing: -.5,
          ),
          bodyMedium: const TextStyle(fontSize: 14, height: 1.5),
          bodySmall: const TextStyle(fontSize: 12, height: 1.5),
        )
        .apply(
          fontFamily: 'DoomSans',
          bodyColor: dark ? const Color(0xFFF2F5ED) : ink,
          displayColor: dark ? const Color(0xFFF2F5ED) : ink,
        ),
    dividerTheme: DividerThemeData(
      color: dark ? const Color(0xFF343B34) : const Color(0xFFE4E8DE),
      thickness: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ink,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: const StadiumBorder(),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
  );
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(22),
    this.radius = 28,
  });
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final double radius;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: color == null
            ? Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .6)
            : Colors.transparent,
      ),
    ),
    child: Material(
      type: MaterialType.transparency,
      child: color == null
          ? child
          : DefaultTextStyle.merge(
              style: const TextStyle(color: ink),
              child: IconTheme(
                data: const IconThemeData(color: ink),
                child: child,
              ),
            ),
    ),
  );
}

class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 42});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: ink,
      borderRadius: BorderRadius.circular(size * .29),
      border: Border.all(color: Colors.white12),
    ),
    child: Icon(CupertinoIcons.pause_solid, color: mint, size: size * .5),
  );
}

class TintedIcon extends StatelessWidget {
  const TintedIcon({
    super.key,
    required this.icon,
    this.tint = mint,
    this.size = 46,
  });
  final IconData icon;
  final Color tint;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF353B35), Color(0xFF191D1A)],
      ),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.white12),
    ),
    child: Icon(icon, color: tint, size: 23),
  );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.6,
      height: 1.5,
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

class ThemePicker extends StatelessWidget {
  const ThemePicker({super.key, required this.mode, required this.onChanged});
  final String mode;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Appearance',
    child: CupertinoSlidingSegmentedControl<String>(
      groupValue: mode,
      backgroundColor: Theme.of(context).colorScheme.outlineVariant,
      thumbColor: Theme.of(context).colorScheme.surface,
      children: {
        for (final entry in [
          ('system', 'System'),
          ('light', 'Light'),
          ('dark', 'Dark'),
        ])
          entry.$1: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Text(
              entry.$2,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
              ),
            ),
          ),
      },
      onValueChanged: onChanged == null
          ? (_) {}
          : (value) {
              if (value != null) onChanged!(value);
            },
    ),
  );
}
