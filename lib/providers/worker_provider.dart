import 'package:flutter/material.dart';
import '../models/worker.dart';
import '../database/database_helper.dart';

class WorkerProvider extends ChangeNotifier {
  List<Worker> _workers = [];
  List<Worker> _activeWorkers = [];
  bool _isLoading = false;

  List<Worker> get workers => _workers;
  List<Worker> get activeWorkers => _activeWorkers;
  bool get isLoading => _isLoading;

  Future<void> loadWorkers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _workers = await DatabaseHelper.instance.getAllWorkers();
      _activeWorkers = await DatabaseHelper.instance.getActiveWorkers();
    } catch (e) {
      debugPrint('Error loading workers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addWorker(Worker worker) async {
    try {
      await DatabaseHelper.instance.insertWorker(worker);
      await loadWorkers();
    } catch (e) {
      debugPrint('Error adding worker: $e');
      rethrow;
    }
  }

  Future<void> updateWorker(Worker worker) async {
    try {
      await DatabaseHelper.instance.updateWorker(worker);
      await loadWorkers();
    } catch (e) {
      debugPrint('Error updating worker: $e');
      rethrow;
    }
  }

  Future<void> deleteWorker(int id) async {
    try {
      await DatabaseHelper.instance.deleteWorker(id);
      await loadWorkers();
    } catch (e) {
      debugPrint('Error deleting worker: $e');
      rethrow;
    }
  }

  Future<Worker?> getWorker(int id) async {
    try {
      return await DatabaseHelper.instance.getWorker(id);
    } catch (e) {
      debugPrint('Error getting worker: $e');
      return null;
    }
  }
}
