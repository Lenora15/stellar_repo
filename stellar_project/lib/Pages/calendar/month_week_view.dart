import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'widgets/event_item.dart';
import 'models/event_model.dart';
import 'models/class_model.dart';
import 'models/reminder_model.dart';
import 'services/database_service.dart';

//had claude remove some redundencies

enum _ViewState { fullMonth, monthWithList, weekWithList }

class MonthWeekView extends StatefulWidget {
  final DateTime focusedDay;
  final bool showSchedule;
  final Function(DateTime) onPageChanged;
  final bool locked;
  final bool remindersOnly;

  const MonthWeekView({
    super.key,
    required this.focusedDay,
    required this.showSchedule,
    required this.onPageChanged,
    this.locked = false,
    this.remindersOnly = false,
  });

  @override
  State<MonthWeekView> createState() => _MonthWeekViewState();
}

class _MonthWeekViewState extends State<MonthWeekView> {
  final String _uid = FirebaseAuth.instance.currentUser!.uid;
  late DatabaseService _dbService;
  DateTime? _selectedDay;

  //Default is month w/ list
  _ViewState _viewState = _ViewState.monthWithList;

  double _dragAccumulator = 0;


  //Helpers
  CalendarFormat get _calendarFormat =>
      _viewState == _ViewState.weekWithList
          ? CalendarFormat.week
          : CalendarFormat.month;
  bool get _isFullMonth => _viewState == _ViewState.fullMonth;

 @override
  void initState() {
    super.initState();
    _dbService = DatabaseService(uid: _uid);
    _selectedDay = widget.focusedDay;
    if (widget.locked) _viewState = _ViewState.weekWithList;
  }

  @override
  void didUpdateWidget(MonthWeekView oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (widget.locked && !oldWidget.locked) {
    setState(() => _viewState = _ViewState.weekWithList);
  }
}

  void _onDragUpdate(DragUpdateDetails details) {
    if (widget.locked) return;
    _dragAccumulator += details.delta.dy;
  }

  void _onDragEnd(DragEndDetails details) {
    if (widget.locked) return;
    final drag = _dragAccumulator;
    _dragAccumulator = 0;

    final velocity = details.primaryVelocity ?? 0;
    final swipedUp   = drag < -40 || velocity < -300;
    final swipedDown = drag >  40 || velocity >  300;

    if (swipedUp) {
      setState(() {
        if (_viewState == _ViewState.fullMonth) {
          _viewState = _ViewState.monthWithList;
        } else if (_viewState == _ViewState.monthWithList) {
          _viewState = _ViewState.weekWithList;
        }
      });
    } else if (swipedDown) {
      setState(() {
        if (_viewState == _ViewState.weekWithList) {
          _viewState = _ViewState.monthWithList;
        } else if (_viewState == _ViewState.monthWithList) {
          _viewState = _ViewState.fullMonth;
        }
      });
    }
  }

  bool _shouldShowEventOnDay(EventModel event, DateTime day) {
      final dayOnly = DateTime(day.year, day.month, day.day);
  
  final String dateString =
      "${dayOnly.year}-${dayOnly.month.toString().padLeft(2, '0')}-${dayOnly.day.toString().padLeft(2, '0')}";

  if (event.skippedDates.contains(dateString)) return false;

  final eventStart = DateTime(
      event.startDateTime.year,
      event.startDateTime.month,
      event.startDateTime.day);

  if (dayOnly.isBefore(eventStart)) return false;

  if (event.endDate != null && dayOnly.isAfter(event.endDate!)) return false;

  if (!event.isRecurring) {
    final eventEnd = DateTime(event.endDateTime.year,
        event.endDateTime.month, event.endDateTime.day);
    return isSameDay(dayOnly, eventStart) ||
        isSameDay(dayOnly, eventEnd) ||
        (dayOnly.isAfter(eventStart) && dayOnly.isBefore(eventEnd));
  }

  switch (event.frequency) {
    case 'daily':
      final difference = dayOnly.difference(eventStart).inDays;
      return difference % event.interval == 0;
    case 'weekly':
      if (!event.repeatDays.contains(dayOnly.weekday)) return false;
      final startWeek =
          eventStart.millisecondsSinceEpoch ~/ (7 * 24 * 60 * 60 * 1000);
      final currentWeek =
          dayOnly.millisecondsSinceEpoch ~/ (7 * 24 * 60 * 60 * 1000);
      return (currentWeek - startWeek) % event.interval == 0;
    case 'monthly':
      return dayOnly.day == eventStart.day;
    default:
      return isSameDay(event.startDateTime, dayOnly);
  }
}

  List<dynamic> _getEventsForDay(
      DateTime day, List<EventModel> events, List<ClassModel> classes) {
    final String dateStr =
        "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
    List<dynamic> items = [];
    items.addAll(events.where((e) => _shouldShowEventOnDay(e, day)));
    if (widget.showSchedule) {
      items.addAll(classes.where((c) =>
          c.daysOfWeek.contains(day.weekday) &&
          !c.skippedDays.contains(dateStr)));
    }
    return items;
  }

  List<dynamic> _getItemsForDay(DateTime day, List<EventModel> events,
    List<ClassModel> classes, List<ReminderModel> reminders) {
  final dayOnly = DateTime(day.year, day.month, day.day);
  
  if (widget.remindersOnly) {
    final items = reminders
        .where((r) => isSameDay(r.dateTime, dayOnly))
        .toList();
    items.sort((a, b) => _itemTime(a).compareTo(_itemTime(b)));
    return items;
  }

  final items = _getEventsForDay(dayOnly, events, classes);
  items.addAll(reminders.where((r) => isSameDay(r.dateTime, dayOnly)));
  items.sort((a, b) => _itemTime(a).compareTo(_itemTime(b)));
  return items;
}

  DateTime _itemTime(dynamic item) {
    if (item is EventModel) return item.startDateTime;
    if (item is ReminderModel) return item.dateTime;
    if (item is ClassModel) {
      try {
        return DateFormat.jm().parse(item.startTime);
      } catch (_) {}
    }
    return DateTime.now();
  }

  Widget _buildDayCell(DateTime day,
      {Color? bgColor,
      Color textColor = Colors.black,
      bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: Colors.deepPurpleAccent, width: 2)
            : null,
      ),
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        '${day.day}',
        style: TextStyle(
            color: textColor,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.w500),
      ),
    );
  }

  Widget _buildEventList(DateTime day, List<dynamic> items) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              Text(
                '${day.day}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEE').format(day).toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: Colors.black12),

        if (items.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                'Nothing Today',
                style: TextStyle(color: Colors.black38, fontSize: 14),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              physics: const ClampingScrollPhysics(), 
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: Colors.black12,
              ),
              itemBuilder: (context, index) => EventItem(
                item: items[index],
                dbService: _dbService,
                selectedDate: day,
              ),
            ),
          ),
      ],
    ),
  );
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

                final selectedDay = _selectedDay ?? widget.focusedDay;
                final dayItems =
                    _getItemsForDay(selectedDay, events, classes, reminders);

                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragUpdate: _onDragUpdate,
                  onVerticalDragEnd: _onDragEnd,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double rowHeight = _isFullMonth
                          ? constraints.maxHeight.isFinite
                              ? ((constraints.maxHeight - 30) / 6)
                                  .clamp(52.0, 130.0)
                              : 90.0
                          : 60.0;

                      return AnimatedSize(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOutCubic,
                        child: Column(
                          children: [
                            TableCalendar(
                              firstDay: DateTime.utc(2020, 1, 1),
                              lastDay: DateTime.utc(2030, 12, 31),
                              focusedDay: widget.focusedDay,
                              calendarFormat: _calendarFormat,
                              availableCalendarFormats: const {
                                CalendarFormat.month: 'Month',
                                CalendarFormat.week: 'Week',
                              },
                             onFormatChanged: widget.locked
                                  ? null
                                  : (format) {
                                      setState(() {
                                        _viewState =
                                            format == CalendarFormat.week
                                                ? _ViewState.weekWithList
                                                : _ViewState.monthWithList;
                                      });
                                    },
                              startingDayOfWeek: StartingDayOfWeek.sunday,
                              headerVisible: false,
                              rowHeight: rowHeight,
                              daysOfWeekHeight: 30,
                              selectedDayPredicate: (day) =>
                                  isSameDay(_selectedDay, day),
                              onDaySelected: (selectedDay, focusedDay) {
                                setState(() => _selectedDay = selectedDay);
                                widget.onPageChanged(focusedDay);
                              },
                              onPageChanged: widget.onPageChanged,
                              eventLoader: (day) => widget.remindersOnly
                                ? reminders.where((r) => isSameDay(r.dateTime, day)).toList()
                                : _getEventsForDay(day, events, classes),
                              calendarStyle: const CalendarStyle(
                                outsideDaysVisible: false,
                                defaultTextStyle:
                                    TextStyle(color: Colors.transparent),
                              ),
                              calendarBuilders: CalendarBuilders(
                                dowBuilder: (context, day) {
                                  final text = [
                                    'S', 'M', 'T', 'W', 'T', 'F', 'S'
                                  ][day.weekday % 7];
                                  return Center(
                                    child: Text(
                                      text,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  );
                                },
                                defaultBuilder: (context, day, _) =>
                                    _buildDayCell(day),
                                todayBuilder: (context, day, _) =>
                                    _buildDayCell(
                                  day,
                                  bgColor: Colors.grey.withValues(alpha: 0.15),
                                  textColor: Colors.black,
                                ),
                                selectedBuilder: (context, day, _) =>
                                    _buildDayCell(day, isSelected: true),
                                outsideBuilder: (context, day, _) =>
                                    _buildDayCell(day,
                                        textColor: Colors.black38),
                                markerBuilder: (context, date, dayItems) {
                                  if (dayItems.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  final maxMarkers = _isFullMonth ? 5 : 3;
                                  final showText =
                                      _viewState != _ViewState.weekWithList;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children:
                                          dayItems.take(maxMarkers).map((item) {
                                        final Color baseColor;
                                        final String label;
                                        final bool isClass;

                                        if (item is ClassModel) {
                                          baseColor = Color(item.colorValue);
                                          label = item.courseName;
                                          isClass = true;
                                        } else if (item is EventModel) {
                                          baseColor = Color(item.colorValue);
                                          label = item.title;
                                          isClass = false;
                                        } else {
                                          return const SizedBox.shrink();
                                        }

                                        return Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 1),
                                          height: 6,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: isClass
                                                ? baseColor
                                                    .withValues(alpha: 0.2)
                                                : baseColor,
                                            border: isClass
                                                ? Border.all(
                                                    color: baseColor, width: 1)
                                                : null,
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                          child: showText
                                              ? Center(
                                                  child: Text(
                                                    label,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.clip,
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 4.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                )
                                              : null,
                                        );
                                      }).toList(),
                                    ),
                                  );
                                },
                              ),
                            ),

                            if (!_isFullMonth)
                              Expanded(
                                child: _buildEventList(selectedDay, dayItems),
                              ),
                          ],
                        ),
                      );
                    },
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
