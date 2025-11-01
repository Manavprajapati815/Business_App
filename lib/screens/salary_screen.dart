import 'package:flutter/material.dart';
import '../models/worker.dart';
import '../models/salary.dart';
import '../models/attendance.dart';
import '../providers/worker_provider.dart';
import '../providers/salary_provider.dart';
import '../providers/attendance_provider.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  bool _isLoading = true;
  List<Worker> _workers = [];
  List<Salary> _salaries = [];
  Map<String, List<Attendance>> _attendanceByWorker = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final workerProvider = WorkerProvider();
    // ignore: unused_local_variable
    final salaryProvider = SalaryProvider();
    // ignore: unused_local_variable
    final attendanceProvider = AttendanceProvider();

    await workerProvider.loadWorkers();
    _workers = workerProvider.workers.where((w) => w.isActive).toList();

    // Load salaries for the selected date range
    await _loadSalariesForDateRange(_startDate, _endDate);

    // Load attendance for all workers for the selected date range
    await _loadAttendanceForDateRange(_startDate, _endDate);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSalariesForDateRange(DateTime startDate, DateTime endDate) async {
    final salaryProvider = SalaryProvider();
    List<Salary> salaries = [];

    for (var worker in _workers) {
      final salary = await salaryProvider.getSalaryForMonth(
        worker.id!,
        startDate,
        endDate,
      );
      if (salary != null) {
        salaries.add(salary);
      }
    }

    if (mounted) {
      setState(() {
        _salaries = salaries;
      });
    }
  }

  Future<void> _loadAttendanceForDateRange(DateTime startDate, DateTime endDate) async {
    final attendanceProvider = AttendanceProvider();
    Map<String, List<Attendance>> attendanceByWorker = {};

    for (var worker in _workers) {
      await attendanceProvider.loadWorkerAttendance(worker.id!, startDate, endDate);
      attendanceByWorker[worker.id!.toString()] = attendanceProvider.attendanceRecords;
    }

    if (mounted) {
      setState(() {
        _attendanceByWorker = attendanceByWorker;
      });
    }
  }

  Future<void> _calculateSalaries() async {
    setState(() {
      _isLoading = true;
    });

    final salaryProvider = SalaryProvider();

    for (var worker in _workers) {
      try {
        await salaryProvider.calculateAndSaveSalary(
          worker.id!,
          _startDate,
          _endDate,
        );
      } catch (e) {
        debugPrint('Error calculating salary for worker ${worker.name}: $e');
      }
    }

    await _loadSalariesForDateRange(_startDate, _endDate);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salaries calculated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salary Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectMonth,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildDateRangeHeader(),
                Expanded(
                  child: _buildSalaryList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _calculateSalaries,
        child: const Icon(Icons.calculate),
      ),
    );
  }

  Widget _buildDateRangeHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      // ignore: deprecated_member_use
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Column(
        children: [
          Text(
            'Salary Period',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryList() {
    if (_workers.isEmpty) {
      return const Center(
        child: Text('No active workers found'),
      );
    }

    return ListView.builder(
      itemCount: _workers.length,
      itemBuilder: (context, index) {
        final worker = _workers[index];
        final salary = _salaries.firstWhere(
          (s) => s.workerId == worker.id,
          orElse: () => Salary(
            workerId: worker.id!,
            year: _startDate.year,
            month: _startDate.month,
            baseSalary: 0,
            overtimeAmount: 0,
            totalSalary: 0,
            paidAmount: 0,
            remainingAmount: 0,
            isPaid: false,
          ),
        );

        final attendance = _attendanceByWorker[worker.id.toString()] ?? [];
        final presentDays = attendance.where((a) => a.isPresent).length;
        final overtimeHours = attendance.fold<double>(
          0,
          (sum, a) => sum + (a.overtimeHours ?? 0),
        );

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(worker.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Present: $presentDays days'),
                if (overtimeHours > 0) Text('Overtime: ${overtimeHours.toStringAsFixed(1)} hrs'),
              ],
            ),
            trailing: SizedBox(
              width: 180,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₹${salary.totalSalary.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (salary.paidAmount > 0)
                          Text(
                            'Paid: ₹${salary.paidAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                            ),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          salary.isPaid ? 'PAID' : 'PENDING: ₹${salary.remainingAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: salary.isPaid ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: salary.isPaid ? Colors.red : Colors.green,
                      minimumSize: const Size(80, 36),
                    ),
                    onPressed: () {
                      if (salary.isPaid) {
                        _markAsUnpaid(salary);
                      } else {
                        _showPaymentDialog(salary, _workers.firstWhere((w) => w.id == salary.workerId));
                      }
                    },
                    child: Text(salary.isPaid ? 'Unpaid' : 'Paid'),
                  ),
                ],
              ),
            ),
            onTap: () => _showSalaryDetails(salary, worker, presentDays, overtimeHours),
          ),
        );
      },
    );
  }

  Future<void> _selectMonth() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _isLoading = true;
      });
      await _loadData();
    }
  }

  void _showSalaryDetails(Salary salary, Worker worker, int presentDays, double overtimeHours) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(worker.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Designation', worker.designation),
              const Divider(),
              _buildDetailRow('Present Days', presentDays.toString()),
              _buildDetailRow('Daily Wage', '₹${worker.dailyWage.toStringAsFixed(0)}'),
              _buildDetailRow('Base Salary', '₹${salary.baseSalary.toStringAsFixed(0)}'),
              if (overtimeHours > 0) ...[
                _buildDetailRow('Overtime Hours', overtimeHours.toStringAsFixed(1)),
                _buildDetailRow('Overtime Rate', '₹${worker.overtimeRate.toStringAsFixed(0)}/hr'),
                _buildDetailRow('Overtime Amount', '₹${salary.overtimeAmount.toStringAsFixed(0)}'),
              ],
              if (salary.workEntryAmount > 0) ...[
                _buildDetailRow('Work Entry Amount', '₹${salary.workEntryAmount.toStringAsFixed(0)}'),
              ],
              if (salary.advanceDeductions > 0) ...[
                _buildDetailRow('Advance Deductions', '-₹${salary.advanceDeductions.toStringAsFixed(0)}'),
              ],
              const Divider(),
              _buildDetailRow('Total Salary', '₹${salary.totalSalary.toStringAsFixed(0)}', isTotal: true),
              _buildDetailRow('Paid Amount', '₹${salary.paidAmount.toStringAsFixed(0)}'),
              _buildDetailRow('Remaining', '₹${salary.remainingAmount.toStringAsFixed(0)}'),
              if (salary.paymentDate != null) ...[
                const Divider(),
                _buildDetailRow('Payment Date', '${salary.paymentDate!.day}/${salary.paymentDate!.month}/${salary.paymentDate!.year}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (salary.isPaid) {
                // Mark as unpaid by setting paidAmount to 0
                final salaryProvider = SalaryProvider();
                setState(() {
                  _isLoading = true;
                });
                await salaryProvider.updateSalaryPayment(salary, 0);
                await _loadSalariesForDateRange(_startDate, _endDate);
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Salary marked as unpaid')),
                );
              } else {
                _showPaymentDialog(salary, worker);
              }
            },
            child: Text(salary.isPaid ? 'Mark as Unpaid' : 'Mark as Paid'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(Salary salary, Worker worker) {
    final TextEditingController paymentController = TextEditingController(
      text: salary.remainingAmount.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Record Payment - ${worker.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total Salary: ₹${salary.totalSalary.toStringAsFixed(0)}'),
            Text('Already Paid: ₹${salary.paidAmount.toStringAsFixed(0)}'),
            Text('Remaining: ₹${salary.remainingAmount.toStringAsFixed(0)}'),
            const SizedBox(height: 16),
            TextField(
              controller: paymentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Payment Amount',
                prefixText: '₹',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final paymentAmount = double.tryParse(paymentController.text) ?? 0;
              if (paymentAmount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid payment amount')),
                );
                return;
              }

              if (paymentAmount > salary.remainingAmount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment amount cannot exceed remaining salary')),
                );
                return;
              }

              Navigator.pop(context);
              await _recordPayment(salary, paymentAmount);
            },
            child: const Text('Record Payment'),
          ),
        ],
      ),
    );
  }

  Future<void> _recordPayment(Salary salary, double paymentAmount) async {
    final salaryProvider = SalaryProvider();

    setState(() {
      _isLoading = true;
    });

    final newPaidAmount = salary.paidAmount + paymentAmount;
    final totalSalary = salary.totalSalary;

    double updatedPaidAmount = newPaidAmount;
    if (updatedPaidAmount > totalSalary) {
      updatedPaidAmount = totalSalary;
    }

    await salaryProvider.updateSalaryPayment(salary, updatedPaidAmount);
    await _loadSalariesForDateRange(_startDate, _endDate);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment of ₹${paymentAmount.toStringAsFixed(0)} recorded successfully')),
      );
    }
  }

  // ignore: unused_element
  Future<void> _markAsPaid(Salary salary) async {
    final salaryProvider = SalaryProvider();

    setState(() {
      _isLoading = true;
    });

    await salaryProvider.updateSalaryPayment(salary, salary.totalSalary);
    await _loadSalariesForDateRange(_startDate, _endDate);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salary marked as paid')),
      );
    }
  }

  Future<void> _markAsUnpaid(Salary salary) async {
    final salaryProvider = SalaryProvider();

    setState(() {
      _isLoading = true;
    });

    await salaryProvider.updateSalaryPayment(salary, 0);
    await _loadSalariesForDateRange(_startDate, _endDate);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salary marked as unpaid')),
      );
    }
  }

  // ignore: unused_element
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
