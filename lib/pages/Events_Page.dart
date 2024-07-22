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
    });
  }

  void calculateTotalParticipants() {
    totalParticipants = events.fold(0, (sum, event) => sum + event.participants.length);
  }

  void applyFiltersAndSorting() {
    _logger.info('Applying filters and sorting with filter: $selectedFilter and sort order: $selectedSortOrder');
    List<Event> tempEvents = List.from(events);

    if (selectedFilter == 'Today') {
      tempEvents = tempEvents.where((event) => isToday(event.date)).toList();
    } else if (selectedFilter == 'Upcoming') {
      tempEvents = tempEvents.where((event) => event.date.isAfter(DateTime.now())).toList();
    } else if (selectedFilter == 'Joined') {
      tempEvents = tempEvents.where((event) => event.isParticipant(_buildUserModel())).toList();
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

  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.day == now.day && date.month == now.month && date.year == now.year;
  }

  Future<void> _toggleEventParticipation(Event event) async {
    try {
      final user = _buildUserModel();
      if (event.isParticipant(user)) {
        await FirebaseService.leaveEvent(event.id, user);
      } else {
        if (event.participants.length >= event.availableSeats) {
          widget.onError('No available seats left for this event');
          return;
        }
        await FirebaseService.joinEvent(event.id, user);
      }
      calculateTotalParticipants();
    } catch (e) {
      widget.onError(e.toString());
      _logger.severe('Error toggling event participation for event ${event.id} and user ${widget.user.uid}: $e');
    }
  }

  void _navigateToEventDetails(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsPage(event: event),
      ),
    );
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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: filteredEvents.length,
          itemBuilder: (context, index) {
            final event = filteredEvents[index];
            return GestureDetector(
              onTap: () => _navigateToEventDetails(event),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.all(0),
                  childrenPadding: EdgeInsets.all(16.0),
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CachedNetworkImage(
                      imageUrl: event.imageUrl,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                      imageBuilder: (context, imageProvider) => Container(
                        width: 90, // Increased width
                        height: 90, // Increased height
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    event.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(DateFormat.yMMMMd('th_TH').format(event.date)),
                  children: [
                    CachedNetworkImage(
                      imageUrl: event.imageUrl,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                      imageBuilder: (context, imageProvider) => Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        event.description,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Start: ${DateFormat('HH:mm').format(event.startTime)}',
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'End: ${DateFormat('HH:mm').format(event.endTime)}',
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Location: ${event.location}',
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Organizer: ${event.organizer}',
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Related Link: ${event.relatedLink}',
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Terms: ${event.terms}',
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Contact Info: ${event.contactInfo}',
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tags: ${event.tags}',
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Available Seats: ${event.availableSeats - event.participants.length}',
                        style: TextStyle(
                          fontSize: 14,
                          color: event.participants.length >= event.availableSeats
                              ? Colors.red
                              : Colors.black,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Participants: ${event.participants.length}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        ElevatedButton(
                          onPressed: event.participants.length < event.availableSeats
                              ? () => _toggleEventParticipation(event)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: event.isParticipant(_buildUserModel())
                                ? Colors.green
                                : Colors.blue,
                          ),
                          child: Text(
                            event.isParticipant(_buildUserModel())
                                ? 'Joined'
                                : 'Join',
                          ),
                        ),
                        if (event.isParticipant(_buildUserModel())) // Only show cancel button if user is a participant
                          ElevatedButton(
                            onPressed: () => _toggleEventParticipation(event),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: Text('Cancel'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
