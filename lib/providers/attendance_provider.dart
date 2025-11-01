// ignore: dangling_library_doc_comments
/// Provider class for managing attendance-related state and operations.
/// Handles loading, marking, and retrieving attendance data for workers.
import 'package:flutter/material.dart';
import '../models/attendance.dart';
import '../database/database_helper.dart';

class AttendanceProvider extends ChangeNotifier {
  List<Attendance> _attendanceRecords = [];
  bool _isLoading = false;

  /// Getter for the list of attendance records.
  List<Attendance> get attendanceRecords => _attendanceRecords;
  /// Getter for the loading state.
  bool get isLoading => _isLoading;

  /// Loads attendance records for a specific worker within a date range.
  /// Updates the loading state and notifies listeners.
  Future<void> loadWorkerAttendance(int workerId, DateTime startDate, DateTime endDate) async {
    _isLoading = true;
    notifyListeners();

    try {
      _attendanceRecords = await DatabaseHelper.instance.getWorkerAttendance(workerId, startDate, endDate);
    } catch (e) {
      debugPrint('Error loading attendance: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marks attendance for a worker on a specific date.
  /// If attendance already exists, updates it; otherwise, inserts new record.
  Future<void> markAttendance(Attendance attendance) async {
    try {
      final existing = await DatabaseHelper.instance.getAttendanceForDate(
        attendance.workerId,
        attendance.date,
      );

      if (existing != null) {
        await DatabaseHelper.instance.updateAttendance(
          attendance.copyWith(id: existing.id),
        );
      } else {
        await DatabaseHelper.instance.insertAttendance(attendance);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking attendance: $e');
      rethrow;
    }
  }

  /// Marks attendance for multiple records in bulk.
  /// Uses batch operations for efficiency.
  Future<void> markBulkAttendance(List<Attendance> attendanceList) async {
    try {
      await DatabaseHelper.instance.insertBulkAttendance(attendanceList);
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking bulk attendance: $e');
      rethrow;
    }
  }

  /// Retrieves attendance record for a specific worker and date.
  /// Returns null if not found or on error.
  Future<Attendance?> getAttendanceForDate(int workerId, DateTime date) async {
    try {
      return await DatabaseHelper.instance.getAttendanceForDate(workerId, date);
    } catch (e) {
      debugPrint('Error getting attendance: $e');
      return null;
    }
  }

  /// Gets a summary of attendance data for a date range.
  /// Includes worker attendance statistics.
  Future<Map<String, dynamic>> getMonthlySummary(DateTime startDate, DateTime endDate) async {
    try {
      return await DatabaseHelper.instance.getAttendanceSummaryForDateRange(startDate, endDate);
    } catch (e) {
      debugPrint('Error getting monthly summary: $e');
      return {'workers': [], 'totalWorkers': 0};
    }
  }
}
