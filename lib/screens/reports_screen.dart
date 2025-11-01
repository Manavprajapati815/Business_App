import 'package:flutter/material.dart';
import '../models/worker.dart';
import '../providers/worker_provider.dart';
import '../providers/salary_provider.dart';
import '../services/pdf_report_service.dart';
import '../database/database_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  bool _isLoading = false;
  List<Worker> _workers = [];

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    setState(() {
      _isLoading = true;
    });

    final workerProvider = WorkerProvider();
    await workerProvider.loadWorkers();
    _workers = workerProvider.workers.where((w) => w.isActive).toList();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectMonth,
            tooltip: 'Select Month',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateRangeHeader(),
                  const SizedBox(height: 24),
                  const Text(
                    'Generate Reports',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildReportCard(
                          'Individual Worker Salary Slip',
                          Icons.person,
                          Colors.blue,
                          _generateIndividualReport,
                        ),
                        _buildReportCard(
                          'Factory Salary Sheet',
                          Icons.business,
                          Colors.green,
                          _generateFactoryReport,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDateRangeHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              'Report Period',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Text(
              '${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
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
      });
    }
  }

  Future<void> _generateIndividualReport() async {
    if (_workers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No workers available')),
      );
      return;
    }

    Worker? selectedWorker = _workers.first;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Worker'),
        content: DropdownButtonFormField<Worker>(
          value: selectedWorker,
          items: _workers.map((worker) => DropdownMenuItem(
            value: worker,
            child: Text(worker.name),
          )).toList(),
          onChanged: (worker) {
            selectedWorker = worker;
          },
          decoration: const InputDecoration(
            labelText: 'Worker',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _generateWorkerSlip(selectedWorker!);
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateWorkerSlip(Worker worker) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get salary for the worker
      final salaryProvider = SalaryProvider();
      final salary = await salaryProvider.getSalaryForMonth(
        worker.id!,
        _startDate,
        _endDate,
      );

      if (salary == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No salary data found for selected period')),
        );
        return;
      }

      // Get attendance
      final attendance = await DatabaseHelper.instance.getWorkerAttendance(
        worker.id!,
        _startDate,
        _endDate,
      );

      // Get work entries
      final workEntries = await DatabaseHelper.instance.getWorkEntries(
        worker.id!,
        _startDate,
        _endDate,
      );

      // Get advances
      final advances = await DatabaseHelper.instance.getAdvances(
        worker.id!,
        _startDate,
        _endDate,
      );

      // Generate PDF
      final pdfData = await PdfReportService.generateWorkerSalarySlip(
        worker,
        salary,
        attendance,
        workEntries,
        advances,
        _startDate,
        _endDate,
      );

      // Preview PDF
      await PdfReportService.previewPdf(
        pdfData,
        '${worker.name}_salary_slip_${_startDate.month}_${_startDate.year}.pdf',
      );
    } catch (e) {
      debugPrint('Error generating report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error generating report')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateFactoryReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get salary report for the month
      final salaryProvider = SalaryProvider();
      final salaryReport = await salaryProvider.getSalaryReport(
        _startDate.year,
        _startDate.month,
      );

      if (salaryReport.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No salary data found for selected month')),
        );
        return;
      }

      // Generate PDF
      final pdfData = await PdfReportService.generateFactorySalarySheet(
        salaryReport,
        _startDate.year,
        _startDate.month,
      );

      // Preview PDF
      await PdfReportService.previewPdf(
        pdfData,
        'factory_salary_sheet_${_startDate.month}_${_startDate.year}.pdf',
      );
    } catch (e) {
      debugPrint('Error generating factory report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error generating factory report')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
