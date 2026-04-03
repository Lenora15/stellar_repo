import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class YearView extends StatelessWidget {
  final DateTime focusedDay;

  const YearView({super.key, required this.focusedDay});

  @override
  Widget build(BuildContext context) {
    final int currentYear = focusedDay.year;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            "$currentYear",
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w200,
              color: Colors.black,
              letterSpacing: 5.0,
            ),
          ),
        ),
        
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, 
              crossAxisSpacing: 15,
              mainAxisSpacing: 25,
              childAspectRatio: 0.7,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final monthDate = DateTime(currentYear, index + 1);
              return _buildMiniMonth(context, monthDate);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMiniMonth(BuildContext context, DateTime monthDate) {
    final String monthName = DateFormat('MMM').format(monthDate).toUpperCase();
    final int daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    final int firstWeekday = DateTime(monthDate.year, monthDate.month, 1).weekday % 7; // 0 (Sun) - 6 (Sat)

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
          child: Text(
            monthName,
            style: const TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            itemCount: firstWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstWeekday) {
                return const SizedBox.shrink();
              }
              
              final int dayNumber = index - firstWeekday + 1;
              final bool isToday = isSameDay(DateTime.now(), DateTime(monthDate.year, monthDate.month, dayNumber));

              return Center(
                child: Text(
                  "$dayNumber",
                  style: TextStyle(
                    fontSize: 8,
                    color: isToday ? Colors.blueAccent : Colors.white70,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}