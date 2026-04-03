import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/event_model.dart';
import 'models/class_model.dart';
import 'services/database_service.dart';

class MonthWeekView extends StatefulWidget {
  final DateTime focusedDay;
  final bool isWeekFormat;
  final bool showSchedule;
  final Function(DateTime) onPageChanged;

  const MonthWeekView({
    super.key,
    required this.focusedDay,
    required this.isWeekFormat,
    required this.showSchedule,
    required this.onPageChanged,
  });

  @override
  State<MonthWeekView> createState() => _MonthWeekViewState();
}

class _MonthWeekViewState extends State<MonthWeekView> {
  final String _uid = FirebaseAuth.instance.currentUser!.uid;
  late DatabaseService _dbService;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService(uid: _uid);
    _selectedDay = widget.focusedDay;
  }

  bool _shouldShowEventOnDay(EventModel event, DateTime day) {
    final String dateString = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";

    if (event.skippedDates.contains(dateString)) return false;

    final eventStart = DateTime(event.startDateTime.year, event.startDateTime.month, event.startDateTime.day);
    if (day.isBefore(eventStart)) return false;

    if (event.endDate != null && day.isAfter(event.endDate!)) return false;

    if (!event.isRecurring) {
      final eventEnd = DateTime(event.endDateTime.year, event.endDateTime.month, event.endDateTime.day);
      return day.isAtSameMomentAs(eventStart) || 
             day.isAtSameMomentAs(eventEnd) || 
             (day.isAfter(eventStart) && day.isBefore(eventEnd));
    }

    switch (event.frequency) {
      case 'daily':
        final difference = day.difference(eventStart).inDays;
        return difference % event.interval == 0;
      
      case 'weekly':
        if (!event.repeatDays.contains(day.weekday)) return false;
        final startWeek = eventStart.millisecondsSinceEpoch ~/ (7 * 24 * 60 * 60 * 1000);
        final currentWeek = day.millisecondsSinceEpoch ~/ (7 * 24 * 60 * 60 * 1000);
        return (currentWeek - startWeek) % event.interval == 0;

      case 'monthly':
        return day.day == eventStart.day;

      default:
        return isSameDay(event.startDateTime, day);
    }
  }

  List<dynamic> _getEventsForDay(DateTime day, List<EventModel> events, List<ClassModel> classes) {
    List<dynamic> dayItems = [];
    dayItems.addAll(events.where((e) => _shouldShowEventOnDay(e, day)));


    if (widget.showSchedule) {
      dayItems.addAll(classes.where((c) {
        bool occursToday = c.daysOfWeek.contains(day.weekday);
        
        String dateStr = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
        bool isCanceled = c.skippedDays.contains(dateStr); 
        
        return occursToday && !isCanceled;
      }));
    }

    return dayItems;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventModel>>(
      stream: _dbService.allEvents,
      builder: (context, eventSnapshot) {
        return StreamBuilder<List<ClassModel>>(
          stream: _dbService.allClasses,
          builder: (context, classSnapshot) {
            final events = eventSnapshot.data ?? [];
            final classes = classSnapshot.data ?? [];

            return TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: widget.focusedDay,
              calendarFormat: widget.isWeekFormat ? CalendarFormat.week : CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              headerVisible: false,

              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() => _selectedDay = selectedDay);
                widget.onPageChanged(focusedDay);
              },
              onPageChanged: widget.onPageChanged,


              eventLoader: (day) => _getEventsForDay(day, events, classes),

              daysOfWeekHeight: 30,
              calendarBuilders: CalendarBuilders(
                dowBuilder: (context, day) {
                  final text = const ['S', 'M', 'T', 'W', 'T', 'F', 'S'][day.weekday % 7];
                  return Center(
                    child: Text(
                      text,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
                

                markerBuilder: (context, date, dayItems) {
                  if (dayItems.isEmpty) return const SizedBox.shrink();

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dayItems.length > 3 ? 3 : dayItems.length,
                    itemBuilder: (context, index) {
                      final item = dayItems[index];
                      bool isClass = item is ClassModel;
                      
                      Color baseColor = Color(isClass ? item.colorValue : (item as EventModel).colorValue);

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                        height: 7,
                        decoration: BoxDecoration(
                          color: isClass 
                              ? baseColor.withOpacity(0.2) 
                              : baseColor,
                          border: isClass 
                              ? Border.all(color: baseColor, width: 1) 
                              : null,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: widget.isWeekFormat 
                          ? null
                          : Center(
                              child: Text(
                                isClass ? (item as ClassModel).courseName : (item as EventModel).title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black, 
                                  fontSize: 5, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                      );
                    },
                  );
                },
              ),

              calendarStyle: CalendarStyle(
                defaultTextStyle: const TextStyle(color: Colors.black),
                weekendTextStyle: const TextStyle(color: Colors.black),
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                markerMargin: const EdgeInsets.only(top: 25),
              ),
            );
          },
        );
      },
    );
  }
}