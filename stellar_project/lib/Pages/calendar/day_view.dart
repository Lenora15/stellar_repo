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
  final Function(DateTime)? onDayChanged;

  const DayView({
    super.key,
    required this.focusedDay,
    this.onDayChanged,
  });

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

  List<List<int>> _assignColumns(List<dynamic> items, List<DateTime> starts, List<DateTime> ends) {
    final int n = items.length;
    final List<int> col = List.filled(n, 0);
    final List<int> maxCols = List.filled(n, 1);

    for (int i = 0; i < n; i++) {
      final List<int> overlapping = [];
      for (int j = 0; j < i; j++) {
        if (starts[i].isBefore(ends[j]) && ends[i].isAfter(starts[j])) {
          overlapping.add(j);
        }
      }
      final usedCols = overlapping.map((j) => col[j]).toSet();
      int c = 0;
      while (usedCols.contains(c)) c++;
      col[i] = c;
    }

    for (int i = 0; i < n; i++) {
      int total = col[i] + 1;
      for (int j = 0; j < n; j++) {
        if (i != j &&
            starts[i].isBefore(ends[j]) &&
            ends[i].isAfter(starts[j])) {
          total = total > col[j] + 1 ? total : col[j] + 1;
        }
      }
      maxCols[i] = total;
    }

    return List.generate(n, (i) => [col[i], maxCols[i]]);
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

                final dayEvents = events
                    .where((e) => isSameDay(e.startDateTime, widget.focusedDay))
                    .toList();
                final dayClasses = classes
                    .where((c) => c.daysOfWeek.contains(widget.focusedDay.weekday))
                    .toList();
                final dayReminders = reminders
                    .where((r) => isSameDay(r.dateTime, widget.focusedDay))
                    .toList();
                final allItems = [...dayClasses, ...dayEvents];
                final allStarts = allItems.map((item) {
                  if (item is ClassModel) return _parseClassTime(item.startTime);
                  return (item as EventModel).startDateTime;
                }).toList();
                final allEnds = allItems.map((item) {
                  if (item is ClassModel) return _parseClassTime(item.endTime);
                  return (item as EventModel).endDateTime;
                }).toList();

                final layout = _assignColumns(allItems, allStarts, allEnds);

                return ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: 0.8),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => widget.onDayChanged?.call(
                                  widget.focusedDay
                                      .subtract(const Duration(days: 1)),
                                ),
                                child: const Icon(Icons.chevron_left,
                                    color: Colors.black54),
                              ),
                              const Spacer(),
                              Text(
                                DateFormat('EEEE, MMMM d')
                                    .format(widget.focusedDay),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => widget.onDayChanged?.call(
                                  widget.focusedDay
                                      .add(const Duration(days: 1)),
                                ),
                                child: const Icon(Icons.chevron_right,
                                    color: Colors.black54),
                              ),
                            ],
                          ),
                        ),

                        const Divider(height: 1, color: Colors.black12),

                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final double timelineWidth = constraints.maxWidth;
                              final double eventAreaLeft = 65.0;
                              final double eventAreaWidth =
                                  timelineWidth - eventAreaLeft - 8;

                              return SingleChildScrollView(
                                child: SizedBox(
                                  height: hourHeight * 24,
                                  child: Stack(
                                    children: [

                                      Column(
                                        children: List.generate(24, (index) {
                                          return Container(
                                            height: hourHeight,
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.1),
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  width: 60,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 8, left: 8),
                                                    child: Text(
                                                      DateFormat('h a').format(
                                                          DateTime(
                                                              2026, 1, 1, index)),
                                                      style: const TextStyle(
                                                          color: Colors.black54,
                                                          fontSize: 12),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ),

                                      ...List.generate(allItems.length, (i) {
                                        final item = allItems[i];
                                        final start = allStarts[i];
                                        final end = allEnds[i];
                                        final top = _calculateTopPosition(start);
                                        final height = (_calculateTopPosition(end) - top).clamp(20.0, 1000.0);
                                        final col = layout[i][0];
                                        final totalCols = layout[i][1];

                                        final double colWidth =
                                            eventAreaWidth / totalCols;
                                        final double left =
                                            eventAreaLeft + col * colWidth;
                                        final double width = colWidth - 4;

                                        if (item is ClassModel) {
                                          return Positioned(
                                            top: top,
                                            left: left,
                                            width: width,
                                            height: height,
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Color(item.colorValue)
                                                    .withValues(alpha: 0.15),
                                                border: Border.all(
                                                    color:
                                                        Color(item.colorValue),
                                                    width: 1.5),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                item.courseName,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          );
                                        } else {
                                          final e = item as EventModel;
                                          return Positioned(
                                            top: top,
                                            left: left,
                                            width: width,
                                            height: height,
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Color(e.colorValue)
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                e.title,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          );
                                        }
                                      }),
                                      ...dayReminders.map((r) {
                                        final top =
                                            _calculateTopPosition(r.dateTime);
                                        return Positioned(
                                          top: top - 10,
                                          left: 45,
                                          child: Icon(
                                            Icons.notifications_active,
                                            color: r.isCompleted
                                                ? Colors.black
                                                : Colors.deepPurpleAccent,
                                            size: 18,
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
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