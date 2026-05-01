import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_model.dart';
import '../models/event_model.dart';
import '../models/reminder_model.dart';

//This is a different method of working with the database than what I used for the notes
//module. I am learning a more professional way to handle the backend than what I did initially

class DatabaseService{

  //each user will have their own instance of the database service that is initialized with their unique uid. 
  //This way, all database calls made through this service will be specific to the signed in user and their data  
  final String uid;
  late final FirebaseFirestore _db;

  //constructor that initializes the database connection for the calendar info database
  DatabaseService({required this.uid}){
    _db = FirebaseFirestore.instance;
  }

  //references to the specific collections in the database that will be working with.
  CollectionReference get _reminderRef => 
      _db.collection('calendar').doc(uid).collection('reminders');
  
  CollectionReference get _classRef => 
      _db.collection('calendar').doc(uid).collection('classes');

  CollectionReference get _eventRef => 
      _db.collection('calendar').doc(uid).collection('events');



//-----REMINDER STUFF -----//

  //getting all reminders for signed in user
  Stream<List<ReminderModel>> get allReminders {
    return _reminderRef.snapshots().map((snapshot){
      return snapshot.docs.map((doc) => ReminderModel.fromFirestore(doc)).toList();
    });
  }

  //get reminder for only specified day
  Stream<List<ReminderModel>> getRemindersForDay(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    //query the database for reminders where the dateTime is between the start and end of the specified day
    return _reminderRef
      .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => ReminderModel.fromFirestore(doc)).toList();
      });
  }

  //add new reminder
  Future<DocumentReference> addReminder(ReminderModel reminder) async {
    Map<String, dynamic> reminderData = reminder.toMap();
    reminderData['userID'] = uid;
    return await _reminderRef.add(reminderData);
  }

  //update existing reminder
  Future<void> updateReminder(ReminderModel reminder) async {
    await _reminderRef.doc(reminder.id).update(reminder.toMap());
  }

  //delete reminder
  Future<void> deleteReminder(String id) async {
    await _reminderRef.doc(id).delete();
  }

  //-----CLASS STUFF -----//

  //getting all classes for signed in user based on day of the week. 
  Stream<List<ClassModel>> get allClasses {
    return _classRef.snapshots().map((snapshot){
      return snapshot.docs.map((doc) => ClassModel.fromFirestore(doc)).toList();
    });
  }

  //get classes for specific day of the week (1-7)
  Stream<List<ClassModel>> getClassesForDay(int weekday) {
    //weekday is representsed as a number 1 (Monday) through 7 (Sunday)
    return _classRef
      .orderBy('position')    
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => ClassModel.fromFirestore(doc)).toList();
      });
  }

  //adds a new class to private classes collection in database
    Future<void> addClass(ClassModel classModel) async {
    Map<String, dynamic> classData = classModel.toMap();
    classData['userID'] = uid;
    await _classRef.add(classData);
  }

    //update existing class
  Future<void> updateClass(ClassModel classModel) async {
    await _classRef.doc(classModel.id).update(classModel.toMap());
  }

  //delete class
  Future<void> deleteClass(String id) async {
    await _classRef.doc(id).delete();
  }

  //moving class pos
  Future<void> updateClassOrder(String classId, int newPosition) async {
    await _classRef.doc(classId).update({'position': newPosition});
  }


Future<void> toggleSkipClass(ClassModel classModel, DateTime date) async {
    String dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    List<String> updatedSkips = List.from(classModel.skippedDays);

    if (updatedSkips.contains(dateStr)) {
      updatedSkips.remove(dateStr);
    } else {
      updatedSkips.add(dateStr);
    }

    await _classRef.doc(classModel.id).update({'skippedDays': updatedSkips});
  }



  // -----EVENT STUFF -----//

  Stream<List<EventModel>> get allEvents {
    return _eventRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    });
  }

  //grabbing standard events for specific day
  Stream<List<EventModel>> getEventsForDay(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    //query the database for events where the dateTime is between the start and end of the specified day
    return _eventRef
      .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
      });
  }

  //adds new event to user's private events collection in database
  Future<DocumentReference> addEvent(EventModel event) async {
    Map<String, dynamic> eventData = event.toMap();
    eventData['userID'] = uid;
    return await _eventRef.add(eventData);
  }

    //update existing reminder
  Future<void> updateEvent(EventModel reminder) async {
    await _eventRef.doc(reminder.id).update(reminder.toMap());
  }

  //delete reminder
  Future<void> deleteEvent(String id) async {
    await _eventRef.doc(id).delete();
  }
}
