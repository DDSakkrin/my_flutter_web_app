import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatelessWidget {
  final User user;

  ProfilePage({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (user.photoURL != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(user.photoURL!),
              )
            else
              CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
            SizedBox(height: 20),
            Text('Name: ${user.displayName ?? 'Anonymous'}'),
            Text('Email: ${user.email ?? 'No email'}'),
            // เพิ่มข้อมูลของ user ได้ที่นี่
          ],
        ),
      ),
    );
  }
}
