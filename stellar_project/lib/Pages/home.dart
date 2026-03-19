//home page

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'authentication/login.dart';

class HomeContent extends StatelessWidget{
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    // need to use listview for widgets on the homepage. 
    // widgets will be linked to other pages, and show basic content from other pages

    //sample for testing purposes
    return ListView(
      children: [
        // FOR DEBUGGING PURPOSES ONLY
        Card(
          color: Colors.redAccent.withValues(alpha: 0.7),
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text(
              'Logout (Debug)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                // This clears the navigation stack so they can't go "back" into the home page
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ),
        const SizedBox(height:20),
        //END FOR DEBUGGING PURPOSES ONLY
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