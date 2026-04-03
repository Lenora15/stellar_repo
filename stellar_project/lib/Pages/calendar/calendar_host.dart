import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'services/database_service.dart';
import 'models/event_model.dart';
import 'models/class_model.dart';
import 'models/reminder_model.dart';


import 'year_view.dart';
import 'month_week_view.dart';
import 'day_view.dart';

import 'calendar_drawer.dart';
import 'widgets/creator_box.dart';
import 'widgets/event_item.dart';

enum CalendarView { year, month, week, day }

class CalendarHost extends StatefulWidget {
  const CalendarHost({super.key});

  @override
  State<CalendarHost> createState() => _CalendarHostState();
}

class _CalendarHostState extends State<CalendarHost> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  CalendarView _currentView = CalendarView.month; 
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
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
                color: Colors.black.withOpacity(0.5), 
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.5)),
              ),
              child: CreatorBox(
                dbService: _dbService,
                initialDate: _selectedDay,
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
        return DayView(focusedDay: _focusedDay);
      case CalendarView.month:
      case CalendarView.week:
      default:
        return MonthWeekView(
          focusedDay: _focusedDay,
          isWeekFormat: _currentView == CalendarView.week,
          showSchedule: _showSchedule,
          onPageChanged: (newDate) {
            setState(() {
              _focusedDay = newDate;
              _selectedDay = newDate;
            });
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
        child: Stack(
          children: [
            Column(
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
                            DateFormat('MMMM').format(_focusedDay).toUpperCase(),
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
                
                if (_currentView == CalendarView.month || _currentView == CalendarView.week)
                  const SizedBox(height: 140), 
              ],
            ),


            if (_currentView == CalendarView.month || _currentView == CalendarView.week)
              Align(
                alignment: Alignment.bottomCenter,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                    child: Container(
                      height: 160, 
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            height: 4,
                            width: 40,
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                          ),
                          
                          Expanded(
                            child: StreamBuilder<List<EventModel>>(
                              stream: _dbService.allEvents,
                              builder: (context, eventSnapshot) {
                                return StreamBuilder<List<ReminderModel>>(
                                  stream: _dbService.allReminders,
                                  builder: (context, reminderSnapshot) {
                                    return StreamBuilder<List<ClassModel>>(
                                      stream: _dbService.allClasses,
                                      builder: (context, classSnapshot) {
                                        List<dynamic> combinedList = [];
                                        
                                        if (eventSnapshot.hasData) {
                                          combinedList.addAll(eventSnapshot.data!.where((e) => 
                                            e.startDateTime.year == _selectedDay.year &&
                                            e.startDateTime.month == _selectedDay.month &&
                                            e.startDateTime.day == _selectedDay.day));
                                        }
                                        
                                        if (reminderSnapshot.hasData) {
                                          combinedList.addAll(reminderSnapshot.data!.where((r) => 
                                            r.dateTime.year == _selectedDay.year &&
                                            r.dateTime.month == _selectedDay.month &&
                                            r.dateTime.day == _selectedDay.day));
                                        }

                                        if (_showSchedule && classSnapshot.hasData) {
                                          combinedList.addAll(classSnapshot.data!.where((c) => 
                                            c.daysOfWeek.contains(_selectedDay.weekday)));
                                        }

                                        if (combinedList.isEmpty) {
                                          return const Center(child: Text("No items for today", style: TextStyle(color: Colors.white38)));
                                        }

                                        return ListView.builder(
                                          itemCount: combinedList.length,
                                          itemBuilder: (context, index) {
                                            return EventItem(
                                              item: combinedList[index], 
                                              dbService: _dbService,
                                              selectedDate: _selectedDay,
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70.0), 
        child: FloatingActionButton(
          onPressed: _showCreatorBox, 
          backgroundColor: Colors.blueAccent,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}



/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/database_service.dart';
import 'models/event_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:intl/intl.dart';



class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late DatabaseService _dbService;
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService(uid: _uid);
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(

      //come back to this
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      drawer: const Drawer(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 10.0, 8.0, 20.0),
                 child: Row(
                   children: [
                     IconButton(
                       icon: const Icon(Icons.menu),
                       onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                     ),
                     Expanded(
                       child: Center(
                         child: Text(
                           "${_focusedDay.month.toString().toUpperCase()} ${_focusedDay.year}",
                           style: const TextStyle(
                             fontSize: 20,
                             fontWeight: FontWeight.w200,
                             letterSpacing: 2,
                           ),
                         ),
                       ),
                     ),
                     const SizedBox(width: 48),
                    ],
                  ),
                ),
              
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0), 
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                headerVisible: false,


                daysOfWeekHeight: 40,
                calendarBuilders: CalendarBuilders(
                  dowBuilder: (context, day) {
                    final text = const ['S', 'M', 'T', 'W', 'T', 'F', 'S'][day.weekday % 7];
                    return Center(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600, 
                        ),
                      ),
                    );
                  },
                ),

                // Interactions
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },

                // Clean Grid Styling
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false, 
                  defaultTextStyle: const TextStyle(fontSize: 16),
                  weekendTextStyle: const TextStyle(fontSize: 16),
                  
                  // Today's marker
                  todayDecoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  
                  // Selected Day marker
                  selectedDecoration: const BoxDecoration(
                    color: Colors.blueAccent, 
                    shape: BoxShape.circle,
                  ),
                  markersAlignment: Alignment.bottomCenter,
                ),
              ),
            ),

            const SizedBox(height: 10),


            Expanded(
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (details.delta.dy < -10 && _calendarFormat == CalendarFormat.month) {
                    setState(() => _calendarFormat = CalendarFormat.week);
                  }
                  
                  if (details.delta.dy > 10 && _calendarFormat == CalendarFormat.week) {
                    setState(() => _calendarFormat = CalendarFormat.month);
                  }
                },
                child: ClipRRect( 
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), 
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15), 
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                        border: Border(
                          top: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.5), 
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 15, bottom: 20),
                            height: 5,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),

                          // Content area
                          const Expanded(
                            child: Center(
                              child: Text(
                                "Day Details will appear here",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        elevation: 2,
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}*/