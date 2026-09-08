class Validators {
  static bool isValidUrl(String text) {
    final uri = Uri.tryParse(text);
    if (uri == null) return false;
    return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  static bool isValidEmail(String text) {
    return RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(text);
  }

  static bool isValidPhone(String text) {
    return RegExp(r'^\+?[\d\s\-()]{7,}$').hasMatch(text);
  }

  static String? validateNotEmpty(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }
}
