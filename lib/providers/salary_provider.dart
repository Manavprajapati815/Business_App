import 'package:flutter/material.dart';
import '../models/salary.dart';
import '../database/database_helper.dart';

class SalaryProvider extends ChangeNotifier {
  List<Salary> _salaries = [];
  bool _isLoading = false;

  List<Salary> get salaries => _salaries;
  bool get isLoading => _isLoading;

  Future<void> loadWorkerSalaries(int workerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _salaries = await DatabaseHelper.instance.getWorkerSalaries(workerId);
    } catch (e) {
      debugPrint('Error loading salaries: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> calculateAndSaveSalary(int workerId, DateTime startDate, DateTime endDate) async {
    try {
      // Get attendance summary for the specific worker
      final workerData = await DatabaseHelper.instance.getWorkerAttendanceSummary(workerId, startDate, endDate);

      debugPrint('Worker $workerId attendance summary: $workerData');

      // Defensive null checks and type casting
      final presentDays = (workerData['presentDays'] ?? 0).toDouble();
      final dailyWage = (workerData['dailyWage'] ?? 0).toDouble();
      final overtimeHours = (workerData['totalOvertimeHours'] ?? 0).toDouble();
      final overtimeRate = (workerData['overtimeRate'] ?? 0).toDouble();

      debugPrint('Calculating salary for worker $workerId: presentDays=$presentDays, dailyWage=$dailyWage, overtimeHours=$overtimeHours, overtimeRate=$overtimeRate');

      // Calculate base salary considering half days as 0.5
      final baseSalary = presentDays * dailyWage;
      final overtimeAmount = overtimeHours * overtimeRate;

      debugPrint('Calculated baseSalary=$baseSalary, overtimeAmount=$overtimeAmount');

      // Calculate work entry amount (per-piece/carat)
      final workEntryAmountRaw = await DatabaseHelper.instance.getTotalWorkEntryAmount(workerId, startDate, endDate);
      // ignore: unnecessary_null_comparison
      final workEntryAmount = workEntryAmountRaw != null ? (workEntryAmountRaw as num).toDouble() : 0.0;

      // Calculate advance deductions
      final advanceDeductionsRaw = await DatabaseHelper.instance.getTotalAdvanceDeductions(workerId, startDate, endDate);
      // ignore: unnecessary_null_comparison
      final advanceDeductions = advanceDeductionsRaw != null ? (advanceDeductionsRaw as num).toDouble() : 0.0;

      debugPrint('Work entry amount=$workEntryAmount, advance deductions=$advanceDeductions');

      // Calculate total salary as base + overtime + work - advances
      final totalSalary = baseSalary + overtimeAmount + workEntryAmount - advanceDeductions;

      debugPrint('Total salary calculated: $totalSalary');

      // Check if salary already exists for this worker/month
      final existingSalary = await DatabaseHelper.instance.getSalaryForMonth(workerId, startDate.year, startDate.month);

      if (existingSalary != null) {
        // Update existing salary record
        final updatedSalary = existingSalary.copyWith(
          baseSalary: baseSalary,
          overtimeAmount: overtimeAmount,
          workEntryAmount: workEntryAmount,
          advanceDeductions: advanceDeductions,
          totalSalary: totalSalary,
          remainingAmount: totalSalary - existingSalary.paidAmount, // Keep existing paid amount
          createdAt: DateTime.now(), // Update timestamp
        );
        await DatabaseHelper.instance.updateSalary(updatedSalary);
      } else {
        // Create new salary record
        final salary = Salary(
          workerId: workerId,
          year: startDate.year,
          month: startDate.month,
          baseSalary: baseSalary,
          overtimeAmount: overtimeAmount,
          workEntryAmount: workEntryAmount,
          advanceDeductions: advanceDeductions,
          totalSalary: totalSalary,
          paidAmount: 0,
          remainingAmount: totalSalary,
          createdAt: DateTime.now(),
        );
        await DatabaseHelper.instance.insertSalary(salary);
      }

      await loadWorkerSalaries(workerId);
    } catch (e) {
      debugPrint('Error calculating salary: $e');
      rethrow;
    }
  }

  Future<void> updateSalaryPayment(Salary salary, double paidAmount) async {
    try {
      final remainingAmount = salary.totalSalary - paidAmount;
      final isPaid = remainingAmount <= 0;

      final updatedSalary = salary.copyWith(
        paidAmount: paidAmount,
        remainingAmount: remainingAmount,
        isPaid: isPaid,
        paymentDate: DateTime.now(),
      );

      await DatabaseHelper.instance.updateSalary(updatedSalary);
      await loadWorkerSalaries(salary.workerId);
    } catch (e) {
      debugPrint('Error updating salary payment: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSalaryReport(int year, int month) async {
    try {
      return await DatabaseHelper.instance.getSalaryReport(year, month);
    } catch (e) {
      debugPrint('Error getting salary report: $e');
      return [];
    }
  }

  Future<Salary?> getSalaryForMonth(int workerId, DateTime startDate, DateTime endDate) async {
    try {
      // For compatibility, get salary for the month of startDate
      return await DatabaseHelper.instance.getSalaryForMonth(workerId, startDate.year, startDate.month);
    } catch (e) {
      debugPrint('Error getting salary for month: $e');
      return null;
    }
  }
}
