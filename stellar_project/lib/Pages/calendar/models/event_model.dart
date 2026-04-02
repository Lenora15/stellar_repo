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
    required this.isRecurring,
    required this.colorValue,

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
      startDateTime: data[]
    );
  }

}
