/// Model class representing a work entry for piece-work or task-based payments.
/// This tracks specific work done by a worker, including quantity and rate for calculation.
class WorkEntry {
  /// Unique identifier for the work entry record. Null for new records.
  final int? id;
  /// ID of the worker this work entry belongs to.
  final int workerId;
  /// Date when the work was performed.
  final DateTime date;
  /// Type or description of the work performed (e.g., 'Diamond Cutting').
  final String workType;
  /// Quantity of work units completed.
  final double quantity;
  /// Rate per unit of work.
  final double ratePerUnit;
  /// Total amount calculated as quantity * ratePerUnit.
  final double totalAmount;
  /// Optional notes about the work entry.
  final String? notes;
  /// Timestamp when this record was created.
  final DateTime createdAt;

  /// Constructor for creating a WorkEntry instance.
  /// [createdAt] defaults to the current time if not provided.
  WorkEntry({
    this.id,
    required this.workerId,
    required this.date,
    required this.workType,
    required this.quantity,
    required this.ratePerUnit,
    required this.totalAmount,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Converts the WorkEntry object to a Map for database storage.
  /// Dates are serialized to ISO 8601 strings for storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workerId': workerId,
      'date': date.toIso8601String(),
      'workType': workType,
      'quantity': quantity,
      'ratePerUnit': ratePerUnit,
      'totalAmount': totalAmount,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Factory constructor to create a WorkEntry from a Map (typically from database query results).
  /// Parses ISO 8601 date strings back to DateTime objects.
  factory WorkEntry.fromMap(Map<String, dynamic> map) {
    return WorkEntry(
      id: map['id'],
      workerId: map['workerId'],
      date: DateTime.parse(map['date']),
      workType: map['workType'],
      quantity: map['quantity'],
      ratePerUnit: map['ratePerUnit'],
      totalAmount: map['totalAmount'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  /// Creates a copy of this WorkEntry instance with the specified fields optionally updated.
  /// This is useful for immutable updates in state management.
  WorkEntry copyWith({
    int? id,
    int? workerId,
    DateTime? date,
    String? workType,
    double? quantity,
    double? ratePerUnit,
    double? totalAmount,
    String? notes,
    DateTime? createdAt,
  }) {
    return WorkEntry(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      date: date ?? this.date,
      workType: workType ?? this.workType,
      quantity: quantity ?? this.quantity,
      ratePerUnit: ratePerUnit ?? this.ratePerUnit,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
