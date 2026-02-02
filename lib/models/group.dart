import 'package:uuid/uuid.dart';

class Group {
  final String id;
  final String userId;
  final String name;
  final List<String> memberIds; // Contact IDs
  final DateTime createdAt;
  final DateTime updatedAt;

  Group({
    required this.id,
    required this.userId,
    required this.name,
    required this.memberIds,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create new group
  factory Group.create({
    required String userId,
    required String name,
    List<String>? memberIds,
  }) {
    final now = DateTime.now();
    return Group(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      memberIds: memberIds ?? [],
      createdAt: now,
      updatedAt: now,
    );
  }

  // Copy with updated fields
  Group copyWith({
    String? name,
    List<String>? memberIds,
  }) {
    return Group(
      id: id,
      userId: userId,
      name: name ?? this.name,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Add member
  Group addMember(String contactId) {
    if (memberIds.contains(contactId)) return this;
    return copyWith(
      memberIds: [...memberIds, contactId],
    );
  }

  // Remove member
  Group removeMember(String contactId) {
    return copyWith(
      memberIds: memberIds.where((id) => id != contactId).toList(),
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'memberIds': memberIds,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'] as String,
        userId: json['userId'] as String,
        name: json['name'] as String,
        memberIds: (json['memberIds'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  // Helpers
  int get memberCount => memberIds.length;
  bool get isEmpty => memberIds.isEmpty;
  bool hasMember(String contactId) => memberIds.contains(contactId);
}
