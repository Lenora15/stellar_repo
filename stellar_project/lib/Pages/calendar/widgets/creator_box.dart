import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/event_model.dart';
import '../models/reminder_model.dart';
import '../../../notification_service.dart';

//had claude remove all class things, migrating class creation to a different location.
class CreatorBox extends StatefulWidget {
  final DatabaseService dbService;
  final DateTime initialDate;
  final String initialMode;
    final EventModel? existingEvent;
  final ReminderModel? existingReminder;

  const CreatorBox({
    super.key,
    required this.dbService,
    required this.initialDate,
    this.initialMode = 'Event',
    this.existingEvent,
    this.existingReminder
  });

  @override
  State<CreatorBox> createState() => _CreatorBoxState();
}

class _CreatorBoxState extends State<CreatorBox> {
  late String _currentMode;

  bool _isAllDay = false;
  int _selectedColor = 0xFF8AB4F8;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final Color _standardDark = const Color(0xFF2D2E33);

  late DateTime _startDate;
  late DateTime _endDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  List<int> _selectedReminderMinutes = [10];
  String _reminderFrequency = 'none';

   @override
  void initState() {
    super.initState();
    _currentMode = widget.existingReminder != null ? 'Reminder' : widget.initialMode;
    _startDate = widget.initialDate;
    _endDate = widget.initialDate.add(const Duration(hours: 1));
 
    if (widget.existingEvent != null) {
      final e = widget.existingEvent!;
      _titleController.text = e.title;
      _noteController.text = e.note;
      _isAllDay = e.isAllDay;
      _selectedColor = e.colorValue;
      _startDate = e.startDateTime;
      _endDate = e.endDateTime;
      _startTime = TimeOfDay(hour: e.startDateTime.hour, minute: e.startDateTime.minute);
      _endTime = TimeOfDay(hour: e.endDateTime.hour, minute: e.endDateTime.minute);
      _selectedReminderMinutes = List.from(e.reminderMinutes);
    } else if (widget.existingReminder != null) {
      final r = widget.existingReminder!;
      _titleController.text = r.title;
      _startDate = r.dateTime;
      _startTime = TimeOfDay(hour: r.dateTime.hour, minute: r.dateTime.minute);
      _reminderFrequency = r.recurrence?.frequency ?? 'none';
    }
  }

    Future<void> _selectDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _standardDark,
              onPrimary: Colors.white,
              onSurface: _standardDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
        } else {
          _endDate = picked;
        }
      });
    }
  }

   
  void _handleSave() async {
    String title = _titleController.text.trim();
    if (title.isEmpty) {
      title = "Untitled $_currentMode";
    }
 
    DateTime start = _isAllDay
        ? DateTime(_startDate.year, _startDate.month, _startDate.day)
        : DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute);
 
    DateTime end = _isAllDay
        ? DateTime(_endDate.year, _endDate.month, _endDate.day)
        : DateTime(_endDate.year, _endDate.month, _endDate.day, _endTime.hour, _endTime.minute);
 
    if (end.isBefore(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time cannot be before start time.')),
      );
      return;
    }
 
    try {
      if (_currentMode == 'Event') {
        final newEvent = EventModel(
          id: widget.existingEvent?.id ?? '',
          title: title,
          isAllDay: _isAllDay,
          startDateTime: start,
          endDateTime: end,
          note: _noteController.text.trim(),
          reminderMinutes: _selectedReminderMinutes,
          colorValue: _selectedColor,
          isRecurring: widget.existingEvent?.isRecurring ?? false,
          frequency: widget.existingEvent?.frequency ?? 'none',
          interval: widget.existingEvent?.interval ?? 1,
          repeatDays: widget.existingEvent?.repeatDays ?? [],
          endDate: widget.existingEvent?.endDate,
          skippedDates: widget.existingEvent?.skippedDates ?? [],
        );
        if (widget.existingEvent != null) {
          await widget.dbService.updateEvent(newEvent);
          final notifId = NotificationService.idFor(widget.existingEvent!.id);
          await NotificationService.cancel(notifId);
          if (_selectedReminderMinutes.isNotEmpty) {
            final notifTime = start.subtract(Duration(minutes: _selectedReminderMinutes.first));
            await NotificationService.schedule(
              id: notifId,
              title: title,
              body: _selectedReminderMinutes.first == 0
                  ? 'Starting now'
                  : 'Starting in ${_selectedReminderMinutes.first}m',
              at: notifTime,
            );
          }
        } else {
          final docRef = await widget.dbService.addEvent(newEvent);
          if (_selectedReminderMinutes.isNotEmpty) {
            final notifTime = start.subtract(Duration(minutes: _selectedReminderMinutes.first));
            await NotificationService.schedule(
              id: NotificationService.idFor(docRef.id),
              title: title,
              body: _selectedReminderMinutes.first == 0
                  ? 'Starting now'
                  : 'Starting in ${_selectedReminderMinutes.first}m',
              at: notifTime,
            );
          }
        }
      } else {
        final newReminder = ReminderModel(
          id: widget.existingReminder?.id ?? '',
          title: title,
          dateTime: start,
          isCompleted: widget.existingReminder?.isCompleted ?? false,
          recurrence: _reminderFrequency != 'none'
              ? RecurrenceSettings(frequency: _reminderFrequency)
              : null,
        );
        if (widget.existingReminder != null) {
          final notifId = NotificationService.idFor(widget.existingReminder!.id);
          await NotificationService.cancel(notifId);
          await widget.dbService.updateReminder(newReminder);
          await NotificationService.schedule(
            id: notifId,
            title: title,
            body: 'Your reminder is due',
            at: start,
          );
        } else {
          final docRef = await widget.dbService.addReminder(newReminder);
          await NotificationService.schedule(
            id: NotificationService.idFor(docRef.id),
            title: title,
            body: 'Your reminder is due',
            at: start,
          );
        }
      }
 
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text('$_currentMode saved!'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print("Error saving: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save $_currentMode. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                ),
              ),
            ),
          ),
        ),

        Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 5,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: _buildStellarToggle(),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  TextField(
                    controller: _titleController,
                    style: TextStyle(
                      color: _standardDark,
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: "Title",
                      hintStyle: TextStyle(color: _standardDark.withValues(alpha: 0.2)),
                      border: InputBorder.none,
                    ),
                  ),

                  Divider(color: _standardDark.withValues(alpha: 0.1), height: 32),

                  if (_currentMode == 'Event') ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "All day",
                        style: TextStyle(
                          color: _standardDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      value: _isAllDay,
                      activeColor: Colors.deepPurpleAccent,
                      onChanged: (val) => setState(() => _isAllDay = val),
                    ),
                    _buildDateTimeRow(true),
                    const SizedBox(height: 16),
                    _buildDateTimeRow(false),
                    const SizedBox(height: 30),
                    Text(
                      "Color",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildColorRow(),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Reminder",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.notifications, color: Colors.grey),
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            value: _selectedReminderMinutes.isNotEmpty
                                ? _selectedReminderMinutes.first
                                : null,
                            items: const [
                              DropdownMenuItem(value: 0, child: Text('At time of event', style: TextStyle(color: Colors.black))),
                              DropdownMenuItem(value: 5, child: Text('5 minutes before', style: TextStyle(color: Colors.black))),
                              DropdownMenuItem(value: 10, child: Text('10 minutes before', style: TextStyle(color: Colors.black))),
                              DropdownMenuItem(value: 30, child: Text('30 minutes before', style: TextStyle(color: Colors.black))),
                              DropdownMenuItem(value: 60, child: Text('1 hour before', style: TextStyle(color: Colors.black))),
                              DropdownMenuItem(value: 1440, child: Text('1 day before', style: TextStyle(color: Colors.black))),
                            ],
                            onChanged: (int? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedReminderMinutes = [newValue];
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: TextField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.notes, color: Colors.black54),
                          hintText: 'Add note...',
                          hintStyle: TextStyle(color: _standardDark.withValues(alpha: 0.4)),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (_currentMode == 'Reminder') ...[
                    _buildDateTimeRow(true),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Repeat",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.repeat, color: Colors.grey),
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            value: _reminderFrequency,
                            items: const [
                              DropdownMenuItem(value: 'none', child: Text('Never', style: TextStyle(color: Colors.black))),
                              DropdownMenuItem(value: 'daily', child: Text('Daily', style: TextStyle(color: Colors.black))),
                              DropdownMenuItem(value: 'weekly', child: Text('Weekly', style: TextStyle(color: Colors.black))),
                              DropdownMenuItem(value: 'monthly', child: Text('Monthly', style: TextStyle(color: Colors.black))),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _reminderFrequency = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            _buildBottomButtons(),
          ],
        ),
      ],
    );
  }

  Widget _buildStellarToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn("Event", _currentMode == 'Event'),
          _toggleBtn("Reminder", _currentMode == 'Reminder'),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active) {
    return GestureDetector(
      onTap: () => setState(() => _currentMode = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? _standardDark : _standardDark.withValues(alpha: 0.4),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeRow(bool isStart) {
    DateTime date = isStart ? _startDate : _endDate;
    TimeOfDay time = isStart ? _startTime : _endTime;

    return Row(
      children: [
        Icon(Icons.calendar_today, color: _standardDark.withValues(alpha: 0.6), size: 20),
        const SizedBox(width: 15),

        GestureDetector(
          onTap: () => _selectDate(isStart),
          child: Text(
            DateFormat('EEE, MMM d').format(date),
            style: TextStyle(
              color: _standardDark,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const Spacer(),

        if (!_isAllDay)
          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: time);
              if (picked != null) {
                setState(() {
                  if (isStart) _startTime = picked;
                  else _endTime = picked;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                time.format(context),
                style: TextStyle(
                  color: _standardDark,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildColorRow() {
    return Row(
      children: [0xFF8AB4F8, 0xFFC58AF9, 0xFFFDE293, 0xFF81C995, 0xFFF28B82].map((c) {
        bool sel = _selectedColor == c;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 18),
            width: sel ? 28 : 36,
            height: sel ? 28 : 36,
            decoration: BoxDecoration(
              color: Color(c),
              shape: BoxShape.circle,
              border: sel
                  ? Border.all(color: _standardDark.withValues(alpha: 0.3), width: 3)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: _standardDark.withValues(alpha: 0.6),
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: GestureDetector(
              onTap: _handleSave,
              child: Container(
                height: 55,
                decoration: BoxDecoration(
                  color: _standardDark,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Center(
                  child: Text(
                    "Save",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
