import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

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

      //body will be modified later to be better looking. just for testing purposes 
      //note: plan is to have the note creator be a pop up instead of a whole new page. will modify later.
      //add ability to color code notes upon creation.
      //modifications will need to be possible to edit after creation as well. possibly in different file
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
                //add some sort of error handling a litte later. this is just for texting purposes.

                final db = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: '(default)' );
                await db.collection('notes').add({
                  'title': title,
                  'content': content,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                // back to page after saving
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