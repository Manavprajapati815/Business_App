import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/worker.dart';
import '../models/attendance.dart';
import '../models/salary.dart';
import '../models/work_entry.dart';
import '../models/advance.dart';
/// Singleton class for managing SQLite database operations in the Worker Salary Manager app.
/// Handles all CRUD operations for workers, attendance, salaries, work entries, and advances.
/// Uses Sqflite for local database storage.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Getter for the database instance. Initializes the database if not already done.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('worker_salary.db');
    return _database!;
  }

  /// Initializes the database with the given file path.
  /// Sets up database version and upgrade callbacks.
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Creates the database tables and indexes.
  /// Called when the database is first created.
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT NOT NULL,
        designation TEXT NOT NULL,
        dailyWage REAL NOT NULL,
        overtimeRate REAL NOT NULL,
        joinDate TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workerId INTEGER NOT NULL,
        date TEXT NOT NULL,
        isPresent INTEGER NOT NULL,
        isHalfDay INTEGER NOT NULL DEFAULT 0,
        overtimeHours REAL,
        notes TEXT,
        FOREIGN KEY (workerId) REFERENCES workers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE salaries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workerId INTEGER NOT NULL,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        baseSalary REAL NOT NULL,
        overtimeAmount REAL NOT NULL,
        workEntryAmount REAL NOT NULL DEFAULT 0,
        advanceDeductions REAL NOT NULL DEFAULT 0,
        totalSalary REAL NOT NULL,
        paidAmount REAL NOT NULL,
        remainingAmount REAL NOT NULL,
        paymentDate TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (workerId) REFERENCES workers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE work_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workerId INTEGER NOT NULL,
        date TEXT NOT NULL,
        workType TEXT NOT NULL,
        quantity REAL NOT NULL,
        ratePerUnit REAL NOT NULL,
        totalAmount REAL NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (workerId) REFERENCES workers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE advances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workerId INTEGER NOT NULL,
        date TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (workerId) REFERENCES workers (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX idx_attendance_worker_date 
      ON attendance (workerId, date)
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX idx_salary_worker_month 
      ON salaries (workerId, year, month)
    ''');

    await db.execute('''
      CREATE INDEX idx_work_entries_worker_date 
      ON work_entries (workerId, date)
    ''');

    await db.execute('''
      CREATE INDEX idx_advances_worker_date
      ON advances (workerId, date)
    ''');
  }

  /// Upgrades the database schema when version changes.
  /// Handles migrations from old versions to new.
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add isPaid column to salaries table
      await db.execute('ALTER TABLE salaries ADD COLUMN isPaid INTEGER DEFAULT 0');
    }
  }

  // Worker CRUD operations
  /// Inserts a new worker into the database.
  /// Returns the ID of the inserted worker.
  Future<int> insertWorker(Worker worker) async {
    final db = await instance.database;
    return await db.insert('workers', worker.toMap());
  }

  /// Retrieves all workers from the database, ordered by name.
  Future<List<Worker>> getAllWorkers() async {
    final db = await instance.database;
    final result = await db.query(
      'workers',
      orderBy: 'name ASC',
    );
    return result.map((json) => Worker.fromMap(json)).toList();
  }

  /// Retrieves only active workers from the database, ordered by name.
  Future<List<Worker>> getActiveWorkers() async {
    final db = await instance.database;
    final result = await db.query(
      'workers',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return result.map((json) => Worker.fromMap(json)).toList();
  }

  /// Retrieves a specific worker by ID.
  /// Returns null if not found.
  Future<Worker?> getWorker(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'workers',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? Worker.fromMap(result.first) : null;
  }

  /// Updates an existing worker in the database.
  /// Returns the number of rows affected.
  Future<int> updateWorker(Worker worker) async {
    final db = await instance.database;
    return await db.update(
      'workers',
      worker.toMap(),
      where: 'id = ?',
      whereArgs: [worker.id],
    );
  }

  /// Deletes a worker from the database by ID.
  /// Returns the number of rows affected.
  Future<int> deleteWorker(int id) async {
    final db = await instance.database;
    return await db.delete(
      'workers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Attendance CRUD operations
  Future<int> insertAttendance(Attendance attendance) async {
    final db = await instance.database;
    return await db.insert('attendance', attendance.toMap());
  }

  Future<List<Attendance>> getWorkerAttendance(int workerId, DateTime startDate, DateTime endDate) async {
    final db = await instance.database;
    final result = await db.query(
      'attendance',
      where: 'workerId = ? AND date >= ? AND date <= ?',
      whereArgs: [workerId, startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'date ASC',
    );
    return result.map((json) => Attendance.fromMap(json)).toList();
  }

  Future<Attendance?> getAttendanceForDate(int workerId, DateTime date) async {
    final db = await instance.database;
    final result = await db.query(
      'attendance',
      where: 'workerId = ? AND date = ?',
      whereArgs: [workerId, date.toIso8601String()],
    );
    return result.isNotEmpty ? Attendance.fromMap(result.first) : null;
  }

  Future<int> updateAttendance(Attendance attendance) async {
    final db = await instance.database;
    return await db.update(
      'attendance',
      attendance.toMap(),
      where: 'id = ?',
      whereArgs: [attendance.id],
    );
  }

  Future<int> deleteAttendance(int id) async {
    final db = await instance.database;
    return await db.delete(
      'attendance',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Bulk attendance operations
  Future<void> insertBulkAttendance(List<Attendance> attendanceList) async {
    final db = await instance.database;
    final batch = db.batch();
    
    for (final attendance in attendanceList) {
      batch.insert(
        'attendance',
        attendance.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
  }

  // Salary CRUD operations
  Future<int> insertSalary(Salary salary) async {
    final db = await instance.database;
    return await db.insert('salaries', salary.toMap());
  }

  Future<List<Salary>> getWorkerSalaries(int workerId) async {
    final db = await instance.database;
    final result = await db.query(
      'salaries',
      where: 'workerId = ?',
      whereArgs: [workerId],
      orderBy: 'year DESC, month DESC',
    );
    return result.map((json) => Salary.fromMap(json)).toList();
  }

  Future<Salary?> getSalaryForMonth(int workerId, int year, int month) async {
    final db = await instance.database;
    final result = await db.query(
      'salaries',
      where: 'workerId = ? AND year = ? AND month = ?',
      whereArgs: [workerId, year, month],
    );
    return result.isNotEmpty ? Salary.fromMap(result.first) : null;
  }

  Future<int> updateSalary(Salary salary) async {
    final db = await instance.database;
    return await db.update(
      'salaries',
      salary.toMap(),
      where: 'id = ?',
      whereArgs: [salary.id],
    );
  }

  // Analytics queries
  Future<Map<String, dynamic>> getAttendanceSummaryForDateRange(DateTime startDate, DateTime endDate) async {
    final db = await instance.database;

    final result = await db.rawQuery('''
      SELECT
        w.id,
        w.name,
        w.dailyWage,
        w.overtimeRate,
        COUNT(CASE WHEN a.isPresent = 1 AND a.isHalfDay = 0 THEN 1 END) as fullDays,
        COUNT(CASE WHEN a.isPresent = 1 AND a.isHalfDay = 1 THEN 1 END) as halfDays,
        COUNT(CASE WHEN a.isPresent = 0 THEN 1 END) as absentDays,
        COALESCE(SUM(a.overtimeHours), 0) as totalOvertimeHours
      FROM workers w
      LEFT JOIN attendance a ON w.id = a.workerId
        AND a.date >= ? AND a.date <= ?
      WHERE w.isActive = 1
      GROUP BY w.id, w.name, w.dailyWage, w.overtimeRate
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    // Calculate effective present days (full days)
    for (var row in result) {
      double fullDays = (row['fullDays'] as int).toDouble();
      double halfDays = (row['halfDays'] as int).toDouble();
      row['presentDays'] = fullDays + (halfDays * 0.5);
    }

    return {
      'workers': result,
      'totalWorkers': result.length,
    };
  }

  Future<Map<String, dynamic>> getWorkerAttendanceSummary(int workerId, DateTime startDate, DateTime endDate) async {
    final db = await instance.database;

    final result = await db.rawQuery('''
      SELECT
        w.id,
        w.name,
        w.dailyWage,
        w.overtimeRate,
        COUNT(CASE WHEN a.isPresent = 1 AND a.isHalfDay = 0 THEN 1 END) as fullDays,
        COUNT(CASE WHEN a.isPresent = 1 AND a.isHalfDay = 1 THEN 1 END) as halfDays,
        COUNT(CASE WHEN a.isPresent = 0 THEN 1 END) as absentDays,
        COALESCE(SUM(a.overtimeHours), 0) as totalOvertimeHours
      FROM workers w
      LEFT JOIN attendance a ON w.id = a.workerId
        AND a.date >= ? AND a.date <= ?
      WHERE w.id = ? AND w.isActive = 1
      GROUP BY w.id, w.name, w.dailyWage, w.overtimeRate
    ''', [startDate.toIso8601String(), endDate.toIso8601String(), workerId]);

    debugPrint('getWorkerAttendanceSummary result for worker $workerId: $result');

    if (result.isEmpty) {
      return {
        'id': workerId,
        'name': '',
        'dailyWage': 0.0,
        'overtimeRate': 0.0,
        'fullDays': 0,
        'halfDays': 0,
        'absentDays': 0,
        'totalOvertimeHours': 0.0,
        'presentDays': 0.0,
      };
    }

    // Calculate effective present days (full days)
    final row = result.first;
    double fullDays = (row['fullDays'] as int).toDouble();
    double halfDays = (row['halfDays'] as int).toDouble();
    double presentDays = fullDays + (halfDays * 0.5);

    // Create a new map to avoid read-only issues
    return {
      'id': row['id'],
      'name': row['name'],
      'dailyWage': row['dailyWage'],
      'overtimeRate': row['overtimeRate'],
      'fullDays': row['fullDays'],
      'halfDays': row['halfDays'],
      'absentDays': row['absentDays'],
      'totalOvertimeHours': row['totalOvertimeHours'],
      'presentDays': presentDays,
    };
  }

  Future<List<Map<String, dynamic>>> getSalaryReport(int year, int month) async {
    final db = await instance.database;
    
    final result = await db.rawQuery('''
      SELECT 
        w.id,
        w.name,
        w.designation,
        w.dailyWage,
        w.overtimeRate,
        s.baseSalary,
        s.overtimeAmount,
        s.workEntryAmount,
        s.advanceDeductions,
        s.totalSalary,
        s.paidAmount,
        s.remainingAmount,
        s.paymentDate
      FROM workers w
      LEFT JOIN salaries s ON w.id = s.workerId 
        AND s.year = ? AND s.month = ?
      WHERE w.isActive = 1
      ORDER BY w.name ASC
    ''', [year, month]);
    
    return result;
  }

  Future<Map<String, dynamic>> getSalaryReportForDateRange(DateTime startDate, DateTime endDate) async {
    final db = await instance.database;

    final result = await db.rawQuery('''
      SELECT
        w.id,
        w.name,
        w.designation,
        w.dailyWage,
        w.overtimeRate,
        SUM(s.baseSalary) as baseSalary,
        SUM(s.overtimeAmount) as overtimeAmount,
        SUM(s.totalSalary) as totalSalary,
        SUM(s.paidAmount) as totalPaid,
        SUM(s.remainingAmount) as totalPending,
        MAX(s.paymentDate) as lastPaymentDate
      FROM workers w
      LEFT JOIN salaries s ON w.id = s.workerId
        AND s.createdAt >= ? AND s.createdAt <= ?
      WHERE w.isActive = 1
      GROUP BY w.id, w.name, w.designation, w.dailyWage, w.overtimeRate
      ORDER BY w.name ASC
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    double totalSalary = 0;
    double totalPaid = 0;
    double totalPending = 0;
    List<Map<String, dynamic>> workerSalaries = [];

    for (var row in result) {
      totalSalary += (row['totalSalary'] as num?)?.toDouble() ?? 0;
      totalPaid += (row['totalPaid'] as num?)?.toDouble() ?? 0;
      totalPending += (row['totalPending'] as num?)?.toDouble() ?? 0;
      workerSalaries.add(row);
    }

    return {
      'totalSalary': totalSalary,
      'totalPaid': totalPaid,
      'totalPending': totalPending,
      'workerSalaries': workerSalaries,
    };
  }

  Future<Map<String, dynamic>> getWorkerPerformanceReport(DateTime startDate, DateTime endDate) async {
    final db = await instance.database;

    final result = await db.rawQuery('''
      SELECT
        w.id,
        w.name,
        w.designation,
        w.dailyWage,
        w.isActive,
        COUNT(a.id) as presentDays,
        COALESCE(SUM(s.totalSalary), 0) as totalSalary,
        COALESCE(SUM(ad.amount), 0) as totalAdvances,
        (COALESCE(SUM(s.totalSalary), 0) - COALESCE(SUM(ad.amount), 0)) as pendingSalary
      FROM workers w
      LEFT JOIN attendance a ON w.id = a.workerId
        AND a.date >= ? AND a.date <= ? AND a.isPresent = 1
      LEFT JOIN salaries s ON w.id = s.workerId
        AND s.createdAt >= ? AND s.createdAt <= ?
      LEFT JOIN advances ad ON w.id = ad.workerId
        AND ad.date >= ? AND ad.date <= ?
      GROUP BY w.id, w.name, w.designation, w.dailyWage, w.isActive
      ORDER BY w.name ASC
    ''', [
      startDate.toIso8601String(),
      endDate.toIso8601String(),
      startDate.toIso8601String(),
      endDate.toIso8601String(),
      startDate.toIso8601String(),
      endDate.toIso8601String(),
    ]);

    int totalWorkers = 0;
    int activeWorkers = 0;
    double totalAdvances = 0;
    List<Map<String, dynamic>> workers = [];

    for (var row in result) {
      totalWorkers++;
      if (row['isActive'] == 1) activeWorkers++;
      totalAdvances += (row['totalAdvances'] as num?)?.toDouble() ?? 0;
      workers.add(row);
    }

    return {
      'totalWorkers': totalWorkers,
      'activeWorkers': activeWorkers,
      'totalAdvances': totalAdvances,
      'workers': workers,
    };
  }

  // Work Entry CRUD operations
  Future<int> insertWorkEntry(WorkEntry workEntry) async {
    final db = await instance.database;
    return await db.insert('work_entries', workEntry.toMap());
  }

  Future<List<WorkEntry>> getWorkEntries(int workerId, DateTime startDate, DateTime endDate) async {
    final db = await instance.database;
    final result = await db.query(
      'work_entries',
      where: 'workerId = ? AND date >= ? AND date <= ?',
      whereArgs: [workerId, startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'date ASC',
    );
    return result.map((json) => WorkEntry.fromMap(json)).toList();
  }

  Future<WorkEntry?> getWorkEntry(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'work_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? WorkEntry.fromMap(result.first) : null;
  }

  Future<int> updateWorkEntry(WorkEntry workEntry) async {
    final db = await instance.database;
    return await db.update(
      'work_entries',
      workEntry.toMap(),
      where: 'id = ?',
      whereArgs: [workEntry.id],
    );
  }

  Future<int> deleteWorkEntry(int id) async {
    final db = await instance.database;
    return await db.delete(
      'work_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Advance CRUD operations
  Future<int> insertAdvance(Advance advance) async {
    final db = await instance.database;
    return await db.insert('advances', advance.toMap());
  }

  Future<List<Advance>> getAdvances(int workerId, DateTime startDate, DateTime endDate) async {
    final db = await instance.database;
    final result = await db.query(
      'advances',
      where: 'workerId = ? AND date >= ? AND date <= ?',
      whereArgs: [workerId, startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'date ASC',
    );
    return result.map((json) => Advance.fromMap(json)).toList();
  }

  Future<Advance?> getAdvance(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'advances',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? Advance.fromMap(result.first) : null;
  }

  Future<int> updateAdvance(Advance advance) async {
    final db = await instance.database;
    return await db.update(
      'advances',
      advance.toMap(),
      where: 'id = ?',
      whereArgs: [advance.id],
    );
  }

  Future<int> deleteAdvance(int id) async {
    final db = await instance.database;
    return await db.delete(
      'advances',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalAdvanceDeductions(int workerId, DateTime startDate, DateTime endDate) async {
    final db = await instance.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as totalDeductions
      FROM advances
      WHERE workerId = ? AND date >= ? AND date <= ?
    ''', [workerId, startDate.toIso8601String(), endDate.toIso8601String()]);

    final totalDeductions = result.first['totalDeductions'];
    if (totalDeductions is int) {
      return totalDeductions.toDouble();
    } else if (totalDeductions is double) {
      return totalDeductions;
    } else {
      return 0.0;
    }
  }

  Future<double> getTotalWorkEntryAmount(int workerId, DateTime startDate, DateTime endDate) async {
    final db = await instance.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(totalAmount), 0) as totalWorkAmount
      FROM work_entries
      WHERE workerId = ? AND date >= ? AND date <= ?
    ''', [workerId, startDate.toIso8601String(), endDate.toIso8601String()]);

    final totalWorkAmount = result.first['totalWorkAmount'];
    if (totalWorkAmount is int) {
      return totalWorkAmount.toDouble();
    } else if (totalWorkAmount is double) {
      return totalWorkAmount;
    } else {
      return 0.0;
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
