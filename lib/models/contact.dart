import 'package:uuid/uuid.dart';

enum ContactSource {
  manual,
  phone,
}

class Contact {
  final String id;
  final String userId;
  final String name;
  final String? phone;
  final String? email;
  final String? notes;
  final ContactSource source;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Contact({
    required this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.email,
    this.notes,
    this.source = ContactSource.manual,
    required this.createdAt,
    this.updatedAt,
  });

  factory Contact.create({
    required String userId,
    required String name,
    String? phone,
    String? email,
    String? notes,
    ContactSource source = ContactSource.manual,
  }) {
    return Contact(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      phone: phone,
      email: email,
      notes: notes,
      source: source,
      createdAt: DateTime.now(),
    );
  }

  Contact copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? email,
    String? notes,
    ContactSource? source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'notes': notes,
      'source': source.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      notes: json['notes'] as String?,
      source: ContactSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => ContactSource.manual,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  String get displayName => name;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  String get displayInfo {
    if (phone != null && phone!.isNotEmpty) return phone!;
    if (email != null && email!.isNotEmpty) return email!;
    return 'No contact info';
  }

  @override
  String toString() => 'Contact(id: $id, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contact && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
