import 'package:flutter/material.dart';
import '../main.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = AppProvider.of(context);
    final storage = appState.storage;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader(title: 'Appearance'),
          RadioGroup<ThemeMode>(
            groupValue: appState.themeMode,
            onChanged: (v) {
              if (v != null) appState.setThemeMode(v);
            },
            child: const Column(
              children: [
                RadioListTile<ThemeMode>(
                  secondary: Icon(Icons.brightness_auto),
                  title: Text('System'),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  secondary: Icon(Icons.light_mode),
                  title: Text('Light'),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  secondary: Icon(Icons.dark_mode),
                  title: Text('Dark'),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),
          const Divider(),
          _SectionHeader(title: 'Scanner'),
          SwitchListTile(
            title: const Text('Vibrate on scan'),
            subtitle: const Text('Vibrate when a code is detected'),
            value: storage.vibrateOnScan,
            onChanged: (v) async {
              await storage.setVibrateOnScan(v);
              setState(() {});
            },
          ),
          SwitchListTile(
            title: const Text('Play sound'),
            subtitle: const Text('Play a sound when a code is detected'),
            value: storage.playSound,
            onChanged: (v) async {
              await storage.setPlaySound(v);
              setState(() {});
            },
          ),
          SwitchListTile(
            title: const Text('Auto-save scans'),
            subtitle: const Text('Automatically save scans to history'),
            value: storage.autoSave,
            onChanged: (v) async {
              await storage.setAutoSave(v);
              setState(() {});
            },
          ),
          const Divider(),
          _SectionHeader(title: 'History'),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear history'),
            subtitle: const Text('Delete all scan history'),
            onTap: () => _confirmClearHistory(context, appState),
          ),
          const Divider(),
          _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: Text(AppConstants.version),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy'),
            subtitle: const Text(AppConstants.privacyText),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Open-source licenses'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: AppConstants.appName,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearHistory(BuildContext context, ScanAppState appState) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to delete all scan history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await appState.history.clear();
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History cleared')),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
