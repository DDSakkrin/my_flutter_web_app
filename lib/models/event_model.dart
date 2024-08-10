import 'package:equatable/equatable.dart';
import 'user_model.dart';

class Event extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String createdBy;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? reminderTime;
  final String location;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.createdBy,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.reminderTime,
    required this.location,
    required this.participants,
    required this.organizer,
    required this.relatedLink,
    required this.terms,
    required this.availableSeats,
    required this.contactInfo,
    required this.tags,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'date': date.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'reminderTime': reminderTime?.toIso8601String(),
      'location': location,
      'participants': participants.map((x) => x.toMap()).toList(),
      'organizer': organizer,
      'relatedLink': relatedLink,
      'terms': terms,
      'availableSeats': availableSeats,
      'contactInfo': contactInfo,
      'tags': tags,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    List<String> missingFields = [];
    if (!map.containsKey('id')) missingFields.add('id');
    if (!map.containsKey('title')) missingFields.add('title');
    if (!map.containsKey('description')) missingFields.add('description');
    if (!map.containsKey('createdBy')) missingFields.add('createdBy');
    if (!map.containsKey('date')) missingFields.add('date');
    if (!map.containsKey('location')) missingFields.add('location');

    if (missingFields.isNotEmpty) {
      throw ArgumentError(
          'Missing required field(s): ${missingFields.join(', ')}');
    }

    try {
      return Event(
        id: map['id'],
        title: map['title'],
        description: map['description'],
        imageUrl: map['imageUrl'],
        createdBy: map['createdBy'],
        date: DateTime.parse(map['date']),
        reminderTime: map['reminderTime'] != null
            ? DateTime.parse(map['reminderTime'])
            : null,
        joinedUsers: map['joinedUsers'] != null
            ? List<Map<String, String>>.from(map['joinedUsers'])
            : [],
        location: map['location'],
      );
    } catch (e) {
      throw ArgumentError('Invalid data format in map: $e');
    }
  }

  /// Creates a copy of this Event instance with the given fields replaced.
  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? createdBy,
    DateTime? date,
    DateTime? reminderTime,
    List<Map<String, String>>? joinedUsers,
    String? location,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdBy: createdBy ?? this.createdBy,
      date: date ?? this.date,
      reminderTime: reminderTime ?? this.reminderTime,
      joinedUsers: joinedUsers ?? this.joinedUsers,
      location: location ?? this.location,
    );
  }

  bool isParticipant(UserModel user) {
    return participants.any((participant) => participant.id == user.id);
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        imageUrl,
        createdBy,
        date,
        startTime,
        endTime,
        reminderTime,
        location,
        participants,
        organizer,
        relatedLink,
        terms,
        availableSeats,
        contactInfo,
        tags,
      ];
}
