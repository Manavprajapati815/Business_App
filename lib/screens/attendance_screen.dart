import 'package:flutter/material.dart';
import '../models/worker.dart';
import '../models/attendance.dart';
import '../providers/worker_provider.dart';
import '../providers/attendance_provider.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  bool _isLoading = true;
  List<Attendance> _attendanceRecords = [];
  List<Worker> _workers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final workerProvider = WorkerProvider();
    
    await workerProvider.loadWorkers();
    _workers = workerProvider.workers;
    
    // Load attendance for the selected day
    await _loadAttendanceForDate(_selectedDay);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAttendanceForDate(DateTime date) async {
    final attendanceProvider = AttendanceProvider();
    
    // Get all attendance records for the selected day
    List<Attendance> allAttendance = [];
    
    for (var worker in _workers) {
      final attendance = await attendanceProvider.getAttendanceForDate(worker.id!, date);
      if (attendance != null) {
        allAttendance.add(attendance);
      }
    }
    
    if (mounted) {
      setState(() {
        _attendanceRecords = allAttendance;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _showDateRangeDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildAttendanceContent(isSmallScreen),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMarkAttendanceDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAttendanceContent(bool isSmallScreen) {
    return Column(
      children: [
        _buildCalendarHeader(isSmallScreen),
        Expanded(
          child: _buildAttendanceList(),
        ),
      ],
    );
  }

  Widget _buildCalendarHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                  });
                },
              ),
              Text(
                '${_getMonthName(_focusedDay.month)} ${_focusedDay.year}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18.0 : 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                  });
                },
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 6.0 : 8.0),
          _buildCalendarGrid(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(bool isSmallScreen) {
    final daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final startingWeekday = firstDayOfMonth.weekday;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('Sun', style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 12.0 : 14.0,
            )),
            Text('Mon', style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 12.0 : 14.0,
            )),
            Text('Tue', style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 12.0 : 14.0,
            )),
            Text('Wed', style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 12.0 : 14.0,
            )),
            Text('Thu', style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 12.0 : 14.0,
            )),
            Text('Fri', style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 12.0 : 14.0,
            )),
            Text('Sat', style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 12.0 : 14.0,
            )),
          ],
        ),
        SizedBox(height: isSmallScreen ? 6.0 : 8.0),
        ..._buildCalendarRows(daysInMonth, startingWeekday, isSmallScreen),
      ],
    );
  }

  List<Widget> _buildCalendarRows(int daysInMonth, int startingWeekday, bool isSmallScreen) {
    List<Widget> rows = [];
    List<Widget> currentRow = [];
    
    // Add empty cells for days before the first day of the month
    for (int i = 0; i < startingWeekday % 7; i++) {
      currentRow.add(const Expanded(child: SizedBox()));
    }

    // Add days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedDay.year, _focusedDay.month, day);
      currentRow.add(
        Expanded(
          child: GestureDetector(
            onTap: () async {
              setState(() {
                _selectedDay = date;
              });
              await _loadAttendanceForDate(date);
            },
            child: Container(
              margin: EdgeInsets.all(isSmallScreen ? 1.0 : 2.0),
              padding: EdgeInsets.all(isSmallScreen ? 4.0 : 8.0),
              decoration: BoxDecoration(
                color: _getDayColor(date),
                borderRadius: BorderRadius.circular(4),
                border: isSameDay(date, _selectedDay)
                    ? Border.all(color: Colors.blue, width: 2)
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    day.toString(),
                    style: TextStyle(
                      color: isSameDay(date, _selectedDay) ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 12.0 : 14.0,
                    ),
                  ),
                  _buildDayStatusIndicator(date),
                ],
              ),
            ),
          ),
        ),
      );

      if (currentRow.length == 7 || day == daysInMonth) {
        rows.add(Row(children: currentRow));
        currentRow = [];
      }
    }

    return rows;
  }

  Color? _getDayColor(DateTime date) {
    if (isSameDay(date, _selectedDay)) {
      return Colors.blue;
    }
    return null;
  }

  Widget _buildDayStatusIndicator(DateTime date) {
    return FutureBuilder<List<Attendance>>(
      future: _getAttendanceForDate(date),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(height: 4);
        }

        final attendance = snapshot.data!;
        int presentCount = 0;
        int absentCount = 0;
        
        for (var att in attendance) {
          if (att.isPresent) {
            presentCount++;
          } else {
            absentCount++;
          }
        }
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (presentCount > 0)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            if (absentCount > 0)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        );
      },
    );
  }

  Future<List<Attendance>> _getAttendanceForDate(DateTime date) async {
    final attendanceProvider = AttendanceProvider();
    List<Attendance> attendanceForDate = [];
    
    for (var worker in _workers) {
      final attendance = await attendanceProvider.getAttendanceForDate(worker.id!, date);
      if (attendance != null) {
        attendanceForDate.add(attendance);
      }
    }
    
    return attendanceForDate;
  }

  Widget _buildAttendanceList() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    if (_attendanceRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: isSmallScreen ? 48.0 : 64.0, color: Colors.grey),
            SizedBox(height: isSmallScreen ? 12.0 : 16.0),
            Text(
              'No attendance marked for ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
              style: TextStyle(
                color: Colors.grey,
                fontSize: isSmallScreen ? 14.0 : 16.0,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _attendanceRecords.length,
      itemBuilder: (context, index) {
        final attendance = _attendanceRecords[index];
        final worker = _workers.firstWhere(
          (w) => w.id == attendance.workerId,
          orElse: () => Worker(
            name: 'Unknown Worker',
            phone: '',
            address: '',
            designation: '',
            dailyWage: 0,
            overtimeRate: 0,
            joinDate: DateTime.now(),
          ),
        );

        return _buildAttendanceCard(attendance, worker, isSmallScreen);
      },
    );
  }

  Widget _buildAttendanceCard(Attendance attendance, Worker worker, bool isSmallScreen) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8.0 : 16.0, 
        vertical: 4.0
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: attendance.isPresent ? Colors.green : Colors.red,
          child: Text(
            worker.name[0].toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 12.0 : 14.0,
            ),
          ),
        ),
        title: Text(
          worker.name,
          style: TextStyle(
            fontSize: isSmallScreen ? 14.0 : 16.0,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              attendance.isPresent ? 'Present' : 'Absent',
              style: TextStyle(
                fontSize: isSmallScreen ? 12.0 : 14.0,
              ),
            ),
            if (attendance.overtimeHours != null && attendance.overtimeHours! > 0)
              Text(
                'Overtime: ${attendance.overtimeHours} hrs',
                style: TextStyle(
                  fontSize: isSmallScreen ? 11.0 : 13.0,
                ),
              ),
            if (attendance.notes != null && attendance.notes!.isNotEmpty)
              Text(
                'Notes: ${attendance.notes}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 11.0 : 13.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.edit, 
            color: Colors.blue,
            size: isSmallScreen ? 18.0 : 24.0,
          ),
          onPressed: () => _showEditAttendanceDialog(attendance, worker),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  void _showMarkAttendanceDialog() {
    final activeWorkers = _workers.where((w) => w.isActive).toList();

    if (activeWorkers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active workers found')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Mark Attendance - ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: activeWorkers.length,
              itemBuilder: (context, index) {
                final worker = activeWorkers[index];
                return _buildWorkerAttendanceItem(worker);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWorkerAttendanceItem(Worker worker) {
    final attendanceProvider = AttendanceProvider();

    return StatefulBuilder(
      builder: (context, setState) {
        return FutureBuilder<Attendance?>(
          future: attendanceProvider.getAttendanceForDate(worker.id!, _selectedDay),
          builder: (context, snapshot) {
            final existingAttendance = snapshot.data;
            bool isPresent = existingAttendance?.isPresent ?? true;
            double overtimeHours = existingAttendance?.overtimeHours ?? 0;
            final notesController = TextEditingController(text: existingAttendance?.notes ?? '');

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        const Text('Status:'),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Present'),
                          selected: isPresent,
                          onSelected: (selected) {
                            setState(() {
                              isPresent = selected;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Absent'),
                          selected: !isPresent,
                          onSelected: (selected) {
                            setState(() {
                              isPresent = !selected;
                            });
                          },
                        ),
                      ],
                    ),
                    if (isPresent) ...[
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Overtime Hours',
                          suffixText: 'hours',
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(text: overtimeHours.toString()),
                        onChanged: (value) {
                          overtimeHours = double.tryParse(value) ?? 0;
                        },
                      ),
                    ],
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                      ),
                      controller: notesController,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final attendance = Attendance(
                          id: existingAttendance?.id,
                          workerId: worker.id!,
                          date: _selectedDay,
                          isPresent: isPresent,
                          overtimeHours: isPresent ? overtimeHours : 0,
                          notes: notesController.text,
                        );

                        try {
                          await attendanceProvider.markAttendance(attendance);
                          await _loadAttendanceForDate(_selectedDay);
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      child: Text(existingAttendance != null ? 'Update' : 'Save'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditAttendanceDialog(Attendance attendance, Worker worker) {
    final attendanceProvider = AttendanceProvider();

    bool isPresent = attendance.isPresent;
    double overtimeHours = attendance.overtimeHours ?? 0;
    final notesController = TextEditingController(text: attendance.notes ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Attendance - ${worker.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text('Status:'),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Present'),
                          selected: isPresent,
                          onSelected: (selected) {
                            setState(() {
                              isPresent = selected;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Absent'),
                          selected: !isPresent,
                          onSelected: (selected) {
                            setState(() {
                              isPresent = !selected;
                            });
                          },
                        ),
                      ],
                    ),
                    if (isPresent) ...[
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Overtime Hours',
                          suffixText: 'hours',
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(text: overtimeHours.toString()),
                        onChanged: (value) {
                          overtimeHours = double.tryParse(value) ?? 0;
                        },
                      ),
                    ],
                    TextField(
                      decoration: const InputDecoration(labelText: 'Notes'),
                      controller: notesController,
                      maxLines: 3,
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
                  onPressed: () async {
                    final updatedAttendance = Attendance(
                      id: attendance.id,
                      workerId: attendance.workerId,
                      date: attendance.date,
                      isPresent: isPresent,
                      overtimeHours: isPresent ? overtimeHours : 0,
                      notes: notesController.text,
                    );

                    try {
                      await attendanceProvider.markAttendance(updatedAttendance);
                      await _loadAttendanceForDate(_selectedDay);
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDateRangeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Date Range'),
          content: const Text('Feature coming soon: Generate attendance reports for date ranges'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
