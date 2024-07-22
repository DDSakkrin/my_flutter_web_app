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
  final List<UserModel> participants;
  final String organizer; // เพิ่มฟิลด์ใหม่
  final String relatedLink; // เพิ่มฟิลด์ใหม่
  final String terms; // เพิ่มฟิลด์ใหม่
  final int availableSeats; // เพิ่มฟิลด์ใหม่
  final String contactInfo; // เพิ่มฟิลด์ใหม่
  final String tags; // เพิ่มฟิลด์ใหม่

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
    return Event(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      createdBy: map['createdBy'],
      date: DateTime.parse(map['date']),
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      reminderTime: map['reminderTime'] != null
          ? DateTime.parse(map['reminderTime'])
          : null,
      location: map['location'],
      participants: List<UserModel>.from(map['participants']?.map((x) => UserModel.fromMap(Map<String, dynamic>.from(x))) ?? const []),
      organizer: map['organizer'],
      relatedLink: map['relatedLink'],
      terms: map['terms'],
      availableSeats: map['availableSeats'],
      contactInfo: map['contactInfo'],
      tags: map['tags'],
    );
  }

  void addParticipant(UserModel user) {
    if (!isParticipant(user)) {
      participants.add(user);
    }
  }

  void removeParticipant(UserModel user) {
    participants.removeWhere((participant) => participant.id == user.id);
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
