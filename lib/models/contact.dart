class Contact {
  final String id;
  final String userId;
  final String name;
  final String? phone;
  final String? email;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Contact({
    required this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.email,
    required this.createdAt,
    this.updatedAt,
  });

  // Create from phone contact
  factory Contact.fromPhoneContact({
    required String userId,
    required String name,
    String? phone,
    String? email,
  }) {
    return Contact(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      name: name,
      phone: phone,
      email: email,
      createdAt: DateTime.now(),
    );
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
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
      'phone': phone,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Contact copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Contact(id: $id, name: $name, phone: $phone)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contact && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
