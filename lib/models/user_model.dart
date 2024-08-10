import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String? fullName;
  final String? email;

  UserModel({
    required this.id,
    this.fullName,
    this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    if (!map.containsKey('id')) {
      throw ArgumentError('Missing required field: id');
    }

    return UserModel(
      id: map['id'],
      fullName: map['fullName'],
      email: map['email'],
    );
  }

  @override
  List<Object?> get props => [id, fullName, email];
}
