import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:intl/intl.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ChatService {
  final String uid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ChatService({required this.uid});

  CollectionReference get _conversationsRef =>
      _db.collection('chats').doc(uid).collection('conversations');

  CollectionReference _messagesRef(String conversationId) =>
      _conversationsRef.doc(conversationId).collection('messages');

  // Pulls the student's live data from Firestore to inject into the system prompt
  Future<String> _buildUserContext() async {
    final buffer = StringBuffer();

    try {
      final userDoc = await _db.collection('user-info').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final firstName = data['firstName'] ?? '';
        final lastName = data['lastName'] ?? '';
        if (firstName.isNotEmpty) buffer.writeln('Student: $firstName $lastName');
      }
    } catch (_) {}

    try {
      final classSnap = await _db
          .collection('calendar')
          .doc(uid)
          .collection('classes')
          .orderBy('position')
          .get();
      if (classSnap.docs.isNotEmpty) {
        buffer.writeln('\nCLASSES:');
        const dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        for (final doc in classSnap.docs) {
          final d = doc.data();
          final course = d['courseName'] ?? '';
          final instructor = d['instructor'] ?? '';
          final room = d['room'] ?? '';
          final start = d['startTime'] ?? '';
          final end = d['endTime'] ?? '';
          final dayNums = List<int>.from(d['daysOfWeek'] ?? []);
          final days = dayNums
              .where((n) => n >= 1 && n <= 7)
              .map((n) => dayNames[n])
              .join(', ');
          buffer.writeln('- $course | $days $start–$end | Room $room | $instructor');
        }
      }
    } catch (_) {}

    try {
      final now = DateTime.now();
      final twoWeeks = now.add(const Duration(days: 14));
      final eventSnap = await _db
          .collection('calendar')
          .doc(uid)
          .collection('events')
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(twoWeeks))
          .get();
      if (eventSnap.docs.isNotEmpty) {
        buffer.writeln('\nUPCOMING EVENTS (next 14 days):');
        final fmt = DateFormat("EEE MMM d 'at' h:mm a");
        for (final doc in eventSnap.docs) {
          final d = doc.data();
          final title = d['title'] ?? '';
          final dt = (d['dateTime'] as Timestamp?)?.toDate();
          final note = (d['note'] as String? ?? '');
          final dateStr = dt != null ? fmt.format(dt) : '';
          buffer.writeln('- $title on $dateStr${note.isNotEmpty ? ' (${note.substring(0, note.length > 60 ? 60 : note.length)})' : ''}');
        }
      }
    } catch (_) {}

    try {
      final now = DateTime.now();
      final twoWeeks = now.add(const Duration(days: 14));
      final reminderSnap = await _db
          .collection('calendar')
          .doc(uid)
          .collection('reminders')
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(twoWeeks))
          .get();
      if (reminderSnap.docs.isNotEmpty) {
        buffer.writeln('\nUPCOMING REMINDERS:');
        final fmt = DateFormat("EEE MMM d 'at' h:mm a");
        for (final doc in reminderSnap.docs) {
          final d = doc.data();
          final title = d['title'] ?? '';
          final dt = (d['dateTime'] as Timestamp?)?.toDate();
          buffer.writeln('- $title${dt != null ? ' on ${fmt.format(dt)}' : ''}');
        }
      }
    } catch (_) {}

    try {
      final notesSnap = await _db
          .collection('notes')
          .where('userID', isEqualTo: uid)
          .limit(5)
          .get();
      if (notesSnap.docs.isNotEmpty) {
        buffer.writeln('\nRECENT NOTES:');
        for (final doc in notesSnap.docs) {
          final d = doc.data();
          final title = d['title'] ?? 'Untitled';
          final content = d['content'] as String? ?? '';
          final preview = content.length > 80 ? '${content.substring(0, 80)}...' : content;
          buffer.writeln('- "$title": $preview');
        }
      }
    } catch (_) {}

    return buffer.toString();
  }

  String _buildSystemPrompt(String userContext) {
    final today = DateFormat('EEEE, MMMM d, y').format(DateTime.now());
    return '''You are Stellar AI, a dedicated academic planning assistant built into the Stellar student app. Your purpose is to help students succeed through personalized planning, focused organization, and thoughtful academic strategy.

Today is $today.

Here is this student's live academic profile pulled from their Stellar app:
$userContext
---
Your approach:
- Always reference the student's actual classes, events, and reminders when giving advice — never give generic plans
- When asked for a study plan or schedule, produce a detailed, day-by-day breakdown with specific time blocks
- Identify realistic free windows between the student's real commitments
- Break large goals into concrete, manageable daily and weekly steps
- Surface upcoming deadlines and help the student prioritize by urgency and importance
- Consider workload balance: flag when a week is overloaded and suggest redistributing effort
- Account for rest and mental health — sustainable plans outperform burnout plans
- Format plans with clear structure: bold days, bullet points, specific times
- Be encouraging, honest, and thorough — this student deserves a real plan, not a template

If you are missing context for something the student asks about, give your best advice using general academic planning principles and acknowledge what you don't know.''';
  }

  // Creates the Vertex AI generative model loaded with the student's live context
  Future<GenerativeModel> buildModel() async {
    final context = await _buildUserContext();
    final systemPrompt = _buildSystemPrompt(context);
    return FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: Content.system(systemPrompt),
    );
  }

  // --- Conversation CRUD ---

  Stream<List<ConversationModel>> get conversations {
    return _conversationsRef
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ConversationModel.fromFirestore).toList());
  }

  Future<String> createConversation() async {
    final now = Timestamp.now();
    final doc = await _conversationsRef.add({
      'title': 'New Chat',
      'createdAt': now,
      'updatedAt': now,
      'lastMessage': '',
    });
    return doc.id;
  }

  Future<void> updateConversation(
    String conversationId, {
    String? title,
    String? lastMessage,
  }) async {
    final updates = <String, dynamic>{'updatedAt': Timestamp.now()};
    if (title != null) updates['title'] = title;
    if (lastMessage != null) updates['lastMessage'] = lastMessage;
    await _conversationsRef.doc(conversationId).update(updates);
  }

  Future<void> deleteConversation(String conversationId) async {
    final messages = await _messagesRef(conversationId).get();
    final batch = _db.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_conversationsRef.doc(conversationId));
    await batch.commit();
  }

  // --- Messages ---

  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _messagesRef(conversationId)
        .orderBy('timestamp')
        .snapshots()
        .map((snap) => snap.docs.map(MessageModel.fromFirestore).toList());
  }

  Future<MessageModel> saveMessage(
    String conversationId,
    String role,
    String content,
  ) async {
    final now = DateTime.now();
    final doc = await _messagesRef(conversationId).add({
      'role': role,
      'content': content,
      'timestamp': Timestamp.fromDate(now),
    });
    return MessageModel(id: doc.id, role: role, content: content, timestamp: now);
  }
}
