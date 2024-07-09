import 'package:flutter/foundation.dart' show listEquals;

class Event {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String createdBy;
  final DateTime date;
  final DateTime? reminderTime;
  final List<Map<String, String>> joinedUsers;
  final String location;

  Event({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.createdBy,
    required this.date,
    this.reminderTime,
    List<Map<String, String>>? joinedUsers,
    required this.location,
  })  : joinedUsers = joinedUsers ?? [],
        assert(id.isNotEmpty, 'ID cannot be empty'),
        assert(title.isNotEmpty, 'Title cannot be empty'),
        assert(description.isNotEmpty, 'Description cannot be empty'),
        assert(createdBy.isNotEmpty, 'CreatedBy cannot be empty'),
        assert(location.isNotEmpty, 'Location cannot be empty');

  /// Converts Event instance to a Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'date': date.toIso8601String(),
      'reminderTime': reminderTime?.toIso8601String(),
      'joinedUsers': joinedUsers,
      'location': location,
    };
  }

  /// Creates an Event instance from a Map.
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

  /// Getter to extract user IDs from the joinedUsers list.
  List<String> get joinedUserIds {
    return joinedUsers.map((user) => user['userId']!).toList();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Event &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.imageUrl == imageUrl &&
        other.createdBy == createdBy &&
        other.date == date &&
        other.reminderTime == reminderTime &&
        listEquals(other.joinedUsers, joinedUsers) &&
        other.location == location;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        imageUrl.hashCode ^
        createdBy.hashCode ^
        date.hashCode ^
        reminderTime.hashCode ^
        joinedUsers.hashCode ^
        location.hashCode;
  }
}
