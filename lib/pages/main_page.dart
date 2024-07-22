import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'calendar_page.dart';
import 'events_page.dart';
import 'profile_page.dart';
import '../auth_service.dart';
import '../services/notification_service.dart';
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
  final NotificationService _notificationService = NotificationService();

  late final List<Widget> _widgetOptions;
  List<Event> _upcomingEvents = []; // List to store upcoming events

  @override
  void initState() {
    super.initState();
    _logger.info('Initializing MainPage with user: ${widget.user.email}');
    _initializePageOptions();
    _loadUpcomingEvents(); // Load upcoming events
    _scheduleEventNotification();
  }

  // Initializes the list of page options for the BottomNavigationBar
  void _initializePageOptions() {
    _widgetOptions = <Widget>[
      CalendarPage(user: widget.user, onError: _showErrorDialog),
      EventsPage(user: widget.user, onError: _showErrorDialog),
      ProfilePage(user: widget.user, onError: _showErrorDialog),
    ];
  }

  // Loads upcoming events into _upcomingEvents list
  void _loadUpcomingEvents() async {
    final events = await fetchUserEvents(widget.user);
    setState(() {
      _upcomingEvents = events.where((event) => event.startTime.isAfter(DateTime.now())).toList();
    });
  }

  // Schedules notifications for upcoming user events
  void _scheduleEventNotification() async {
    try {
      final event = await _getUpcomingUserEvent();
      if (event != null) {
        DateTime scheduledDateOneMinuteBefore = event.startTime.subtract(Duration(minutes: 1));
        DateTime scheduledDateFiveMinutesBefore = event.startTime.subtract(Duration(minutes: 5));

        if (scheduledDateFiveMinutesBefore.isAfter(DateTime.now())) {
          await _notificationService.scheduleNotification(
            event.id,
            'Event Reminder: ${event.title}',
            'Your event "${event.title}" will start in 5 minutes',
            scheduledDateFiveMinutesBefore,
          );
          _logger.info('Notification scheduled successfully for event: ${event.title} (5 minutes before)');
        }

        if (scheduledDateOneMinuteBefore.isAfter(DateTime.now())) {
          await _notificationService.scheduleNotification(
            event.id + 1,
            'Event Reminder: ${event.title}',
            'Your event "${event.title}" will start in 1 minute',
            scheduledDateOneMinuteBefore,
          );
          _logger.info('Notification scheduled successfully for event: ${event.title} (1 minute before)');
        }
      }
    } catch (error) {
      _logger.severe('Error fetching events: $error');
      _showErrorDialog('Error fetching events: $error');
    }
  }

  // Retrieves the next upcoming event for the user
  Future<Event?> _getUpcomingUserEvent() async {
    try {
      final events = await fetchUserEvents(widget.user);
      final now = DateTime.now();
      for (var event in events) {
        if (event.startTime.isAfter(now)) {
          return event;
        }
      }
    } catch (e) {
      _logger.severe('Failed to fetch user events: $e');
      _showErrorDialog('Failed to fetch user events: $e');
    }
    return null;
  }

  // Handles tab selection in the BottomNavigationBar
  void _onItemTapped(int index) {
    setState(() {
      _logger.info('Tab selected: $index');
      _selectedIndex = index;
    });
  }

  // Displays an error dialog with a given message
  void _showErrorDialog(String error) {
    if (!mounted) return;

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

  // Handles user logout
  Future<void> _handleLogout() async {
    _logger.info('User is logging out');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(child: CircularProgressIndicator());
      },
    );

    try {
      await _authService.signOut(context);
      Navigator.of(context).pop(); // Close the loading dialog
      _logger.info('User logged out successfully');
    } catch (e) {
      Navigator.of(context).pop(); // Close the loading dialog
      _logger.severe('Failed to log out: $e');
      _showErrorDialog('Failed to log out: $e');
    }
  }

  // Shows a dialog with upcoming events and their notification times
  void _showUpcomingEventsDialog() {
    if (_upcomingEvents.isEmpty) {
      _showErrorDialog('No upcoming events found.');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Upcoming Events'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _upcomingEvents.map((event) {
                final eventTime = event.startTime;
                final notificationTimeFiveMinutesBefore = eventTime.subtract(Duration(minutes: 5));
                final notificationTimeOneMinuteBefore = eventTime.subtract(Duration(minutes: 1));

                return ListTile(
                  leading: Icon(Icons.notifications),
                  title: Text(event.title),
                  subtitle: Text(
                      'Starts at: ${eventTime.toLocal()}\n'
                      'Notification 5 mins before: ${notificationTimeFiveMinutesBefore.toLocal()}\n'
                      'Notification 1 min before: ${notificationTimeOneMinuteBefore.toLocal()}',
                  ),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _logger.info('Disposing MainPage');
    // Cancel any subscriptions or services if needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.info('Building MainPage');

    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Firebase Google Sign-In'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: _showUpcomingEventsDialog,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
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

class Event {
  final int id;
  final String title;
  final DateTime startTime;

  Event({required this.id, required this.title, required this.startTime});
}

// Replace with your actual function to fetch user-specific events
Future<List<Event>> fetchUserEvents(User user) async {
  // Implement your logic to fetch events that the user has joined
  return [
    Event(id: 1, title: "Event 1", startTime: DateTime.now().add(Duration(minutes: 10))),
    // Add more events here
  ];
}
