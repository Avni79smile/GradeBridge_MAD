import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calculation_model.dart';

class LocalStorageService {
  static const String _calculationsKey = 'calculations';

  Future<List<CalculationRecord>> getAllCalculations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_calculationsKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => CalculationRecord.fromMap(json)).toList();
    }
    return [];
  }

  Future<void> insertCalculation(CalculationRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final calculations = await getAllCalculations();
    calculations.add(record);
    final jsonString = json.encode(
      calculations.map((rec) => rec.toMap()).toList(),
    );
    await prefs.setString(_calculationsKey, jsonString);
  }

  Future<void> deleteCalculation(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final calculations = await getAllCalculations();
    calculations.removeWhere((rec) => rec.id == id);
    final jsonString = json.encode(
      calculations.map((rec) => rec.toMap()).toList(),
    );
    await prefs.setString(_calculationsKey, jsonString);
  }

  Future<void> deleteAllCalculations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_calculationsKey);
  }
}
