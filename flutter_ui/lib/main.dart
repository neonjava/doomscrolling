import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/platform_settings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    DoomscrollingApp(controller: ProtectionController(const AndroidSettings())),
  );
}
