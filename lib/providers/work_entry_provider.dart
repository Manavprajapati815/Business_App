import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/work_entry.dart';

class WorkEntryProvider with ChangeNotifier {
  List<WorkEntry> _workEntries = [];
  bool _isLoading = false;

  List<WorkEntry> get workEntries => _workEntries;
  bool get isLoading => _isLoading;

  Future<void> loadWorkEntries(int workerId, DateTime startDate, DateTime endDate) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = DatabaseHelper.instance;
      _workEntries = await db.getWorkEntries(workerId, startDate, endDate);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading work entries: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addWorkEntry(WorkEntry workEntry) async {
    try {
      final db = DatabaseHelper.instance;
      await db.insertWorkEntry(workEntry);
      await loadWorkEntries(workEntry.workerId, workEntry.date, workEntry.date);
    } catch (e) {
      if (kDebugMode) {
        print('Error adding work entry: $e');
      }
      rethrow;
    }
  }

  Future<void> updateWorkEntry(WorkEntry workEntry) async {
    try {
      final db = DatabaseHelper.instance;
      await db.updateWorkEntry(workEntry);
      await loadWorkEntries(workEntry.workerId, workEntry.date, workEntry.date);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating work entry: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteWorkEntry(int id, int workerId, DateTime date) async {
    try {
      final db = DatabaseHelper.instance;
      await db.deleteWorkEntry(id);
      await loadWorkEntries(workerId, date, date);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting work entry: $e');
      }
      rethrow;
    }
  }

  Future<List<WorkEntry>> getWorkEntriesForMonth(int workerId, int year, int month) async {
    try {
      final db = DatabaseHelper.instance;
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);
      return await db.getWorkEntries(workerId, startDate, endDate);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting work entries for month: $e');
      }
      return [];
    }
  }

  double getTotalWorkAmount(int workerId, DateTime startDate, DateTime endDate) {
    return _workEntries
        .where((entry) => entry.workerId == workerId && 
            entry.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            entry.date.isBefore(endDate.add(const Duration(days: 1))))
        .fold(0.0, (sum, entry) => sum + entry.totalAmount);
  }
}
