import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'calendar_host.dart';
import 'services/database_service.dart';
import 'models/class_model.dart';
import 'widgets/class_card.dart';

class CalendarDrawer extends StatefulWidget {
  final CalendarView currentView;
  final Function(CalendarView) onViewChanged;
  final bool showSchedule;
  final Function(bool) onScheduleToggle;

  const CalendarDrawer({
    super.key,
    required this.currentView,
    required this.onViewChanged,
    required this.showSchedule,
    required this.onScheduleToggle,
  });

  @override
  State<CalendarDrawer> createState() => _CalendarDrawerState();
}

class _CalendarDrawerState extends State<CalendarDrawer> {
  late DatabaseService _dbService;
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService(uid: _uid);
  }

  Widget _buildViewSelector(CalendarView view, String title, IconData icon) {
    final isSelected = widget.currentView == view;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blueAccent : Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blueAccent : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.white.withOpacity(0.05),
      onTap: () => widget.onViewChanged(view),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A24),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                "VIEWS",
                style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5),
              ),
            ),
            
            _buildViewSelector(CalendarView.year, "Year", Icons.calendar_today_outlined),
            _buildViewSelector(CalendarView.month, "Month", Icons.calendar_month_outlined),
            _buildViewSelector(CalendarView.week, "Week", Icons.view_week_outlined),
            _buildViewSelector(CalendarView.day, "Day", Icons.view_day_outlined),

            const Divider(color: Colors.white12, height: 30),

            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: Colors.white70),
              title: const Text("Reminders", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);

              },
            ),

            const Divider(color: Colors.white12, height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  const Text(
                    "SCHEDULE",
                    style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
                    onPressed: () {
                    },
                  ),
                  Switch(
                    value: widget.showSchedule,
                    onChanged: widget.onScheduleToggle,
                    activeColor: Colors.blueAccent,
                  ),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<List<ClassModel>>(
                stream: _dbService.allClasses,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text("No classes added.", style: TextStyle(color: Colors.white38)),
                    );
                  }

                  final classes = snapshot.data!;
                  
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    itemCount: classes.length,
                    itemBuilder: (context, index) {
                      return ClassCard(
                        classModel: classes[index],
                        dbService: _dbService,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}