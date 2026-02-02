import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'contact.dart';

class Group {
  final String id;
  final String userId;
  final String name;
  final List<String> memberIds; // Contact IDs
  final int colorValue; // Store as int for JSON serialization
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? description;

  Group({
    required this.id,
    required this.userId,
    required this.name,
    required this.memberIds,
    required this.colorValue,
    required this.createdAt,
    this.updatedAt,
    this.description,
  });

  factory Group.create({
    required String userId,
    required String name,
    List<String> memberIds = const [],
    Color color = Colors.blue,
    String? description,
  }) {
    return Group(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      memberIds: List.from(memberIds),
      colorValue: color.value,
      createdAt: DateTime.now(),
      description: description,
    );
  }

  Color get color => Color(colorValue);

  Group copyWith({
    String? id,
    String? userId,
    String? name,
    List<String>? memberIds,
    int? colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
  }) {
    return Group(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      memberIds: memberIds ?? List.from(this.memberIds),
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
    );
  }

  Group addMember(String contactId) {
    if (memberIds.contains(contactId)) return this;
    final newMembers = List<String>.from(memberIds)..add(contactId);
    return copyWith(
      memberIds: newMembers,
      updatedAt: DateTime.now(),
    );
  }

  Group removeMember(String contactId) {
    final newMembers = List<String>.from(memberIds)..remove(contactId);
    return copyWith(
      memberIds: newMembers,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'memberIds': memberIds,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'description': description,
    };
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      memberIds: (json['memberIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      colorValue: json['colorValue'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      description: json['description'] as String?,
    );
  }

  int get memberCount => memberIds.length;

  bool hasMember(String contactId) => memberIds.contains(contactId);

  @override
  String toString() => 'Group(id: $id, name: $name, members: ${memberIds.length})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Group && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Predefined group colors
class GroupColors {
  static const List<Color> presets = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFF44336), // Red
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFFE91E63), // Pink
    Color(0xFF00BCD4), // Cyan
    Color(0xFFFFEB3B), // Yellow
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
  ];

  static Color random() {
    return presets[DateTime.now().millisecond % presets.length];
  }
}
