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
            Text(
              widget.event.title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              widget.event.description,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Date: ${widget.event.date.toLocal()}'.split(' ')[0],
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            if (widget.event.imageUrl != null && widget.event.imageUrl!.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: widget.event.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Text('Failed to load image', style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _confirmDelete(context),
              child: Text('Delete Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
