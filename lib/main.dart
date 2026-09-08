import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/storage_service.dart';
import '../services/history_service.dart';
import 'app/theme.dart';
import 'app/routes.dart';

class ScanAppState extends ChangeNotifier {
  final StorageService storage;
  final HistoryService history;
  ThemeMode _themeMode = ThemeMode.system;

  ScanAppState({required this.storage})
      : history = HistoryService(storage) {
    _themeMode = storage.themeMode;
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await storage.setThemeMode(mode);
    notifyListeners();
  }
}

class AppProvider extends InheritedWidget {
  final ScanAppState state;

  const AppProvider({
    super.key,
    required this.state,
    required super.child,
  });

  static ScanAppState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppProvider>()!.state;
  }

  @override
  bool updateShouldNotify(AppProvider oldWidget) => false;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  final storage = StorageService();
  await storage.init();
  final state = ScanAppState(storage: storage);

  runApp(AppProvider(state: state, child: const ScanApp()));
}

class ScanApp extends StatelessWidget {
  const ScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppProvider.of(context);

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return MaterialApp(
          title: 'ScanLite',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: state.themeMode,
          initialRoute: AppRoutes.home,
          onGenerateRoute: AppRoutes.generateRoute,
        );
      },
    );
  }
}
