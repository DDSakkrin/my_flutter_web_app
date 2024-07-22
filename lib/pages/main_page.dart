import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'calendar_page.dart';
import 'events_page.dart';
import 'profile_page.dart';
import '../auth_service.dart';
import 'package:logging/logging.dart';

class MainPage extends StatefulWidget {
  final User user;

  MainPage({required this.user});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final Logger _logger = Logger('MainPage');
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _logger.info('Initializing MainPage with user: ${widget.user.email}');
    _widgetOptions = <Widget>[
      CalendarPage(user: widget.user, onError: _showErrorDialog),
      EventsPage(user: widget.user, onError: _showErrorDialog),
      ProfilePage(user: widget.user, onError: _showErrorDialog),
    ];
  }

  void _onItemTapped(int index) {
    if (mounted) {
      setState(() {
        _logger.info('Tab selected: $index');
        _selectedIndex = index;
      });
    }
  }

  void _showErrorDialog(String error) {
    if (mounted) {
      _logger.severe('Error occurred: $error');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('An error occurred: $error'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.info('Building MainPage');
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Firebase Google Sign-In'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              _logger.info('User is logging out');
              try {
                await _authService.signOut(context);
                _logger.info('User logged out successfully');
              } catch (e) {
                _logger.severe('Failed to log out: $e');
                _showErrorDialog('Failed to log out: $e');
              }
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
