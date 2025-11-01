/// Model class representing an advance or withdrawal payment made to a worker.
/// This class is used to track financial transactions given to workers in advance
/// or deductions/withdrawals from their salary.
class Advance {
  /// Unique identifier for the advance record. Null for new records.
  final int? id;
  /// ID of the worker this advance belongs to.
  final int workerId;
  /// Date when the advance was given or withdrawal made.
  final DateTime date;
  /// Amount of money involved in the advance/withdrawal.
  final double amount;
  /// Type of transaction: 'advance' for money given, 'withdrawal' for deductions.
  final String type; // 'advance' or 'withdrawal'
  /// Optional notes about the advance.
  final String? notes;
  /// Timestamp when this record was created.
  final DateTime createdAt;

  /// Constructor for creating an Advance instance.
  /// [createdAt] defaults to the current time if not provided.
  Advance({
    this.id,
    required this.workerId,
    required this.date,
    required this.amount,
    required this.type,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Converts the Advance object to a Map for database storage.
  /// Dates are serialized to ISO 8601 strings for storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workerId': workerId,
      'date': date.toIso8601String(),
      'amount': amount,
      'type': type,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Factory constructor to create an Advance from a Map (typically from database query results).
  /// Parses ISO 8601 date strings back to DateTime objects.
  factory Advance.fromMap(Map<String, dynamic> map) {
    return Advance(
      id: map['id'],
      workerId: map['workerId'],
      date: DateTime.parse(map['date']),
      amount: map['amount'],
      type: map['type'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  /// Creates a copy of this Advance instance with the specified fields optionally updated.
  /// This is useful for immutable updates in state management.
  Advance copyWith({
    int? id,
    int? workerId,
    DateTime? date,
    double? amount,
    String? type,
    String? notes,
    DateTime? createdAt,
  }) {
    return Advance(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Returns true if this transaction is an advance payment.
  bool get isAdvance => type == 'advance';
  /// Returns true if this transaction is a withdrawal/deduction.
  bool get isWithdrawal => type == 'withdrawal';
}
