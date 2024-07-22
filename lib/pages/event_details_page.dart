import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import 'edit_event_page.dart';
import 'auth_dialog.dart';

class EventDetailsPage extends StatefulWidget {
  final Event event;

  EventDetailsPage({required this.event});

  @override
  _EventDetailsPageState createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  User? _currentUser;
  late Event _event;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _event = widget.event;
  }

  Future<void> _deleteEvent(BuildContext context) async {
    try {
      await FirebaseService.deleteEvent(_event.id, imageUrl: _event.imageUrl);
      Navigator.pop(context, true); // Navigate back after deletion
    } catch (e) {
      print('Error deleting event: $e');
      _showErrorDialog(context, 'Failed to delete event. Please try again later.');
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AuthDialog(
          title: 'Delete Event',
          action: 'Delete',
        );
      },
    );

    if (result == true) {
      await _deleteEvent(context);
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToEditEventPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEventPage(user: _currentUser!, event: _event),
      ),
    );

    if (result == true) {
      // Fetch updated event data
      final updatedEvent = await FirebaseService.getEventById(_event.id);
      setState(() {
        _event = updatedEvent;
      });
    }
  }

  Future<void> _confirmEdit(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AuthDialog(
          title: 'Edit Event',
          action: 'Edit',
        );
      },
    );

    if (result == true) {
      await _navigateToEditEventPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;

    // Debugging: Print participants to console
    print('Participants in EventDetailsPage: ${event.participants}');

    return Scaffold(
      appBar: AppBar(
        title: Text('Event Details'),
        actions: [
          if (_currentUser?.uid == event.createdBy)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => _confirmEdit(context),
            ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.imageUrl.isNotEmpty)
              Center(
                child: CachedNetworkImage(
                  imageUrl: event.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: Text('Failed to load image',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ),
              ),
            SizedBox(height: 16),
            _buildSectionTitle('Event Details'),
            _buildCardRow([
              _buildDetailCard(Icons.title, 'Title', event.title),
              _buildDetailCard(
                  Icons.description, 'Description', event.description),
            ]),
            _buildCardRow([
              _buildDetailCard(Icons.location_on, 'Location', event.location),
              _buildDetailCard(Icons.person, 'Organizer', event.organizer),
            ]),
            _buildDetailCard(Icons.people, 'Available Seats',
                event.availableSeats.toString()),
            SizedBox(height: 16),
            _buildSectionTitle('Event Schedule'),
            _buildCardRow([
              _buildDetailCard(Icons.calendar_today, 'Date',
                  DateFormat('yyyy-MM-dd').format(event.date)),
              _buildDetailCard(Icons.access_time, 'Start Time',
                  DateFormat('HH:mm').format(event.startTime)),
            ]),
            _buildDetailCard(Icons.access_time_filled, 'End Time',
                DateFormat('HH:mm').format(event.endTime)),
            SizedBox(height: 16),
            _buildSectionTitle('Tags'),
            _buildDetailCard(Icons.label, 'Tags', event.tags),
            SizedBox(height: 16),
            _buildSectionTitle('Details Others'),
            _buildCardRow([
              _buildDetailCard(Icons.article, 'Terms', event.terms),
              _buildDetailCard(
                  Icons.contact_phone, 'Contact Info', event.contactInfo),
            ]),
            _buildDetailCard(Icons.link, 'Related Link', event.relatedLink),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),
            if (event.participants.isEmpty)
              Center(
                child: Text(
                  'No participants yet. Be the first to join!',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Participants:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ...event.participants.map((participant) {
                    return ListTile(
                      leading: Icon(Icons.person),
                      title: Text(participant.fullName ?? 'Unknown'),
                      subtitle: Text(participant.email ?? 'Unknown'),
                    );
                  }).toList(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent),
      ),
    );
  }

  Widget _buildCardRow(List<Widget> cards) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: cards.map((card) => Expanded(child: card)).toList(),
    );
  }

  Widget _buildDetailCard(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700]),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
