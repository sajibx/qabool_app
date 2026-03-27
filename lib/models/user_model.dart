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
  final double? height;
  final double? weight;
  final String? profession;
  final String? education;
  final String? specialConsiderations;
  final bool isVerified;
  final bool isFavorited;
  final String status;
  final bool isOnline;
  final DateTime? lastSeen;
  final String connectionStatus; // NONE, PENDING_SENT, PENDING_RECEIVED, ACCEPTED, REJECTED
  final String? connectionId;
  final bool hasPastIssues;
  final bool acceptsPastIssues;
  final String? phoneNumber;

  
  // New Fields
  final String? maritalStatus;
  final String? currentCity;
  final double? monthlyIncome;
  final int? siblings;
  final int? familyMembers;
  final String? lookingForAge;
  final String? lookingForType;
  final String? lookingForProfession;
  final String verifiedStatus; // active, inactive
  final String? sect;
  final String? caste;

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
    this.isFavorited = false,
    this.status = 'ACTIVE',
    this.isOnline = false,
    this.lastSeen,
    this.connectionStatus = 'NONE',
    this.connectionId,
    this.hasPastIssues = false,
    this.acceptsPastIssues = true,
    this.phoneNumber,
    this.maritalStatus,
    this.currentCity,
    this.monthlyIncome,
    this.siblings,
    this.familyMembers,
    this.lookingForAge,
    this.lookingForType,
    this.lookingForProfession,
    this.verifiedStatus = 'inactive',
    this.sect,
    this.caste,
  });

  String get fullName => '$firstName $lastName';

  int get displayAge {
    if (age != null && age != 0) return age!;
    if (dob == null) return 0;
    final now = DateTime.now();
    int ageCalc = now.year - dob!.year;
    if (now.month < dob!.month || (now.month == dob!.month && now.day < dob!.day)) {
      ageCalc--;
    }
    return ageCalc;
  }

  String get city {
    if (currentCity != null && currentCity!.isNotEmpty) return currentCity!;
    if (region == null) return "";
    return region!.split(',').first.trim();
  }

  String get country {
    if (region == null || !region!.contains(',')) return "";
    return region!.split(',').last.trim();
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      profileImageUrl: json['profileImageUrl'],
      bio: json['bio'],
      age: json['age'],
      dob: json['dob'] != null ? DateTime.parse(json['dob']) : null,
      gender: json['gender'],
      region: json['region'],
      religion: json['religion'],
      ethnicity: json['ethnicity'],
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      profession: json['profession'],
      education: json['education'],
      specialConsiderations: json['specialConsiderations'],
      isVerified: json['isVerified'] ?? false,
      isFavorited: json['isFavorited'] ?? false,
      status: json['status']?.toString() ?? 'ACTIVE',
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen']) : null,
      connectionStatus: json['connectionStatus']?.toString() ?? 'NONE',
      connectionId: json['connectionId']?.toString(),
      hasPastIssues: json['hasPastIssues'] ?? false,
      acceptsPastIssues: json['acceptsPastIssues'] ?? true,
      phoneNumber: json['phoneNumber']?.toString(),
      maritalStatus: json['maritalStatus'],
      currentCity: json['currentCity'],
      monthlyIncome: json['monthlyIncome']?.toDouble(),
      siblings: json['siblings'],
      familyMembers: json['familyMembers'],
      lookingForAge: json['lookingForAge'],
      lookingForType: json['lookingForType'],
      lookingForProfession: json['lookingForProfession'],
      verifiedStatus: json['verifiedStatus']?.toString() ?? 'inactive',
      sect: json['sect'],
      caste: json['caste'],
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
      'isFavorited': isFavorited,
      'status': status,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'connectionStatus': connectionStatus,
      'connectionId': connectionId,
      'hasPastIssues': hasPastIssues,
      'acceptsPastIssues': acceptsPastIssues,
      'phoneNumber': phoneNumber,
      'maritalStatus': maritalStatus,
      'currentCity': currentCity,
      'monthlyIncome': monthlyIncome,
      'siblings': siblings,
      'familyMembers': familyMembers,
      'lookingForAge': lookingForAge,
      'lookingForType': lookingForType,
      'lookingForProfession': lookingForProfession,
      'verifiedStatus': verifiedStatus,
      'sect': sect,
      'caste': caste,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? profileImageUrl,
    String? bio,
    int? age,
    DateTime? dob,
    String? gender,
    String? region,
    String? religion,
    String? ethnicity,
    double? height,
    double? weight,
    String? profession,
    String? education,
    String? specialConsiderations,
    bool? isVerified,
    bool? isFavorited,
    String? status,
    bool? isOnline,
    DateTime? lastSeen,
    String? connectionStatus,
    String? connectionId,
    bool? hasPastIssues,
    bool? acceptsPastIssues,
    String? phoneNumber,
    String? maritalStatus,
    String? currentCity,
    double? monthlyIncome,
    int? siblings,
    int? familyMembers,
    String? lookingForAge,
    String? lookingForType,
    String? lookingForProfession,
    String? verifiedStatus,
    String? sect,
    String? caste,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      age: age ?? this.age,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      region: region ?? this.region,
      religion: religion ?? this.religion,
      ethnicity: ethnicity ?? this.ethnicity,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      profession: profession ?? this.profession,
      education: education ?? this.education,
      specialConsiderations: specialConsiderations ?? this.specialConsiderations,
      isVerified: isVerified ?? this.isVerified,
      isFavorited: isFavorited ?? this.isFavorited,
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      connectionId: connectionId ?? this.connectionId,
      hasPastIssues: hasPastIssues ?? this.hasPastIssues,
      acceptsPastIssues: acceptsPastIssues ?? this.acceptsPastIssues,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      currentCity: currentCity ?? this.currentCity,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      siblings: siblings ?? this.siblings,
      familyMembers: familyMembers ?? this.familyMembers,
      lookingForAge: lookingForAge ?? this.lookingForAge,
      lookingForType: lookingForType ?? this.lookingForType,
      lookingForProfession: lookingForProfession ?? this.lookingForProfession,
      verifiedStatus: verifiedStatus ?? this.verifiedStatus,
      sect: sect ?? this.sect,
      caste: caste ?? this.caste,
    );
  }
}
