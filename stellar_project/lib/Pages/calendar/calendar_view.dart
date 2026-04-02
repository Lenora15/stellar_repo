import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';


final calendarFirestore = FirebaseFirestore.instanceFor(
  app: Firebase.app(),
  databaseId: 'calendar-info'
);