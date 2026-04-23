import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/class_model.dart';

class ClassCreatorBox extends StatefulWidget {
  final DatabaseService dbService;
  final ClassModel? existingClass; 

  const ClassCreatorBox({super.key, required this.dbService, this.existingClass});

  @override
  State<ClassCreatorBox> createState() => _ClassCreatorBoxState();
}

class _ClassCreatorBoxState extends State<ClassCreatorBox> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _instructorController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  
  List<int> _selectedDaysOfWeek = [];
  int _selectedColor = 0xFF8AB4F8;
  final Color _standardDark = const Color(0xFF2D2E33);

  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  void initState() {
    super.initState();
    if (widget.existingClass != null) {
      final oldClass = widget.existingClass!;
      
      _titleController.text = oldClass.courseName;
      _instructorController.text = oldClass.instructor;
      _roomController.text = oldClass.room;
      _selectedDaysOfWeek = List.from(oldClass.daysOfWeek);
      _selectedColor = oldClass.colorValue;
      
      _startTime = _parseTimeString(oldClass.startTime);
      _endTime = _parseTimeString(oldClass.endTime);
    }
  }

  TimeOfDay _parseTimeString(String timeString) {
    try {
      final dateTime = DateFormat('h:mm a').parse(timeString);
      return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    } catch (e) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  void _handleSave() async {
    if (_titleController.text.trim().isEmpty || _selectedDaysOfWeek.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a course name and select at least one day.'))
      );
      return;
    }

    DateTime today = DateTime.now();
    DateTime start = DateTime(today.year, today.month, today.day, _startTime.hour, _startTime.minute);
    DateTime end = DateTime(today.year, today.month, today.day, _endTime.hour, _endTime.minute);

    try {
      final classData = ClassModel(
        id: widget.existingClass?.id ?? '', 
        courseName: _titleController.text.trim(),
        instructor: _instructorController.text.trim(),
        room: _roomController.text.trim(),
        daysOfWeek: _selectedDaysOfWeek,
        startTime: DateFormat('h:mm a').format(start),
        endTime: DateFormat('h:mm a').format(end),
        colorValue: _selectedColor,
        skippedDays: widget.existingClass?.skippedDays ?? [],
        position: widget.existingClass?.position ?? 0,
      );
      
      if (widget.existingClass != null) {
        await widget.dbService.updateClass(classData);
      } else {
        await widget.dbService.addClass(classData);
      }
      
      if (mounted) Navigator.pop(context);
      
    } catch (e) {
      print("Error saving class: $e");
    }
  }

  Widget _buildDaySelector() {
    const daysMap = {1: 'M', 2: 'T', 3: 'W', 4: 'Th', 5: 'F', 6: 'S', 7: 'Su'};
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: daysMap.entries.map((entry) {
        int dayValue = entry.key;
        bool isSelected = _selectedDaysOfWeek.contains(dayValue);
        return GestureDetector(
          onTap: () {
            setState(() {
              isSelected ? _selectedDaysOfWeek.remove(dayValue) : _selectedDaysOfWeek.add(dayValue);
            });
          },
          child: CircleAvatar(
            radius: 18,
            backgroundColor: isSelected ? Colors.deepPurpleAccent : Colors.black.withValues(alpha: 0.05),
            child: Text(entry.value, style: TextStyle(color: isSelected ? Colors.black : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeRow(bool isStart) {
    TimeOfDay time = isStart ? _startTime : _endTime;
    return Row(
      children: [
        Icon(Icons.access_time, color: _standardDark.withValues(alpha: 0.6), size: 20),
        const SizedBox(width: 15),
        Text(isStart ? "Start Time" : "End Time", style: TextStyle(color: _standardDark, fontSize: 16)),
        const Spacer(),
        GestureDetector(
          onTap: () async {
            final picked = await showTimePicker(context: context, initialTime: time);
            if (picked != null) setState(() => isStart ? _startTime = picked : _endTime = picked);
          },
          child: Text(time.format(context), style: TextStyle(color: _standardDark, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  //color selecter
  Widget _buildColorRow() {
    final colors = [0xFF8AB4F8, 0xFFF28B82, 0xFFFBB662, 0xFF81C995, 0xFFC58AF9];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: colors.map((colorValue) {
        bool sel = _selectedColor == colorValue;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = colorValue),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Color(colorValue), shape: BoxShape.circle,
              border: sel ? Border.all(color: _standardDark.withValues(alpha: 0.3), width: 3) : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {

    //header
    String headerTitle = widget.existingClass != null ? "Edit Class" : "New Class";
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(color: Colors.white),
              ),
            ),
          ),
          Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                height: 5, width: 40,
                decoration: BoxDecoration(color: _standardDark, borderRadius: BorderRadius.circular(10)),
              ),
              Text(headerTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              //main content of class
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    
                    //course name input
                    TextField(
                      controller: _titleController,
                      style: TextStyle(color: _standardDark, fontSize: 28, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(hintText: "Course Name", border: InputBorder.none, hintStyle: TextStyle(color: _standardDark.withValues(alpha: 0.2))),
                    ),
                    Divider(color: _standardDark.withValues(alpha: 0.1), height: 32),
                    
                    //day of week
                    _buildDaySelector(),
                    const SizedBox(height: 20),
                    _buildTimeRow(true),
                    const SizedBox(height: 16),
                    _buildTimeRow(false),
                    const SizedBox(),

                    //color selector
                    const SizedBox(height: 30),
                    const SizedBox(height: 0),
                    _buildColorRow(),
                    const SizedBox(height: 15),

                    //Instructor input field
                    TextField(
                      controller: _instructorController,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline, color: Colors.black54),
                        hintText: "Instructor", filled: true, fillColor: Colors.black.withValues(alpha: 0.05),
                        
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    //Room number input field
                    TextField(
                      controller: _roomController,
                       style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.meeting_room_outlined, color: Colors.black54),
                        hintText: "Room Number", filled: true, fillColor: Colors.black.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),

              //save and cancel buttons.
              Container(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
                child: Row(
                  children: [
                    Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: _standardDark.withValues(alpha: 0.6), fontSize: 16)))),
                    const SizedBox(width: 20),
                    Expanded(
                      child: GestureDetector(
                        onTap: _handleSave,
                        child: Container(
                          height: 55, alignment: Alignment.center,
                          decoration: BoxDecoration(color: _standardDark, borderRadius: BorderRadius.circular(15)),
                          child: const Text("Save", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}