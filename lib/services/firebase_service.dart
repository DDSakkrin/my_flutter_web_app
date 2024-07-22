import 'dart:io';
import 'dart:typed_data';
import 'dart:collection';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logging/logging.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../services/image_service.dart'; // Import the ImageService

class FirebaseService {
  static final DatabaseReference _eventRef =
      FirebaseDatabase.instance.ref().child('events');
  static final Logger _logger = Logger('FirebaseService');

  static String generateEventId() {
    return _eventRef.push().key!;
  }

  static Future<void> addEvent(Event event) async {
    _logger.info('Starting addEvent operation');
    await _performDatabaseOperation(
      () async {
        await _eventRef.child(event.id).set(event.toMap());
        _logger.info('Event added: ${event.id}');
      },
      'addEvent',
    );
    _logger.info('Completed addEvent operation');
  }

  static Future<void> updateEvent(Event event) async {
    _logger.info('Starting updateEvent operation');
    await _performDatabaseOperation(
      () async {
        await _eventRef.child(event.id).update(event.toMap());
        _logger.info('Event updated: ${event.id}');
      },
      'updateEvent',
    );
    _logger.info('Completed updateEvent operation');
  }

  static Future<void> deleteEvent(String eventId, {String? imageUrl}) async {
    _logger.info('Starting deleteEvent operation');
    await _performDatabaseOperation(
      () async {
        if (imageUrl != null) {
          await ImageService.deleteImage(imageUrl);
        }
        await _eventRef.child(eventId).remove();
        _logger.info('Event deleted: $eventId');
      },
      'deleteEvent',
    );
    _logger.info('Completed deleteEvent operation');
  }

  static Future<List<Event>> getEvents({int limit = 10}) async {
    print('Starting getEvents operation');
    final snapshot = await _eventRef.limitToFirst(limit).get();
    final events = <Event>[];

    if (snapshot.value != null) {
      print('Snapshot received: ${snapshot.value}');
      final map = Map<String, dynamic>.from(
          snapshot.value as LinkedHashMap<dynamic, dynamic>);
      print('Snapshot converted to map: $map');

      map.forEach((key, value) {
        print('Processing event key: $key');
        if (value is Map) {
          try {
            final eventMap = Map<String, dynamic>.from(value);
            eventMap['id'] = key; // Ensure eventMap has id
            print('Event map created: $eventMap');

            // Check and convert participants
            if (eventMap.containsKey('participants') &&
                eventMap['participants'] != null) {
              print('Participants map created: ${eventMap['participants']}');
              final participantsMap = Map<String, dynamic>.from(
                  eventMap['participants'] as Map<dynamic, dynamic>);
              final participants = participantsMap.values
                  .map((participantValue) {
                    if (participantValue is Map) {
                      try {
                        return UserModel.fromMap(
                            Map<String, dynamic>.from(participantValue));
                      } catch (e) {
                        print(
                            'Error parsing participant: $participantValue, error: $e');
                        return null;
                      }
                    } else {
                      print('Invalid participant format: $participantValue');
                      return null;
                    }
                  })
                  .whereType<UserModel>()
                  .toList();
              print('Participants list during creation: $participants');
              eventMap['participants'] = participants;
            } else {
              eventMap['participants'] = [];
            }

            events.add(Event.fromMap(eventMap));
          } catch (e) {
            print(
                'Error parsing event for key: $key, value: $value, error: $e');
          }
        } else {
          print('Invalid event format for key: $key');
        }
      });
    } else {
      print('No events found in the database');
    }
    print('Fetched ${events.length} events');
    return events;
  }

  static Future<Event> getEventById(String eventId) async {
    print('Starting getEventById operation for eventId: $eventId');
    return await _performDatabaseOperation<Event>(
      () async {
        final snapshot = await _eventRef.child(eventId).get();
        if (snapshot.exists) {
          print('Snapshot received for eventId: $eventId');
          final eventMap = Map<String, dynamic>.from(
              snapshot.value as LinkedHashMap<dynamic, dynamic>);
          eventMap['id'] = eventId; // Ensure eventMap has id
          print('Event map created: $eventMap');

          // Check and convert participants
          if (eventMap.containsKey('participants') &&
              eventMap['participants'] != null) {
            print('Participants map created: ${eventMap['participants']}');
            final participantsMap = Map<String, dynamic>.from(
                eventMap['participants'] as Map<dynamic, dynamic>);
            final participants = <UserModel>[];

            participantsMap.forEach((participantKey, participantValue) {
              print('Processing participant key: $participantKey');
              if (participantValue is Map) {
                try {
                  final participantMap =
                      Map<String, dynamic>.from(participantValue);
                  print('Participant map created: $participantMap');
                  participants.add(UserModel.fromMap(participantMap));
                } catch (e) {
                  print('Error parsing participant: $participantValue');
                }
              } else {
                print('Invalid participant format: $participantValue');
              }
            });
            eventMap['participants'] = participants;
            print('Participants list created: $participants');
          } else {
            eventMap['participants'] = [];
          }

          return Event.fromMap(eventMap);
        } else {
          print('Event not found for eventId: $eventId');
          throw Exception('Event not found');
        }
      },
      'getEventById',
    );
  }

  static Stream<List<Event>> getEventsStream() {
    DatabaseReference eventsRef =
        FirebaseDatabase.instance.ref().child('events');
    return eventsRef.onValue.map((event) {
      final List<Event> events = [];
      if (event.snapshot.value != null) {
        final map =
            Map<String, dynamic>.from(event.snapshot.value as LinkedHashMap);
        map.forEach((key, value) {
          if (value is Map) {
            try {
              final eventMap = Map<String, dynamic>.from(value);
              eventMap['id'] = key;

              print('Event Map before participants parsing: $eventMap');

              // Check and convert participants
              if (eventMap.containsKey('participants') &&
                  eventMap['participants'] != null) {
                final participantsMap =
                    Map<String, dynamic>.from(eventMap['participants'] as Map);
                final participants = participantsMap.values
                    .map((participantValue) {
                      if (participantValue is Map) {
                        try {
                          final participantMap =
                              Map<String, dynamic>.from(participantValue);
                          print('Parsed participant map: $participantMap');
                          return participantMap;
                        } catch (e) {
                          print(
                              'Error parsing participant: $participantValue, error: $e');
                          return null;
                        }
                      } else {
                        print('Invalid participant format: $participantValue');
                        return null;
                      }
                    })
                    .whereType<Map<String, dynamic>>()
                    .toList();
                print('Participants list during creation: $participants');
                eventMap['participants'] = participants;
              } else {
                eventMap['participants'] = [];
              }

              print('Event Map after participants parsing: $eventMap');

              events.add(Event.fromMap(eventMap));
            } catch (e) {
              print('Error parsing event for key: $key, error: $e');
            }
          } else {
            print('Invalid event format for key: $key, value: $value');
          }
        });
      }
      return events;
    });
  }

  static Future<void> joinEvent(String eventId, UserModel user) async {
    _logger.info(
        'Starting joinEvent operation for event $eventId and user ${user.id}');
    try {
      final eventSnapshot = await _eventRef.child(eventId).get();

      if (!eventSnapshot.exists) {
        _logger.warning('Event $eventId does not exist');
        throw Exception('Event does not exist');
      }

      // Extract event details safely
      final eventMap = Map<String, dynamic>.from(eventSnapshot.value as Map);
      final participantsSnapshot =
          await _eventRef.child(eventId).child('participants').get();
      final participantsCount = participantsSnapshot.children.length;
      final availableSeats = eventMap['availableSeats'] ?? 0;

      if (participantsCount >= availableSeats) {
        _logger.warning('No available seats left for event $eventId');
        throw Exception('No available seats left for this event');
      }

      final participantsRef = _eventRef.child(eventId).child('participants');
      final participantSnapshot = await participantsRef.child(user.id).get();

      if (!participantSnapshot.exists) {
        await participantsRef.child(user.id).set(user.toMap());
        _logger.info('User ${user.id} joined event $eventId');
      } else {
        _logger
            .info('User ${user.id} is already a participant in event $eventId');
      }
    } catch (e, stackTrace) {
      _logger.severe(
          'Error in joinEvent operation for event $eventId and user ${user.id}: $e',
          e,
          stackTrace);
    }
  }

  static Future<void> leaveEvent(String eventId, UserModel user) async {
    _logger.info(
        'Starting leaveEvent operation for event $eventId and user ${user.id}');
    try {
      final participantsRef = _eventRef.child(eventId).child('participants');
      await participantsRef.child(user.id).remove();
      _logger.info('User ${user.id} left event $eventId');
    } catch (e, stackTrace) {
      _logger.severe(
          'Error in leaveEvent operation for event $eventId and user ${user.id}: $e',
          e,
          stackTrace);
    }
  }

  static Future<T> _performDatabaseOperation<T>(
    Future<T> Function() operation,
    String operationName,
  ) async {
    _logger.info('Starting $operationName database operation');
    int retries = 3;
    while (retries > 0) {
      try {
        return await operation();
      } catch (e, stackTrace) {
        if (retries == 1) {
          _logError('$operationName -> Database operation', e, stackTrace);
          rethrow;
        }
        retries--;
        _logger.warning(
            'Retrying $operationName operation, attempts left: $retries');
      }
    }
    _logger.severe('$operationName failed after retries');
    throw Exception('$operationName failed after retries');
  }

  static void _logError(String context, dynamic error, StackTrace stackTrace) {
    _logger.severe('Error in $context: $error', error, stackTrace);
  }
}
