import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../app/routes.dart';
import '../main.dart';
import '../models/scan_result.dart';
import '../services/ad_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  bool _isProcessing = false;
  bool _isFlashOn = false;
  MobileScannerController? _cameraController;
  bool _cameraReady = false;
  String? _error;
  final AdService _adService = AdService();
  static const _channel = MethodChannel('com.scanlite.scanlite/haptic');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _adService.loadInterstitialAd();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cameraController!.stop();
    } else if (state == AppLifecycleState.resumed) {
      _cameraController!.start();
    }
  }

  void _initCamera() {
    _cameraController?.dispose();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    _cameraReady = true;
    _error = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _cameraController = null;
    _adService.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    if (barcode.rawValue == null || barcode.rawValue!.isEmpty) return;

    _isProcessing = true;
    _cameraController?.stop();

    final appState = AppProvider.of(context);
    if (appState.storage.vibrateOnScan) {
      _channel.invokeMethod('vibrate');
    }
    if (appState.storage.playSound) {
      _channel.invokeMethod('playBeep');
    }

    final scanResult = ScanResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: barcode.rawValue!,
      type: barcode.format.name,
      timestamp: DateTime.now(),
    );

    AppProvider.of(context).history.add(scanResult);

    if (mounted) {
      _adService.showInterstitialAd(
        onDismissed: () {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.result,
              arguments: {
                'content': scanResult.content,
                'type': scanResult.type,
                'imagePath': null,
              },
            ).then((_) {
              _isProcessing = false;
              if (mounted) {
                _cameraController?.start();
              }
            });
          }
        },
      );
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    try {
      await _cameraController!.toggleTorch();
      setState(() => _isFlashOn = !_isFlashOn);
    } catch (e) {
      // Flash may not be available
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null || !mounted) return;

      _isProcessing = true;

      final galleryController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
      );

      try {
        final result = await galleryController.analyzeImage(image.path);
        if (result != null && result.barcodes.isNotEmpty) {
          final barcode = result.barcodes.first;
          if (barcode.rawValue != null && mounted) {
            final scanResult = ScanResult(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              content: barcode.rawValue!,
              type: barcode.format.name,
              timestamp: DateTime.now(),
            );
            AppProvider.of(context).history.add(scanResult);

            final appState = AppProvider.of(context);
            if (appState.storage.vibrateOnScan) {
              _channel.invokeMethod('vibrate');
            }
            if (appState.storage.playSound) {
              _channel.invokeMethod('playBeep');
            }

            _adService.showInterstitialAd(
              onDismissed: () {
                if (mounted) {
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.result,
                    arguments: {
                      'content': barcode.rawValue!,
                      'type': barcode.format.name,
                      'imagePath': image.path,
                    },
                  ).then((_) {
                    _isProcessing = false;
                  });
                }
              },
            );
            return;
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No QR or barcode detected in this image.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } finally {
        await galleryController.dispose();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning image: $e')),
        );
      }
    }

    _isProcessing = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_cameraReady && _cameraController != null)
            MobileScanner(
              controller: _cameraController!,
              onDetect: _onDetect,
            ),

          if (_error != null)
            Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _error = null;
                          _initCamera();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),

          CustomPaint(painter: _ScannerOverlayPainter()),

          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.of(context).pop(),
                ),
                _CircleButton(
                  icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  onTap: _toggleFlash,
                ),
              ],
            ),
          ),

          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Align the QR code inside the frame',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 24),
                _CircleButton(
                  icon: Icons.photo_library_outlined,
                  onTap: _pickFromGallery,
                  size: 56,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    final scanAreaSize = size.width * 0.7;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2;
    final rect = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(16)),
          ),
      ),
      paint,
    );

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 32.0;

    canvas.drawPath(
      Path()
        ..moveTo(left + cornerLength, top)
        ..lineTo(left, top)
        ..lineTo(left, top + cornerLength),
      borderPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(left + scanAreaSize - cornerLength, top)
        ..lineTo(left + scanAreaSize, top)
        ..lineTo(left + scanAreaSize, top + cornerLength),
      borderPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(left, top + scanAreaSize - cornerLength)
        ..lineTo(left, top + scanAreaSize)
        ..lineTo(left + cornerLength, top + scanAreaSize),
      borderPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(left + scanAreaSize, top + scanAreaSize - cornerLength)
        ..lineTo(left + scanAreaSize, top + scanAreaSize)
        ..lineTo(left + scanAreaSize - cornerLength, top + scanAreaSize),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}
