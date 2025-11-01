/// Model class representing a worker's attendance record for a specific date.
/// This tracks whether a worker was present, if it was a half day, overtime hours, etc.
class Attendance {
  /// Unique identifier for the attendance record. Null for new records.
  final int? id;
  /// ID of the worker this attendance belongs to.
  final int workerId;
  /// Date of the attendance record.
  final DateTime date;
  /// Whether the worker was present on this date.
  final bool isPresent;
  /// Whether the presence was for a half day (if present).
  final bool isHalfDay;
  /// Number of overtime hours worked on this date (if any).
  final double? overtimeHours;
  /// Optional notes about the attendance.
  final String? notes;

  /// Constructor for creating an Attendance instance.
  /// [isHalfDay] defaults to false.
  Attendance({
    this.id,
    required this.workerId,
    required this.date,
    required this.isPresent,
    this.isHalfDay = false,
    this.overtimeHours,
    this.notes,
  });

  /// Converts the Attendance object to a Map for database storage.
  /// Dates are serialized to ISO 8601 strings, booleans to integers.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workerId': workerId,
      'date': date.toIso8601String(),
      'isPresent': isPresent ? 1 : 0,
      'isHalfDay': isHalfDay ? 1 : 0,
      'overtimeHours': overtimeHours,
      'notes': notes,
    };
  }

  /// Factory constructor to create an Attendance from a Map (typically from database query results).
  /// Parses ISO 8601 date strings back to DateTime objects, integers back to booleans.
  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      workerId: map['workerId'],
      date: DateTime.parse(map['date']),
      isPresent: map['isPresent'] == 1,
      isHalfDay: map['isHalfDay'] == 1,
      overtimeHours: map['overtimeHours'],
      notes: map['notes'],
    );
  }

  /// Creates a copy of this Attendance instance with the specified fields optionally updated.
  /// This is useful for immutable updates in state management.
  Attendance copyWith({
    int? id,
    int? workerId,
    DateTime? date,
    bool? isPresent,
    bool? isHalfDay,
    double? overtimeHours,
    String? notes,
  }) {
    return Attendance(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      date: date ?? this.date,
      isPresent: isPresent ?? this.isPresent,
      isHalfDay: isHalfDay ?? this.isHalfDay,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      notes: notes ?? this.notes,
    );
  }

  /// Returns true if the worker was present for a full day.
  bool get isFullDay => isPresent && !isHalfDay;
  /// Returns true if the worker was absent.
  bool get isAbsent => !isPresent;
}
