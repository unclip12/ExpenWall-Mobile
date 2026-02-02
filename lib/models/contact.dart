import 'package:uuid/uuid.dart';

class Contact {
  final String id;
  final String userId;
  final String name;
  final String? phoneNumber;
  final String? email;
  final DateTime createdAt;
  final DateTime updatedAt;

  Contact({
    required this.id,
    required this.userId,
    required this.name,
    this.phoneNumber,
    this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create new contact
  factory Contact.create({
    required String userId,
    required String name,
    String? phoneNumber,
    String? email,
  }) {
    final now = DateTime.now();
    return Contact(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      phoneNumber: phoneNumber,
      email: email,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Copy with updated fields
  Contact copyWith({
    String? name,
    String? phoneNumber,
    String? email,
  }) {
    return Contact(
      id: id,
      userId: userId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'phoneNumber': phoneNumber,
        'email': email,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        id: json['id'] as String,
        userId: json['userId'] as String,
        name: json['name'] as String,
        phoneNumber: json['phoneNumber'] as String?,
        email: json['email'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  // Display helpers
  String get displayName => name;
  
  String get displayInfo {
    if (phoneNumber != null && phoneNumber!.isNotEmpty) {
      return phoneNumber!;
    }
    if (email != null && email!.isNotEmpty) {
      return email!;
    }
    return '';
  }

  bool get hasPhoneNumber => phoneNumber != null && phoneNumber!.isNotEmpty;
  bool get hasEmail => email != null && email!.isNotEmpty;
}
