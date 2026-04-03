import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/event_model.dart';
import 'models/class_model.dart';
import 'models/reminder_model.dart';
import 'services/database_service.dart';
import 'package:table_calendar/table_calendar.dart';

class DayView extends StatefulWidget {
  final DateTime focusedDay;

  const DayView({super.key, required this.focusedDay});

  @override
  State<DayView> createState() => _DayViewState();
}

class _DayViewState extends State<DayView> {
  final double hourHeight = 70.0;
  final String _uid = FirebaseAuth.instance.currentUser!.uid;
  late DatabaseService _dbService;

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService(uid: _uid);
  }


  double _calculateTopPosition(DateTime time) {
    return (time.hour * hourHeight) + (time.minute / 60 * hourHeight);
  }

  DateTime _parseClassTime(String timeStr) {
    try {
      final format = DateFormat.jm();
      DateTime parsed = format.parse(timeStr);
      return DateTime(
        widget.focusedDay.year,
        widget.focusedDay.month,
        widget.focusedDay.day,
        parsed.hour,
        parsed.minute,
      );
    } catch (e) {
      return widget.focusedDay;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventModel>>(
      stream: _dbService.allEvents,
      builder: (context, eventSnapshot) {
        return StreamBuilder<List<ClassModel>>(
          stream: _dbService.allClasses,
          builder: (context, classSnapshot) {
            return StreamBuilder<List<ReminderModel>>(
              stream: _dbService.allReminders,
              builder: (context, reminderSnapshot) {
                final events = eventSnapshot.data ?? [];
                final classes = classSnapshot.data ?? [];
                final reminders = reminderSnapshot.data ?? [];

                final dayEvents = events.where((e) => isSameDay(e.startDateTime, widget.focusedDay)).toList();
                final dayClasses = classes.where((c) => c.daysOfWeek.contains(widget.focusedDay.weekday)).toList();
                final dayReminders = reminders.where((r) => isSameDay(r.dateTime, widget.focusedDay)).toList();

                return SingleChildScrollView(
                  child: Stack(
                    children: [
                      Column(
                        children: List.generate(24, (index) {
                          return Container(
                            height: hourHeight,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.black.withOpacity(0.05), width: 1),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 60,
                                  padding: const EdgeInsets.only(top: 8, left: 8),
                                  child: Text(
                                    DateFormat('h a').format(DateTime(2026, 1, 1, index)),
                                    style: const TextStyle(color: Colors.black38, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),

                      ...dayClasses.map((c) {
                        final start = _parseClassTime(c.startTime);
                        final end = _parseClassTime(c.endTime);
                        final top = _calculateTopPosition(start);
                        final height = _calculateTopPosition(end) - top;

                        return Positioned(
                          top: top,
                          left: 70,
                          right: 20,
                          height: height,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(c.colorValue).withOpacity(0.15),
                              border: Border.all(color: Color(c.colorValue), width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              c.courseName,
                              style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }),

                      ...dayEvents.map((e) {
                        final top = _calculateTopPosition(e.startDateTime);
                        final height = _calculateTopPosition(e.endDateTime) - top;

                        return Positioned(
                          top: top,
                          left: 75, 
                          right: 25,
                          height: height.clamp(20.0, 1000.0),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(e.colorValue),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              e.title,
                              style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }),


                      ...dayReminders.map((r) {
                        final top = _calculateTopPosition(r.dateTime);
                        return Positioned(
                          top: top - 10,
                          left: 45,
                          child: Icon(
                            Icons.notifications_active,
                            color: r.isCompleted ? Colors.black : Colors.blueAccent,
                            size: 18,
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}