import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatelessWidget {
  final User user;
  final Function(String) onError;

  ProfilePage({required this.user, required this.onError});

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
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
              Text('Name: ${user.displayName ?? 'Anonymous'}', style: TextStyle(fontSize: 18)),
              Text('Email: ${user.email ?? 'No email'}', style: TextStyle(fontSize: 18)),
              SizedBox(height: 10),
              // Text('UID: ${user.uid}', style: TextStyle(fontSize: 16)),
              Text('Last Sign-in: ${dateFormat.format(user.metadata.lastSignInTime ?? DateTime.now())}', style: TextStyle(fontSize: 16)),
              Text('Creation Time: ${dateFormat.format(user.metadata.creationTime ?? DateTime.now())}', style: TextStyle(fontSize: 16)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pushReplacementNamed('/login');
                  } catch (e) {
                    onError('Failed to log out: $e');
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to log out: $e')));
                  }
                },
                child: Text('Log Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
