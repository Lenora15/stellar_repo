import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String lastMessage;

  ConversationModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessage,
  });

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      id: doc.id,
      title: data['title'] ?? 'New Chat',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: data['lastMessage'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastMessage': lastMessage,
    };
  }
}
