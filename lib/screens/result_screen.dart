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
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
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
            if (scanType == ScanType.wifi) ...[
              _WifiInfoCard(content: content),
              const SizedBox(height: 24),
            ],
            if (scanType == ScanType.url) ...[
              FilledButton.icon(
                onPressed: () => _openUrl(context, content),
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open'),
              ),
              const SizedBox(height: 12),
            ],
            if (scanType == ScanType.phone) ...[
              FilledButton.icon(
                onPressed: () => _makeCall(context, content),
                icon: const Icon(Icons.phone),
                label: const Text('Call'),
              ),
              const SizedBox(height: 12),
            ],
            if (scanType == ScanType.email) ...[
              FilledButton.icon(
                onPressed: () => _sendEmail(context, content),
                icon: const Icon(Icons.email),
                label: const Text('Email'),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _shareContent(context),
              icon: const Icon(Icons.share),
              label: const Text('Share'),
            ),
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

  Future<void> _shareContent(BuildContext context) async {
    try {
      await SharePlus.instance.share(ShareParams(text: content));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot share this content')),
        );
      }
    }
  }

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
