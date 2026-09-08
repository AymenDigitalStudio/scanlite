import 'dart:convert';

class ScanResult {
  final String id;
  final String content;
  final String type;
  final DateTime timestamp;
  bool favorite;

  ScanResult({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.favorite = false,
  });

  ScanType get scanType {
    if (content.startsWith('http://') || content.startsWith('https://')) {
      return ScanType.url;
    }
    if (content.startsWith('WIFI:')) {
      return ScanType.wifi;
    }
    if (RegExp(r'^\+?[\d\s\-()]{7,}$').hasMatch(content)) {
      return ScanType.phone;
    }
    if (RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(content)) {
      return ScanType.email;
    }
    return ScanType.text;
  }

  String get displayType => switch (scanType) {
    ScanType.url => 'URL',
    ScanType.wifi => 'WiFi',
    ScanType.phone => 'Phone',
    ScanType.email => 'Email',
    ScanType.text => 'Text',
  };

  String get shortContent {
    if (content.length <= 60) return content;
    return '${content.substring(0, 57)}...';
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'favorite': favorite,
  };

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
    id: json['id'] as String,
    content: json['content'] as String,
    type: json['type'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    favorite: json['favorite'] as bool? ?? false,
  );

  String toJsonString() => jsonEncode(toJson());

  factory ScanResult.fromJsonString(String source) =>
      ScanResult.fromJson(jsonDecode(source) as Map<String, dynamic>);
}

enum ScanType { url, wifi, phone, email, text }
