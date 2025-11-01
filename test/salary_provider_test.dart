import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:worker_salary_app/providers/salary_provider.dart';
import 'package:worker_salary_app/database/database_helper.dart';

void main() {
  // Initialize sqflite for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  group('SalaryProvider Tests', () {
    final salaryProvider = SalaryProvider();

    test('Calculate salary correctly', () async {
      // Setup test data
      final workerId = 1;
      final startDate = DateTime(2025, 10, 1);
      final endDate = DateTime(2025, 10, 31);

      // Clear existing salary for test worker/month if any
      final existingSalary = await DatabaseHelper.instance.getSalaryForMonth(workerId, startDate.year, startDate.month);
      if (existingSalary != null) {
        await DatabaseHelper.instance.updateSalary(existingSalary.copyWith(
          baseSalary: 0,
          overtimeAmount: 0,
          workEntryAmount: 0,
          advanceDeductions: 0,
          totalSalary: 0,
          paidAmount: 0,
          remainingAmount: 0,
        ));
      }

      // Calculate and save salary
      await salaryProvider.calculateAndSaveSalary(workerId, startDate, endDate);

      // Load salary for worker/month
      final salary = await DatabaseHelper.instance.getSalaryForMonth(workerId, startDate.year, startDate.month);

      expect(salary, isNotNull);
      expect(salary!.totalSalary, greaterThan(0));
      expect(salary.baseSalary, greaterThanOrEqualTo(0));
      expect(salary.overtimeAmount, greaterThanOrEqualTo(0));
      expect(salary.paidAmount, equals(0));
      expect(salary.remainingAmount, equals(salary.totalSalary));
    });

    test('Update salary payment correctly', () async {
      final workerId = 1;
      final startDate = DateTime(2025, 10, 1);
      final endDate = DateTime(2025, 10, 31);

      await salaryProvider.calculateAndSaveSalary(workerId, startDate, endDate);
      final salary = await DatabaseHelper.instance.getSalaryForMonth(workerId, startDate.year, startDate.month);
      expect(salary, isNotNull);

      final paidAmount = salary!.totalSalary / 2;
      await salaryProvider.updateSalaryPayment(salary, paidAmount);

      final updatedSalary = await DatabaseHelper.instance.getSalaryForMonth(workerId, startDate.year, startDate.month);
      expect(updatedSalary, isNotNull);
      expect(updatedSalary!.paidAmount, equals(paidAmount));
      expect(updatedSalary.remainingAmount, equals(salary.totalSalary - paidAmount));
      expect(updatedSalary.isPaid, isFalse);

      // Mark full payment
      await salaryProvider.updateSalaryPayment(updatedSalary, updatedSalary.totalSalary);
      final fullyPaidSalary = await DatabaseHelper.instance.getSalaryForMonth(workerId, startDate.year, startDate.month);
      expect(fullyPaidSalary!.isPaid, isTrue);
    });
  });
}
