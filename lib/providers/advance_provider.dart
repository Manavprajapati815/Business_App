import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/advance.dart';

class AdvanceProvider with ChangeNotifier {
  List<Advance> _advances = [];
  bool _isLoading = false;

  List<Advance> get advances => _advances;
  bool get isLoading => _isLoading;

  Future<void> loadAdvances(int workerId, DateTime startDate, DateTime endDate) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = DatabaseHelper.instance;
      _advances = await db.getAdvances(workerId, startDate, endDate);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading advances: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAdvance(Advance advance) async {
    try {
      final db = DatabaseHelper.instance;
      await db.insertAdvance(advance);
      await loadAdvances(advance.workerId, advance.date, advance.date);
    } catch (e) {
      if (kDebugMode) {
        print('Error adding advance: $e');
      }
      rethrow;
    }
  }

  Future<void> updateAdvance(Advance advance) async {
    try {
      final db = DatabaseHelper.instance;
      await db.updateAdvance(advance);
      await loadAdvances(advance.workerId, advance.date, advance.date);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating advance: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteAdvance(int id, int workerId, DateTime date) async {
    try {
      final db = DatabaseHelper.instance;
      await db.deleteAdvance(id);
      await loadAdvances(workerId, date, date);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting advance: $e');
      }
      rethrow;
    }
  }
}
