import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/worker.dart';
import '../providers/worker_provider.dart';

class WorkersScreen extends StatefulWidget {
  const WorkersScreen({super.key});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<WorkerProvider>().loadWorkers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddWorkerDialog(context),
          ),
        ],
      ),
      body: Consumer<WorkerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final workers = provider.workers;

          if (workers.isEmpty) {
            return const Center(
              child: Text('No workers found. Add a new worker to get started.'),
            );
          }

          return ListView.builder(
            itemCount: workers.length,
            itemBuilder: (context, index) {
              final worker = workers[index];
              return _buildWorkerCard(worker);
            },
          );
        },
      ),
    );
  }

  Widget _buildWorkerCard(Worker worker) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: worker.isActive ? Colors.green : Colors.grey,
          child: Text(
            worker.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          worker.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone: ${worker.phone}'),
            Text('Daily Wage: ₹${worker.dailyWage.toStringAsFixed(2)}'),
            Text('Overtime Rate: ₹${worker.overtimeRate.toStringAsFixed(2)}/hr'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showEditWorkerDialog(context, worker),
            ),
            IconButton(
              icon: Icon(
                worker.isActive ? Icons.toggle_on : Icons.toggle_off,
                color: worker.isActive ? Colors.green : Colors.grey,
              ),
              onPressed: () => _toggleWorkerStatus(worker),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWorkerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final dailyWageController = TextEditingController();
    final overtimeRateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Worker'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: dailyWageController,
                  decoration: const InputDecoration(
                    labelText: 'Daily Wage (₹)',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: overtimeRateController,
                  decoration: const InputDecoration(
                    labelText: 'Overtime Rate (₹/hr)',
                    prefixIcon: Icon(Icons.timer),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_validateInputs(
                  nameController.text,
                  phoneController.text,
                  dailyWageController.text,
                  overtimeRateController.text,
                )) {
                  final worker = Worker(
                    name: nameController.text,
                    phone: phoneController.text,
                    address: 'N/A',
                    designation: 'Worker',
                    dailyWage: double.parse(dailyWageController.text),
                    overtimeRate: double.parse(overtimeRateController.text),
                    joinDate: DateTime.now(),
                    isActive: true,
                  );

                  context.read<WorkerProvider>().addWorker(worker);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add Worker'),
            ),
          ],
        );
      },
    );
  }

  void _showEditWorkerDialog(BuildContext context, Worker worker) {
    final nameController = TextEditingController(text: worker.name);
    final phoneController = TextEditingController(text: worker.phone);
    final dailyWageController = TextEditingController(text: worker.dailyWage.toString());
    final overtimeRateController = TextEditingController(text: worker.overtimeRate.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Worker'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: dailyWageController,
                  decoration: const InputDecoration(
                    labelText: 'Daily Wage (₹)',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: overtimeRateController,
                  decoration: const InputDecoration(
                    labelText: 'Overtime Rate (₹/hr)',
                    prefixIcon: Icon(Icons.timer),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_validateInputs(
                  nameController.text,
                  phoneController.text,
                  dailyWageController.text,
                  overtimeRateController.text,
                )) {
                  final updatedWorker = worker.copyWith(
                    name: nameController.text,
                    phone: phoneController.text,
                    dailyWage: double.parse(dailyWageController.text),
                    overtimeRate: double.parse(overtimeRateController.text),
                  );

                  context.read<WorkerProvider>().updateWorker(updatedWorker);
                  Navigator.pop(context);
                }
              },
              child: const Text('Update Worker'),
            ),
          ],
        );
      },
    );
  }

  bool _validateInputs(String name, String phone, String dailyWage, String overtimeRate) {
    if (name.isEmpty || phone.isEmpty || dailyWage.isEmpty || overtimeRate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return false;
    }

    final wage = double.tryParse(dailyWage);
    final rate = double.tryParse(overtimeRate);

    if (wage == null || rate == null || wage <= 0 || rate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid wage and overtime rate')),
      );
      return false;
    }

    return true;
  }

  void _toggleWorkerStatus(Worker worker) {
    final updatedWorker = worker.copyWith(isActive: !worker.isActive);
    context.read<WorkerProvider>().updateWorker(updatedWorker);
  }
}
