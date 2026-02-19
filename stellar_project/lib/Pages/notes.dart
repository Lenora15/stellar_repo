// notes page

import 'package:flutter/material.dart';
import 'creator_screens/note_creator.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();


}

class _NotesPageState extends State<NotesPage> {
  @override
  Widget build(BuildContext context) {
  return Scaffold(
      backgroundColor: (Colors.transparent),

      //implement list of notes, the titles will be called from the database
      body: ListView.builder(
          itemBuilder: (context, index) {
            return ListTile(
              title: Text('Note ${index + 1}'),
              onTap: () {
                //when user taps note, brings user to edit page. 
                
                // Handle note tap, e.g., navigate to note details
              },
            );
          },
        ),
        //giving notes the location of bottomnavbar

        //creating the add button for the notes. 
        floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 75.0),
        child: FloatingActionButton(
          // Handle add note action, e.g., navigate to note creation page
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NoteCreatorPage()),
            );
            
          },
          child: const Icon(Icons.add),
        ),
      )
    );
  }
}

