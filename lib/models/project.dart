enum ProjectStatus { open, applied, inProgress, completed }

extension ProjectStatusExtension on ProjectStatus {
  String get label {
    switch (this) {
      case ProjectStatus.open:
        return 'Open';
      case ProjectStatus.applied:
        return 'Applied';
      case ProjectStatus.inProgress:
        return 'In Progress';
      case ProjectStatus.completed:
        return 'Completed';
    }
  }
}

class Project {
  final String id;
  final String title;
  final String company;
  final double payout;
  final String category;
  final String duration;
  final String description;
  final List<String> skills;
  final ProjectStatus status;
  final DateTime deadline;
  final int spotsLeft;
  final bool isBookmarked;
  final DateTime? appliedDate;

  const Project({
    required this.id,
    required this.title,
    required this.company,
    required this.payout,
    this.category = 'General',
    this.duration = '1-2 weeks',
    this.description = '',
    this.skills = const [],
    required this.deadline,
    this.status = ProjectStatus.open,
    this.spotsLeft = 3,
    this.isBookmarked = false,
    this.appliedDate,
  });

  // Backward-compatible alias for UI components referencing stipend
  double get stipend => payout;

  Project copyWith({
    String? id,
    String? title,
    String? company,
    double? payout,
    String? category,
    String? duration,
    String? description,
    List<String>? skills,
    ProjectStatus? status,
    DateTime? deadline,
    int? spotsLeft,
    bool? isBookmarked,
    DateTime? appliedDate,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      company: company ?? this.company,
      payout: payout ?? this.payout,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      description: description ?? this.description,
      skills: skills ?? this.skills,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      spotsLeft: spotsLeft ?? this.spotsLeft,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      appliedDate: appliedDate ?? this.appliedDate,
    );
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      title: json['title'] as String,
      company: json['company'] as String,
      payout: (json['payout'] ?? json['stipend'] as num).toDouble(),
      category: json['category'] as String? ?? 'General',
      duration: json['duration'] as String? ?? '1-2 weeks',
      description: json['description'] as String? ?? '',
      skills: json['skills'] != null
          ? List<String>.from(json['skills'] as List)
          : const [],
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : DateTime.now().add(const Duration(days: 7)),
      status: ProjectStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ProjectStatus.open,
      ),
      spotsLeft: json['spotsLeft'] as int? ?? 2,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      appliedDate: json['appliedDate'] != null
          ? DateTime.parse(json['appliedDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'company': company,
      'payout': payout,
      'category': category,
      'duration': duration,
      'description': description,
      'skills': skills,
      'deadline': deadline.toIso8601String(),
      'status': status.name,
      'spotsLeft': spotsLeft,
      'isBookmarked': isBookmarked,
      'appliedDate': appliedDate?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
