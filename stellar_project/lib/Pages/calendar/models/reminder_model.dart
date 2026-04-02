//include: title, isAllDay?, date, time, doesRepeat? isCompleted?
import 'package:cloud_firestore/cloud_firestore.dart';
class ReminderModel{
  final String id;
  final String title;
  final DateTime dateTime;
  final bool isCompleted;
  final RecurrenceSettings? recurrence;

  //constructor
  ReminderModel({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.isCompleted,
    this.recurrence,
  });

  //refer to class_model.dart
  factory ReminderModel.fromFirestore(DocumentSnapshot doc){

    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    //if isRecurring is true, build the RecurrenceSettings object,
    //otherwise, set it to null
    bool isRecurring = data['isRecurring'] ?? false;

    return ReminderModel(
      id: doc.id,
      title: data['title'] ?? 'untitled',
      dateTime: data['dateTime'] != null ? (data['dateTime'] as Timestamp).toDate() : DateTime.now(),
      isCompleted: data['isCompleted'] ?? false,

      //only create settings if 'isRecurring' was true within the DB
      recurrence: isRecurring
      ? RecurrenceSettings.fromMap(data)
      : null,
    );
  }

  //method to convert the reminder back into a map for storage in the database
  Map<String, dynamic> toMap(){
    return {
      'title': title,
      'dateTime': Timestamp.fromDate(dateTime),
      'isCompleted': isCompleted,
      'isRecurring': recurrence != null, //indicates whether or not this reminder has recurrence settings
      if(recurrence != null) ...recurrence!.toMap(), //if there are settings, include them in the map
    };
  } 

  //allows the change of a final variable by creating a new copy
  ReminderModel copyWith({
    String? id,
    String? title,
    DateTime? dateTime,
    bool? isCompleted,
    RecurrenceSettings? recurrence,
  }){
    return ReminderModel(
      id: this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      isCompleted: isCompleted ?? this.isCompleted,
      recurrence: recurrence ?? this.recurrence,
    );
  }

  //equality check: two reminders are the same if they have the same id
  @override
  bool operator ==(Object other) => 
  identical(this, other) ||
  other is ReminderModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

//establishing settings for recurring reminders
class RecurrenceSettings{
  final String frequency;
  final int interval;
  final List<int> repeatDays;
  final DateTime? endDate;
  final List<String> skippedDates;

  //constructor
  RecurrenceSettings({
    this.frequency = 'none',
    this.interval = 1,
    this.repeatDays = const [],
    this.endDate,
    this.skippedDates = const [],
  });

  //factory constructor to create settings from the database
  factory RecurrenceSettings.fromMap(Map<String, dynamic> data){
    return RecurrenceSettings(
      frequency: data['recurrenceFrequency'] ?? 'none',
      interval: data['recurrenceInterval'] ?? 1,
      repeatDays: List<int>.from(data['recurrenceRepeatDays'] ?? []),
      endDate: data['recurrenceEndDate'] != null ? (data['recurrenceEndDate'] as Timestamp).toDate() : null,
      skippedDates: List<String>.from(data['recurrenceSkippedDates'] ?? []),
    );
  }
  
  //method to convert settings back into a map for storage in the database
  Map<String, dynamic> toMap(){
    return {
      'recurrenceFrequency': frequency,
      'recurrenceInterval': interval,
      'recurrenceRepeatDays': repeatDays,
      'recurrenceEndDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'recurrenceSkippedDates': skippedDates,
    };
  }

  //allows the change of a final variable by creating a new copy
  RecurrenceSettings copyWith({
    String? frequency,
    int? interval,
    List<int>? repeatDays,
    DateTime? endDate,
    List<String>? skippedDates,
  }){
    return RecurrenceSettings(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      repeatDays: repeatDays ?? this.repeatDays,
      endDate: endDate ?? this.endDate,
      skippedDates: skippedDates ?? this.skippedDates,
    );
  }
}