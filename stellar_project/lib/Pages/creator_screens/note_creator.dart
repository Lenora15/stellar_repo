import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NoteCreatorPage extends StatefulWidget {
  final String? noteId;
  final String? initialTitle;
  final String? initialContent;
  final int? initialColor;

  const NoteCreatorPage({
    super.key,
    this.noteId,
    this.initialColor,
    this.initialContent,
    this.initialTitle,
  });

  @override
  State<NoteCreatorPage> createState() => _NoteCreatorPageState();
}

class _NoteCreatorPageState extends State<NoteCreatorPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late int _selectedColor;
  String? _noteDocId;
  Timer? _saveTimer;

  final List<Color> _noteColors = [
    const Color(0xFF8AB4F8),
    const Color(0xFFC58AF9),
    const Color(0xFFFDE293),
    const Color(0xFF81C995),
    const Color(0xFFF28B82),
  ];

  @override
  void initState() {
    super.initState();
    _noteDocId = widget.noteId;
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController = TextEditingController(text: widget.initialContent ?? '');
    _selectedColor = widget.initialColor ?? _noteColors[0].toARGB32();
    _titleController.addListener(_scheduleAutosave);
    _contentController.addListener(_scheduleAutosave);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _titleController.removeListener(_scheduleAutosave);
    _contentController.removeListener(_scheduleAutosave);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _scheduleAutosave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), _autoSave);
  }

  Future<void> _autoSave() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    String title = _titleController.text.trim();
    if (title.isEmpty) title = 'Untitled';

    final db = FirebaseFirestore.instance;
    final noteData = <String, dynamic>{
      'userID': uid,
      'title': title,
      'content': _contentController.text,
      'color': _selectedColor,
      'lastEdited': FieldValue.serverTimestamp(),
    };

    try {
      if (_noteDocId == null) {
        noteData['timestamp'] = FieldValue.serverTimestamp();
        final docRef = await db.collection('notes').add(noteData);
        if (mounted) setState(() => _noteDocId = docRef.id);
      } else {
        await db.collection('notes').doc(_noteDocId).update(noteData);
      }
    } catch (_) {}
  }

  Future<void> _saveNote() async {
    _saveTimer?.cancel();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to save notes.')),
      );
      return;
    }

    String title = _titleController.text.trim();
    if (title.isEmpty) title = 'Untitled';

    final db = FirebaseFirestore.instance;
    final noteData = <String, dynamic>{
      'userID': uid,
      'title': title,
      'content': _contentController.text,
      'color': _selectedColor,
      'lastEdited': FieldValue.serverTimestamp(),
    };

    if (_noteDocId == null) {
      noteData['timestamp'] = FieldValue.serverTimestamp();
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note saved!'), duration: Duration(seconds: 1)),
      );
    }

    try {
      if (_noteDocId == null) {
        await db.collection('notes').add(noteData);
      } else {
        await db.collection('notes').doc(_noteDocId).update(noteData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save note: ${e.toString()}'),
            action: SnackBarAction(label: 'Retry', onPressed: _saveNote),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveNote,
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _noteColors.length,
                  itemBuilder: (context, index) {
                    final color = _noteColors[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedColor = color.toARGB32());
                        _scheduleAutosave();
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedColor == color.toARGB32()
                                ? Colors.black87
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: ListView(
                  children: [
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        border: InputBorder.none,
                      ),
                    ),
                    TextField(
                      controller: _contentController,
                      maxLines: null,
                      style:
                          const TextStyle(fontSize: 18, color: Colors.black87),
                      decoration: const InputDecoration(
                        hintText: 'Write your note here...',
                        hintStyle: TextStyle(fontStyle: FontStyle.italic),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
