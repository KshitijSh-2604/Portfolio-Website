class PortfolioDataModel {
  final Map<String, dynamic> basics;
  final List<dynamic> projects;
  final List<dynamic> skills;
  final List<dynamic> education;
  final List<dynamic> experience;
  final List<dynamic> socials;
  final List<dynamic> certifications;

  PortfolioDataModel({
    required this.basics,
    required this.projects,
    required this.skills,
    required this.education,
    required this.experience,
    required this.socials,
    required this.certifications,
  });

  factory PortfolioDataModel.fromJson(Map<String, dynamic> json) {
    return PortfolioDataModel(
      basics: json['basics'] is Map ? Map<String, dynamic>.from(json['basics'] as Map) : {},
      projects: json['projects'] is List ? List<dynamic>.from(json['projects'] as List) : [],
      skills: json['skills'] is List ? List<dynamic>.from(json['skills'] as List) : [],
      education: json['education'] is List ? List<dynamic>.from(json['education'] as List) : [],
      experience: json['experience'] is List ? List<dynamic>.from(json['experience'] as List) : [],
      socials: json['socials'] is List ? List<dynamic>.from(json['socials'] as List) : [],
      certifications: json['certifications'] is List ? List<dynamic>.from(json['certifications'] as List) : [],
    );
  }

  // Getters for specific basics fields with defaults
  String get name => basics['name'] as String? ?? 'Kshitij Sharma';
  String get role => basics['role'] as String? ?? 'SDE / Flutter Developer';
  String get location => basics['location'] as String? ?? 'Delhi';
  String get avatarUrl => basics['avatarUrl']?.toString() ?? 'https://avatars.githubusercontent.com/u/55450150?v=4';
  String get resumeUrl => basics['resumeUrl']?.toString() ?? '';
  List<String> get about => basics['about'] is List 
      ? List<String>.from(basics['about'] as List) 
      : [];
}
