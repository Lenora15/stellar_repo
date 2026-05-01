import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String role;
  final String content;
  final DateTime timestamp;

  MessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      role: data['role'] ?? 'user',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
