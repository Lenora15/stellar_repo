import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'services/database_service.dart';

import 'year_view.dart';
import 'month_week_view.dart';
import 'day_view.dart';

import 'calendar_drawer.dart';
import 'widgets/creator_box.dart';

//had claude remove some redundencies

enum CalendarView { year, month, week, day, reminders }

class CalendarHost extends StatefulWidget {
  const CalendarHost({super.key});

  @override
  State<CalendarHost> createState() => _CalendarHostState();
}

class _CalendarHostState extends State<CalendarHost> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  CalendarView _currentView = CalendarView.month;
  DateTime _focusedDay = DateTime.now();
  bool _showSchedule = true;

  late DatabaseService _dbService;
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService(uid: _uid);
  }

  void _changeView(CalendarView newView) {
    setState(() {
      _currentView = newView;
    });
    Navigator.pop(context);
  }

  void _showCreatorBox() {
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
                        color: Colors.white.withValues(alpha: 0.3), width: 1.5)),
              ),
              child: CreatorBox(
                dbService: _dbService,
                initialDate: _focusedDay,
              ),
            ),
          ),
        );
      },
    );
  }

Widget _buildCurrentView() {
  switch (_currentView) {
    case CalendarView.year:
      return YearView(focusedDay: _focusedDay);
    case CalendarView.day:
      return DayView(
        focusedDay: _focusedDay,
        onDayChanged: (newDate) {
          setState(() => _focusedDay = newDate);
        },
      );
    case CalendarView.month:
      return MonthWeekView(
        focusedDay: _focusedDay,
        showSchedule: _showSchedule,
        onPageChanged: (newDate) {
          setState(() => _focusedDay = newDate);
        },
      );
    case CalendarView.week:
      return MonthWeekView(
        focusedDay: _focusedDay,
        showSchedule: _showSchedule,
        locked: true,
        onPageChanged: (newDate) {
          setState(() => _focusedDay = newDate);
        },
      );
    case CalendarView.reminders:
      return MonthWeekView(
        focusedDay: _focusedDay,
        showSchedule: false,
        locked: true,
        remindersOnly: true,
        onPageChanged: (newDate) {
          setState(() => _focusedDay = newDate);
        },
      );
  }
}

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,

      drawer: CalendarDrawer(
        currentView: _currentView,
        onViewChanged: _changeView,
        showSchedule: _showSchedule,
        onScheduleToggle: (val) => setState(() => _showSchedule = val),
      ),

      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, size: 28, color: Colors.white),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '${DateFormat('MMMM').format(_focusedDay).toUpperCase()}  ${_focusedDay.year}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 4.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentView(),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 10),
        child: FloatingActionButton(
          onPressed: _showCreatorBox,
          backgroundColor: Colors.white.withValues(alpha: 0.5),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
