class Group {
  final String id;
  final String userId;
  final String name;
  final List<String> memberIds; // Contact IDs
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Group({
    required this.id,
    required this.userId,
    required this.name,
    required this.memberIds,
    this.description,
    required this.createdAt,
    this.updatedAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      memberIds: List<String>.from(json['memberIds'] as List),
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'memberIds': memberIds,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Group copyWith({
    String? id,
    String? userId,
    String? name,
    List<String>? memberIds,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Group(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      memberIds: memberIds ?? this.memberIds,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get memberCount => memberIds.length;

  @override
  String toString() {
    return 'Group(id: $id, name: $name, members: ${memberIds.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Group && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
