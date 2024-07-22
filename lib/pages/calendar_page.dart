import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';

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
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                  color: Colors.black87,
                ),
              ),
            ),
            subtitle: Text(
              event.description,
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(
                  fontSize: 14.0,
                  color: Colors.black54,
                ),
              ),
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailsPage(event: event),
                ),
              );
              // Refresh events after details page
            },
            trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF00ADB5)),
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TableCalendar(
                    locale: 'th_TH',
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
                        color: Color(0xFF00ADB5),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: Color(0xFF00ADB5),
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Color(0xFF00ADB5).withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      weekendTextStyle: TextStyle(color: Colors.redAccent),
                      outsideDaysVisible: false,
                      todayTextStyle: TextStyle(color: Colors.black87),
                      defaultTextStyle: TextStyle(color: Colors.black87),
                      selectedTextStyle: TextStyle(color: Colors.white),
                      cellMargin: EdgeInsets.all(4.0),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: GoogleFonts.roboto(
                        textStyle: const TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00ADB5),
                        ),
                      ),
                      leftChevronIcon: const Icon(
                        Icons.chevron_left,
                        color: Color(0xFF00ADB5),
                      ),
                      rightChevronIcon: const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF00ADB5),
                      ),
                      headerPadding: EdgeInsets.symmetric(vertical: 4.0),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        color: Color(0xFF00ADB5),
                        fontWeight: FontWeight.bold,
                      ),
                      weekendStyle: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (events.isNotEmpty) {
                          return Positioned(
                            right: 1,
                            bottom: 1,
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.redAccent,
                              ),
                              width: 16.0,
                              height: 16.0,
                              child: Center(
                                child: Text(
                                  '${events.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.0,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        return null;
                      },
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
                      style: GoogleFonts.roboto(
                        textStyle: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
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
