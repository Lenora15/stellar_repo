import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

//this is where notes.dart will take you when you go to create a new note. 
// this will also be what interacts with the database to create a new note and save it.

class NoteCreatorPage extends StatefulWidget {
  //const NoteCreatorPage({super.key});

  @override
  State<NoteCreatorPage> createState() => _NoteCreatorPageState();

  final String? noteId;
  final String? initialTitle;
  final String? initialContent;
  final int? initialColor;

  const NoteCreatorPage({
    super.key,
    this.noteId,
    this.initialColor,
    this.initialContent,
    this.initialTitle
  });
}

class _NoteCreatorPageState extends State<NoteCreatorPage> {
  late TextEditingController _titleController = TextEditingController();
  late TextEditingController _contentController = TextEditingController();

  //default color
  late int _selectedColor;

  //determining the colors
  //add more colors later --> current ones for testing purposes
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
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController = TextEditingController(text: widget.initialContent ?? '');
    //value is depreciated, used .toARGB32() instead. test to see if works properly
    _selectedColor = widget.initialColor ?? _noteColors[0].toARGB32();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    String title = _titleController.text;
    String content = _contentController.text;
  
    //give note the name "untitled" if not given a name by the user
    if(title.isEmpty) {
      title = "Untitled";
    }

    //communication with the database
    final db = FirebaseFirestore.instance;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    //deny if no user
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to save notes.'))
      );
      return;
    }

    if (mounted) {
        Navigator.pop(context); 
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved!'), duration: Duration(seconds: 1)),
        );
      }

    final noteData = {
      'userID' : uid,
      'title' : title,
      'content' : content,
      'color' : _selectedColor,
      //timestamp doesnt change after editing
      if (widget.noteId == null) 'timestamp' : FieldValue.serverTimestamp(),
      'lastEdited' : FieldValue.serverTimestamp(),
    };

    //making sure note saved successfully
    try {
      if (widget.noteId == null){
        await db.collection('notes').add(noteData);

      } else {

        await db.collection('notes').doc(widget.noteId).update(noteData);
      }
    } catch (e) {
      if (mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save note: ${e.toString()}'),
            action: SnackBarAction(label: 'Retry', onPressed: _saveNote),
          )
        );
      }
    }
  }
   
//building the UI
@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context)
        ),
        actions: [
          TextButton(
            onPressed: _saveNote,
            child: const Text(
              'Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18,)
              )
            )
        ]
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        child: Column(
          children:[
            // Color Picker
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
                      onTap: () => setState(() => _selectedColor = color.value),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            //review color.value. it is depreciated
                            color: _selectedColor == color.value ? Colors.black87 : Colors.transparent,
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
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        border: InputBorder.none,
                      )
                    ),
                    TextField(
                      controller: _contentController,
                      maxLines: null,
                      style: const TextStyle(fontSize: 18, color: Colors.black87),
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
        ),
      )
    );
  }
}