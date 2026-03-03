import 'package:flutter/material.dart';
import '../models/calculation_model.dart';
import '../services/local_storage_service.dart';

class CalculationHistoryProvider extends ChangeNotifier {
  final LocalStorageService _localStorageService = LocalStorageService();
  List<CalculationRecord> _calculations = [];
  bool _isLoading = false;

  List<CalculationRecord> get calculations => _calculations;
  bool get isLoading => _isLoading;

  Future<void> loadCalculations() async {
    _isLoading = true;
    notifyListeners();
    _calculations = await _localStorageService.getAllCalculations();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCalculation(CalculationRecord record) async {
    await _localStorageService.insertCalculation(record);
    await loadCalculations();
  }

  Future<void> deleteCalculation(int id) async {
    await _localStorageService.deleteCalculation(id);
    await loadCalculations();
  }

  Future<void> deleteAllCalculations() async {
    await _localStorageService.deleteAllCalculations();
    await loadCalculations();
  }

  List<CalculationRecord> getCalculationsByType(String type) {
    return _calculations.where((c) => c.calculationType == type).toList();
  }

  double getAverageGPA() {
    if (_calculations.isEmpty) return 0.0;
    final sum = _calculations.fold(0.0, (prev, curr) => prev + curr.result);
    return sum / _calculations.length;
  }

  double getHighestGPA() {
    if (_calculations.isEmpty) return 0.0;
    return _calculations.fold(
      0.0,
      (prev, curr) => curr.result > prev ? curr.result : prev,
    );
  }

  double getLowestGPA() {
    if (_calculations.isEmpty) return 0.0;
    return _calculations.fold(
      double.infinity,
      (prev, curr) => curr.result < prev ? curr.result : prev,
    );
  }
}
