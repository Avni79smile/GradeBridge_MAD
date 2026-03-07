import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/batch_model.dart';

class BatchProvider extends ChangeNotifier {
  List<Batch> _batches = [];
  bool _isLoading = false;

  List<Batch> get batches => _batches;
  bool get isLoading => _isLoading;

  SupabaseClient get _db => Supabase.instance.client;

  BatchProvider() {
    loadBatches();
  }

  Future<void> loadBatches() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _db.from('batches').select().order('created_at');
      _batches = (data as List).map((e) => Batch.fromSupabase(e)).toList();
    } catch (e) {
      debugPrint('Error loading batches: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addBatch({
    required String name,
    required String className,
    String description = '',
  }) async {
    final teacherId = _db.auth.currentUser?.id;
    if (teacherId == null) return;

    final batch = Batch(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      className: className,
      description: description,
    );

    try {
      await _db.from('batches').insert({
        ...batch.toSupabase(),
        'teacher_id': teacherId,
      });
      _batches.add(batch);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding batch: $e');
    }
  }

  Future<void> updateBatch(Batch updatedBatch) async {
    try {
      await _db
          .from('batches')
          .update(updatedBatch.toSupabase())
          .eq('id', updatedBatch.id);
      final index = _batches.indexWhere((b) => b.id == updatedBatch.id);
      if (index != -1) {
        _batches[index] = updatedBatch;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating batch: $e');
    }
  }

  Future<void> deleteBatch(String id) async {
    try {
      await _db.from('batches').delete().eq('id', id);
      _batches.removeWhere((b) => b.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting batch: $e');
    }
  }

  Batch? getBatchById(String id) {
    try {
      return _batches.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }
}
