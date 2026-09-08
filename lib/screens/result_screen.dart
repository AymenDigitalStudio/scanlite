import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/scan_result.dart';
import '../utils/validators.dart';

class ResultScreen extends StatelessWidget {
  final String content;
  final String type;
  final String? imagePath;

  const ResultScreen({
    super.key,
    required this.content,
    required this.type,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scanType = _getScanType(content);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Result'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scanned image
            if (imagePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(imagePath!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Type badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  _getDisplayType(scanType),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Content card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Content',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      content,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // WiFi info
            if (scanType == ScanType.wifi) ...[
              _WifiInfoCard(content: content),
              const SizedBox(height: 24),
            ],

            // === URL Actions ===
            if (scanType == ScanType.url) ...[
              FilledButton.icon(
                onPressed: () => _openUrl(context, content),
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open in Browser'),
              ),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.copy,
                label: 'Copy URL',
                onTap: () => _copy(context, content),
              ),
              _ActionRow(
                icon: Icons.share,
                label: 'Share URL',
                onTap: () => _share(context, content),
              ),
              _ActionRow(
                icon: Icons.search,
                label: 'Search Web',
                onTap: () => _searchWeb(context, content),
              ),
            ],

            // === Phone Actions ===
            if (scanType == ScanType.phone) ...[
              FilledButton.icon(
                onPressed: () => _makeCall(context, content),
                icon: const Icon(Icons.phone),
                label: const Text('Call'),
              ),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.message,
                label: 'Send SMS',
                onTap: () => _sendSms(context, content),
              ),
              _ActionRow(
                icon: Icons.person_add,
                label: 'Add to Contacts',
                onTap: () => _addToContacts(context, content),
              ),
              _ActionRow(
                icon: Icons.copy,
                label: 'Copy Number',
                onTap: () => _copy(context, content),
              ),
              _ActionRow(
                icon: Icons.share,
                label: 'Share Number',
                onTap: () => _share(context, content),
              ),
            ],

            // === Email Actions ===
            if (scanType == ScanType.email) ...[
              FilledButton.icon(
                onPressed: () => _sendEmail(context, content),
                icon: const Icon(Icons.email),
                label: const Text('Send Email'),
              ),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.copy,
                label: 'Copy Email',
                onTap: () => _copy(context, content),
              ),
              _ActionRow(
                icon: Icons.share,
                label: 'Share Email',
                onTap: () => _share(context, content),
              ),
            ],

            // === WiFi Actions ===
            if (scanType == ScanType.wifi) ...[
              FilledButton.icon(
                onPressed: () => _copyWifiPassword(context, content),
                icon: const Icon(Icons.wifi),
                label: const Text('Copy Password'),
              ),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.copy,
                label: 'Copy Network Name',
                onTap: () => _copyWifiName(context, content),
              ),
              _ActionRow(
                icon: Icons.copy_all,
                label: 'Copy All WiFi Info',
                onTap: () => _copy(context, content),
              ),
              _ActionRow(
                icon: Icons.share,
                label: 'Share WiFi',
                onTap: () => _share(context, content),
              ),
            ],

            // === Text Actions ===
            if (scanType == ScanType.text) ...[
              FilledButton.icon(
                onPressed: () => _copy(context, content),
                icon: const Icon(Icons.copy),
                label: const Text('Copy Text'),
              ),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.share,
                label: 'Share Text',
                onTap: () => _share(context, content),
              ),
              _ActionRow(
                icon: Icons.search,
                label: 'Search Web',
                onTap: () => _searchWeb(context, content),
              ),
              _ActionRow(
                icon: Icons.translate,
                label: 'Open in Translator',
                onTap: () => _openTranslator(context, content),
              ),
            ],
          ],
        ),
      ),
    );
  }

  ScanType _getScanType(String content) {
    if (Validators.isValidUrl(content)) return ScanType.url;
    if (content.startsWith('WIFI:')) return ScanType.wifi;
    if (Validators.isValidPhone(content)) return ScanType.phone;
    if (Validators.isValidEmail(content)) return ScanType.email;
    return ScanType.text;
  }

  String _getDisplayType(ScanType type) => switch (type) {
    ScanType.url => 'URL',
    ScanType.wifi => 'WiFi Network',
    ScanType.phone => 'Phone Number',
    ScanType.email => 'Email',
    ScanType.text => 'Text',
  };

  // === Shared Actions ===

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  Future<void> _share(BuildContext context, String text) async {
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot share')),
        );
      }
    }
  }

  // === URL Actions ===

  Future<void> _openUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      try {
        final uri = Uri.parse('https://$url');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e2) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot open this URL')),
          );
        }
      }
    }
  }

  Future<void> _searchWeb(BuildContext context, String query) async {
    try {
      final uri = Uri.parse(
        'https://www.google.com/search?q=${Uri.encodeComponent(query)}',
      );
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open search')),
        );
      }
    }
  }

  // === Phone Actions ===

  Future<void> _makeCall(BuildContext context, String phone) async {
    try {
      final uri = Uri(scheme: 'tel', path: phone);
      await launchUrl(uri);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot make this call')),
        );
      }
    }
  }

  Future<void> _sendSms(BuildContext context, String phone) async {
    try {
      final uri = Uri(scheme: 'sms', path: phone);
      await launchUrl(uri);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open SMS')),
        );
      }
    }
  }

  Future<void> _addToContacts(BuildContext context, String phone) async {
    try {
      final uri = Uri.parse('content://com.android.contacts');
      await launchUrl(uri);
    } catch (e) {
      if (!context.mounted) return;
      _copy(context, phone);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Number copied — paste into contacts')),
      );
    }
  }

  // === Email Actions ===

  Future<void> _sendEmail(BuildContext context, String email) async {
    try {
      final uri = Uri(scheme: 'mailto', path: email);
      await launchUrl(uri);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No email app available')),
        );
      }
    }
  }

  // === WiFi Actions ===

  void _copyWifiPassword(BuildContext context, String wifi) {
    final match = RegExp(r'P:"([^"]*)"').firstMatch(wifi);
    final password = match?.group(1) ?? '';
    if (password.isNotEmpty) {
      _copy(context, password);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No password found')),
      );
    }
  }

  void _copyWifiName(BuildContext context, String wifi) {
    final match = RegExp(r'S:"([^"]*)"').firstMatch(wifi);
    final name = match?.group(1) ?? '';
    if (name.isNotEmpty) {
      _copy(context, name);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No network name found')),
      );
    }
  }

  // === Translator ===

  Future<void> _openTranslator(BuildContext context, String text) async {
    try {
      final uri = Uri.parse(
        'https://translate.google.com/?sl=auto&tl=en&text=${Uri.encodeComponent(text)}',
      );
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open translator')),
        );
      }
    }
  }
}

class _WifiInfoCard extends StatelessWidget {
  final String content;
  const _WifiInfoCard({required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = _parseWifi(content);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WiFi Network',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Network', value: info['ssid'] ?? ''),
            const SizedBox(height: 8),
            _InfoRow(label: 'Security', value: info['type'] ?? ''),
            const SizedBox(height: 8),
            _InfoRow(label: 'Password', value: info['password'] ?? ''),
          ],
        ),
      ),
    );
  }

  Map<String, String> _parseWifi(String wifi) {
    final result = <String, String>{};
    final ssidMatch = RegExp(r'S:"([^"]*)"').firstMatch(wifi);
    if (ssidMatch != null) result['ssid'] = ssidMatch.group(1) ?? '';
    final typeMatch = RegExp(r'T:([^\s;]+)').firstMatch(wifi);
    if (typeMatch != null) result['type'] = typeMatch.group(1) ?? '';
    final passMatch = RegExp(r'P:"([^"]*)"').firstMatch(wifi);
    if (passMatch != null) result['password'] = passMatch.group(1) ?? '';
    return result;
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : 'N/A',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
