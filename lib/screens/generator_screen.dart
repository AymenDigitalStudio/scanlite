import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

enum QRType {
  url,
  text,
  phone,
  email,
  sms,
  wifi,
  contact,
}

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  QRType _selectedType = QRType.url;
  final _controllers = <QRType, TextEditingController>{};
  String _generatedData = '';

  // WiFi fields
  final _wifiSsidController = TextEditingController();
  final _wifiPassController = TextEditingController();
  String _wifiSecurity = 'WPA';

  // Contact fields
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controllers[QRType.url] = TextEditingController();
    _controllers[QRType.text] = TextEditingController();
    _controllers[QRType.phone] = TextEditingController();
    _controllers[QRType.email] = TextEditingController();
    _controllers[QRType.sms] = TextEditingController();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _wifiSsidController.dispose();
    _wifiPassController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  void _generate() {
    String data = '';
    switch (_selectedType) {
      case QRType.url:
        data = _controllers[QRType.url]!.text.trim();
        break;
      case QRType.text:
        data = _controllers[QRType.text]!.text.trim();
        break;
      case QRType.phone:
        data = 'tel:${_controllers[QRType.phone]!.text.trim()}';
        break;
      case QRType.email:
        final email = _controllers[QRType.email]!.text.trim();
        data = 'mailto:$email';
        break;
      case QRType.sms:
        final phone = _controllers[QRType.sms]!.text.trim();
        data = 'sms:$phone';
        break;
      case QRType.wifi:
        final ssid = _wifiSsidController.text.trim();
        final pass = _wifiPassController.text.trim();
        data = 'WIFI:T:$_wifiSecurity;S:$ssid;P:$pass;;';
        break;
      case QRType.contact:
        final name = _contactNameController.text.trim();
        final phone = _contactPhoneController.text.trim();
        final email = _contactEmailController.text.trim();
        data = 'BEGIN:VCARD\nVERSION:3.0\nFN:$name\nTEL:$phone\nEMAIL:$email\nEND:VCARD';
        break;
    }
    setState(() => _generatedData = data);
  }

  void _clear() {
    for (final c in _controllers.values) {
      c.clear();
    }
    _wifiSsidController.clear();
    _wifiPassController.clear();
    _contactNameController.clear();
    _contactPhoneController.clear();
    _contactEmailController.clear();
    setState(() {
      _generatedData = '';
      _wifiSecurity = 'WPA';
    });
  }

  Future<void> _share() async {
    if (_generatedData.isEmpty) return;
    try {
      await SharePlus.instance.share(ShareParams(text: _generatedData));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot share')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate QR Code'),
        actions: [
          if (_generatedData.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _clear,
              tooltip: 'Clear',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type selector
            Text(
              'QR Code Type',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: QRType.values.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(_getTypeLabel(type)),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedType = type;
                      _generatedData = '';
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Input fields based on type
            _buildInputFields(theme),
            const SizedBox(height: 24),

            // Generate button
            FilledButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.qr_code),
              label: const Text('Generate QR Code'),
            ),
            const SizedBox(height: 24),

            // QR Code display
            if (_generatedData.isNotEmpty) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: _generatedData,
                    version: QrVersions.auto,
                    size: 250,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Data preview
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QR Data',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _generatedData,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _generatedData),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('QR data copied'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _share,
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(QRType type) => switch (type) {
    QRType.url => 'URL',
    QRType.text => 'Text',
    QRType.phone => 'Phone',
    QRType.email => 'Email',
    QRType.sms => 'SMS',
    QRType.wifi => 'WiFi',
    QRType.contact => 'Contact',
  };

  Widget _buildInputFields(ThemeData theme) {
    switch (_selectedType) {
      case QRType.url:
        return TextField(
          controller: _controllers[QRType.url],
          decoration: const InputDecoration(
            labelText: 'URL',
            hintText: 'https://example.com',
            prefixIcon: Icon(Icons.link),
          ),
          keyboardType: TextInputType.url,
          onChanged: (_) => setState(() => _generatedData = ''),
        );
      case QRType.text:
        return TextField(
          controller: _controllers[QRType.text],
          decoration: const InputDecoration(
            labelText: 'Text',
            hintText: 'Enter any text',
            prefixIcon: Icon(Icons.text_fields),
          ),
          maxLines: 3,
          onChanged: (_) => setState(() => _generatedData = ''),
        );
      case QRType.phone:
        return TextField(
          controller: _controllers[QRType.phone],
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: '+1234567890',
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          onChanged: (_) => setState(() => _generatedData = ''),
        );
      case QRType.email:
        return TextField(
          controller: _controllers[QRType.email],
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'user@example.com',
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => setState(() => _generatedData = ''),
        );
      case QRType.sms:
        return TextField(
          controller: _controllers[QRType.sms],
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: '+1234567890',
            prefixIcon: Icon(Icons.message),
          ),
          keyboardType: TextInputType.phone,
          onChanged: (_) => setState(() => _generatedData = ''),
        );
      case QRType.wifi:
        return Column(
          children: [
            TextField(
              controller: _wifiSsidController,
              decoration: const InputDecoration(
                labelText: 'Network Name (SSID)',
                hintText: 'MyWiFi',
                prefixIcon: Icon(Icons.wifi),
              ),
              onChanged: (_) => setState(() => _generatedData = ''),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _wifiPassController,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter password',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
              onChanged: (_) => setState(() => _generatedData = ''),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'WPA', label: Text('WPA')),
                ButtonSegment(value: 'WEP', label: Text('WEP')),
                ButtonSegment(value: 'nopass', label: Text('None')),
              ],
              selected: {_wifiSecurity},
              onSelectionChanged: (v) {
                setState(() {
                  _wifiSecurity = v.first;
                  _generatedData = '';
                });
              },
            ),
          ],
        );
      case QRType.contact:
        return Column(
          children: [
            TextField(
              controller: _contactNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'John Doe',
                prefixIcon: Icon(Icons.person),
              ),
              onChanged: (_) => setState(() => _generatedData = ''),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactPhoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                hintText: '+1234567890',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() => _generatedData = ''),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'john@example.com',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => setState(() => _generatedData = ''),
            ),
          ],
        );
    }
  }
}
