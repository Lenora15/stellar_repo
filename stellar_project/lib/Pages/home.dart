//home page

import 'package:flutter/material.dart';

class HomeContent extends StatelessWidget{
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    // need to use listview for widgets on the homepage. 
    // widgets will be linked to other pages, and show basic content from other pages

    //sample for testing purposes
    return ListView(
      children: [
        Container(
          height: 100,
          color: Colors.blue,
          child: const Center(child: Text('Widget 1')),
        ),
        const SizedBox(height: 10),
        Container(
          height: 100,
          color: Colors.green,
          child: const Center(child: Text('Widget 2')),
        ),
       const SizedBox(height: 10),
        Container(
          height: 100,
          color: Colors.orange,
          child: const Center(child: Text('Widget 3')),
        ),
       const SizedBox(height: 10),
        Container(
          height: 100,
          color: Colors.purple,
          child: const Center(child: Text('Widget 4')),
        ),
       const SizedBox(height: 10),
        Container(
          height: 100,
          color: Colors.red,
          child: const Center(child: Text('Widget 5')),
        ),
       const SizedBox(height: 10),
       Container(
         height: 100,
         color: Colors.yellow,
         child: const Center(child: Text('Widget 6')),
       ),
       const SizedBox(height: 10),
       Container(
         height: 100,
         color: Colors.cyan,
         child: const Center(child: Text('Widget 7')),
       ),
      ]
    );
  }
}