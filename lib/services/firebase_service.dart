import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';

class FirebaseService {
  static final DatabaseReference _eventRef =
      FirebaseDatabase.instance.reference().child('events');
  static final DatabaseReference _userRef =
      FirebaseDatabase.instance.reference().child('users');
  static final Reference _storageRef =
      FirebaseStorage.instance.ref().child('event_images');

  static Future<void> addEvent(Event event) async {
    try {
      await _eventRef.child(event.id).set(event.toMap());
      print('Event added: ${event.id}');
    } catch (e) {
      _logError('addEvent', e);
      throw Exception('Failed to add event');
    }
  }

  static Future<void> updateEvent(Event event) async {
    try {
      await _eventRef.child(event.id).update(event.toMap());
      print('Event updated: ${event.id}');
    } catch (e) {
      _logError('updateEvent', e);
      throw Exception('Failed to update event');
    }
  }

  static Future<void> deleteEvent(String eventId, {String? imageUrl}) async {
    try {
      if (imageUrl != null) {
        await _deleteImage(imageUrl);
      }
      await _eventRef.child(eventId).remove();
      print('Event deleted: $eventId');
    } catch (e) {
      _logError('deleteEvent', e);
      throw Exception('Failed to delete event');
    }
  }

  static Future<List<Event>> getEvents() async {
    try {
      DatabaseEvent event = await _eventRef.once();
      DataSnapshot snapshot = event.snapshot;
      List<Event> events = [];

      if (snapshot.value != null) {
        Map<dynamic, dynamic> map = snapshot.value as Map<dynamic, dynamic>;
        map.forEach((key, value) {
          try {
            if (value is Map) {
              Map<String, dynamic> eventMap = Map<String, dynamic>.from(value);
              events.add(Event.fromMap(eventMap));
            } else {
              print('Invalid event format for key: $key');
            }
          } catch (e) {
            _logError('getEvents -> parsing event', e);
          }
        });
      }
      print('Fetched ${events.length} events');
      return events;
    } catch (e) {
      _logError('getEvents', e);
      throw Exception('Failed to fetch events');
    }
  }

  static Future<UserModel?> getUserDetails(
      String uid, String fullName, String email) async {
    try {
      print('Fetching user details for UID: $uid');
      DatabaseEvent event = await _userRef.child(uid).once();
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        print('User data found for UID: $uid');
        return UserModel.fromMap(
            Map<String, dynamic>.from(snapshot.value as Map));
      } else {
        print('User not found for UID: $uid');
        // Here we can call a function to create new user data
        return await createUser(uid, fullName, email);
      }
    } catch (e) {
      _logError('getUserDetails', e);
      throw Exception('Failed to fetch user details');
    }
  }

  static Future<UserModel?> createUser(
      String id, String fullName, String email) async {
    try {
      UserModel newUser = UserModel(id: id, fullName: fullName, email: email);
      await _userRef.child(id).set(newUser.toMap());
      print('New user created with UID: $id');
      return newUser;
    } catch (e) {
      _logError('createUser', e);
      throw Exception('Failed to create user');
    }
  }

  static String generateEventId() {
    return _eventRef.push().key!;
  }

  static Future<void> _deleteImage(String imageUrl) async {
    try {
      await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      print('Image deleted: $imageUrl');
    } catch (e) {
      _logError('_deleteImage', e);
      throw Exception('Failed to delete image');
    }
  }

  static Future<void> joinEvent(String userId, String eventId) async {
    try {
      DatabaseReference eventRef =
          _eventRef.child(eventId).child('joinedUserIds').push();
      await eventRef.set(userId);
      print('User $userId joined event $eventId');
    } catch (e) {
      _logError('joinEvent', e);
      throw Exception('Failed to join event');
    }
  }

  static Future<void> leaveEvent(String userId, String eventId) async {
    try {
      DatabaseEvent event =
          await _eventRef.child(eventId).child('joinedUserIds').once();
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        Map<dynamic, dynamic> joinedUserIds =
            snapshot.value as Map<dynamic, dynamic>;
        String? keyToRemove;
        joinedUserIds.forEach((key, value) {
          if (value == userId) {
            keyToRemove = key;
          }
        });
        if (keyToRemove != null) {
          await _eventRef
              .child(eventId)
              .child('joinedUserIds')
              .child(keyToRemove!)
              .remove();
          print('User $userId left event $eventId');
        }
      }
    } catch (e) {
      _logError('leaveEvent', e);
      throw Exception('Failed to leave event');
    }
  }

  static Future<bool> checkIfUserJoined(String userId, String eventId) async {
    try {
      DatabaseEvent event =
          await _eventRef.child(eventId).child('joinedUserIds').once();
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        Map<dynamic, dynamic> joinedUserIds =
            snapshot.value as Map<dynamic, dynamic>;
        return joinedUserIds.containsValue(userId);
      }
      return false;
    } catch (e) {
      _logError('checkIfUserJoined', e);
      throw Exception('Failed to check if user joined event');
    }
  }

  static void _logError(String context, dynamic error) {
    print('Error in $context: $error');
  }
}
