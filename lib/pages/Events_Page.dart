import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import 'package:logging/logging.dart';
import 'event_details_page.dart';
import 'edit_event_page.dart';

class EventsPage extends StatefulWidget {
  final User user;
  final Function(String) onError;

  const EventsPage({
    Key? key,
    required this.user,
    required this.onError,
  }) : super(key: key);

  @override
  EventsPageState createState() => EventsPageState();
}

class EventsPageState extends State<EventsPage> {
  final Logger _logger = Logger('EventsPage');
  List<Event> events = [];
  List<Event> filteredEvents = [];
  String selectedFilter = 'All';
  String selectedSortOrder = 'Ascending';
  int totalParticipants = 0;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('th_TH', null);
    FirebaseService.getEventsStream().listen((data) {
      setState(() {
        events = data;
        calculateTotalParticipants();
        applyFiltersAndSorting();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load events')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Applies the selected filter and sorting to the list of events
  void applyFiltersAndSorting() {
    List<Event> tempEvents = events;

    if (selectedFilter == 'Today') {
      tempEvents = tempEvents.where((event) => isToday(event.date)).toList();
    } else if (selectedFilter == 'Upcoming') {
      tempEvents = tempEvents.where((event) {
        return event.date.isAfter(DateTime.now());
      }).toList();
    }

    tempEvents.sort((a, b) {
      return selectedSortOrder == 'Ascending' ? a.date.compareTo(b.date) : b.date.compareTo(a.date);
    });

    setState(() {
      filteredEvents = tempEvents;
    });
  }

  UserModel _buildUserModel() {
    return UserModel(
      id: widget.user.uid,
      fullName: widget.user.displayName ?? 'Unknown User',
      email: widget.user.email!,
    );
  }

  /// Sets the selected sort order and applies the filter and sorting
  void _selectSortOrder(String order) {
    setState(() {
      selectedSortOrder = order;
      applyFiltersAndSorting();
    });
  }

  /// Toggles the join status for the given event
  Future<void> _toggleJoin(Event event) async {
    setState(() {
      isLoading = true;
    });

    try {
      bool isAttending =
          event.joinedUsers.any((user) => user['id'] == widget.user.uid);

      if (isAttending) {
        await FirebaseService.leaveEvent(widget.user.uid, event.id);
        setState(() {
          event.joinedUsers
              .removeWhere((user) => user['id'] == widget.user.uid);
        });
      } else {
        if (event.participants.length >= event.availableSeats) {
          widget.onError('No available seats left for this event');
          return;
        }
        await FirebaseService.joinEvent(event.id, user);
      }
      calculateTotalParticipants();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update event status')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) {
              setState(() {
                selectedFilter = result;
                applyFiltersAndSorting();
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'All',
                child: Text('All'),
              ),
              const PopupMenuItem<String>(
                value: 'Today',
                child: Text('Today'),
              ),
              const PopupMenuItem<String>(
                value: 'Upcoming',
                child: Text('Upcoming'),
              ),
              const PopupMenuItem<String>(
                value: 'Joined',
                child: Text('Joined'),
              ),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (String result) {
              setState(() {
                selectedSortOrder = result;
                applyFiltersAndSorting();
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'Ascending',
                child: Text('Ascending'),
              ),
              const PopupMenuItem<String>(
                value: 'Descending',
                child: Text('Descending'),
              ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: filteredEvents.length,
              itemBuilder: (context, index) {
                return EventCard(
                  event: filteredEvents[index],
                  user: widget.user,
                  onJoinToggle: _toggleJoin,
                );
              },
            ),
    );
  }
}

class EventCard extends StatelessWidget {
  final Event event;
  final User user;
  final Future<void> Function(Event) onJoinToggle;

  const EventCard({
    required this.event,
    required this.user,
    required this.onJoinToggle,
  });

  @override
  Widget build(BuildContext context) {
    bool isAttending =
        event.joinedUsers.any((joinedUser) => joinedUser['id'] == user.uid);

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
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            const SizedBox(height: 12.0),
            Text(
              event.title,
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              event.description,
              style: const TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16.0),
                const SizedBox(width: 4.0),
                Text(
                  event.date.toLocal().toString(),
                  style: const TextStyle(fontSize: 16.0),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16.0),
                const SizedBox(width: 4.0),
                Text(
                  event.location,
                  style: const TextStyle(fontSize: 16.0),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            if (event.joinedUsers.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Participants:',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  for (var joinedUser in event.joinedUsers.take(3))
                    Text(
                      '${joinedUser['fullName']} (${joinedUser['email']})',
                      style: const TextStyle(fontSize: 16.0),
                    ),
                  if (event.joinedUsers.length > 3)
                    Text(
                      'and ${event.joinedUsers.length - 3} more...',
                      style: const TextStyle(
                          fontSize: 16.0, fontStyle: FontStyle.italic),
                    ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Total Participants: ${event.joinedUsers.length}',
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ],
              ),
            const SizedBox(height: 12.0),
            ElevatedButton(
              onPressed: () => onJoinToggle(event),
              child: Text(isAttending ? 'Leave Event' : 'Join Event'),
            ),
          ],
        ),
      ),
    );
  }
}
