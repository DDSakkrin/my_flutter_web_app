import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/event_model.dart';
import '../services/firebase_service.dart';

class EventDetailsPage extends StatelessWidget {
  final Event event;

  EventDetailsPage({required this.event});

  Future<void> _deleteEvent(BuildContext context) async {
    try {
      await FirebaseService.deleteEvent(event.id, event.imageUrl);
      Navigator.pop(context); // Navigate back after deletion
    } catch (e) {
      // Handle any errors here
      print('Error deleting event: $e');
      // Show an error dialog or message
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to delete event. Please try again later.'),
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
  }

  Future<void> _confirmDelete(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Event'),
          content: Text('Are you sure you want to delete this event?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteEvent(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event Details'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              event.description,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Date: ${event.date.toLocal()}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
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
                      imageUrl: event.imageUrl!,
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
