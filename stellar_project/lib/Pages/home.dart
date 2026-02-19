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
          color: Colors.white.withValues(alpha:0.3),
          child: const Center(child: Text('some text')),
        ),
        const SizedBox(height: 10),
        Container(
          height: 100,
          color: Colors.white.withValues(alpha:0.3),
          child: const Center(child: Text('some text')),
        ),
       const SizedBox(height: 10),
        Container(
          height: 100,
          color: Colors.white.withValues(alpha:0.3),
          child: const Center(child: Text('some text')),
        ),
       const SizedBox(height: 10),
        Container(
          height: 100,
          color: Colors.white.withValues(alpha:0.3),
          child: const Center(child: Text('some text')),
        ),
      ]
    );
  }
}