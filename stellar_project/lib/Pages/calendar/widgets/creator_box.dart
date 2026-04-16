import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/event_model.dart';
import '../models/reminder_model.dart';
import 'time_picker.dart';

class CreatorBox extends StatefulWidget {
  final DatabaseService dbService;
  final DateTime initialDate;

  const CreatorBox({super.key, required this.dbService, required this.initialDate});

  @override
  State<CreatorBox> createState() => _CreatorBoxState();
}

class _CreatorBoxState extends State<CreatorBox> {
  bool _isEventMode = true;
  bool _isAllDay = false;
  int _selectedColor = 0xFF8AB4F8;


  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController(); 
  final Color _standardDark = const Color(0xFF2D2E33);

  late DateTime _startDate;
  late DateTime _endDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDate;
    _endDate = widget.initialDate.add(const Duration(hours: 1));
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
    //handling title for the event. 
    String title = _titleController.text.trim();
    if (title.isEmpty) {
      title = _isEventMode ? "Untitled Event" : "Untitled Reminder";
    }

    DateTime start = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startDate.hour,
      _startDate.minute,
    );

    DateTime end = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _endDate.hour,
      _endDate.minute,
    );

    //have to do both reminder and event
    try{
      if (_isEventMode) {
        //handling event creation here
        final newEvent = EventModel(
          id: '',
          title: title,
          isAllDay: _isAllDay,
          startDateTime: start,
          endDateTime: end,
          note: _noteController.text.trim(),
          reminderMinutes: [],
          colorValue: _selectedColor,
          isRecurring: false,
        );
        await widget.dbService.addEvent(newEvent);
      } else {
        //handling reminder creation here
        final newReminder = ReminderModel(
          id: '',
          title: title,
          dateTime: start,
          isCompleted: false,
          recurrence: null,
        );
        await widget.dbService.addReminder(newReminder);
      }
      //close the creator box and show success message
      if (mounted) {
        Navigator.pop(context); 
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEventMode ? 'Event saved!' : 'Reminder saved!'), duration: const Duration(seconds: 1)),
        );
      }
    } catch (e) {
      //error handling
      print("Error saving: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save ${_isEventMode ? 'event' : 'reminder'}. Please try again.'))
        );
      }
    }
  }
  //building the UI for the creator box
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

        //actual content of the creator box
        Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 5,
              width: 40,
              decoration: BoxDecoration(color: _standardDark, borderRadius: BorderRadius.circular(10)),
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
                    style: TextStyle(color: _standardDark, fontSize: 32, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: _isEventMode ? "Title" : "Title",
                      hintStyle: TextStyle(color: _standardDark.withValues(alpha: 0.2)),
                      border: InputBorder.none,
                    ),
                  ),
                  
                  Divider(color: _standardDark.withValues(alpha: 0.1), height: 32),
                  
                  if (_isEventMode)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text("All day", style: TextStyle(color: _standardDark, fontSize: 16, fontWeight: FontWeight.w500)),
                      value: _isAllDay,
                      activeColor: Colors.deepPurpleAccent,
                      onChanged: (val) => setState(() => _isAllDay = val),
                    ),

                  //date and time pickers
                  _buildDateTimeRow(true),
                  if (_isEventMode) ...[
                    const SizedBox(height: 16),
                    _buildDateTimeRow(false),
                  ],

                  const SizedBox(height: 30),


                  if (_isEventMode) ...[
                    Text("Color", style: TextStyle(color: _standardDark.withValues(alpha: 0.5), fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 15),
                    _buildColorRow(),
                  ],

                  const SizedBox(height: 30),
                  _buildMetadataTile(Icons.notifications_none_outlined, "Alert"),
                  _buildMetadataTile(Icons.notes_outlined, "Notes"),
                ],
              ),
            ),

            _buildBottomButtons(),
          ],
        ),
      ],
    );
  }

  //switch between event and reminder creation modes
  Widget _buildStellarToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn("Event", _isEventMode),
          _toggleBtn("Reminder", !_isEventMode),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active) {
    return GestureDetector(
      onTap: () => setState(() => _isEventMode = label == "Event"),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : [],
        ),
        child: Text(label, style: TextStyle(color: active ? _standardDark : _standardDark.withValues(alpha: 0.4), fontWeight: FontWeight.bold)),
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
            style: TextStyle(color: _standardDark, fontSize: 17, fontWeight: FontWeight.w500),
          ),
        ),
        
        const Spacer(),


        if (!_isAllDay)
          GestureDetector(
            onTap: () async {
              final picked = await StellarTimePicker.show(context, initialTime: time);
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
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                time.format(context),
                style: TextStyle(color: _standardDark, fontSize: 17, fontWeight: FontWeight.bold),
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
              border: sel ? Border.all(color: _standardDark.withValues(alpha: 0.3), width: 3) : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetadataTile(IconData icon, String label) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: _standardDark.withValues(alpha: 0.4)),
      title: Text(label, style: TextStyle(color: _standardDark.withValues(alpha: 0.6), fontSize: 16)),
      trailing: Icon(Icons.chevron_right, color: _standardDark.withValues(alpha: 0.2)),
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
              child: Text("Cancel", style: TextStyle(color: _standardDark.withValues(alpha: 0.6), fontSize: 16)),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: GestureDetector(
              onTap: _handleSave,
              child: Container(
                height: 55,
                decoration: BoxDecoration(color: _standardDark, borderRadius: BorderRadius.circular(15)),
                child: const Center(child: Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}