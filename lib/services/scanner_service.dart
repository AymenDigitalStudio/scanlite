class ScannerService {
  String? _lastScanned;
  DateTime? _lastScanTime;

  bool _isDuplicate(String content) {
    if (_lastScanned == content && _lastScanTime != null) {
      final elapsed = DateTime.now().difference(_lastScanTime!);
      if (elapsed < const Duration(seconds: 3)) {
        return true;
      }
    }
    return false;
  }

  dynamic processDetection(dynamic capture) {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return null;

    final content = barcode.rawValue!;
    if (_isDuplicate(content)) return null;

    _lastScanned = content;
    _lastScanTime = DateTime.now();

    return true;
  }

  void reset() {
    _lastScanned = null;
    _lastScanTime = null;
  }
}
