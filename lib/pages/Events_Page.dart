import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/event_model.dart';
import '../services/firebase_service.dart';
import 'event_details_page.dart';
import 'edit_event_page.dart';

class EventsPage extends StatefulWidget {
  final User user;

  EventsPage({required this.user});

  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  List<Event> events = [];
  List<Event> filteredEvents = [];
  String selectedFilter = 'All';
  String selectedSortOrder = 'Ascending';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    setState(() {
      isLoading = true;
    });
    try {
      List<Event> fetchedEvents = await FirebaseService.getEvents();
      setState(() {
        events = fetchedEvents;
        applyFiltersAndSorting();
      });
    } catch (e) {
      print('Error fetching events: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load events: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void applyFiltersAndSorting() {
    List<Event> tempEvents = events;

    if (selectedFilter == 'Today') {
      tempEvents = tempEvents.where((event) {
        return event.date.day == DateTime.now().day &&
               event.date.month == DateTime.now().month &&
               event.date.year == DateTime.now().year;
      }).toList();
    } else if (selectedFilter == 'Upcoming') {
      tempEvents = tempEvents.where((event) {
        return event.date.isAfter(DateTime.now());
      }).toList();
    }

    tempEvents.sort((a, b) {
      if (selectedSortOrder == 'Ascending') {
        return a.date.compareTo(b.date);
      } else {
        return b.date.compareTo(a.date);
      }
    });

    setState(() {
      filteredEvents = tempEvents;
    });
  }

  void _selectFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      applyFiltersAndSorting();
    });
  }

  void _selectSortOrder(String order) {
    setState(() {
      selectedSortOrder = order;
      applyFiltersAndSorting();
    });
  }

  Future<void> _joinEvent(Event event) async {
    if (!event.joinedUsers.contains(widget.user.uid)) {
      event.joinedUsers.add(widget.user.uid);
      try {
        await FirebaseService.updateEvent(event);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joined event successfully')),
        );
        fetchEvents();
      } catch (e) {
        print('Error joining event: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join event: $e')),
        );
        event.joinedUsers.remove(widget.user.uid);
      }
    }
  }

  Future<void> _cancelJoinEvent(Event event) async {
    if (event.joinedUsers.contains(widget.user.uid)) {
      event.joinedUsers.remove(widget.user.uid);
      try {
        await FirebaseService.updateEvent(event);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Canceled join successfully')),
        );
        fetchEvents();
      } catch (e) {
        print('Error canceling join event: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel join event: $e')),
        );
        event.joinedUsers.add(widget.user.uid);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Events'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: _selectFilter,
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'All',
                  child: ListTile(
                    leading: Icon(Icons.all_inclusive),
                    title: Text('All Events'),
                  ),
                ),
                PopupMenuItem(
                  value: 'Today',
                  child: ListTile(
                    leading: Icon(Icons.today),
                    title: Text('Today'),
                  ),
                ),
                PopupMenuItem(
                  value: 'Upcoming',
                  child: ListTile(
                    leading: Icon(Icons.upcoming),
                    title: Text('Upcoming'),
                  ),
                ),
              ];
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.sort),
            onSelected: _selectSortOrder,
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'Ascending',
                  child: ListTile(
                    leading: Icon(Icons.arrow_upward),
                    title: Text('Ascending'),
                  ),
                ),
                PopupMenuItem(
                  value: 'Descending',
                  child: ListTile(
                    leading: Icon(Icons.arrow_downward),
                    title: Text('Descending'),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: filteredEvents.length,
              itemBuilder: (context, index) {
                Event event = filteredEvents[index];
                bool isAttending = event.joinedUsers.contains(widget.user.uid);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (event.imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: CachedNetworkImage(
                              imageUrl: event.imageUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => Icon(Icons.error),
                            ),
                          ),
                        SizedBox(height: 12.0),
                        Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          event.description,
                          style: TextStyle(fontSize: 16.0),
                        ),
                        SizedBox(height: 8.0),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16.0),
                            SizedBox(width: 4.0),
                            Text(
                              '${event.date.toLocal()}'.split(' ')[0],
                              style: TextStyle(fontSize: 16.0),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.0),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16.0),
                            SizedBox(width: 4.0),
                            Text(
                              '${event.date.hour}:${event.date.minute}',
                              style: TextStyle(fontSize: 16.0),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.0),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16.0),
                            SizedBox(width: 4.0),
                            Text(
                              event.location,
                              style: TextStyle(fontSize: 16.0),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.0),
                        if (isAttending)
                          ElevatedButton(
                            onPressed: () => _cancelJoinEvent(event),
                            child: Text('Cancel Join'),
                          )
                        else
                          ElevatedButton(
                            onPressed: () => _joinEvent(event),
                            child: Text('Join'),
                          ),
                        SizedBox(height: 8.0),
                        Text(
                          'Joined Users:',
                          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                        ),
                        ...event.joinedUsers.map((userId) => Text(
                              userId,
                              style: TextStyle(fontSize: 16.0),
                            )),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.info, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => EventDetailsPage(event: event)),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.orange),
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
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
