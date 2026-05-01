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

  //contains whether or not the user longpressed a card.
  bool _isLongPressed = false;

  //converts list of int to days (1-7)
  String _formatDays(List<int> days) {
    const dayMap = {1: 'M', 2: 'T', 3: 'W', 4: 'Th', 5: 'F', 6: 'S', 7: 'Su'};
    return days.map((d) => dayMap[d] ?? '').join(', ');
  }

  //class skip confirmation
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

          //selecting "no" closes dialogue box and doesnt do anything
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No", style: TextStyle(color: Colors.grey)),
          ),

          //yes updates database to mark class as skipped, and closes box
          TextButton(
            onPressed: () {

              //calls db service to toggle the skip for that days class
              widget.dbService.toggleSkipClass(widget.classModel, DateTime.now());
              Navigator.pop(context);
            },
            child: const Text("Yes", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  //build UI
  @override
  Widget build(BuildContext context) {
    final c = widget.classModel;
    final classColor = Color(c.colorValue);

    //allows entire card to respond to touch
    return GestureDetector(
      onTap: () {

        //long press displays options, tapping anywhere cancles the action
        if (_isLongPressed) {
          setState(() => _isLongPressed = false);
        } else {
          //prompts for skip if not in longpressed mode
          _showCancelPrompt();
        }
      },
      onLongPress: () {
        //triggers state change for edit and delete icons
        setState(() => _isLongPressed = true);
      },

      //main card container
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        //adjusting sizes --> rows fit the height of the tallest child
        child: IntrinsicHeight( 
          child: Row(
            children: [
              
              //color theme display
              Container(
                width: 5,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: classColor,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
                ),
              ),
              
              const SizedBox(width: 12),

              //column takes up horizontal space
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      //class name
                      Text(
                        c.courseName,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),

                      //class details
                      Text(
                        "${c.startTime} - ${c.endTime}  |  ${_formatDays(c.daysOfWeek)}  |  Rm ${c.room}",
                        style: const TextStyle(color: Colors.black, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

              //buttomns display if longpresed is true
              if (_isLongPressed)
                Row(
                  children: [
                    
                    //needs edited
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                      onPressed: () {},
                    ),

                    //showing that user can drag
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