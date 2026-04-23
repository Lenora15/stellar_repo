import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'calendar_host.dart';
import 'services/database_service.dart';
import 'models/class_model.dart';
import 'widgets/class_card.dart';
import 'widgets/class_creator_box.dart';
import 'package:dotted_line/dotted_line.dart';

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
  bool _isEditMode = false;
  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService(uid: _uid);
  }

  //beginnings of handling calendar view for classes. when toggled on, will display classes on calendar.
  Widget _buildViewSelector(CalendarView view, String title, IconData icon) {
    final isSelected = widget.currentView == view;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.deepPurpleAccent : Colors.black),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.deepPurpleAccent : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.white,
      onTap: () => widget.onViewChanged(view),
    );
  }

//building the drawer
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                "VIEWS",
                style: TextStyle(color: Colors.black, fontSize: 12, letterSpacing: 1.5),
              ),
            ),
            
            //displaying different views for the calendar.
            _buildViewSelector(CalendarView.year, "Year", Icons.calendar_today_outlined),
            _buildViewSelector(CalendarView.month, "Month", Icons.calendar_month_outlined),
            _buildViewSelector(CalendarView.week, "Week", Icons.view_week_outlined),
            _buildViewSelector(CalendarView.day, "Day", Icons.view_day_outlined),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: DottedLine(
                dashColor: Colors.black26,
                lineThickness: 1,
                dashLength: 4,
                dashGapLength: 4,
              ),
            ),

            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: Colors.black),
              title: const Text("Reminders", style: TextStyle(color: Colors.black)),
              onTap: () => widget.onViewChanged(CalendarView.reminders),
            ),

            //separates views from schedule section of the drawer
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: DottedLine(
                dashColor: Colors.black26,
                lineThickness: 1,
                dashLength: 4,
                dashGapLength: 4,
              ),
            ),
            //actually building the schedule section of the drawer. this is for classes.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  const Text(
                    "SCHEDULE",
                    style: TextStyle(color: Colors.black, fontSize: 12, letterSpacing: 1.5),
                  ),
                  const Spacer(),
                  if (_isEditMode)
                    IconButton(
                      icon: const Icon(Icons.add_box, color: Colors.deepPurpleAccent, size: 24),
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (context) => ClassCreatorBox(dbService: _dbService),
                        );
                      },
                    ),
                  IconButton(
                    icon: Icon(_isEditMode ? Icons.check_circle : Icons.edit_outlined,
                        color: _isEditMode ? Colors.black : Colors.black, size: 22),
                    onPressed: () {
                      setState(() {
                        _isEditMode = !_isEditMode;
                      });
                    },
                  ),
                  Switch(
                    value: widget.showSchedule,
                    onChanged: widget.onScheduleToggle,
                    activeColor: Colors.deepPurpleAccent,
                  )
                ],
              ),
            ),

            //displaying classes in the schedule section of the drawer.
            Expanded(
              child: StreamBuilder<List<ClassModel>>(
                stream: _dbService.allClasses,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text("No classes added", style: TextStyle(color: Colors.black)),
                    );
                  }

                  final classes = snapshot.data!;
                  
                  if (_isEditMode) {
                    return ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      proxyDecorator: (child, index, animation,){
                        return Material(
                          color: Colors.transparent,
                          child: child,
                        );
                      },
                      itemCount: classes.length,
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final mutableClasses = List<ClassModel>.from(classes);
                        final movedClass = mutableClasses.removeAt(oldIndex);
                        mutableClasses.insert(newIndex, movedClass);

                        //update positions in database
                        for (int i = 0; i < mutableClasses.length; i++) {
                          _dbService.updateClassOrder(mutableClasses[i].id, i);
                        }
                      },
                      itemBuilder: (context, index) {
                        return Container(
                          key: ValueKey(classes[index].id),
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              //delete
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                                onPressed: () => _dbService.deleteClass(classes[index].id),
                              ),

                              //class card
                              Expanded(
                                child:
                                ClassCard(classModel: classes[index], dbService: _dbService),
                              ),

                              //edit icon
                              // Edit Icon 
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.black54),
                                onPressed: () {
                                  Navigator.pop(context);
                                  
                                  showDialog(
                                    context: context,
                                    builder: (context) => ClassCreatorBox(
                                      dbService: _dbService,
                                      existingClass: classes[index],
                                    ),
                                  );
                                },
                              ),
                              ReorderableDragStartListener(
                                index: index,
                                child: const Icon(Icons.drag_handle, color: Colors.grey),
                              ),
                              const SizedBox(width: 8),
                            ]
                          )
                        );
                      }

                    );
                  }
                  //view mode
                  else {
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      itemCount: classes.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: ClassCard(
                            classModel: classes[index],
                            dbService: _dbService,
                          )
                        );
                      }
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}