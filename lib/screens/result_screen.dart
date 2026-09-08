import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/scan_result.dart';
import '../services/ad_service.dart';
import '../utils/validators.dart';

class ResultScreen extends StatefulWidget {
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
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final GlobalKey _qrKey = GlobalKey();
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _bannerAd = createBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _saveQrAsImage() async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        _showSnackBar('Could not capture QR code');
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _showSnackBar('Could not encode QR code');
        return;
      }

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/scanlite_qr.png');
      await file.writeAsBytes(bytes);

      await Gal.putImage(file.path, album: 'ScanLite');
      await file.delete();

      if (mounted) {
        _showSnackBar('QR code saved to gallery');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error saving QR code: $e');
      }
    }
  }

  Future<void> _shareQr() async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        _showSnackBar('Could not capture QR code');
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _showSnackBar('Could not encode QR code');
        return;
      }

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/scanlite_qr.png');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'QR Code'),
      );

      await file.delete();
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error sharing QR code: $e');
      }
    }
  }

  Future<Uint8List?> _captureQrBytes() async {
    final boundary = _qrKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _printQr() async {
    try {
      final imageBytes = await _captureQrBytes();
      if (imageBytes == null) {
        _showSnackBar('Could not capture QR code');
        return;
      }

      await Printing.layoutPdf(
        onLayout: (format) async {
          final pdf = pw.Document();
          final image = pw.MemoryImage(imageBytes);

          pdf.addPage(
            pw.Page(
              pageFormat: format,
              build: (context) => pw.Center(
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Image(image, width: 200, height: 200),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      widget.content,
                      style: const pw.TextStyle(fontSize: 12),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );

          return pdf.save();
        },
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error printing QR code: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scanType = _getScanType(widget.content);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Result'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.imagePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(widget.imagePath!),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // QR code image
            Center(
              child: RepaintBoundary(
                key: _qrKey,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: widget.content,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Save, share, print buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _saveQrAsImage,
                  icon: const Icon(Icons.save_alt, size: 18),
                  label: const Text('Save'),
                ),
                ElevatedButton.icon(
                  onPressed: _shareQr,
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share'),
                ),
                ElevatedButton.icon(
                  onPressed: _printQr,
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Print'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Type badge
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      widget.content,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (scanType == ScanType.wifi) ...[
              _WifiInfoCard(content: widget.content),
              const SizedBox(height: 24),
            ],

            if (scanType == ScanType.url) ...[
              FilledButton.icon(
                onPressed: () => _openUrl(context, widget.content),
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open in Browser'),
              ),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.copy,
                label: 'Copy URL',
                onTap: () => _copy(context, widget.content),
              ),
              _ActionRow(
                icon: Icons.share,
                label: 'Share URL',
                onTap: () => _share(context, widget.content),
              ),
              _ActionRow(
                icon: Icons.search,
                label: 'Search Web',
                onTap: () => _searchWeb(context, widget.content),
              ),
            ],

            if (scanType == ScanType.phone) ...[
              FilledButton.icon(
                onPressed: () => _makeCall(context, widget.content),
                icon: const Icon(Icons.phone),
                label: const Text('Call'),
              ),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.message,
                label: 'Send SMS',
                onTap: () => _sendSms(context, widget.content),
              ),
              _ActionRow(
                icon: Icons.person_add,
                label: 'Add to Contacts',
                onTap: () => _addToContacts(context, widget.content),
              ),
              _ActionRow(
                icon: Icons.copy,
                label: 'Copy Number',
                onTap: () => _copy(context, widget.content),
              ),
              _ActionRow(
                icon: Icons.share,
                label: 'Share Number',
                onTap: () => _share(context, widget.content),
              ),
            ],

            if (scanType == ScanType.email) ...[
              FilledButton.icon(
                onPressed: () => _sendEmail(context, widget.content),
                icon: const Icon(Icons.email),
                label: const Text('Send Email'),
              ),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.copy,
                label: 'Copy Email',
                onTap: () => _copy(context, widget.content),
              ),
              _ActionRow(
                icon: Icons.share,
                label: 'Share Email',
                onTap: () => _share(context, widget.content),
              ),
            ],

            if (scanType == ScanType.sms) ...[
              FilledButton.icon(
                onPressed: () => _sendSms(context, widget.content),
                icon: const Icon(Icons.message),
                label: const Text('Send SMS'),
              ),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.copy,
                label: 'Copy Number',
                onTap: () => _copy(context, widget.content),
              ),
              _ActionRow(
                icon: Icons.share,
                label: 'Share',
                onTap: () => _share(context, widget.content),
              ),
            ],

            if (scanType == ScanType.contact) ...[
              _ActionRow(
                icon: Icons.copy,
                label: 'Copy vCard',
                onTap: () => _copy(context, widget.content),
              ),
              _ActionRow(
                icon: Icons.share,
                label: 'Share Contact',
                onTap: () => _share(context, widget.content),
              ),
            ],

            if (scanType == ScanType.wifi) ...[
              FilledButton.icon(
                onPressed: () => _copyWifiPassword(context, widget.content),
                icon: const Icon(Icons.wifi),
                label: const Text('Copy Password'),
              ),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.copy,
                label: 'Copy Network Name',
                onTap: () => _copyWifiName(context, widget.content),
              ),
              _ActionRow(
                icon: Icons.copy_all,
                label: 'Copy All WiFi Info',
                onTap: () => _copy(context, widget.content),
              ),
              _ActionRow(
                icon: Icons.share,
                label: 'Share WiFi',
                onTap: () => _share(context, widget.content),
              ),
            ],

            if (scanType == ScanType.text) ...[
              FilledButton.icon(
                onPressed: () => _copy(context, widget.content),
                icon: const Icon(Icons.copy),
                label: const Text('Copy Text'),
              ),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.share,
                label: 'Share Text',
                onTap: () => _share(context, widget.content),
              ),
              _ActionRow(
                icon: Icons.search,
                label: 'Search Web',
                onTap: () => _searchWeb(context, widget.content),
              ),
              _ActionRow(
                icon: Icons.translate,
                label: 'Open in Translator',
                onTap: () => _openTranslator(context, widget.content),
              ),
            ],

            if (_bannerAd != null) ...[
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
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
    if (content.startsWith('tel:')) return ScanType.phone;
    if (content.startsWith('mailto:')) return ScanType.email;
    if (content.startsWith('sms:')) return ScanType.sms;
    if (content.startsWith('BEGIN:VCARD')) return ScanType.contact;
    if (Validators.isValidPhone(content)) return ScanType.phone;
    if (Validators.isValidEmail(content)) return ScanType.email;
    return ScanType.text;
  }

  String _getDisplayType(ScanType type) => switch (type) {
    ScanType.url => 'URL',
    ScanType.wifi => 'WiFi Network',
    ScanType.phone => 'Phone Number',
    ScanType.email => 'Email',
    ScanType.sms => 'SMS',
    ScanType.contact => 'Contact',
    ScanType.text => 'Text',
  };

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

  Future<void> _makeCall(BuildContext context, String phone) async {
    try {
      final number = phone.startsWith('tel:') ? phone.substring(4) : phone;
      final uri = Uri(scheme: 'tel', path: number);
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
      final number = phone.startsWith('sms:') ? phone.substring(4) : phone;
      final uri = Uri(scheme: 'sms', path: number);
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

  Future<void> _sendEmail(BuildContext context, String email) async {
    try {
      final addr = email.startsWith('mailto:') ? email.substring(7) : email;
      final uri = Uri(scheme: 'mailto', path: addr);
      await launchUrl(uri);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No email app available')),
        );
      }
    }
  }

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
