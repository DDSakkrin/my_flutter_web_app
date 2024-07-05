class Event {
  String id;
  String title;
  String description;
  String? imageUrl;
  String createdBy;
  DateTime date;
  DateTime? reminderTime;
  List<String> joinedUsers;
  String location;

  Event({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.createdBy,
    required this.date,
    this.reminderTime,
    required this.joinedUsers,
    required this.location,
  });

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

  static Event fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      createdBy: map['createdBy'],
      date: DateTime.parse(map['date']),
      reminderTime: map['reminderTime'] != null ? DateTime.parse(map['reminderTime']) : null,
      joinedUsers: List<String>.from(map['joinedUsers'] ?? []),
      location: map['location'],
    );
  }
}
