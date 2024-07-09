import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
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

  /// Fetches events from Firebase and applies the selected filters and sorting
  Future<void> fetchEvents() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<Event> fetchedEvents = await FirebaseService.getEvents();

      // Check if the user has joined each event
      for (var event in fetchedEvents) {
        bool alreadyJoined =
            await FirebaseService.checkIfUserJoined(widget.user.uid, event.id);
        if (alreadyJoined) {
          UserModel? userModel = await FirebaseService.getUserDetails(
              widget.user.uid,
              widget.user.displayName ?? 'Unknown User',
              widget.user.email ?? 'unknown@example.com');

          if (userModel != null) {
            event.joinedUsers.add({
              'id': userModel.id,
              'fullName': userModel.fullName,
              'email': userModel.email,
            });
          }
        }
      }

      setState(() {
        events = fetchedEvents;
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
      return selectedSortOrder == 'Ascending'
          ? a.date.compareTo(b.date)
          : b.date.compareTo(a.date);
    });

    setState(() {
      filteredEvents = tempEvents;
    });
  }

  /// Sets the selected filter and applies the filter and sorting
  void _selectFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      applyFiltersAndSorting();
    });
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
        bool alreadyJoined =
            await FirebaseService.checkIfUserJoined(widget.user.uid, event.id);
        if (alreadyJoined) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You have already joined this event')),
          );
        } else {
          await FirebaseService.joinEvent(widget.user.uid, event.id);

          // Assuming you have user's full name and email stored in widget.user
          UserModel? userModel = await FirebaseService.getUserDetails(
              widget.user.uid,
              widget.user.displayName ??
                  'Unknown User', // Replace with actual full name
              widget.user.email ??
                  'unknown@example.com' // Replace with actual email
              );

          if (userModel != null) {
            setState(() {
              event.joinedUsers.add({
                'id': userModel.id,
                'fullName': userModel.fullName,
                'email': userModel.email,
              });
            });
          }
        }
      }
      // Applying filters and sorting after the update
      applyFiltersAndSorting();
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
            onSelected: _selectFilter,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Events')),
              const PopupMenuItem(
                  value: 'Today', child: Text('Today\'s Events')),
              const PopupMenuItem(
                  value: 'Upcoming', child: Text('Upcoming Events')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
          PopupMenuButton<String>(
            onSelected: _selectSortOrder,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Ascending', child: Text('Ascending')),
              const PopupMenuItem(
                  value: 'Descending', child: Text('Descending')),
            ],
            icon: const Icon(Icons.sort),
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
