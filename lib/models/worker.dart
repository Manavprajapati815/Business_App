/// Model class representing a worker in the system.
/// This class holds all the information about a worker, including personal details,
/// wage information, and employment status.
class Worker {
  /// Unique identifier for the worker. Null for new workers.
  final int? id;
  /// Full name of the worker.
  final String name;
  /// Phone number of the worker.
  final String phone;
  /// Residential address of the worker.
  final String address;
  /// Job designation or role of the worker (e.g., 'Diamond Cutter').
  final String designation;
  /// Daily wage rate for the worker.
  final double dailyWage;
  /// Hourly rate for overtime work.
  final double overtimeRate;
  /// Date when the worker joined the company.
  final DateTime joinDate;
  /// Whether the worker is currently active/employed.
  final bool isActive;
  /// Optional additional notes about the worker.
  final String? notes;

  /// Constructor for creating a Worker instance.
  /// [isActive] defaults to true for new workers.
  Worker({
    this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.designation,
    required this.dailyWage,
    required this.overtimeRate,
    required this.joinDate,
    this.isActive = true,
    this.notes,
  });

  /// Converts the Worker object to a Map for database storage.
  /// Dates are serialized to ISO 8601 strings, booleans to integers.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'designation': designation,
      'dailyWage': dailyWage,
      'overtimeRate': overtimeRate,
      'joinDate': joinDate.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'notes': notes,
    };
  }

  /// Factory constructor to create a Worker from a Map (typically from database query results).
  /// Parses ISO 8601 date strings back to DateTime objects, integers back to booleans.
  factory Worker.fromMap(Map<String, dynamic> map) {
    return Worker(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      address: map['address'],
      designation: map['designation'],
      dailyWage: map['dailyWage'],
      overtimeRate: map['overtimeRate'],
      joinDate: DateTime.parse(map['joinDate']),
      isActive: map['isActive'] == 1,
      notes: map['notes'],
    );
  }

  /// Creates a copy of this Worker instance with the specified fields optionally updated.
  /// This is useful for immutable updates in state management.
  Worker copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    String? designation,
    double? dailyWage,
    double? overtimeRate,
    DateTime? joinDate,
    bool? isActive,
    String? notes,
  }) {
    return Worker(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      designation: designation ?? this.designation,
      dailyWage: dailyWage ?? this.dailyWage,
      overtimeRate: overtimeRate ?? this.overtimeRate,
      joinDate: joinDate ?? this.joinDate,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
    );
  }
}
