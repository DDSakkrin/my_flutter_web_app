class UserModel {
  final String id;
  final String fullName;
  final String email;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
  })  : assert(id.isNotEmpty, 'ID cannot be empty'),
        assert(fullName.isNotEmpty, 'Full name cannot be empty'),
        assert(email.isNotEmpty, 'Email cannot be empty');

  /// Converts UserModel instance to a Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
    };
  }

  /// Creates a UserModel instance from a Map.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    if (!map.containsKey('id') ||
        !map.containsKey('fullName') ||
        !map.containsKey('email')) {
      throw ArgumentError('Missing required field(s) in map');
    }

    return UserModel(
      id: map['id'],
      fullName: map['fullName'],
      email: map['email'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.id == id &&
        other.fullName == fullName &&
        other.email == email;
  }

  @override
  int get hashCode {
    return id.hashCode ^ fullName.hashCode ^ email.hashCode;
  }
}
