import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/database_service.dart';
import 'models/event_model.dart';
import 'package:firebase_auth/firebase_auth.dart';


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
      drawer: const Drawer(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12,31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

              //Labling days of the week
              daysOfWeekHeight: 40,
              calendarBuilders: CalendarBuilders(
                dowBuilder: (context, day) {
                  final text = ['S', 'M', 'T', 'W', 'T', 'F', 'S'][day.weekday % 7];
                  return Center(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay; // update `_focusedDay` here
                });
              },
              onPageChanged: (focuesedDay){
                _focusedDay = _focusedDay;
              },

              //grid styling
              //change withOpacity
              calendarStyle: CalendarStyle(
                defaultTextStyle: const TextStyle(color: Colors.black),
                weekendTextStyle: const TextStyle(color: Colors.black),
                todayDecoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),

                selectedDecoration: const BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                markersAlignment: Alignment.bottomCenter,
              ),
            ),

              Expanded(
                child: GestureDetector(
                  onVerticalDragUpdate: (details){
                    if (details.delta.dy < -10 && _calendarFormat == CalendarFormat.week) {
                      setState(() => _calendarFormat = CalendarFormat.month);
                    }
                    if (details.delta.dy > 10 && _calendarFormat == CalendarFormat.month) {
                      setState(() => _calendarFormat = CalendarFormat.week);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          height: 4,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        const Expanded(
                          child: Center(
                            child: Text(
                              "Day Details will appear here",
                              style: TextStyle(color: Colors.white38),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      )
      
    );
  }
}