import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { civilian, volunteer }

class UserModel {
  final String id;
  final String? name;
  final String? bio;
  final String phone;
  final int? age;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    this.name,
    this.bio,
    required this.phone,
    this.age,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: (data['name'] == 'null' || data['name'] == null)
          ? null
          : data['name'] as String,
      bio: (data['bio'] == 'null' || data['bio'] == null)
          ? null
          : data['bio'] as String,
      phone: data['phone'] as String,
      age: data['age'] != null ? data['age'] as int : null,
      role: UserRole.values.firstWhere(
        (e) => e.name.toLowerCase() == (data['role'] as String).toLowerCase(),
        orElse: () => UserRole.civilian,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'bio': bio,
      'phone': phone,
      'age': age,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? bio,
    String? phone,
    int? age,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      age: age ?? this.age,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
