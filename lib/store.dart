import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class AppStore extends ChangeNotifier {
  List<VisaCase> cases = [];

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('cases');
    if (raw != null) {
      try {
        cases = (jsonDecode(raw) as List)
            .map((e) => VisaCase.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        cases = [];
      }
    }
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('cases', jsonEncode(cases.map((c) => c.toJson()).toList()));
  }

  VisaCase? byId(String id) {
    for (final c in cases) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> upsert(VisaCase c) async {
    final i = cases.indexWhere((x) => x.id == c.id);
    if (i >= 0) {
      cases[i] = c;
    } else {
      cases.insert(0, c);
    }
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    cases.removeWhere((c) => c.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> addEvent(String id, StatusEvent e) async {
    final c = byId(id);
    if (c == null) return;
    c.history.add(e);
    notifyListeners();
    await _save();
  }
}
