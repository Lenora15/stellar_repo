// notes page

import 'package:flutter/material.dart';
import 'creator_screens/note_creator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

//starting adding ability to select note
class _NotesPageState extends State<NotesPage>{
  //search and sortby holders
  String _search = "";
  String _sortBy = "Newest";

//selection
  bool _isSelectionMode = false;
  final Set<String> _selectedNoteIds = {};

  //Toggles selection for a specific note
  void _toggleSelection(String noteId) {
    setState(() {
      if (_selectedNoteIds.contains(noteId)) {
        _selectedNoteIds.remove(noteId);
        //Exit selection mode if no notes are selected
        if (_selectedNoteIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedNoteIds.add(noteId);
      }
    });
  }

  Future<void> _deleteSelectedNotes() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 39, 45, 57),
          title: const Text('Delete Notes?', style: TextStyle(color: Colors.white)),
          content: Text('Are you sure you want to delete ${_selectedNoteIds.length} notes?', 
            style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final db = FirebaseFirestore.instance;
    final batch = db.batch();

    for (String id in _selectedNoteIds) {
      batch.delete(db.collection('notes').doc(id));
    }

    await batch.commit();


    setState(() {
      _isSelectionMode = false;
      _selectedNoteIds.clear();
    });
  }
  @override
  Widget build(BuildContext context){
    //determining which user's information to show
    final currentUser = FirebaseAuth.instance.currentUser;
    final notesDB = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: '(default)');
    return Scaffold(
      backgroundColor: Colors.transparent,

      //safeArea keeps crucial UI elements visable and interactive
      body: SafeArea(
        child: Column(
          children: [
            //Search
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10
              ),
              child: _isSelectionMode
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Cancel Button
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isSelectionMode = false;
                              _selectedNoteIds.clear();
                            });
                          },
                        ),
                        // Selection Count
                        Text(
                          '${_selectedNoteIds.length} Selected',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        // Delete Button
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: _deleteSelectedNotes,
                        ),
                      ],
                    )
              : Row(
                children: [
                  //forces child of row, column to fill remaining available space
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        onChanged: (value) => setState(() => _search = value),
                        decoration: const InputDecoration(
                          icon: Icon(Icons.search, color: Colors.black),
                          hintText: "Search",
                          hintStyle: TextStyle(
                            color: Colors.black
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width:10),
                  Container(
                    decoration: BoxDecoration(
                      //test purposes change to theme colors
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NoteCreatorPage()),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
            
            //sorting
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Align(
                alignment: Alignment.centerRight,
                child: DropdownButton<String>(
                  value: _sortBy,
                  dropdownColor: Color.fromARGB(255, 32, 45, 57),
                  underline: const SizedBox(),
                  items: <String>['Newest', 'Oldest'].map((String value) { //add sort by color
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text('Sort By: $value'),
                    );
                  }).toList(),
                  onChanged: (newValue){
                    setState((){
                      _sortBy = newValue!;
                    });
                  },
                ),
              ),
            ),
            
            //Display Notes
            Expanded(
              
              //streamBuilder listens to stream of data and automatically rebuilds its UI when 
              //new data or status update is emitted by that stream
              
              child: StreamBuilder<QuerySnapshot>(
                stream: notesDB
                  .collection('notes')
                  //only display current user's notes
                  .where('userID', isEqualTo: currentUser?.uid)
                  .snapshots(),
                builder: (context, snapshot){
                    if (snapshot.hasError) {
                    return const Center(child: Text("Permission Denied or Connection Error", style: TextStyle(color: Colors.white)));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var docs = snapshot.data?.docs ?? [];

                  //filter by search
                  var filteredDocs = docs.where((doc){
                    var data = doc.data() as Map<String, dynamic>;
                    //searching by title and making sure all is in lowercase
                    var title = data['title']?.toString().toLowerCase() ?? '';
                    return title.contains(_search.toLowerCase());
                  }).toList();

                  //sort logic
                  filteredDocs.sort((a,b) {
                    //sorting by color
                    var dataA = a.data() as Map<String, dynamic>;
                    var dataB = b.data() as Map<String, dynamic>;

                    if (_sortBy == 'Color'){
                      int colorA = dataA['color'] ?? 0;
                      int colorB = dataB['color'] ?? 0;

                      return colorA.compareTo(colorB);
                    } else{
                      //sorting by newest to oldest
                      Timestamp timeA = dataA['timestamp'] ?? Timestamp.now();
                      Timestamp timeB = dataB['timestamp'] ?? Timestamp.now();
                      return _sortBy == 'Newest'
                        ? timeB.compareTo(timeA)
                        : timeA.compareTo(timeB);
                    }
                  });

                  if (filteredDocs.isEmpty){
                    return const Center(
                      child: Text("No notes found.",
                        style: TextStyle(color: Colors.black)
                      )
                    );
                  }

                  return ListView.builder(
                    padding:  const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10
                    ),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index){
                      var doc = filteredDocs[index];
                      var data = doc.data() as Map<String, dynamic>;
                      Color noteColor = Color(data['color'] ?? 0xFF8AB4F8);
                      bool isSelected = _selectedNoteIds.contains(doc.id);

                      return GestureDetector(
                          onLongPress: () {
                          if (!_isSelectionMode) {
                            setState(() {
                              _isSelectionMode = true;
                              _selectedNoteIds.add(doc.id);
                            });
                          }
                        },
                        // TAP behavior changes based on mode
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(doc.id);
                          } else {
                            // Edit note
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NoteCreatorPage(
                                  noteId: doc.id,
                                  initialTitle: data['title'],
                                  initialContent: data['content'],
                                  initialColor: data['color'],
                                ),
                              ),
                            );
                          }
                        },      
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 15),
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: isSelected 
                                ? Colors.white.withValues(alpha: 0.9) 
                                : Colors.white.withValues(alpha: 0.6),
                            border: isSelected 
                                ? Border.all(color: Colors.blueAccent, width: 2) 
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 15,
                                decoration: BoxDecoration(
                                  color: noteColor,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(15),
                                    bottomLeft: Radius.circular(15),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  data['title'] ?? 'Untitled',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_isSelectionMode)
                                Padding(
                                  padding: const EdgeInsets.only(right: 15.0),
                                  child: Icon(
                                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: isSelected ? Colors.blueAccent : Colors.black26,
                                  ),
                                )
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}