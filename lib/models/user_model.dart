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
  final String? phoneNumber;
  final String? otherRequirements;
  final String? education;
  final bool isVerified;
  final bool isFavorited;
  final String status;
  final bool isOnline;
  final DateTime? lastSeen;
  final String connectionStatus; // NONE, PENDING_SENT, PENDING_RECEIVED, ACCEPTED, REJECTED
  final String? connectionId;
  final bool hasPastIssues;
  final bool acceptsPastIssues;
  final String? pastIssuesDetails;
  final String? acceptedPastIssuesDetails;
  
  // New Fields
  final String? maritalStatus;
  final String? currentCity;
  final double? monthlyIncome;
  final int? siblings;
  final int? familyMembers;
  final String? lookingForAge;
  final String? lookingForType;
  final String verifiedStatus; // active, inactive
  final String? religionSect;
  final String? religionCast;
  final List<String> interests;
  final List<String> personalityTraits;
  final List<String> lifeStyle;
  final String? grewUpIn;
  final bool managedBySomeoneElse;
  final bool facingChallenges;
  final List<String> facingChallengesList;
  final bool readyToQaboolChallenges;
  final List<String> readyToQaboolChallengesList;
  final String? language;
  final DateTime? updatedAt;

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
    this.education,
    this.isVerified = false,
    this.isFavorited = false,
    this.status = 'ACTIVE',
    this.isOnline = false,
    this.lastSeen,
    this.connectionStatus = 'NONE',
    this.connectionId,
    this.hasPastIssues = false,
    this.acceptsPastIssues = true,
    this.pastIssuesDetails,
    this.acceptedPastIssuesDetails,
    this.phoneNumber,
    this.maritalStatus,
    this.currentCity,
    this.monthlyIncome,
    this.siblings,
    this.familyMembers,
    this.lookingForAge,
    this.lookingForType,
    this.verifiedStatus = 'inactive',
    this.religionSect,
    this.religionCast,
    this.interests = const [],
    this.personalityTraits = const [],
    this.lifeStyle = const [],
    this.grewUpIn,
    this.otherRequirements,
    this.managedBySomeoneElse = false,
    this.facingChallenges = false,
    this.facingChallengesList = const [],
    this.readyToQaboolChallenges = false,
    this.readyToQaboolChallengesList = const [],
    this.language,
    this.updatedAt,
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

  String get lastSeenStatus {
    if (isOnline) return 'Active now';
    if (lastSeen == null) return 'Active today'; // Fallback if data missing but we assume active today
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen!);
    
    if (difference.inMinutes <= 20) {
      return 'Active now';
    } else if (difference.inHours <= 24) {
      return 'Active today';
    } else {
      final days = difference.inDays;
      if (days == 0) return 'Active today';
      return 'Active $days ${days == 1 ? 'day' : 'days'} ago';
    }
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    try {
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value);
      }
    } catch (e) {
      print('UserModel: Error parsing date: $value - $e');
    }
    return null;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      profileImageUrl: json['profileImageUrl'],
      bio: json['bio'],
      age: _toInt(json['age']),
      dob: _toDateTime(json['dob']),
      gender: json['gender'],
      region: json['region'],
      religion: json['religion'],
      ethnicity: json['ethnicity'],
      height: _toDouble(json['height']),
      weight: _toDouble(json['weight']),
      education: json['education'],
      isVerified: json['isVerified'] ?? false,
      isFavorited: json['isFavorited'] ?? false,
      status: json['status']?.toString() ?? 'ACTIVE',
      isOnline: json['isOnline'] ?? false,
      lastSeen: _toDateTime(json['lastSeen']),
      connectionStatus: json['connectionStatus']?.toString() ?? 'NONE',
      connectionId: json['connectionId']?.toString(),
      hasPastIssues: json['hasPastIssues'] ?? false,
      acceptsPastIssues: json['acceptsPastIssues'] ?? true,
      phoneNumber: json['phoneNumber']?.toString(),
      maritalStatus: json['maritalStatus'],
      currentCity: json['currentCity'],
      monthlyIncome: _toDouble(json['monthlyIncome']),
      siblings: _toInt(json['siblings']),
      familyMembers: _toInt(json['familyMembers']),
      lookingForAge: json['lookingForAge'],
      lookingForType: json['lookingForType'],
      verifiedStatus: json['verifiedStatus']?.toString() ?? 'inactive',
      religionSect: json['religionSect'],
      religionCast: json['religionCast'],
      interests: json['interests'] != null ? List<String>.from(json['interests']) : const [],
      personalityTraits: json['personalityTraits'] != null ? List<String>.from(json['personalityTraits']) : const [],
      lifeStyle: json['lifeStyle'] != null ? List<String>.from(json['lifeStyle']) : const [],
      grewUpIn: json['grewUpIn']?.toString(),
      pastIssuesDetails: json['pastIssuesDetails']?.toString(),
      acceptedPastIssuesDetails: json['acceptedPastIssuesDetails']?.toString(),
      otherRequirements: json['otherRequirements']?.toString(),
      managedBySomeoneElse: json['managedBySomeoneElse'] ?? false,
      facingChallenges: json['facingChallenges'] ?? false,
      facingChallengesList: json['facingChallengesList'] != null ? List<String>.from(json['facingChallengesList']) : const [],
      readyToQaboolChallenges: json['readyToQaboolChallenges'] ?? false,
      readyToQaboolChallengesList: json['readyToQaboolChallengesList'] != null ? List<String>.from(json['readyToQaboolChallengesList']) : const [],
      language: json['language']?.toString(),
      updatedAt: _toDateTime(json['updatedAt']),
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
      'education': education,
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
      'verifiedStatus': verifiedStatus,
      'religionSect': religionSect,
      'religionCast': religionCast,
      'interests': interests,
      'personalityTraits': personalityTraits,
      'lifeStyle': lifeStyle,
      'grewUpIn': grewUpIn,
      'pastIssuesDetails': pastIssuesDetails,
      'acceptedPastIssuesDetails': acceptedPastIssuesDetails,
      'otherRequirements': otherRequirements,
      'managedBySomeoneElse': managedBySomeoneElse,
      'facingChallenges': facingChallenges,
      'facingChallengesList': facingChallengesList,
      'readyToQaboolChallenges': readyToQaboolChallenges,
      'readyToQaboolChallengesList': readyToQaboolChallengesList,
      'language': language,
      'updatedAt': updatedAt?.toIso8601String(),
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
    String? education,
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
    String? verifiedStatus,
    String? religionSect,
    String? religionCast,
    List<String>? interests,
    List<String>? personalityTraits,
    List<String>? lifeStyle,
    String? grewUpIn,
    String? otherRequirements,
    bool? managedBySomeoneElse,
    bool? facingChallenges,
    List<String>? facingChallengesList,
    bool? readyToQaboolChallenges,
    List<String>? readyToQaboolChallengesList,
    String? language,
    DateTime? updatedAt,
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
      education: education ?? this.education,
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
      verifiedStatus: verifiedStatus ?? this.verifiedStatus,
      religionSect: religionSect ?? this.religionSect,
      religionCast: religionCast ?? this.religionCast,
      interests: interests ?? this.interests,
      personalityTraits: personalityTraits ?? this.personalityTraits,
      lifeStyle: lifeStyle ?? this.lifeStyle,
      grewUpIn: grewUpIn ?? this.grewUpIn,
      otherRequirements: otherRequirements ?? this.otherRequirements,
      managedBySomeoneElse: managedBySomeoneElse ?? this.managedBySomeoneElse,
      facingChallenges: facingChallenges ?? this.facingChallenges,
      facingChallengesList: facingChallengesList ?? this.facingChallengesList,
      readyToQaboolChallenges: readyToQaboolChallenges ?? this.readyToQaboolChallenges,
      readyToQaboolChallengesList: readyToQaboolChallengesList ?? this.readyToQaboolChallengesList,
      language: language ?? this.language,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
