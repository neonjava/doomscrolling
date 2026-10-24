import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'src/website.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  WidgetsBinding.instance.ensureSemantics();
  runApp(const DoomscrollingWebsite());
}
