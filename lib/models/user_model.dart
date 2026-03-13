import 'package:intl/intl.dart';

class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? profileImageUrl;
  final String? bio;
  final int? age;
  final DateTime? dob;
  final String? gender;
  final String? region;
  final String? religion;
  final String? ethnicity;
  final int? height;
  final int? weight;
  final String? profession;
  final String? education;
  final String? specialConsiderations;
  final bool isVerified;
  final DateTime? lastSeen;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.profileImageUrl,
    this.bio,
    this.age,
    this.dob,
    this.gender,
    this.region,
    this.religion,
    this.ethnicity,
    this.height,
    this.weight,
    this.profession,
    this.education,
    this.specialConsiderations,
    this.isVerified = false,
    this.lastSeen,
  });

  String get fullName => '$firstName $lastName';

  bool get isOnline {
    if (lastSeen == null) return false;
    return DateTime.now().difference(lastSeen!).inMinutes < 5;
  }

  String get city {
    if (region == null) return "";
    return region!.split(',').first.trim();
  }

  String get country {
    if (region == null || !region!.contains(',')) return "";
    return region!.split(',').last.trim();
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      profileImageUrl: json['profileImageUrl'],
      bio: json['bio'],
      age: json['age'],
      dob: json['dob'] != null ? DateTime.parse(json['dob']) : null,
      gender: json['gender'],
      region: json['region'],
      religion: json['religion'],
      ethnicity: json['ethnicity'],
      height: json['height'],
      weight: json['weight'],
      profession: json['profession'],
      education: json['education'],
      specialConsiderations: json['specialConsiderations'],
      isVerified: json['isVerified'] ?? false,
      lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'age': age,
      'dob': dob != null ? formatter.format(dob!) : null,
      'gender': gender,
      'region': region,
      'religion': religion,
      'ethnicity': ethnicity,
      'height': height,
      'weight': weight,
      'profession': profession,
      'education': education,
      'specialConsiderations': specialConsiderations,
      'isVerified': isVerified,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }
}
