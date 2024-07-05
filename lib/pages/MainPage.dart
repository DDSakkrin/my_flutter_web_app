import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'calendar_page.dart';
import 'events_page.dart';
import 'profile_page.dart';
import '../google_sign_in.dart';

class MainPage extends StatefulWidget {
  final User user;

  MainPage({required this.user});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      CalendarPage(user: widget.user), // ส่ง user ไปยัง CalendarPage
      EventsPage(user: widget.user),   // ส่ง user ไปยัง EventsPage (หากจำเป็น)
      ProfilePage(user: widget.user),  // ส่ง user ไปยัง ProfilePage
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Firebase Google Sign-In'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
