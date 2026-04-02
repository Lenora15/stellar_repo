import 'package:cloud_firestore/cloud_firestore.dart';

//Using models to translate what firebase has stored into something flutter can work with. This model is for creating classes within the schedule 
//part of the app

class ClassModel{
  final String id;
  final String courseName;
  final String instructor;
  final String room;
  final List<int> daysOfWeek; //this will be represented as numbers
  final String startTime;
  final String endTime;
  final int colorValue; //user will be able to color code
  final List<String> skippedDays; //user will be able to mark a class as skipped which will put that date in this list
  final int position;

  //constructor
  ClassModel({
    required this.id,
    required this.courseName,
    required this.instructor,
    required this. room,
    required this.daysOfWeek,
    required this.startTime,
    required this.endTime,
    required this.colorValue,
    required this.skippedDays,
    required this.position
  });

  //factory named constructor 
  /* 
    This is a deserilazation method which takes raw pices of data from 
    the database and transforms them into structured dart objects that
    the app can acutally use
  */
  factory ClassModel.fromFirestore(DocumentSnapshot doc){
    Map data = doc.data() as Map<String, dynamic>;
    return ClassModel(
      id: doc.id,
      courseName: data['courseName'] ?? '',
      instructor: data['instructor'] ?? '',
      room: data['room'] ?? '',
      daysOfWeek: List<int>.from(data['daysOfWeek'] ?? []),
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      colorValue: data['color'] ?? 0xFF9C27B0,
      skippedDays: List<String>.from(data['skippedDays'] ?? []),
      position: data['position'] ?? 0,
    );
  }

  //method to convert the class back into a map for storage in the database
  Map<String, dynamic> toMap(){
    return {
      'courseName': courseName,
      'instructor': instructor,
      'room': room,
      'daysOfWeek': daysOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'color': colorValue,
      'skippedDays': skippedDays,
      'position': position,
    };
  }

  //allows the change of a final variable by creating a new copy
  ClassModel copyWith({
    String? id,
    String? courseName,
    String? instructor,
    String? room,
    List<int>? daysOfWeek,
    String? startTime,
    String? endTime,
    int? colorValue,
    List<String>? skippedDays,
    int? position,
  }){
    return ClassModel(
      id: this.id,
      courseName: courseName ?? this.courseName,
      instructor: instructor ?? this.instructor,
      room: room ?? this.room,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      colorValue: colorValue ?? this.colorValue,
      skippedDays: skippedDays ?? this.skippedDays,
      position: position ?? this.position,
     );
   }
  
  //equality check: two classes are the same if they have the same id
  @override
  bool operator ==(Object other) =>
  identical(this, other) ||
  other is ClassModel &&
    runtimeType == other.runtimeType &&
    id == other.id;

  @override
  int get hashCode => id.hashCode;
}
