import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../themes/app_themes.dart';
import 'calendar/models/class_model.dart';
import 'calendar/models/event_model.dart';
import 'calendar/models/reminder_model.dart';
import 'calendar/services/database_service.dart';
import 'creator_screens/note_creator.dart';

class _ScheduleEntry {
  final String type;
  final String title;
  final DateTime start;
  final DateTime end;
  final Color color;

  _ScheduleEntry({
    required this.type,
    required this.title,
    required this.start,
    required this.end,
    required this.color,
  });
}

DateTime _parseClassTime(String timeStr, DateTime date) {
  try {
    final parsed = DateFormat('h:mm a').parse(timeStr);
    return DateTime(date.year, date.month, date.day, parsed.hour, parsed.minute);
  } catch (_) {
    return date;
  }
}

String _greeting() {
  final h = DateTime.now().hour;
  if (h >= 5 && h < 12) return 'Good Morning';
  if (h >= 12 && h < 17) return 'Good Afternoon';
  if (h >= 17 && h < 21) return 'Good Evening';
  return 'Good Night';
}

String _ordinalDay(int day) {
  if (day >= 11 && day <= 13) return '${day}th';
  switch (day % 10) {
    case 1:
      return '${day}st';
    case 2:
      return '${day}nd';
    case 3:
      return '${day}rd';
    default:
      return '${day}th';
  }
}

String _formatCountdown(Duration d) {
  if (d.inMinutes < 1) return 'Starting now';
  if (d.inHours < 1) return '${d.inMinutes}m';
  final h = d.inHours;
  final m = d.inMinutes % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

bool _isSkippedToday(ClassModel c, DateTime now) {
  final s =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return c.skippedDays.contains(s);
}

class HomeContent extends StatefulWidget {
  final VoidCallback? onViewCalendar;

  const HomeContent({super.key, this.onViewCalendar});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late final String _uid;
  late final DatabaseService _db;
  String? _selectedNoteId;
  String _firstName = '';

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser!.uid;
    _db = DatabaseService(uid: _uid);
    _loadFirstName();
  }

  Future<void> _loadFirstName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('user-info')
          .doc(_uid)
          .get();
      if (doc.exists && mounted) {
        final name =
            (doc.data() as Map<String, dynamic>)['firstName'] as String? ?? '';
        setState(() => _firstName = name);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final themeData = AppThemes.getThemeForTimeOfDay();
    final isDark = themeData.theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return SafeArea(
      child: StreamBuilder<List<ClassModel>>(
        stream: _db.allClasses,
        builder: (ctx, classSnap) => StreamBuilder<List<EventModel>>(
          stream: _db.allEvents,
          builder: (ctx, eventSnap) => StreamBuilder<List<ReminderModel>>(
            stream: _db.allReminders,
            builder: (ctx, reminderSnap) {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);

              final classes = (classSnap.data ?? [])
                  .where((c) =>
                      c.daysOfWeek.contains(now.weekday) &&
                      !_isSkippedToday(c, now))
                  .toList();
              final events = (eventSnap.data ?? [])
                  .where((e) => isSameDay(e.startDateTime, today))
                  .toList();
              final reminders = (reminderSnap.data ?? [])
                  .where((r) => isSameDay(r.dateTime, today))
                  .toList();

              final schedule = <_ScheduleEntry>[
                for (final c in classes)
                  _ScheduleEntry(
                    type: 'class',
                    title: c.courseName,
                    start: _parseClassTime(c.startTime, now),
                    end: _parseClassTime(c.endTime, now),
                    color: Color(c.colorValue),
                  ),
                for (final e in events)
                  _ScheduleEntry(
                    type: 'event',
                    title: e.title,
                    start: e.startDateTime,
                    end: e.endDateTime,
                    color: Color(e.colorValue),
                  ),
                for (final r in reminders)
                  _ScheduleEntry(
                    type: 'reminder',
                    title: r.title,
                    start: r.dateTime,
                    end: r.dateTime.add(const Duration(minutes: 15)),
                    color: const Color(0xFF9C27B0),
                  ),
              ]..sort((a, b) => a.start.compareTo(b.start));

              final nextUp =
                  schedule.where((s) => s.start.isAfter(now)).firstOrNull;

              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreeting(textColor),
                    const SizedBox(height: 18),
                    _NextUpCard(
                      nextUp: nextUp,
                      now: now,
                    ),
                    const SizedBox(height: 22),
                    _QuickNotesWidget(
                      uid: _uid,
                      selectedNoteId: _selectedNoteId,
                      onNoteSelected: (id) =>
                          setState(() => _selectedNoteId = id),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _TodayScheduleWidget(
                      schedule: schedule,
                      isDark: isDark,
                      onViewAll: widget.onViewCalendar,
                    ),
                    const SizedBox(height: 90),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(Color textColor) {
    final now = DateTime.now();
    final dayName = DateFormat('EEE').format(now);
    final month = DateFormat('MMM').format(now);
    final ordDay = _ordinalDay(now.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _firstName.isNotEmpty
              ? '${_greeting()}, $_firstName.'
              : '${_greeting()}.',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: textColor,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Today is $dayName, $month $ordDay',
          style: TextStyle(
            fontSize: 15,
            color: textColor.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

}

// --- Next Up Card ---
class _NextUpCard extends StatelessWidget {
  final _ScheduleEntry? nextUp;
  final DateTime now;

  const _NextUpCard({
    required this.nextUp,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8AB4F8),
            Color(0xFFA07CF5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8AB4F8),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: nextUp == null ? _buildEmpty() : _buildEntry(nextUp!),
    );
  }

  Widget _buildEmpty() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'No more classes for today!',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6),
        Text(
          "You're all clear for now",
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildEntry(_ScheduleEntry entry) {
    final countdown = entry.start.difference(now);
    final timeStr = DateFormat.jm().format(entry.start);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Next Up:',
          style: TextStyle(
              color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          '${entry.title} – $timeStr',
          style: const TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const Spacer(),
        Row(
          children: [
            const Icon(Icons.access_time_rounded,
                color: Colors.white70, size: 18),
            const SizedBox(width: 6),
            Text(
              _formatCountdown(countdown),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}

// --- Quick Notes Widget ---
class _QuickNotesWidget extends StatelessWidget {
  final String uid;
  final String? selectedNoteId;
  final void Function(String?) onNoteSelected;
  final bool isDark;

  const _QuickNotesWidget({
    required this.uid,
    required this.selectedNoteId,
    required this.onNoteSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notes')
          .where('userID', isEqualTo: uid)
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];

        final sorted = [...docs]..sort((a, b) {
            final aTs = (a.data() as Map)['timestamp'];
            final bTs = (b.data() as Map)['timestamp'];
            if (aTs == null || bTs == null) return 0;
            return (bTs as Timestamp).compareTo(aTs as Timestamp);
          });

        QueryDocumentSnapshot? displayDoc;
        if (selectedNoteId != null) {
          try {
            displayDoc = sorted.firstWhere((d) => d.id == selectedNoteId);
          } catch (_) {}
        }
        displayDoc ??= sorted.isNotEmpty ? sorted.first : null;

        final cardColor = isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.88);
        final titleColor = isDark ? Colors.white : Colors.black87;
        final bodyColor =
            isDark ? Colors.white.withValues(alpha: 0.82) : Colors.black87;
        final mutedColor =
            isDark ? Colors.white.withValues(alpha: 0.35) : Colors.black38;
        final dividerColor = isDark
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.black.withValues(alpha: 0.1);

        return GestureDetector(
          onLongPress: () => _showNotePicker(context, sorted),
          onTap: () {
            final doc = displayDoc;
            if (doc == null) return;
            final d = doc.data() as Map<String, dynamic>;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NoteCreatorPage(
                  noteId: doc.id,
                  initialTitle: d['title'],
                  initialContent: d['content'],
                  initialColor: d['color'],
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Quick Notes',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: titleColor),
                    ),
                    const Spacer(),
                    Icon(Icons.sticky_note_2_outlined,
                        size: 18, color: mutedColor),
                  ],
                ),
                Divider(color: dividerColor, height: 22),
                if (displayDoc == null)
                  Text(
                    'Long press to select a note',
                    style:
                        TextStyle(color: mutedColor, fontSize: 14, height: 1.5),
                  )
                else
                  ..._buildNoteContent(
                    displayDoc.data() as Map<String, dynamic>,
                    bodyColor,
                    mutedColor,
                  ),
                const SizedBox(height: 8),
                Text(
                  'Hold to change note',
                  style: TextStyle(color: mutedColor, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildNoteContent(
    Map<String, dynamic> note,
    Color bodyColor,
    Color mutedColor,
  ) {
    final content = note['content'] as String? ?? '';
    final allLines =
        content.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final showLines = allLines.take(5).toList();

    return [
      for (final line in showLines)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ',
                  style: TextStyle(color: bodyColor, fontSize: 15, height: 1.4)),
              Expanded(
                child: Text(
                  line.trim(),
                  style: TextStyle(color: bodyColor, fontSize: 15, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      if (allLines.length > 5)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text('…', style: TextStyle(color: mutedColor, fontSize: 15)),
        ),
    ];
  }

  void _showNotePicker(
      BuildContext context, List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No notes yet. Create a note in the Notes tab!')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: const [
                  Text('Select a Note',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final isSelected = docs[i].id == selectedNoteId;
                  return ListTile(
                    leading: const Icon(Icons.sticky_note_2_outlined),
                    title: Text(d['title'] ?? 'Untitled'),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.blue)
                        : null,
                    onTap: () {
                      onNoteSelected(docs[i].id);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// --- Today's Schedule Widget ---
class _TodayScheduleWidget extends StatelessWidget {
  final List<_ScheduleEntry> schedule;
  final bool isDark;
  final VoidCallback? onViewAll;

  const _TodayScheduleWidget({
    required this.schedule,
    required this.isDark,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.88);
    final titleColor = isDark ? Colors.white : Colors.black87;
    final mutedColor =
        isDark ? Colors.white.withValues(alpha: 0.35) : Colors.black38;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Today's Schedule",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: titleColor),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onViewAll,
                child: Icon(Icons.chevron_right, color: mutedColor, size: 22),
              ),
            ],
          ),
          Divider(color: dividerColor, height: 22),
          if (schedule.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nothing scheduled for today',
                style: TextStyle(color: mutedColor, fontSize: 14),
              ),
            )
          else
            ...schedule.map(
              (item) => _ScheduleRow(item: item, isDark: isDark),
            ),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final _ScheduleEntry item;
  final bool isDark;

  const _ScheduleRow({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat.jm().format(item.start);
    final timeColor =
        isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black54;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor =
        isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black38;

    final typeLabel = item.type == 'class'
        ? 'Class'
        : item.type == 'event'
            ? 'Event'
            : 'Reminder';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              timeStr,
              style: TextStyle(
                  color: timeColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            width: 3,
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                      color: titleColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  typeLabel,
                  style: TextStyle(color: subtitleColor, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
