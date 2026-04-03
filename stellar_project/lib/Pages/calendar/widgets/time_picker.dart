import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StellarTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;

  const StellarTimePicker({super.key, required this.initialTime});


  static Future<TimeOfDay?> show(BuildContext context, {required TimeOfDay initialTime}) {
    return showDialog<TimeOfDay>(
      context: context,
      barrierColor: Colors.black87.withOpacity(0.6),
      builder: (context) => StellarTimePicker(initialTime: initialTime),
    );
  }

  @override
  State<StellarTimePicker> createState() => _StellarTimePickerState();
}

class _StellarTimePickerState extends State<StellarTimePicker> {
  late int _selectedHour;
  late int _selectedMinute;
  late int _selectedAmPm;

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late FixedExtentScrollController _amPmController;

  @override
  void initState() {
    super.initState();
    
  
    int hour = widget.initialTime.hour;
    _selectedAmPm = hour >= 12 ? 1 : 0; 
    _selectedHour = hour % 12;
    if (_selectedHour == 0) _selectedHour = 12; 
    _selectedMinute = widget.initialTime.minute;

    _hourController = FixedExtentScrollController(initialItem: _selectedHour - 1);
    _minuteController = FixedExtentScrollController(initialItem: _selectedMinute);
    _amPmController = FixedExtentScrollController(initialItem: _selectedAmPm);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _amPmController.dispose();
    super.dispose();
  }

  void _returnSelectedTime() {
    int finalHour = _selectedHour;
    if (_selectedAmPm == 1 && finalHour != 12) finalHour += 12; 
    if (_selectedAmPm == 0 && finalHour == 12) finalHour = 0;

    Navigator.pop(context, TimeOfDay(hour: finalHour, minute: _selectedMinute));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40), 
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0), 
          child: Container(
            height: 280,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1), 
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Select Time",
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 18, 
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.2,
                      ),
                    ),
                    GestureDetector(
                      onTap: _returnSelectedTime,
                      child: const Text(
                        "Done",
                        style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),

                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 60,
                        child: CupertinoPicker(
                          scrollController: _hourController,
                          itemExtent: 40,

                          selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(background: Colors.transparent),
                          onSelectedItemChanged: (index) => _selectedHour = index + 1,
                          children: List.generate(12, (index) => Center(
                            child: Text("${index + 1}", style: const TextStyle(color: Colors.white, fontSize: 24)),
                          )),
                        ),
                      ),
                      
                      const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text(
                            ":", 
                            style: TextStyle(color: Colors.white54, fontSize: 24),
                          ),
                        ),
                      SizedBox(
                        width: 60,
                        child: CupertinoPicker(
                          scrollController: _minuteController,
                          itemExtent: 40,
                          selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(background: Colors.transparent),
                          onSelectedItemChanged: (index) => _selectedMinute = index,
                          children: List.generate(60, (index) => Center(
                            child: Text(
                              index.toString().padLeft(2, '0'),
                              style: const TextStyle(color: Colors.white, fontSize: 24),
                            ),
                          )),
                        ),
                      ),

                      const SizedBox(width: 15),

                      SizedBox(
                        width: 60,
                        child: CupertinoPicker(
                          scrollController: _amPmController,
                          itemExtent: 40,
                          selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(background: Colors.transparent),
                          onSelectedItemChanged: (index) => _selectedAmPm = index,
                          children: const [
                            Center(child: Text("AM", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w300))),
                            Center(child: Text("PM", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w300))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}