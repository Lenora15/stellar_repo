import 'package:cloud_firestore/cloud_firestore.dart';

//same thing as class_model.dart

class EventModel{
  final String id;
  final String title;
  final bool isAllDay;
  final DateTime startDateTime;
  final DateTime endDateTime;

  //handles if event start and end are different
  bool get isMultiDay =>
    startDateTime.day != endDateTime.day ||
    startDateTime.month != endDateTime.month ||
    startDateTime.year != endDateTime.year;

  final String note;
  final List<int> reminderMinutes;
  final int colorValue;
  
  //handling whether or not the event is recurring
  final bool isRecurring;
  final String frequency;
  final int interval;
  final List<int> repeatDays;
  final DateTime? endDate;
  final List<String> skippedDates; 

  //constructor
  EventModel({
    required this.id,
    required this.title,
    required this.isAllDay,
    required this.startDateTime,
    required this.endDateTime,
    required this.note,
    required this.reminderMinutes,
    required this.colorValue,

    //recurring event fields
    required this.isRecurring,

    //no required because these only apply if the event is recurring
    this.frequency = 'none',
    this.interval = 1,
    this.repeatDays = const [],
    this.endDate,
    this.skippedDates = const [],
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc){
    Map data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? 'untitled',
      isAllDay: data['isAllDay'] ?? false,
      startDateTime: data['startDateTime'] != null ? (data['startDateTime'] as Timestamp).toDate() : DateTime.now(),
      endDateTime: data['endDateTime'] != null ? (data['endDateTime'] as Timestamp).toDate() : DateTime.now(),
      note: data['note'] ?? '',
      reminderMinutes: List<int>.from(data['reminderMinutes'] ?? []),
      colorValue: data['color'] ?? 0xFF2196F3,

      //recurring event fields
      isRecurring: data['isRecurring'] ?? false,
      frequency: data['frequency'] ?? 'none',
      interval: data['interval'] ?? 1,
      repeatDays: List<int>.from(data['repeatDays'] ?? []),
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
      skippedDates: List<String>.from(data['skippedDates'] ?? []),
    );
  }

  //method to convert the event back into a map for storage in the database
  Map<String, dynamic> toMap(){
    return {
      'title': title,
      'isAllDay': isAllDay,
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'note': note,
      'reminderMinutes': reminderMinutes,
      'color': colorValue,

      //recurring event fields
      'isRecurring': isRecurring,
      if(isRecurring) ...{
        'frequency': frequency,
        'interval': interval,
        'repeatDays': repeatDays,
        if(endDate != null) 'endDate': Timestamp.fromDate(endDate!),
        'skippedDates': skippedDates,
      },
    };
  }

  //allows the change of a final variable by creating a new copy
  EventModel copyWith({
    String? title,
    bool? isAllDay,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? note,
    List<int>? reminderMinutes,
    int? colorValue,

    //recurring event fields
    bool? isRecurring,
    String? frequency,
    int? interval,
    List<int>? repeatDays,
    DateTime? endDate,
    List<String>? skippedDates,
  }){
    return EventModel(
      id: id, //id should not change
      title: title ?? this.title,
      isAllDay: isAllDay ?? this.isAllDay,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      note: note ?? this.note,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      colorValue: colorValue ?? this.colorValue,

      //recurring event fields
      isRecurring: isRecurring ?? this.isRecurring,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      repeatDays: repeatDays ?? this.repeatDays,
      endDate: endDate ?? this.endDate,
      skippedDates: skippedDates ?? this.skippedDates,
    );
  }

  //equality check: two events are the same if they have the same id
  @override
  bool operator ==(Object other) =>
  identical(this, other) ||
  other is EventModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
