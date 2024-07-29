import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'add_event_page.dart';
import 'edit_event_page.dart';
import 'event_details_page.dart';
import '../models/event_model.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';
import '../main.dart';

class CalendarPage extends StatefulWidget {
  final User user;
  final Function(String) onError;

  CalendarPage({required this.user, required this.onError});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  List<Event> events = [];
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('th_TH', null);
    FirebaseService.getEventsStream().listen((data) {
      setState(() {
        events = data;
      });
    });
  }

  Future<void> _scheduleNotification(Event event) async {
    if (event.reminderTime != null) {
      var scheduledNotificationDateTime =
          event.reminderTime!.subtract(const Duration(days: 1));

      var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
        'your channel id',
        'your channel name',
        channelDescription: 'your channel description',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
      );
      var platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.schedule(
        event.id.hashCode,
        'Reminder: ${event.title} is tomorrow',
        event.description,
        scheduledNotificationDateTime,
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
      );
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    return events.where((event) => isSameDay(event.date, day)).toList();
  }

  List<Event> _getUpcomingEvents() {
    DateTime now = DateTime.now();
    List<Event> upcomingEvents =
        events.where((event) => event.date.isAfter(now)).toList();
    upcomingEvents.sort((a, b) => a.date.compareTo(b.date));
    return upcomingEvents;
  }

  Widget _buildEventList(List<Event> eventList) {
    return ListView.builder(
      itemCount: eventList.length,
      itemBuilder: (context, index) {
        Event event = eventList[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 4.0,
          shadowColor: Colors.black.withOpacity(0.2),
          child: ListTile(
            title: Text(
              event.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(event.description),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAttending)
                  const Icon(Icons.event_available, color: Colors.green),
                IconButton(
                  icon: const Icon(Icons.info, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EventDetailsPage(event: event)),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () async {
                    bool? result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditEventPage(user: widget.user, event: event)),
                    );
                    if (result == true) {
                      fetchEvents();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEEEEEE),
      appBar: AppBar(
        title: Text(
          'Calendar',
          style: GoogleFonts.roboto(
            textStyle: const TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: Color(0xFF00ADB5),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2010, 10, 16),
                  lastDay: DateTime.utc(2030, 3, 14),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  eventLoader: _getEventsForDay,
                  calendarStyle: CalendarStyle(
                    markersMaxCount: 1,
                    markerDecoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                Expanded(
                  child: _selectedDay == null
                      ? Center(
                          child: Text(
                            'Select a day to see events',
                            style: GoogleFonts.roboto(
                              textStyle: const TextStyle(
                                fontSize: 18.0,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        )
                      : _buildEventList(_getEventsForDay(_selectedDay!)),
                ),
                const SizedBox(height: 8.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Upcoming Events',
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildEventList(_getUpcomingEvents()),
                ),
              ],
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: FloatingActionButton(
          onPressed: () async {
            bool? result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AddEventPage(user: widget.user)),
            );
            if (result == true) {
              // Refresh events
            }
          },
          backgroundColor: Color(0xFF00ADB5),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
