import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../models/class_model.dart';
import '../models/reminder_model.dart';
import '../services/database_service.dart';
import 'creator_box.dart';
 
class EventItem extends StatelessWidget {
  final dynamic item;
  final DatabaseService dbService;
  final DateTime selectedDate;
 
  const EventItem({
    super.key,
    required this.item,
    required this.dbService,
    required this.selectedDate,
  });
 
  void _openEditSheet(BuildContext context) {
    if (item is ClassModel) return;
 
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                ),
              ),
              child: CreatorBox(
                dbService: dbService,
                initialDate: selectedDate,
                existingEvent: item is EventModel ? item as EventModel : null,
                existingReminder: item is ReminderModel ? item as ReminderModel : null,
              ),
            ),
          ),
        );
      },
    );
  }
 
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A36),
        title: const Text("Delete", style: TextStyle(color: Colors.black)),
        content: Text(
          item is EventModel
              ? 'Delete "${(item as EventModel).title}"?'
              : item is ReminderModel
                  ? 'Delete "${(item as ReminderModel).title}"?'
                  : 'Delete this item?',
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (item is EventModel) {
                dbService.deleteEvent((item as EventModel).id);
              } else if (item is ReminderModel) {
                dbService.deleteReminder((item as ReminderModel).id);
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
 
    final bool isEvent = item is EventModel;
    final bool isClass = item is ClassModel;
    final bool isReminder = item is ReminderModel;
 
 
    String title = "";
    String timeDisplay = "";
    String subTitle = "";
    Color baseColor = Colors.blueAccent;
    bool isCompletedOrCanceled = false;
 
    if (isEvent) {
      final e = item as EventModel;
      title = e.title;
      timeDisplay = DateFormat('h:mm a').format(e.startDateTime);
      subTitle = "${DateFormat('h:mm a').format(e.startDateTime)} - ${DateFormat('h:mm a').format(e.endDateTime)}";
      baseColor = Color(e.colorValue);
    } else if (isClass) {
      final c = item as ClassModel;
      title = c.courseName;
      timeDisplay = c.startTime;
      subTitle = "${c.startTime} - ${c.endTime}";
      baseColor = Color(c.colorValue);
 
      String dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
      isCompletedOrCanceled = c.skippedDays.contains(dateStr);
    } else if (isReminder) {
      final r = item as ReminderModel;
      title = r.title;
      timeDisplay = DateFormat('h:mm a').format(r.dateTime);
      subTitle = ""; 
      isCompletedOrCanceled = r.isCompleted;
    }
 
    return GestureDetector(
      onTap: () => _openEditSheet(context),
      onLongPress: () => _confirmDelete(context),
      child: Opacity(
      opacity: isCompletedOrCanceled ? 0.5 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 70,
              child: Text(
                timeDisplay,
                style: const TextStyle(color: Colors.black, fontSize: 13),
              ),
            ),
 
            const SizedBox(width: 10),
 
            if (isReminder)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Icon(Icons.notifications_none, color: Colors.white70, size: 20),
              )
            else
              Container(
                width: 4,
                height: 35,
                decoration: BoxDecoration(
                  color: isClass ? baseColor.withOpacity(0.2) : baseColor,
                  border: isClass ? Border.all(color: baseColor, width: 1.5) : null,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
 
            const SizedBox(width: 15),
 
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      decoration: isCompletedOrCanceled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (subTitle.isNotEmpty)
                    Text(
                      subTitle,
                      style: const TextStyle(color: Colors.black, fontSize: 12),
                    ),
                ],
              ),
            ),
 
            if (isReminder)
              IconButton(
                icon: Icon(
                  isCompletedOrCanceled ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isCompletedOrCanceled ? Colors.blueAccent : Colors.white30,
                ),
                onPressed: () {
                  final r = item as ReminderModel;
                  dbService.updateReminder(r.copyWith(isCompleted: !r.isCompleted));
                },
              ),
          ],
        ),
      ),
      ),
    );
  }
}