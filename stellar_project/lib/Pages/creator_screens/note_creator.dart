import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//this is where notes.dart will take you when you go to create a new note. 
// this will also be what interacts with the database to create a new note and save it.

class NoteCreatorPage extends StatefulWidget {
  const NoteCreatorPage({super.key});

  @override
  State<NoteCreatorPage> createState() => _NoteCreatorPageState();
}

class _NoteCreatorPageState extends State<NoteCreatorPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      //
      body: Padding(
        padding: const EdgeInsets.only(
          top: 50.0,
          left: 16.0,
          right: 16.0,
        ),

        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                String title = _titleController.text;
                String content = _contentController.text;

                // Save the note to Firestore
                await FirebaseFirestore.instance.collection('notes').add({
                  'title': title,
                  'content': content,
                  'timestamp': FieldValue.serverTimestamp(),
                });

                // Navigate back to the notes page after saving
                Navigator.pop(context);
              },
              child: const Text('Save Note'),
            ),
          ],
        ),
      ),
    );
  }
}