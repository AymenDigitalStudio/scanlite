import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/scanner_screen.dart';
import '../screens/result_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/generator_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String scanner = '/scanner';
  static const String result = '/result';
  static const String settings = '/settings';
  static const String generator = '/generator';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/scanner':
        return MaterialPageRoute(builder: (_) => const ScannerScreen());
      case '/result':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ResultScreen(
            content: args['content'] as String,
            type: args['type'] as String,
            imagePath: args['imagePath'] as String?,
          ),
        );
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case '/generator':
        return MaterialPageRoute(builder: (_) => const GeneratorScreen());
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }
}
