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
  final String? pastIssuesDetails;
  final String? acceptedPastIssuesDetails;
  final String? phoneNumber;
  final String? otherRequirements;

  
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
  final List<String> interests;
  final List<String> languages;
  final List<String> personalityTraits;
  final List<String> lifeStyle;
  final List<String> hobbies;
  final String? marriageIntentions;
  final String? hasChildren;
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
    this.lookingForProfession,
    this.verifiedStatus = 'inactive',
    this.sect,
    this.caste,
    this.interests = const [],
    this.languages = const [],
    this.personalityTraits = const [],
    this.lifeStyle = const [],
    this.hobbies = const [],
    this.marriageIntentions,
    this.hasChildren,
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
      interests: json['interests'] != null ? List<String>.from(json['interests']) : const [],
      languages: json['languages'] != null ? List<String>.from(json['languages']) : const [],
      personalityTraits: json['personalityTraits'] != null ? List<String>.from(json['personalityTraits']) : const [],
      lifeStyle: json['lifeStyle'] != null ? List<String>.from(json['lifeStyle']) : const [],
      hobbies: json['hobbies'] != null ? List<String>.from(json['hobbies']) : const [],
      marriageIntentions: json['marriageIntentions']?.toString(),
      hasChildren: json['hasChildren']?.toString(),
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
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
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
      'interests': interests,
      'languages': languages,
      'personalityTraits': personalityTraits,
      'lifeStyle': lifeStyle,
      'hobbies': hobbies,
      'marriageIntentions': marriageIntentions,
      'hasChildren': hasChildren,
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
    List<String>? interests,
    List<String>? languages,
    List<String>? personalityTraits,
    List<String>? lifeStyle,
    List<String>? hobbies,
    String? marriageIntentions,
    String? hasChildren,
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
      interests: interests ?? this.interests,
      languages: languages ?? this.languages,
      personalityTraits: personalityTraits ?? this.personalityTraits,
      lifeStyle: lifeStyle ?? this.lifeStyle,
      hobbies: hobbies ?? this.hobbies,
      marriageIntentions: marriageIntentions ?? this.marriageIntentions,
      hasChildren: hasChildren ?? this.hasChildren,
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
