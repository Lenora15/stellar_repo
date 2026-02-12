import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedInedex = 0;
  
  //establishing text style for the options in the bottom navigation bar
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  
  //display selected option in the center of the page
  static const List<Widget> _widgetOptions = <Widget>[
    Text(
      'Home',
      style: optionStyle,
    ),
    Text(
      'Calendar',
      style: optionStyle,
    ),
    Text(
      'Chat',
      style: optionStyle,
    ),
    Text(
      'Notes',
      style: optionStyle,
    ),
    Text(
      'Profile',
      style: optionStyle,
    ),
  ];

  //setting selected index to item tapped in navbar
  void _onItemTapped(int index) {
    setState(() {
      _selectedInedex = index;
    });
  }
  
  //actually building the page including the navbar
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF303154),
      body: Center(child: _widgetOptions.elementAt(_selectedInedex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            backgroundColor: Color.fromARGB(255, 28, 29, 49),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
            backgroundColor: Color.fromARGB(255, 28, 29, 49),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
            backgroundColor: Color.fromARGB(255, 28, 29, 49),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note),
            label: 'Notes',
            backgroundColor: Color.fromARGB(255, 28, 29, 49),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
            backgroundColor: Color.fromARGB(255, 28, 29, 49),
          ),
        ],
        currentIndex: _selectedInedex,
        onTap: _onItemTapped,
      ),
    );
  }
} 

