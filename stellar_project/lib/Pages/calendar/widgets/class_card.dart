import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../services/database_service.dart';

class ClassCard extends StatefulWidget {
  final ClassModel classModel;
  final DatabaseService dbService;

  const ClassCard({
    super.key,
    required this.classModel,
    required this.dbService,
  });

  @override
  State<ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends State<ClassCard> {
  bool _isLongPressed = false;


  String _formatDays(List<int> days) {
    const dayMap = {1: 'M', 2: 'T', 3: 'W', 4: 'Th', 5: 'F', 6: 'S', 7: 'Su'};
    return days.map((d) => dayMap[d] ?? '').join(', ');
  }


  void _showCancelPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A36),
        title: const Text("Cancel Class", style: TextStyle(color: Colors.white)),
        content: Text(
          "Are you sure you want to cancel ${widget.classModel.courseName} for today?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {

              widget.dbService.toggleSkipClass(widget.classModel, DateTime.now());
              Navigator.pop(context);
            },
            child: const Text("Yes", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.classModel;
    final classColor = Color(c.colorValue);

    return GestureDetector(
      onTap: () {
        if (_isLongPressed) {

          setState(() => _isLongPressed = false);
        } else {

          _showCancelPrompt();
        }
      },
      onLongPress: () {

        setState(() => _isLongPressed = true);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05), 
          borderRadius: BorderRadius.circular(12),
        ),
        child: IntrinsicHeight( 
          child: Row(
            children: [

              Container(
                width: 5,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: classColor,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
                ),
              ),
              
              const SizedBox(width: 12),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.courseName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${c.startTime} - ${c.endTime}  |  ${_formatDays(c.daysOfWeek)}  |  Rm ${c.room}",
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

              if (_isLongPressed)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                      onPressed: () { /* Open edit */ },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () => widget.dbService.deleteClass(c.id),
                    ),
                    const Icon(Icons.drag_handle, color: Colors.white38),
                    const SizedBox(width: 8),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}