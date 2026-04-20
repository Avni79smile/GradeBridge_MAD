import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/calculation_model.dart';

class LocalStorageService {
  static const String _legacyCalculationsKey = 'calculations';

  String _calculationsKeyForUser() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return _legacyCalculationsKey;
    }
    return 'calculations_$userId';
  }

  Future<void> _migrateLegacyIfNeeded(SharedPreferences prefs) async {
    final scopedKey = _calculationsKeyForUser();
    if (scopedKey == _legacyCalculationsKey) return;

    final alreadyScoped = prefs.getString(scopedKey);
    if (alreadyScoped != null) return;

    final legacy = prefs.getString(_legacyCalculationsKey);
    if (legacy == null) return;

    await prefs.setString(scopedKey, legacy);
    await prefs.remove(_legacyCalculationsKey);
  }

  Future<List<CalculationRecord>> getAllCalculations() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyIfNeeded(prefs);
    final jsonString = prefs.getString(_calculationsKeyForUser());
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => CalculationRecord.fromMap(json)).toList();
    }
    return [];
  }

  Future<void> insertCalculation(CalculationRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyIfNeeded(prefs);
    final calculations = await getAllCalculations();
    calculations.add(record);
    final jsonString = json.encode(
      calculations.map((rec) => rec.toMap()).toList(),
    );
    await prefs.setString(_calculationsKeyForUser(), jsonString);
  }

  Future<void> deleteCalculation(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyIfNeeded(prefs);
    final calculations = await getAllCalculations();
    calculations.removeWhere((rec) => rec.id == id);
    final jsonString = json.encode(
      calculations.map((rec) => rec.toMap()).toList(),
    );
    await prefs.setString(_calculationsKeyForUser(), jsonString);
  }

  Future<void> deleteAllCalculations() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyIfNeeded(prefs);
    await prefs.remove(_calculationsKeyForUser());
  }
}
