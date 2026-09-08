import 'package:flutter/material.dart';
import '../models/scan_result.dart';
import '../services/storage_service.dart';

class HistoryService extends ChangeNotifier {
  final StorageService _storage;
  List<ScanResult> _items = [];

  HistoryService(this._storage) {
    _load();
  }

  List<ScanResult> get items => List.unmodifiable(_items);

  void _load() {
    final raw = _storage.scanHistoryJson;
    _items = raw.map((e) => ScanResult.fromJsonString(e)).toList();
    _items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  Future<void> add(ScanResult result) async {
    _items.insert(0, result);
    await _save();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
    await _save();
  }

  Future<void> clear() async {
    _items.clear();
    await _storage.clearHistory();
    notifyListeners();
  }

  List<ScanResult> search(String query) {
    if (query.isEmpty) return items;
    final lower = query.toLowerCase();
    return _items
        .where((e) => e.content.toLowerCase().contains(lower))
        .toList();
  }

  Future<void> _save() async {
    final jsonList = _items.map((e) => e.toJsonString()).toList();
    await _storage.saveScanHistory(jsonList);
    notifyListeners();
  }
}
