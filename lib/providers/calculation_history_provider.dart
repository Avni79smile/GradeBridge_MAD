import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/calculation_model.dart';
import '../services/local_storage_service.dart';

class CalculationHistoryProvider extends ChangeNotifier {
  final LocalStorageService _localStorageService = LocalStorageService();
  List<CalculationRecord> _calculations = [];
  bool _isLoading = false;

  List<CalculationRecord> get calculations => _calculations;
  bool get isLoading => _isLoading;

  SupabaseClient get _db => Supabase.instance.client;
  String? get _userId => _db.auth.currentUser?.id;

  /// Save current calculation list to Supabase (best-effort, silently ignored on error).
  Future<void> _syncToSupabase() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final json = _calculations.map((r) => r.toMap()).toList();
      await _db.from('user_calculations').upsert({
        'user_id': uid,
        'calculations': json,
        'last_updated': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (_) {
      // Table may not exist yet — local storage is the fallback.
    }
  }

  /// Try to load from Supabase; fall back to SharedPreferences.
  Future<void> loadCalculations() async {
    _isLoading = true;
    notifyListeners();

    final uid = _userId;
    if (uid != null) {
      try {
        final rows = await _db
            .from('user_calculations')
            .select()
            .eq('user_id', uid)
            .limit(1);
        if (rows.isNotEmpty) {
          final calcList = rows.first['calculations'] as List<dynamic>? ?? [];
          _calculations = calcList
              .map(
                (c) => CalculationRecord.fromMap(
                  Map<String, dynamic>.from(c as Map),
                ),
              )
              .toList();
          // Keep local storage in sync.
          final prefs = await _localStorageService.getAllCalculations();
          if (prefs.isEmpty && _calculations.isNotEmpty) {
            for (final rec in _calculations) {
              await _localStorageService.insertCalculation(rec);
            }
          }
          _isLoading = false;
          notifyListeners();
          return;
        }
      } catch (_) {
        // Table may not exist — fall through to local storage.
      }
    }

    _calculations = await _localStorageService.getAllCalculations();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCalculation(CalculationRecord record) async {
    await _localStorageService.insertCalculation(record);
    _calculations = await _localStorageService.getAllCalculations();
    await _syncToSupabase();
    notifyListeners();
  }

  Future<void> deleteCalculation(int id) async {
    await _localStorageService.deleteCalculation(id);
    _calculations = await _localStorageService.getAllCalculations();
    await _syncToSupabase();
    notifyListeners();
  }

  Future<void> deleteAllCalculations() async {
    await _localStorageService.deleteAllCalculations();
    _calculations = [];
    await _syncToSupabase();
    notifyListeners();
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
