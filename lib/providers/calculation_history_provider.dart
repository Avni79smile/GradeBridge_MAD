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

  /// Save current calculation list to Supabase. Returns true on success.
  Future<bool> _syncToSupabase() async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      final json = _calculations.map((r) => r.toMap()).toList();
      await _db.from('user_calculations').upsert({
        'user_id': uid,
        'calculations': json,
        'last_updated': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
      return true;
    } catch (e) {
      debugPrint('Supabase sync failed (user_calculations): $e');
      return false;
    }
  }

  /// Try to load from Supabase; fall back to SharedPreferences.
  /// If local has data but Supabase is empty, re-uploads local → Supabase.
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
        if ((rows as List).isNotEmpty) {
          final calcList = rows.first['calculations'] as List<dynamic>? ?? [];
          _calculations = calcList
              .map(
                (c) => CalculationRecord.fromMap(
                  Map<String, dynamic>.from(c as Map),
                ),
              )
              .toList();
          // Mirror to local storage so offline access works.
          await _localStorageService.deleteAllCalculations();
          for (final rec in _calculations) {
            await _localStorageService.insertCalculation(rec);
          }
          _isLoading = false;
          notifyListeners();
          return;
        }
        // Supabase table exists but no row yet — check local and upload.
        final localCalcs = await _localStorageService.getAllCalculations();
        if (localCalcs.isNotEmpty) {
          _calculations = localCalcs;
          // Re-upload local data to Supabase so it persists there too.
          await _syncToSupabase();
          _isLoading = false;
          notifyListeners();
          return;
        }
      } catch (e) {
        debugPrint('Error loading from Supabase, falling back to local: $e');
      }
    }

    _calculations = await _localStorageService.getAllCalculations();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCalculation(CalculationRecord record) async {
    // Save locally first for immediate availability.
    await _localStorageService.insertCalculation(record);
    _calculations = await _localStorageService.getAllCalculations();
    notifyListeners();
    // Then persist to Supabase (awaited so data isn't lost on app close).
    await _syncToSupabase();
  }

  Future<void> deleteCalculation(int id) async {
    await _localStorageService.deleteCalculation(id);
    _calculations = await _localStorageService.getAllCalculations();
    notifyListeners();
    await _syncToSupabase();
  }

  Future<void> deleteAllCalculations() async {
    await _localStorageService.deleteAllCalculations();
    _calculations = [];
    notifyListeners();
    await _syncToSupabase();
  }

  List<CalculationRecord> getCalculationsByType(String type) {
    final normalizedType = type.trim().toUpperCase();
    return _calculations
        .where((c) => c.calculationType.trim().toUpperCase() == normalizedType)
        .toList();
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
