import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String studentId;
  final String hostel;
  final String roomNumber;
  final String role;
  final DateTime createdAt;
  final String? phone;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.studentId,
    required this.hostel,
    required this.roomNumber,
    required this.role,
    required this.createdAt,
    this.phone,
  });

  bool get isStudent => role.toLowerCase() == AppConstants.roleStudent;
  bool get isWarden => role.toLowerCase() == AppConstants.roleWarden;

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime parsedCreatedAt;
    if (map['createdAt'] is Timestamp) {
      parsedCreatedAt = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      parsedCreatedAt = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return UserModel(
      uid: documentId,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      hostel: map['hostel'] as String? ?? '',
      roomNumber: map['roomNumber'] as String? ?? '',
      role: map['role'] as String? ?? AppConstants.roleStudent,
      createdAt: parsedCreatedAt,
      phone: map['phone'] as String?,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'studentId': studentId,
      'hostel': hostel,
      'roomNumber': roomNumber,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      if (phone != null) 'phone': phone,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? studentId,
    String? hostel,
    String? roomNumber,
    String? role,
    DateTime? createdAt,
    String? phone,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      studentId: studentId ?? this.studentId,
      hostel: hostel ?? this.hostel,
      roomNumber: roomNumber ?? this.roomNumber,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      phone: phone ?? this.phone,
    );
  }
}
