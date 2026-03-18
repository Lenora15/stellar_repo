import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

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


  Future<void> _saveNote() async {
    String title = _titleController.text;
    String content = _contentController.text;
  
    //give note the name "untitled" if not given a name by the user
    if(title.isEmpty) {
      title = "Untitled";
    }

    //communication with the database
    final db = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: '(default)' );
    
    //make sure the note saves successfully
    try{
      await db.collection('notes').add({
      'userID': FirebaseAuth.instance.currentUser?.uid,
      'title': title,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (mounted){
      Navigator.pop(context);
    }

    } catch (e) {
      print("Error saving note: $e");

      //display error to the user
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save note: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Retry',

              //attempt to save note again
              onPressed: _saveNote, 
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context)
        ),
        actions: [
          TextButton(
            onPressed: _saveNote,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18,))
          )
        ]
      ),
      //add ability to color code notes upon creation.
      //modifications will need to be possible to edit after creation as well. possibly in different file
      body: Column(
        children:[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ListView(
                children: [
                  const SizedBox(height: 10),

                  //Title
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                    decoration: const InputDecoration(
                      hintText: 'Title',
                      border: InputBorder.none,
                    )
                  ),

                  //content
                  TextField(
                    controller: _contentController,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      hintText: 'Write your note here...',
                      hintStyle: TextStyle(fontStyle: FontStyle.italic),
                      border: InputBorder.none,
                    ),
                  )
                ]
              )
            )
          )
        ],
      )
    );
  }
}