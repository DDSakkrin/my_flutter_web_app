import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/event_model.dart';

class FirebaseService {
  static final DatabaseReference _dbRef = FirebaseDatabase.instance.reference().child('events');
  static final Reference _storage = FirebaseStorage.instance.ref().child('event_images');

  static Future<void> addEvent(Event event) async {
    try {
      await _dbRef.child(event.id).set(event.toMap());
      print('Event added: ${event.id}');
    } catch (e) {
      print('Error adding event: $e');
      throw Exception('Failed to add event: $e');
    }
  }

  static Future<void> updateEvent(Event event) async {
    try {
      await _dbRef.child(event.id).update(event.toMap());
      print('Event updated: ${event.id}');
    } catch (e) {
      print('Error updating event: $e');
      throw Exception('Failed to update event: $e');
    }
  }

  static Future<void> deleteEvent(String eventId, String? imageUrl) async {
    try {
      await _dbRef.child(eventId).remove();
      if (imageUrl != null) {
        await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        print('Image deleted: $imageUrl');
      }
      print('Event deleted: $eventId');
    } catch (e) {
      print('Error deleting event: $e');
      throw Exception('Failed to delete event: $e');
    }
  }

  static Future<List<Event>> getEvents() async {
    try {
      DatabaseEvent event = await _dbRef.once();
      DataSnapshot snapshot = event.snapshot;
      List<Event> events = [];
      
      if (snapshot.value != null) {
        Map<dynamic, dynamic> map = snapshot.value as Map<dynamic, dynamic>;
        map.forEach((key, value) {
          try {
            events.add(Event.fromMap(Map<String, dynamic>.from(value)));
          } catch (e) {
            print('Error parsing event: $e');
          }
        });
      }
      print('Fetched ${events.length} events');
      return events;
    } catch (e) {
      print('Error fetching events: $e');
      throw Exception('Failed to fetch events: $e');
    }
  }

  static String generateEventId() {
    return _dbRef.push().key!;
  }

  static Future<void> joinEvent(String eventId, String userId) async {
    try {
      final eventRef = _dbRef.child(eventId).child('joinedUsers');
      await eventRef.update({userId: true});
      print('User $userId joined event $eventId');
    } catch (e) {
      print('Error joining event: $e');
      throw Exception('Failed to join event: $e');
    }
  }

  static Future<void> cancelJoinEvent(String eventId, String userId) async {
    try {
      final eventRef = _dbRef.child(eventId).child('joinedUsers');
      await eventRef.child(userId).remove();
      print('User $userId canceled join for event $eventId');
    } catch (e) {
      print('Error canceling join event: $e');
      throw Exception('Failed to cancel join event: $e');
    }
  }
}
