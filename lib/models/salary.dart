/// Model class representing a salary record for a worker in a specific month.
/// Contains all salary components, payment status, and related information.
class Salary {
  /// Unique identifier for the salary record. Null for new records.
  final int? id;
  /// ID of the worker this salary belongs to.
  final int workerId;
  /// Year of the salary period.
  final int year;
  /// Month of the salary period (1-12).
  final int month;
  /// Base salary amount based on attendance.
  final double baseSalary;
  /// Amount earned from overtime hours.
  final double overtimeAmount;
  /// Amount from piece-work or additional work entries.
  final double workEntryAmount;
  /// Deductions from advances or withdrawals.
  final double advanceDeductions;
  /// Total calculated salary before payments.
  final double totalSalary;
  /// Amount already paid to the worker.
  final double paidAmount;
  /// Remaining amount to be paid.
  final double remainingAmount;
  /// Whether the salary has been fully paid.
  final bool isPaid;
  /// Date when the payment was made (if paid).
  final DateTime? paymentDate;
  /// Optional notes about the salary.
  final String? notes;
  /// Timestamp when this record was created.
  final DateTime createdAt;

  /// Constructor for creating a Salary instance.
  /// [workEntryAmount] and [advanceDeductions] default to 0, [isPaid] to false.
  /// [createdAt] defaults to current time if not provided.
  Salary({
    this.id,
    required this.workerId,
    required this.year,
    required this.month,
    required this.baseSalary,
    required this.overtimeAmount,
    this.workEntryAmount = 0,
    this.advanceDeductions = 0,
    required this.totalSalary,
    required this.paidAmount,
    required this.remainingAmount,
    this.isPaid = false,
    this.paymentDate,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Converts the Salary object to a Map for database storage.
  /// Dates are serialized to ISO 8601 strings, booleans to integers.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workerId': workerId,
      'year': year,
      'month': month,
      'baseSalary': baseSalary,
      'overtimeAmount': overtimeAmount,
      'workEntryAmount': workEntryAmount,
      'advanceDeductions': advanceDeductions,
      'totalSalary': totalSalary,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'isPaid': isPaid ? 1 : 0,
      'paymentDate': paymentDate?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Factory constructor to create a Salary from a Map (typically from database query results).
  /// Parses ISO 8601 date strings back to DateTime objects, integers back to booleans.
  factory Salary.fromMap(Map<String, dynamic> map) {
    return Salary(
      id: map['id'],
      workerId: map['workerId'],
      year: map['year'],
      month: map['month'],
      baseSalary: map['baseSalary'],
      overtimeAmount: map['overtimeAmount'],
      workEntryAmount: map['workEntryAmount'] ?? 0,
      advanceDeductions: map['advanceDeductions'] ?? 0,
      totalSalary: map['totalSalary'],
      paidAmount: map['paidAmount'],
      remainingAmount: map['remainingAmount'],
      isPaid: (map['isPaid'] ?? 0) == 1,
      paymentDate: map['paymentDate'] != null
          ? DateTime.parse(map['paymentDate'])
          : null,
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  /// Creates a copy of this Salary instance with the specified fields optionally updated.
  /// This is useful for immutable updates in state management.
  Salary copyWith({
    int? id,
    int? workerId,
    int? year,
    int? month,
    double? baseSalary,
    double? overtimeAmount,
    double? workEntryAmount,
    double? advanceDeductions,
    double? totalSalary,
    double? paidAmount,
    double? remainingAmount,
    bool? isPaid,
    DateTime? paymentDate,
    String? notes,
    DateTime? createdAt,
  }) {
    return Salary(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      year: year ?? this.year,
      month: month ?? this.month,
      baseSalary: baseSalary ?? this.baseSalary,
      overtimeAmount: overtimeAmount ?? this.overtimeAmount,
      workEntryAmount: workEntryAmount ?? this.workEntryAmount,
      advanceDeductions: advanceDeductions ?? this.advanceDeductions,
      totalSalary: totalSalary ?? this.totalSalary,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      isPaid: isPaid ?? this.isPaid,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }


}
